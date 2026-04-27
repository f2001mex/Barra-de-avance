global without sharing class PSTA_PostCargaPostventa_bch implements Database.Batchable<SObject>, Database.Stateful {

    @TestVisible static Datetime testWindowStart;
    @TestVisible static Datetime testWindowEnd;
    @TestVisible static Set<Id> testImpactedAccountIds;
    @TestVisible static Set<Id> testAdvisorChangedAccountIds;
    @TestVisible private static final Set<String> CANCELLED_CONTRACT_STATUSES = new Set<String>{
        'C02',
        'CC02'
    };
    @TestVisible private static final Set<String> CONTRACT_HISTORY_FIELDS = new Set<String>{
        'Status__c'
    };
    @TestVisible private static final Set<String> ACCOUNT_HISTORY_FIELDS = new Set<String>{
        'ID_Asesor__c'
    };

    private Set<String> impactedAdvisorIds = new Set<String>();
    private Set<Id> advisorChangedAccountIds = new Set<Id>();

    global Iterable<SObject> start(Database.BatchableContext bc) {
        Datetime windowEnd = testWindowEnd != null ? testWindowEnd : System.now();
        Datetime windowStart = testWindowStart != null ? testWindowStart : windowEnd.addHours(-24);

        Set<Id> impactedAccountIds = new Set<Id>();
        if (Test.isRunningTest() && testImpactedAccountIds != null) {
            impactedAccountIds.addAll(testImpactedAccountIds);
            if (testAdvisorChangedAccountIds != null) {
                this.advisorChangedAccountIds.addAll(testAdvisorChangedAccountIds);
                impactedAccountIds.addAll(testAdvisorChangedAccountIds);
            }
        } else {
            for (ContractHistory contractHistoryRecord : [
                SELECT Contract.AccountId, Field, NewValue
                FROM ContractHistory
                WHERE Contract.AccountId != null
                AND Field IN :CONTRACT_HISTORY_FIELDS
                AND CreatedDate >= :windowStart
                AND CreatedDate < :windowEnd
            ]) {
                String newStatus = String.valueOf(contractHistoryRecord.NewValue);
                if (!CANCELLED_CONTRACT_STATUSES.contains(newStatus)) {
                    continue;
                }
                impactedAccountIds.add(contractHistoryRecord.Contract.AccountId);
            }

            for (AccountHistory accountHistoryRecord : [
                SELECT AccountId, Field
                FROM AccountHistory
                WHERE AccountId != null
                AND Field IN :ACCOUNT_HISTORY_FIELDS
                AND CreatedDate >= :windowStart
                AND CreatedDate < :windowEnd
            ]) {
                this.advisorChangedAccountIds.add(accountHistoryRecord.AccountId);
                impactedAccountIds.add(accountHistoryRecord.AccountId);
            }
        }

        List<SObject> impactedAccounts = new List<SObject>();
        if (!impactedAccountIds.isEmpty()) {
            impactedAccounts.addAll([
                SELECT Id, OwnerId, PersonContactId, ID_Asesor__c
                FROM Account
                WHERE Id IN :impactedAccountIds
            ]);
        }

        return impactedAccounts;
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Account> impactedAccounts = (List<Account>) scope;
        Set<Id> advisorChangeScopeIds = new Set<Id>();
        for (Account currentAccount : impactedAccounts) {
            if (this.advisorChangedAccountIds.contains(currentAccount.Id)) {
                advisorChangeScopeIds.add(currentAccount.Id);
            }
        }

        PSTA_PostCargaPostventa_cls.ProcessResult result = PSTA_PostCargaPostventa_cls.processAccounts(
            impactedAccounts,
            advisorChangeScopeIds
        );

        this.impactedAdvisorIds.addAll(result.impactedAdvisorIds);

        if (!result.accountsToUpdate.isEmpty()) {
            Database.update(result.accountsToUpdate, false);
        }

        if (!result.opportunitiesToDelete.isEmpty()) {
            Database.delete(result.opportunitiesToDelete, false);
        }

        if (!result.tasksToDelete.isEmpty()) {
            Database.delete(result.tasksToDelete, false);
        }

        if (!result.cadenceRequests.isEmpty()) {
            System.enqueueJob(new PSTA_PostCargaPostventaCadencias_qbl(result.cadenceRequests));
        }
    }

    global void finish(Database.BatchableContext bc) {
        PSTA_PostCargaPostventa_cls.refreshSummaryMeta(this.impactedAdvisorIds);
    }
}
