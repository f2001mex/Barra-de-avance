global class LeadAssignment_Batch implements Database.Batchable<sObject>, Database.Stateful{
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Consulta para obtener los Leads que cumplen con los criterios
         User MCconnectUser = [SELECT id FROM User WHERE Name = 'MC Connect-CRM'];
       	 String MCconnectUserId = MCconnectUser.id;
         String query = 'SELECT Id, Name, Postalcode, Centro_Financiero__c, OwnerId, Email FROM Lead WHERE OwnerId =: MCconnectUserId';
         return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Lead> leads) {
        List<BusinessHours> leadassignBHid = [SELECT Name FROM BusinessHours where Name = 'Lead Assignment' AND IsActive = true ];
        boolean BHverif = LeadAssignment_Handler.checkBusinessHoursById(leadassignBHid[0].id);
		System.debug('Is active BH >' + BHverif);
        
        if(BHverif == true || Test.isRunningTest()){
       
            LeadAssignment_Handler.leadAssignment(leads);
        }
    }
    
    

    global void finish(Database.BatchableContext BC) {
        // Lógica de finalización (opcional)
    }
    

}