Id oppId = '006dp00000HgU4jAAF';
Opportunity beforeOpp = [
    SELECT Id, Name, StageName, RecordType.DeveloperName, PatrimExcluirFlow__c
    FROM Opportunity
    WHERE Id = :oppId
    LIMIT 1
];
System.debug('=== BEFORE === ' + beforeOpp.Id + ' | ' + beforeOpp.Name + ' | ' + beforeOpp.StageName + ' | Excluir=' + beforeOpp.PatrimExcluirFlow__c);

Opportunity o1 = new Opportunity(Id = oppId, PatrimExcluirFlow__c = false);
Database.SaveResult r1 = Database.update(o1, false);
if (r1.isSuccess()) {
    System.debug('OK FALSE -> ' + oppId);
} else {
    for (Database.Error e : r1.getErrors()) {
        System.debug('ERR FALSE -> ' + e.getStatusCode() + ' | ' + e.getMessage());
    }
}

Opportunity o2 = new Opportunity(Id = oppId, PatrimExcluirFlow__c = true);
Database.SaveResult r2 = Database.update(o2, false);
if (r2.isSuccess()) {
    System.debug('OK TRUE -> ' + oppId);
} else {
    for (Database.Error e : r2.getErrors()) {
        System.debug('ERR TRUE -> ' + e.getStatusCode() + ' | ' + e.getMessage());
    }
}

Opportunity afterOpp = [
    SELECT Id, Name, StageName, PatrimExcluirFlow__c
    FROM Opportunity
    WHERE Id = :oppId
    LIMIT 1
];
System.debug('=== AFTER === ' + afterOpp.Id + ' | ' + afterOpp.Name + ' | ' + afterOpp.StageName + ' | Excluir=' + afterOpp.PatrimExcluirFlow__c);
