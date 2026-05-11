Opportunity o = [SELECT Id, StageName, Cliente_Acepta_oferta__c FROM Opportunity WHERE Id = '006dp00000FKinRAAT' LIMIT 1];
o.StageName = 'Presentaci?n de oferta';
o.Cliente_Acepta_oferta__c = null;
update o;
System.debug('RESTORED:' + o.Id);
