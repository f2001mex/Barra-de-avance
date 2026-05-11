Id oppId = '006dp00000FKinRAAT';
Opportunity orig = [
  SELECT Id, Name, StageName, PatrimExcluirFlow__c, Motivo_de_p_rdida__c, Competencia__c
  FROM Opportunity WHERE Id = :oppId LIMIT 1
];
System.debug('ORIG -> Stage=' + orig.StageName + ' Excluir=' + orig.PatrimExcluirFlow__c + ' Motivo=' + orig.Motivo_de_p_rdida__c);

Opportunity prep = new Opportunity(
  Id = oppId,
  PatrimExcluirFlow__c = false,
  Motivo_de_p_rdida__c = 'No cumple las expectativas del Cliente (producto o solución inadecuado)'
);
Database.SaveResult prepRes = Database.update(prep, false);
if (prepRes.isSuccess()) {
  System.debug('PREP OK');
} else {
  for (Database.Error e : prepRes.getErrors()) System.debug('PREP ERR -> ' + e.getStatusCode() + ' | ' + e.getMessage());
}

Opportunity testTrue = new Opportunity(Id = oppId, PatrimExcluirFlow__c = true);
Database.SaveResult testRes = Database.update(testTrue, false);
if (testRes.isSuccess()) {
  System.debug('TEST TRUE OK');
} else {
  for (Database.Error e : testRes.getErrors()) System.debug('TEST TRUE ERR -> ' + e.getStatusCode() + ' | ' + e.getMessage());
}

Opportunity restore = new Opportunity(
  Id = oppId,
  PatrimExcluirFlow__c = orig.PatrimExcluirFlow__c,
  Motivo_de_p_rdida__c = orig.Motivo_de_p_rdida__c,
  Competencia__c = orig.Competencia__c
);
Database.SaveResult restoreRes = Database.update(restore, false);
if (restoreRes.isSuccess()) {
  System.debug('RESTORE OK');
} else {
  for (Database.Error e : restoreRes.getErrors()) System.debug('RESTORE ERR -> ' + e.getStatusCode() + ' | ' + e.getMessage());
}

Opportunity fin = [SELECT Id, StageName, PatrimExcluirFlow__c, Motivo_de_p_rdida__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
System.debug('FINAL -> Stage=' + fin.StageName + ' Excluir=' + fin.PatrimExcluirFlow__c + ' Motivo=' + fin.Motivo_de_p_rdida__c);
