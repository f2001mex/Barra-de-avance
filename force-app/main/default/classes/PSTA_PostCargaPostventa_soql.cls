public without sharing class PSTA_PostCargaPostventa_soql {

    @TestVisible private static List<ActionCadenceTracker> testRunningTrackersOverride;
    @TestVisible private static List<ActionCadenceTracker> testTrackersByIdsOverride;

    public static List<Account> getAccountsForProcessing(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new List<Account>();
        }

        return [
            SELECT Id,
                   OwnerId,
                   PersonContactId,
                   ID_Asesor__c,
                   BanqueroAsignado__c,
                   Segmento__c,
                   SaldoIntegral__c,
                   FechaAntiguedad__c,
                   ContactoPriorizadoEsteMes__c,
                   PriorizacionContacto__c,
                   PriorizacionVisita__c,
                   EstatusContacto__c,
                   FechaSiguienteContacto__c,
                   FechaSiguienteVisita__c,
                   TYPEOF BanqueroAsignado__r.BusinessUnitMember
                   WHEN Banker THEN Division__c, ExternalId__c, Id, Cargo__c
                   END,
                   (
                       SELECT Id,
                              Status__c,
                              AccountOpeningDate__c,
                              TypeOfContract__c,
                              Saldo__c
                       FROM Contracts
                       ORDER BY AccountOpeningDate__c ASC
                   )
            FROM Account
            WHERE Id IN :accountIds
        ];
    }

    public static List<Contact> getContactsByAccountIds(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new List<Contact>();
        }

        return [
            SELECT Id, AccountId
            FROM Contact
            WHERE AccountId IN :accountIds
        ];
    }

    public static List<Opportunity> getOpenOpportunities(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new List<Opportunity>();
        }

        return [
            SELECT Id, AccountId, OwnerId
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND IsClosed = false
        ];
    }

    public static List<Task> getActiveTasks(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new List<Task>();
        }

        return [
            SELECT Id, WhatId, OwnerId, Status
            FROM Task
            WHERE WhatId IN :accountIds
            AND IsClosed = false
        ];
    }

    public static List<ActionCadenceTracker> getRunningTrackers(Set<Id> contactIds) {
        if (Test.isRunningTest() && testRunningTrackersOverride != null) {
            return testRunningTrackersOverride;
        }

        if (contactIds == null || contactIds.isEmpty()) {
            return new List<ActionCadenceTracker>();
        }

        return [
            SELECT Id, TargetId, OwnerId, ActionCadenceId, State
            FROM ActionCadenceTracker
            WHERE TargetId IN :contactIds
            AND State = 'Running'
        ];
    }

    public static List<ActionCadenceTracker> getTrackersByIds(Set<Id> trackerIds) {
        if (Test.isRunningTest() && testTrackersByIdsOverride != null) {
            return testTrackersByIdsOverride;
        }

        if (trackerIds == null || trackerIds.isEmpty()) {
            return new List<ActionCadenceTracker>();
        }

        return [
            SELECT Id, TargetId, OwnerId, ActionCadenceId, State
            FROM ActionCadenceTracker
            WHERE Id IN :trackerIds
        ];
    }

    public static List<ResumenGlobalPostventa__c> getResumenesByAdvisorIds(Set<String> advisorIds) {
        if (advisorIds == null || advisorIds.isEmpty()) {
            return new List<ResumenGlobalPostventa__c>();
        }

        return [
            SELECT Id, ExternalId_Nomina__c, Meta__c, Contactados__c
            FROM ResumenGlobalPostventa__c
            WHERE ExternalId_Nomina__c IN :advisorIds
        ];
    }
}
