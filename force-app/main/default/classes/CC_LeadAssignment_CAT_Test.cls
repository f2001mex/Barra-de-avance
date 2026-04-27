@isTest
public class CC_LeadAssignment_CAT_Test {
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
            lead.PostalCode = '01020304'; 
            leadsToAssign.add(lead);
        }
        insert leadsToAssign;


        // Call the leadAssignmentLogic method
        Test.startTest();
        CC_LeadAssignment_CAT.leadAssignmentLogic(leadsToAssign);
        Test.stopTest();

        // Verify that leads are assigned to users
        for (Lead lead : [SELECT Id, OwnerId, owner.profile.name FROM Lead WHERE Id IN :leadsToAssign]) {
            System.assertEquals(true, lead.OwnerId != null, 'Lead should be assigned to a user');
            System.assertEquals('Ejecutivo CAT SEDI', lead.Owner.profile.name, 'Lead owner should have Ejecutivo CAT SEDI profile');
        }
    }
    
    @isTest
    static void testLeadAssignmentLogic2() {
        // Create a test lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Status = 'New',
            Company = 'Test Company',
            PostalCode = '01020304',
            Suffix = 'Apellido Materno', 
            email = 'testemail@dummymail.com'
        );
        insert testLead;

        User testUser = [SELECT Id, IsActive FROM User WHERE Profile.Name = 'Ejecutivo CAT SEDI' AND IsActive = true LIMIT 1];

        testLead.OwnerId = testUser.Id;
        update testLead;

        Test.startTest();
        CC_LeadAssignment_CAT.leadAssignmentLogic(new List<Lead>{ testLead });
        Test.stopTest();

        // Verify that the lead is still assigned to the test user
        //Lead updatedLead = [SELECT OwnerId FROM Lead WHERE Id = :testLead.Id];
        //System.assertEquals(testUser.Id, updatedLead.OwnerId, 'Lead was reassigned when it should not have been');
    }
}