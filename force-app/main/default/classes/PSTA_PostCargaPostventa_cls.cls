public without sharing class PSTA_PostCargaPostventa_cls {

    private static final Set<String> STATUSES_TO_RESET_FOR_ADVISOR_CHANGE = new Set<String>{
        PSTA_ListadoClientes_cls.ESTATUS_CONTACTO_EFECTIVO_EXITOSO,
        PSTA_ListadoClientes_cls.ESTATUS_CONTACTO_NO_EXITOSO,
        PSTA_ListadoClientes_cls.ESTATUS_NO_QUIERE_SER_CONTACTADO
    };

    public class ProcessResult {
        public List<Account> accountsToUpdate = new List<Account>();
        public List<Opportunity> opportunitiesToDelete = new List<Opportunity>();
        public List<Task> tasksToDelete = new List<Task>();
        public List<PSTA_PostCargaPostventa_Request> cadenceRequests = new List<PSTA_PostCargaPostventa_Request>();
        public Set<String> impactedAdvisorIds = new Set<String>();
    }

    public static ProcessResult processAccounts(List<Account> scopeAccounts) {
        return processAccounts(scopeAccounts, new Set<Id>());
    }

    public static ProcessResult processAccounts(List<Account> scopeAccounts, Set<Id> advisorChangedAccountIds) {
        ProcessResult result = new ProcessResult();
        if (scopeAccounts == null || scopeAccounts.isEmpty()) {
            return result;
        }

        Map<Id, Account> scopeById = new Map<Id, Account>(scopeAccounts);
        Map<Id, Account> accountsById = new Map<Id, Account>(
            PSTA_PostCargaPostventa_soql.getAccountsForProcessing(scopeById.keySet())
        );

        if (accountsById.isEmpty()) {
            return result;
        }

        ConfiguracionActinver__c configContratos = PSTA_SegmentacionClientesSelector_cls.getConfiguracionContratosPostventa();
        Set<String> validStatuses = PSTA_UtilityClass.splitValuesMultiPickList(configContratos.EstatusContrato__c);
        Set<String> validTypes = PSTA_UtilityClass.splitValuesMultiPickList(configContratos.TipoContratos__c);

        Set<Id> validAccountIds = new Set<Id>();
        Set<Id> invalidAccountIds = new Set<Id>();
        Map<Id, Account> updatesByAccountId = new Map<Id, Account>();

        for (Account currentAccount : accountsById.values()) {
            if (String.isNotBlank(currentAccount.ID_Asesor__c)) {
                result.impactedAdvisorIds.add(currentAccount.ID_Asesor__c);
            }

            List<Contract> validContracts = filterValidContracts(currentAccount.Contracts, validStatuses, validTypes);
            if (validContracts.isEmpty()) {
                invalidAccountIds.add(currentAccount.Id);
                updatesByAccountId.put(currentAccount.Id, new Account(
                    Id = currentAccount.Id,
                    EstatusContacto__c = null,
                    ContactoPriorizadoEsteMes__c = false,
                    PriorizacionContacto__c = false,
                    PriorizacionVisita__c = false
                ));
                continue;
            }

            validAccountIds.add(currentAccount.Id);
            Account recalculated = buildAccountRecalculation(currentAccount, validContracts);
            if (recalculated != null) {
                mergeAccountUpdate(updatesByAccountId, recalculated);
            }

            if (advisorChangedAccountIds != null &&
                advisorChangedAccountIds.contains(currentAccount.Id) &&
                shouldResetStatusForAdvisorChange(currentAccount)) {
                mergeAccountUpdate(
                    updatesByAccountId,
                    new Account(
                        Id = currentAccount.Id,
                        EstatusContacto__c = 'Pendiente'
                    )
                );
            }
        }

        result.accountsToUpdate.addAll(updatesByAccountId.values());
        collectDeletes(invalidAccountIds, result);
        prepareCadenceRequests(accountsById, invalidAccountIds, result);
        return result;
    }

    public static void refreshSummaryMeta(Set<String> advisorIds) {
        if (advisorIds == null || advisorIds.isEmpty()) {
            return;
        }

        Map<String, Integer> targetMetaByAdvisor = PSTA_RegistroResumenGlobal_cls.getMetaByAccount(
            new List<String>(advisorIds)
        );

        List<ResumenGlobalPostventa__c> summariesToUpdate = new List<ResumenGlobalPostventa__c>();
        for (ResumenGlobalPostventa__c summary : PSTA_PostCargaPostventa_soql.getResumenesByAdvisorIds(advisorIds)) {
            Integer newMeta = targetMetaByAdvisor.containsKey(summary.ExternalId_Nomina__c)
                ? targetMetaByAdvisor.get(summary.ExternalId_Nomina__c)
                : 0;

            if (summary.Meta__c != newMeta) {
                summariesToUpdate.add(new ResumenGlobalPostventa__c(
                    Id = summary.Id,
                    Meta__c = newMeta
                ));
            }
        }

        if (!summariesToUpdate.isEmpty()) {
            Database.update(summariesToUpdate, false);
        }
    }

    private static List<Contract> filterValidContracts(
        List<Contract> contracts,
        Set<String> validStatuses,
        Set<String> validTypes
    ) {
        List<Contract> validContracts = new List<Contract>();
        if (contracts == null) {
            return validContracts;
        }

        for (Contract contractRecord : contracts) {
            if (contractRecord == null) {
                continue;
            }

            if (contractRecord.AccountOpeningDate__c == null || contractRecord.Saldo__c == null) {
                continue;
            }

            if (!validStatuses.contains(contractRecord.Status__c)) {
                continue;
            }

            if (!validTypes.contains(contractRecord.TypeOfContract__c)) {
                continue;
            }

            validContracts.add(contractRecord);
        }

        return validContracts;
    }

    private static Account buildAccountRecalculation(Account currentAccount, List<Contract> validContracts) {
        Decimal totalBalance = 0;
        Date oldestOpeningDate;
        for (Contract contractRecord : validContracts) {
            totalBalance += Decimal.valueOf(contractRecord.Saldo__c);
            if (oldestOpeningDate == null || contractRecord.AccountOpeningDate__c < oldestOpeningDate) {
                oldestOpeningDate = contractRecord.AccountOpeningDate__c;
            }
        }

        String recalculatedSegment = currentAccount.Segmento__c;
        if (currentAccount.BanqueroAsignado__r != null &&
            currentAccount.BanqueroAsignado__r.BusinessUnitMember != null &&
            currentAccount.BanqueroAsignado__r.BusinessUnitMember instanceof Banker) {
            recalculatedSegment = PSTA_Segmentacion_cls.determinarSegmento(
                (Banker) currentAccount.BanqueroAsignado__r.BusinessUnitMember
            );
        }

        Account updateRecord = new Account(Id = currentAccount.Id);
        Boolean requiresUpdate = false;

        if (currentAccount.SaldoIntegral__c != totalBalance) {
            updateRecord.SaldoIntegral__c = totalBalance;
            requiresUpdate = true;
        }

        if (currentAccount.FechaAntiguedad__c != oldestOpeningDate) {
            updateRecord.FechaAntiguedad__c = oldestOpeningDate;
            requiresUpdate = true;
        }

        if (recalculatedSegment != currentAccount.Segmento__c) {
            updateRecord.Segmento__c = recalculatedSegment;
            requiresUpdate = true;
        }

        return requiresUpdate ? updateRecord : null;
    }

    private static Boolean shouldResetStatusForAdvisorChange(Account currentAccount) {
        return currentAccount != null &&
            String.isNotBlank(currentAccount.EstatusContacto__c) &&
            STATUSES_TO_RESET_FOR_ADVISOR_CHANGE.contains(currentAccount.EstatusContacto__c);
    }

    private static void mergeAccountUpdate(Map<Id, Account> updatesByAccountId, Account updateRecord) {
        if (updatesByAccountId == null || updateRecord == null || updateRecord.Id == null) {
            return;
        }

        Account existingUpdate = updatesByAccountId.get(updateRecord.Id);
        if (existingUpdate == null) {
            updatesByAccountId.put(updateRecord.Id, updateRecord);
            return;
        }

        if (updateRecord.EstatusContacto__c != null || existingUpdate.EstatusContacto__c != null) {
            existingUpdate.EstatusContacto__c = updateRecord.EstatusContacto__c;
        }
        if (updateRecord.ContactoPriorizadoEsteMes__c != null) {
            existingUpdate.ContactoPriorizadoEsteMes__c = updateRecord.ContactoPriorizadoEsteMes__c;
        }
        if (updateRecord.PriorizacionContacto__c != null) {
            existingUpdate.PriorizacionContacto__c = updateRecord.PriorizacionContacto__c;
        }
        if (updateRecord.PriorizacionVisita__c != null) {
            existingUpdate.PriorizacionVisita__c = updateRecord.PriorizacionVisita__c;
        }
        if (updateRecord.SaldoIntegral__c != null) {
            existingUpdate.SaldoIntegral__c = updateRecord.SaldoIntegral__c;
        }
        if (updateRecord.FechaAntiguedad__c != null) {
            existingUpdate.FechaAntiguedad__c = updateRecord.FechaAntiguedad__c;
        }
        if (updateRecord.Segmento__c != null) {
            existingUpdate.Segmento__c = updateRecord.Segmento__c;
        }
    }

    private static void collectDeletes(Set<Id> invalidAccountIds, ProcessResult result) {
        if (invalidAccountIds == null || invalidAccountIds.isEmpty()) {
            return;
        }

        result.opportunitiesToDelete.addAll(
            PSTA_PostCargaPostventa_soql.getOpenOpportunities(invalidAccountIds)
        );
        result.tasksToDelete.addAll(
            PSTA_PostCargaPostventa_soql.getActiveTasks(invalidAccountIds)
        );
    }

    private static void prepareCadenceRequests(
        Map<Id, Account> accountsById,
        Set<Id> invalidAccountIds,
        ProcessResult result
    ) {
        Map<Id, Id> accountByContactId = getAccountByContactId(accountsById.values());
        if (accountByContactId.isEmpty()) {
            return;
        }

        for (ActionCadenceTracker tracker : PSTA_PostCargaPostventa_soql.getRunningTrackers(accountByContactId.keySet())) {
            Id accountId = accountByContactId.get(tracker.TargetId);
            if (accountId == null) {
                continue;
            }

            if (invalidAccountIds.contains(accountId)) {
                result.cadenceRequests.add(new PSTA_PostCargaPostventa_Request(
                    tracker.Id,
                    tracker.ActionCadenceId,
                    accountId,
                    null,
                    false
                ));
                continue;
            }
        }
    }

    private static Map<Id, Id> getAccountByContactId(List<Account> accounts) {
        Map<Id, Id> accountByContactId = new Map<Id, Id>();
        Set<Id> accountsWithoutPersonContact = new Set<Id>();

        for (Account currentAccount : accounts) {
            if (currentAccount.PersonContactId != null) {
                accountByContactId.put(currentAccount.PersonContactId, currentAccount.Id);
            } else {
                accountsWithoutPersonContact.add(currentAccount.Id);
            }
        }

        if (!accountsWithoutPersonContact.isEmpty()) {
            for (Contact relatedContact : PSTA_PostCargaPostventa_soql.getContactsByAccountIds(accountsWithoutPersonContact)) {
                if (!accountByContactId.containsKey(relatedContact.Id)) {
                    accountByContactId.put(relatedContact.Id, relatedContact.AccountId);
                }
            }
        }

        return accountByContactId;
    }
}
