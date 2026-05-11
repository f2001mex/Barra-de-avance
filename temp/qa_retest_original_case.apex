Id oppId = '006WF00000fAuNuYAK';
Opportunity beforeOpp = [SELECT Id, StageName, PatrimExcluirFlow__c, Motivo_de_p_rdida__c, Competencia__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
System.debug('BEFORE -> Stage=' + beforeOpp.StageName + ' Excluir=' + beforeOpp.PatrimExcluirFlow__c + ' Motivo=' + beforeOpp.Motivo_de_p_rdida__c + ' Comp=' + beforeOpp.Competencia__c);

Opportunity upd = new Opportunity(Id = oppId, PatrimExcluirFlow__c = true);
Database.SaveResult r = Database.update(upd, false);
if (r.isSuccess()) {
  System.debug('SET TRUE OK');
} else {
  for (Database.Error e : r.getErrors()) System.debug('SET TRUE ERR -> ' + e.getStatusCode() + ' | ' + e.getMessage());
}

Opportunity afterOpp = [SELECT Id, StageName, PatrimExcluirFlow__c, Motivo_de_p_rdida__c, Competencia__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
System.debug('AFTER -> Stage=' + afterOpp.StageName + ' Excluir=' + afterOpp.PatrimExcluirFlow__c + ' Motivo=' + afterOpp.Motivo_de_p_rdida__c + ' Comp=' + afterOpp.Competencia__c);
