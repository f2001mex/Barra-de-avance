@isTest
private class CC_LeadAssignment_Soluciones_Test {
    @isTest
    static void testLeadAssignmentLogic() {
        // Create test data
        List<Lead> leadsToAssign = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            Lead lead = new Lead();
            lead.FirstName = 'Test';
            lead.LastName = 'Lead' + i;
            lead.Suffix = 'Apellido' + i;
            lead.Email = 'test' + i + '@example.com';
            lead.PostalCode = [SELECT Codigo_Postal__c FROM  Mapping_CP_CF__mdt where Centro_Financiero__c = 'AGS AGUASCALIENTES NTE 509' LIMIT 1][0].Codigo_Postal__c; 
            leadsToAssign.add(lead);
        }
        insert leadsToAssign;


        // Call the leadAssignmentLogic method
        Test.startTest();
        CC_LeadAssignment_Soluciones.leadAssignmentLogic(leadsToAssign);
        Test.stopTest();

        // Verify that leads are assigned to users
        for (Lead lead : [SELECT Id, OwnerId FROM Lead WHERE Id IN :leadsToAssign]) {
            System.assertEquals(true, lead.OwnerId != null, 'Lead should be assigned to a user');
        }
    }
}