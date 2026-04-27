Id jobId = '707WF0000IGZmOgYQL';
Set<Id> accountIds = new Set<Id>{
    '0017V00001ULNVKQA5',
    '0017V000020mYO8QAM'
};
Set<Id> contactIds = new Set<Id>();

AsyncApexJob jobRow = [
    SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, CreatedDate, CompletedDate
    FROM AsyncApexJob
    WHERE Id = :jobId
];
System.debug('JOB=' + JSON.serializePretty(jobRow));

List<Account> accounts = [
    SELECT Id, Name, PersonContactId, EstatusContacto__c, ContactoPriorizadoEsteMes__c,
           PriorizacionContacto__c, PriorizacionVisita__c
    FROM Account
    WHERE Id IN :accountIds
];
for (Account acc : accounts) {
    if (acc.PersonContactId != null) {
        contactIds.add(acc.PersonContactId);
    }
}
System.debug('ACCOUNTS=' + JSON.serializePretty(accounts));

List<ActionCadenceTracker> trackers = [
    SELECT Id, TargetId, State, ActionCadenceId, ActionCadence.Name, CreatedDate
    FROM ActionCadenceTracker
    WHERE TargetId IN :contactIds
    ORDER BY CreatedDate DESC
];
System.debug('TRACKERS=' + JSON.serializePretty(trackers));
