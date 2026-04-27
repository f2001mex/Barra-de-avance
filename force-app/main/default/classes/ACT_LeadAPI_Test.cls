@isTest
public class ACT_LeadAPI_Test {
    @testSetup
    static void setupTestData() {
        List<Lead_Web_Service_Setting__mdt> customMetadataRecords = new List<Lead_Web_Service_Setting__mdt>();
        customMetadataRecords.add(new Lead_Web_Service_Setting__mdt(Status__c = 'No Contactado'));
        customMetadataRecords.add(new Lead_Web_Service_Setting__mdt(Status__c = 'Contactado'));
        
       // insert customMetadataRecords;
    }

    @isTest
    static void testACT_LeadAPI() {
        Lead leadRecord = new Lead();
        leadRecord.FirstName = 'Jaidy';
        leadRecord.PostalCode = '12';
        leadRecord.Motivo_No_Contactado__c = 'Otros';
        leadRecord.LastName = 'Chala';
        //leadRecord.ID_ASESOR__c = 'LeadId'; 
        leadRecord.Status = 'No Contactado';
        
        insert leadRecord;
        
        Lead leadRecordC = new Lead();
        leadRecordC.FirstName = 'Gaby';
        leadRecordC.PostalCode = '945';
        leadRecordC.Cliente_Contactado__c = true;
        leadRecordC.LastName = 'Perez';
        //leadRecord.ID_ASESOR__c = 'LeadId'; 
        leadRecordC.Status = 'Contactado';
        
        insert leadRecordC;

        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = '/services/apexrest/leadconsult/LeadId'; 
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = response;

        Integer result = ACT_LeadAPI.getLeadCountByOwner();

       // System.assertEquals(1, result);

        Test.stopTest();
    }
}