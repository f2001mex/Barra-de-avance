Set<Id> accountIds = new Set<Id>{
    '001WP00000fwupCYAQ',
    '001WP00000gXWXgYAO',
    '001WP00000gGOJyYAO'
};

List<Account> accountsToProcess = [
    SELECT Id, OwnerId, PersonContactId, ID_Asesor__c
    FROM Account
    WHERE Id IN :accountIds
];

PSTA_PostCargaPostventa_cls.ProcessResult result =
    PSTA_PostCargaPostventa_cls.processAccounts(accountsToProcess);

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

PSTA_PostCargaPostventa_cls.refreshSummaryMeta(result.impactedAdvisorIds);

System.debug('POSTVENTA_REPROCESO_QA=' + JSON.serialize(new Map<String, Object>{
    'accountsProcessed' => accountIds,
    'accountsToUpdate' => result.accountsToUpdate.size(),
    'opportunitiesToDelete' => result.opportunitiesToDelete.size(),
    'tasksToDelete' => result.tasksToDelete.size(),
    'cadenceRequests' => result.cadenceRequests.size(),
    'impactedAdvisorIds' => result.impactedAdvisorIds
}));
