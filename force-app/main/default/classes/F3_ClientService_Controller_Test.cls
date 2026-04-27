@isTest
public class F3_ClientService_Controller_Test {
    @isTest
    static void testInsertUpdateClientSuccess() {
        // Setup
        F3_Integration_Service_Settings__c serviceSettings = new F3_Integration_Service_Settings__c(
            Name = 'SFcrearActualizarCliente', // Reemplaza DeveloperName con Name u otro campo existente
            F3_Enable_Log__c = true
        );
        insert serviceSettings;

        Account account = new Account(Name = 'Test Account');
        insert account;

        Lead lead = new Lead(FirstName = 'Test', LastName = 'Lead', Company = 'Test Company', Status = 'New',PostalCode = '12345', Email = 'testlead@example.com');
        insert lead;

        String validJson = '{"setRecordTypes":["WealthManagement"],"mapAccountsUpdate":{},"mapConsecutiveByLead":{},"sObjectMap":{}}';

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(validJson);
        req.httpMethod = 'PUT';
        req.requestURI = '/services/apexrest/crearActualizarCliente';
        RestContext.request = req;
        RestContext.response = res;

        F3_ClientService_Controller.insertUpdateClient();
        Test.stopTest();

    }

    @isTest
    static void testInsertUpdateClientError() {
        // Setup
        F3_Integration_Service_Settings__c serviceSettings = new F3_Integration_Service_Settings__c(
            Name = 'SFcrearActualizarCliente', // Reemplaza DeveloperName con Name u otro campo existente
            F3_Enable_Log__c = true
        );
        insert serviceSettings;

        String invalidJson = '{"invalid":true}';

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(invalidJson);
        req.httpMethod = 'PUT';
        req.requestURI = '/services/apexrest/crearActualizarCliente';
        RestContext.request = req;
        RestContext.response = res;

        F3_ClientService_Controller.insertUpdateClient();
        Test.stopTest();

    }
}