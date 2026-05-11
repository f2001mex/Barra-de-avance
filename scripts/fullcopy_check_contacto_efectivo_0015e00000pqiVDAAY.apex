Id accountId = '0015e00000pqiVDAAY';
Id userId = '0057V00000CFgJgQAL';
Id cadenceId = '77CWP0000000hJV2AY';

Account acc = [
    SELECT Id, Name, OwnerId, ID_Asesor__c, PersonContactId, EstatusContacto__c,
           FechaUltimoContacto__c, FechaSiguienteContacto__c, LastModifiedDate
    FROM Account
    WHERE Id = :accountId
    LIMIT 1
];
System.debug('ACCOUNT=' + JSON.serializePretty(acc));

User usr = [
    SELECT Id, Name, ID_Asesor__c
    FROM User
    WHERE Id = :userId
    LIMIT 1
];
System.debug('USER=' + JSON.serializePretty(usr));

List<ActionCadenceTracker> trackers = [
    SELECT Id, TargetId, State, ActionCadenceId, ActionCadence.Name,
           CreatedDate, LastModifiedDate
    FROM ActionCadenceTracker
    WHERE ActionCadenceId = :cadenceId
      AND TargetId = :acc.PersonContactId
    ORDER BY CreatedDate DESC
];
System.debug('TRACKERS=' + JSON.serializePretty(trackers));

List<Task> tasks = [
    SELECT Id, Subject, OwnerId, AccountId, RecordTypeId, RecordType.DeveloperName,
           Status, ActivityDate, CreatedDate, LastModifiedDate, IsClosed
    FROM Task
    WHERE AccountId = :accountId
    ORDER BY LastModifiedDate DESC
    LIMIT 50
];
System.debug('TASKS=' + JSON.serializePretty(tasks));

List<ResumenGlobalPostventa__c> resumenes = [
    SELECT Id, Name, OwnerId, ExternalId_Nomina__c, Fecha__c,
           Meta__c, Contactados__c, PorcentajeAvance__c, LastModifiedDate
    FROM ResumenGlobalPostventa__c
    WHERE OwnerId = :userId
    ORDER BY Fecha__c DESC, LastModifiedDate DESC
    LIMIT 20
];
System.debug('RESUMENES=' + JSON.serializePretty(resumenes));
