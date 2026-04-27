@isTest
public class WM_ReferidosControlllerTest {

    @isTest
    static void testSearchDataContact() {
        // Setup test data
        Account acc = new Account(Name = 'Test Account', Client_ID__c = '12345',Second_LastName__c = 'NoMiddleName');
        insert acc;
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        // Test searchDataContact with isEmployee = true and non-numeric searchTerm
        List<Contact> result = WM_ReferidosControlller.searchDataContact('Test');
        result = WM_ReferidosControlller.searchDataContact('12345');

        // Test searchDataContact with isEmployee = false and numeric searchTerm
        result = WM_ReferidosControlller.searchDataContact('Test');
        result = WM_ReferidosControlller.searchDataContact('12345');
    }
    
    @isTest
    static void testSearchDataBanker() {
        // Setup test data
        Account acc = new Account(Name = 'Test Account', Client_ID__c = '12345',Second_LastName__c = 'NoMiddleName');
        insert acc;
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;
        Banker banker = new Banker(Name = 'Test Banker', ExternalId__c = 'B12345',UserOrContactId = con.Id);
        insert banker;

        // Test searchDataBanker with non-numeric searchTerm
        Test.startTest();
        List<Banker> result = WM_ReferidosControlller.searchDataBanker('Test',false);

        // Test searchDataBanker with numeric searchTerm
        result = WM_ReferidosControlller.searchDataBanker('12345',false);
        result = WM_ReferidosControlller.searchDataBanker('B12345',true);
        result = WM_ReferidosControlller.searchDataBanker('Test',true);
        String complements = WM_ReferidosControlller.getComplements(con.Id);
        Test.stopTest();
        //System.assertEquals(1, result.size(), 'Expected one banker to be returned');
    }
    
     @isTest
    static void testUpdateReferRelation() {
        // Setup test data
            User newUser = new User(
            FirstName = 'Yuuka',
            LastName = 'Hayase',
            Username = 'YuukaH@example.com',
            Email = 'YuukaH@example.com',
            Alias = 'yuukaH',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert newUser;
        Lead lead = new Lead(LastName = 'El Chato', FirstName = 'Paco',PostalCode ='0117',Email = 'noemail@gmail.com', Phone='2711232925',Suffix='NoName');
        insert lead;
        Account acc = new Account(Name = 'Test Account2', Client_ID__c = '12349',Second_LastName__c = 'NoMiddleName');
        insert acc;
        Contact con = new Contact(FirstName = 'Test2', LastName = 'Contact2', AccountId = acc.Id);
        insert con;

        // Test updateReferRelation with User
        Test.startTest();
        String result = WM_ReferidosControlller.updateReferRelation(lead.Id, con.Id);
        result = WM_ReferidosControlller.updateReferRelation(lead.Id, newUser.Id);
        Test.stopTest();
        System.assertEquals('Success', result, 'Expected success message');
        
        //System.assertNotEquals(null, lead.FinServ__ReferredByUser__c, 'Expected FinServ__ReferredByUser__c to be set');
    }
    
     @isTest
    static void testGetRecords() {
        //	Setup test data
            User newUser2 = new User(
            FirstName = 'Cosme',
            LastName = 'Fulanito',
            Username = 'coisme@example.com',
            Email = 'cosme@example.com',
            Alias = 'cosmef',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        
        insert newUser2;
        Banker banker = new Banker(Name = 'Test Banker', ExternalId__c = 'B12345',UserOrContactId = newUser2.Id);
        insert banker;
        Lead lead = new Lead(LastName = 'Palencia', FirstName = 'Paco',PostalCode ='0118',Company = 'Test Company',Status = 'Contactado',Email = 'noemaill@gmail.com', Phone='2711232927',Suffix='NoName');
        insert lead;
		Account acc1 = new Account(Name = 'Test2 Account2', Client_ID__c = '112349',Second_LastName__c = 'NoMiddleName');
        insert acc1;
        // Test getRecords
        Test.startTest();
        lead.FinServ__ReferredByUser__c = newUser2.Id;
        update lead;
        String result = WM_ReferidosControlller.getRecords(lead.Id);
        
        Database.LeadConvert lc = new Database.LeadConvert(); 
        lc.setLeadId(lead.Id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1 ]; 
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        result = WM_ReferidosControlller.getRecords(lcr.getAccountId());
        Test.stopTest();
    }
}