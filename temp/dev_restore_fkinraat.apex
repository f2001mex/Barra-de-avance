Id oppId = '006dp00000FKinRAAT';
Opportunity restore = new Opportunity(
  Id = oppId,
  StageName = 'Presentación de oferta',
  PatrimExcluirFlow__c = true,
  Motivo_de_p_rdida__c = null,
  Competencia__c = null,
  Cliente_Acepta_oferta__c = null
);
Database.SaveResult r = Database.update(restore, false);
if (r.isSuccess()) {
  System.debug('RESTORE OK');
} else {
  for (Database.Error e : r.getErrors()) System.debug('RESTORE ERR -> ' + e.getStatusCode() + ' | ' + e.getMessage());
}
Opportunity fin = [SELECT Id, StageName, PatrimExcluirFlow__c, Motivo_de_p_rdida__c, Competencia__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
System.debug('FINAL -> Stage=' + fin.StageName + ' Excluir=' + fin.PatrimExcluirFlow__c + ' Motivo=' + fin.Motivo_de_p_rdida__c + ' Comp=' + fin.Competencia__c);
