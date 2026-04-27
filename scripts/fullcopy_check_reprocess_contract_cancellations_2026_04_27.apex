Id queueId = '707WF0000IGaiZa';
Set<Id> accountIds = new Set<Id>{
    '0017V00001ULNVKQA5',
    '0017V000020mYO8QAM'
};
Set<Id> contactIds = new Set<Id>();

AsyncApexJob queueRow = [
    SELECT Id, Status, JobType, NumberOfErrors, CreatedDate, CompletedDate, ApexClass.Name
    FROM AsyncApexJob
    WHERE Id = :queueId
];
System.debug('QUEUE=' + JSON.serializePretty(queueRow));

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
    SELECT Id, TargetId, State, ActionCadence.Name, CreatedDate
    FROM ActionCadenceTracker
    WHERE TargetId IN :contactIds
    ORDER BY CreatedDate DESC
];
System.debug('TRACKERS=' + JSON.serializePretty(trackers));
