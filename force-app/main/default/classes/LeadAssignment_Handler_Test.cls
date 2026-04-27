@isTest
public class LeadAssignment_Handler_Test {
    static List<Lead> testLeads;
    
    @testSetup
    static void setup() {
        // Test data setup
        User MCconnectUser = [SELECT id FROM User WHERE Name = 'MC Connect-CRM'];
        String MCconnectUserId = MCconnectUser.id;
        ID asesorSoluciones = [SELECT id from Profile WHERE name = 'Asesor Soluciones'][0].id;
        ID asesorCAT = [SELECT id from Profile WHERE name = 'Ejecutivo CAT SEDI'][0].id;

        List<Lead> leadsToAssign = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            Lead lead = new Lead();
            lead.FirstName = 'Test';
            lead.LastName = 'Lead' + i;
            lead.Suffix ='Apellido' + i;
            lead.Email = 'test' + i + '@example.com';
            lead.PostalCode = [SELECT Codigo_Postal__c FROM  Mapping_CP_CF__mdt where Centro_Financiero__c = 'AGS AGUASCALIENTES NTE 509' LIMIT 1][0].Codigo_Postal__c; 
            lead.OwnerId = MCconnectUserId;
            leadsToAssign.add(lead);
        }
        
          for (Integer i = 0; i < 5; i++) {
            Lead lead = new Lead();
            lead.FirstName = 'TestCAT';
            lead.LastName = 'LeadCAT' + i;
            lead.Suffix ='ApellidoCAT' + i;
            lead.Email = 'testCAT' + i + '@example.com';
            lead.PostalCode = '00000'; 
            lead.OwnerId = MCconnectUserId;
            leadsToAssign.add(lead);
        }
        insert leadsToAssign;
        system.debug('LeadsToAssign: ' + leadsToAssign);
        
        
    }
    
    @isTest
    static void testCheckBusinessHoursById() {
        // Test when businessHoursId is null
        Boolean resultNullId = LeadAssignment_Handler.checkBusinessHoursById(null);
        System.assertEquals(false, resultNullId, 'Expected result to be false when businessHoursId is null');

        // Test when businessHoursId is valid
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        Boolean resultValidId = LeadAssignment_Handler.checkBusinessHoursById(bh.Id);
        
        System.assert(resultValidId != null, 'Expected result to be a boolean');
    }
    
    @isTest
    static void testCheckBusinessHoursByName() {
        
        // Test when active business hours named "Lead Assignment" exist
        Test.startTest();
        List<Boolean> resultWithBusinessHours = LeadAssignment_Handler.checkBusinessHoursByName();
        Test.stopTest();

        System.assertEquals(1, resultWithBusinessHours.size(), 'Expected result size to be 1');
        
    }
    
 
    @isTest
    static void testLeadAssignment() {
        User MCconnectUser = [SELECT id FROM User WHERE Name = 'MC Connect-CRM'];
        String MCconnectUserId = MCconnectUser.id;
        List<Lead> leadsToAssignList = [SELECT Id, Name, PostalCode, Email, OwnerId, CC_CF__c FROM Lead WHERE OwnerId =: MCconnectUserId];
        
        Test.startTest();
        LeadAssignment_Handler.leadAssignment(leadsToAssignList);
        Test.stopTest();

        // Assertions
        //List<Lead> nonAssignedleads = [SELECT Id, OwnerId FROM Lead WHERE OwnerId =: MCconnectUserId];
        //System.assertEquals(0, nonAssignedleads.size(), 'Expected result size to be 0');
        
    }

}