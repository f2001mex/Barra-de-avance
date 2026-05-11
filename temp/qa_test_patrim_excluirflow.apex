Id oppId = '006WF00000fAuNuYAK';

Opportunity beforeOpp = [
  SELECT Id, Name, StageName, RecordType.DeveloperName, PatrimExcluirFlow__c
  FROM Opportunity
  WHERE Id = :oppId
  LIMIT 1
];
System.debug('=== BEFORE === ' + beforeOpp.Id + ' | ' + beforeOpp.Name + ' | ' + beforeOpp.StageName + ' | ' + beforeOpp.RecordType.DeveloperName + ' | Excluir=' + beforeOpp.PatrimExcluirFlow__c);

Opportunity toFalse = new Opportunity(Id = oppId, PatrimExcluirFlow__c = false);
Database.SaveResult rFalse = Database.update(toFalse, false);
if (rFalse.isSuccess()) {
  System.debug('OK FALSE -> ' + oppId);
} else {
  for (Database.Error e : rFalse.getErrors()) {
    System.debug('ERR FALSE -> ' + e.getStatusCode() + ' | ' + e.getMessage());
  }
}

Opportunity toTrue = new Opportunity(Id = oppId, PatrimExcluirFlow__c = true);
Database.SaveResult rTrue = Database.update(toTrue, false);
if (rTrue.isSuccess()) {
  System.debug('OK TRUE -> ' + oppId);
} else {
  for (Database.Error e : rTrue.getErrors()) {
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
