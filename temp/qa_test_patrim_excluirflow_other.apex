Id oppId = '006WF00000bsAoMYAU';
Opportunity o1 = new Opportunity(Id = oppId, PatrimExcluirFlow__c = false);
Database.SaveResult r1 = Database.update(o1, false);
if (r1.isSuccess()) { System.debug('OK FALSE'); } else { for (Database.Error e : r1.getErrors()) System.debug('ERR FALSE -> ' + e.getStatusCode() + ' | ' + e.getMessage()); }
Opportunity o2 = new Opportunity(Id = oppId, PatrimExcluirFlow__c = true);
Database.SaveResult r2 = Database.update(o2, false);
if (r2.isSuccess()) { System.debug('OK TRUE'); } else { for (Database.Error e : r2.getErrors()) System.debug('ERR TRUE -> ' + e.getStatusCode() + ' | ' + e.getMessage()); }
Opportunity o3 = [SELECT Id, PatrimExcluirFlow__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
System.debug('FINAL=' + o3.PatrimExcluirFlow__c);
