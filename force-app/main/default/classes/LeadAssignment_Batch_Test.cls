@isTest
private class LeadAssignment_Batch_Test {

    @isTest
    static void testBatchExecution() {
        
        User MCconnectUser = [SELECT Id FROM User WHERE Name = 'MC Connect-CRM' LIMIT 1];

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Suffix = 'Apellido Materno',
            PostalCode = [SELECT Codigo_Postal__c FROM  Mapping_CP_CF__mdt where Centro_Financiero__c = 'AGS AGUASCALIENTES NTE 509' LIMIT 1][0].Codigo_Postal__c,
            OwnerId = MCconnectUser.Id,
            Email = 'testlead@test.com'
        );
        insert testLead;

        Test.startTest();
        LeadAssignment_Batch batch = new LeadAssignment_Batch();
        Database.executeBatch(batch);
        Test.stopTest();

        //Lead updatedLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :testLead.Id];
        //System.assertNotEquals(MCconnectUser.Id, updatedLead.OwnerId, 'Lead owner should have been changed a new user');
    }

}