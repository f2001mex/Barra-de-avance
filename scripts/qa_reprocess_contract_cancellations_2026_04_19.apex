Set<Id> impactedAccountIds = new Set<Id>{
    '001WP00000ffH0TYAU', // Rosa Patterson
    '001WP00000g71BoYAI', // Wanda Cooper
    '001WP00000fwuowYAA', // Michelle Cook
    '001WP00000g719HYAQ', // Rita Young
    '001WP00000ffhUZYAY'  // Patrick Perez
};

List<Account> impactedAccounts = [
    SELECT Id, OwnerId, PersonContactId, ID_Asesor__c
    FROM Account
    WHERE Id IN :impactedAccountIds
];

PSTA_PostCargaPostventa_cls.ProcessResult result =
    PSTA_PostCargaPostventa_cls.processAccounts(impactedAccounts);

System.debug('IMPACTED_ACCOUNTS=' + impactedAccounts.size());
System.debug('ACCOUNTS_TO_UPDATE=' + result.accountsToUpdate.size());
System.debug('TASKS_TO_DELETE=' + result.tasksToDelete.size());
System.debug('OPPORTUNITIES_TO_DELETE=' + result.opportunitiesToDelete.size());
System.debug('CADENCE_REQUESTS=' + result.cadenceRequests.size());
System.debug('IMPACTED_ADVISORS=' + result.impactedAdvisorIds);

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
    Id queueId = System.enqueueJob(new PSTA_PostCargaPostventaCadencias_qbl(result.cadenceRequests));
    System.debug('QUEUE_ID=' + queueId);
}

PSTA_PostCargaPostventa_cls.refreshSummaryMeta(result.impactedAdvisorIds);
