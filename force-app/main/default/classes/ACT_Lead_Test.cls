/**
* @description       : 
* @author            : JC Cruz
* @group             : 
* @last modified on  : 12-18-2023
* @last modified by  : JC Cruz
**/
@isTest
public class ACT_Lead_Test {
    
    private static final String URL_BASE = '/ACT_Leads/';
    
    @TestSetup
    static void makeData(){
        Profile p = [SELECT Id FROM Profile limit 1]; 
        User newUser = new User();
        newUser.ID_ASESOR__c = '123455';
        newUser.firstName = 'Marcela';
        newUser.phone = '123456';
        newUser.email = 'marcela@test.com';
        newUser.postalCode = '6666';
        newUser.lastName = 'Prueba' + ' ' + 'Test';
        newUser.alias = 'standt';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.LanguageLocaleKey = 'en_US';
        newUser.LocaleSidKey = 'en_US';
        newUser.ProfileId = p.Id;
        newUser.TimeZoneSidKey = 'America/Los_Angeles';
        newUser.UserName = 'user'+ System.currentTimeMillis()+'@testorg.com';
        newUser.IsActive = true;
        
        insert newUser;
    }
    
       
    @isTest
    static void testCreatePosibilidad_Success() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        testLead.claveAsesor = '123455';
        testLead.Name = 'Mary';
        testLead.MotherLastName = 'Doe';
        testLead.FatherLastName = 'Smith';
        testLead.phone = '1234567890';
        testLead.email = 'test@example.com';
        testLead.PostalCode = '12345';
        testLead.tipoDeLead = 'Posibilidad';
        testLead.salution = 'Sr.';
        testLead.recordType = 'Prospecto';
        
        Test.startTest();
        RestContext.request = new System.RestRequest();
        RestContext.response = new System.RestResponse();
        Map<String, String> headers = RestContext.request.headers;
        
        headers.put('Content-Type', 'application/json');
        
        RestContext.request.httpMethod = 'POST';
        
        String response = ACT_APICreateLead.createLead(testLead);
        Test.stopTest();
        
        Data_Structure_Handle_Lead.ResultWithLeads result = (Data_Structure_Handle_Lead.ResultWithLeads) JSON.deserialize(response, Data_Structure_Handle_Lead.ResultWithLeads.class);
        
        System.assertEquals(true, result.result, result.message);
        
    }
    
    @isTest
    static void testCreatePosibilidad_NoClaveAsesor() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        //testLead.claveAsesor = '123455';
        testLead.Name = 'Mary';
        testLead.MotherLastName = 'Doe';
        testLead.FatherLastName = 'Smith';
        testLead.phone = '1234567890';
        testLead.email = 'test@example.com';
        testLead.PostalCode = '12345';
        testLead.tipoDeLead = 'Posibilidad';
        testLead.salution = 'Sr.';
        testLead.recordType = 'Prospecto';
        
        Test.startTest();
        RestContext.request = new System.RestRequest();
        RestContext.response = new System.RestResponse();
        Map<String, String> headers = RestContext.request.headers;
        
        headers.put('Content-Type', 'application/json');
        
        RestContext.request.httpMethod = 'POST';
        
        String response = ACT_APICreateLead.createLead(testLead);
        Test.stopTest();
        
        Data_Structure_Handle_Lead.ResultWithLeads result = (Data_Structure_Handle_Lead.ResultWithLeads) JSON.deserialize(response, Data_Structure_Handle_Lead.ResultWithLeads.class);
        
        System.assertEquals(false, result.result, result.message);
        
    }
    
    @isTest
    static void testCreatePosibilidad_NoSalution() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        testLead.claveAsesor = '123455';
        testLead.Name = 'Mary';
        testLead.MotherLastName = 'Doe';
        testLead.FatherLastName = 'Smith';
        testLead.phone = '1234567890';
        testLead.email = 'test@example.com';
        testLead.PostalCode = '12345';
        testLead.tipoDeLead = 'Posibilidad';
        //testLead.salution = 'Sr.';
        testLead.recordType = 'Prospecto';
        
        Test.startTest();
        RestContext.request = new System.RestRequest();
        RestContext.response = new System.RestResponse();
        Map<String, String> headers = RestContext.request.headers;
        
        headers.put('Content-Type', 'application/json');
        
        RestContext.request.httpMethod = 'POST';
        
        String response = ACT_APICreateLead.createLead(testLead);
        Test.stopTest();
        
        Data_Structure_Handle_Lead.ResultWithLeads result = (Data_Structure_Handle_Lead.ResultWithLeads) JSON.deserialize(response, Data_Structure_Handle_Lead.ResultWithLeads.class);
        
        System.assertEquals(false, result.result, result.message);
        
    }
    
    @isTest
    static void testCreatePosibilidad_NoMotherLastName() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        testLead.claveAsesor = '123455';
        testLead.Name = 'Mary';
        //testLead.MotherLastName = 'Doe';
        testLead.FatherLastName = 'Smith';
        testLead.phone = '1234567890';
        testLead.email = 'test@example.com';
        testLead.PostalCode = '12345';
        testLead.tipoDeLead = 'Posibilidad';
        testLead.salution = 'Sr.';
        testLead.recordType = 'Prospecto';
        
        Test.startTest();
        RestContext.request = new System.RestRequest();
        RestContext.response = new System.RestResponse();
        Map<String, String> headers = RestContext.request.headers;
        
        headers.put('Content-Type', 'application/json');
        
        RestContext.request.httpMethod = 'POST';
        
        String response = ACT_APICreateLead.createLead(testLead);
        Test.stopTest();
        
        Data_Structure_Handle_Lead.ResultWithLeads result = (Data_Structure_Handle_Lead.ResultWithLeads) JSON.deserialize(response, Data_Structure_Handle_Lead.ResultWithLeads.class);
        
        System.assertEquals(false, result.result, result.message);
        
    }
    
    @isTest
    static void testCreatePosibilidad_NoFatherLastName() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        testLead.claveAsesor = '123455';
        testLead.Name = 'Mary';
        testLead.MotherLastName = 'Doe';
        //testLead.FatherLastName = 'Smith';
        testLead.phone = '1234567890';
        testLead.email = 'test@example.com';
        testLead.PostalCode = '12345';
        testLead.tipoDeLead = 'Posibilidad';
        testLead.salution = 'Sr.';
        testLead.recordType = 'Prospecto';
        
        Test.startTest();
        RestContext.request = new System.RestRequest();
        RestContext.response = new System.RestResponse();
        Map<String, String> headers = RestContext.request.headers;
        
        headers.put('Content-Type', 'application/json');
        
        RestContext.request.httpMethod = 'POST';
        
        String response = ACT_APICreateLead.createLead(testLead);
        Test.stopTest();
        
        Data_Structure_Handle_Lead.ResultWithLeads result = (Data_Structure_Handle_Lead.ResultWithLeads) JSON.deserialize(response, Data_Structure_Handle_Lead.ResultWithLeads.class);
        
        System.assertEquals(false, result.result, result.message);
        
    }
    
    @isTest
    static void testCreatePosibilidad_NoName() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        testLead.claveAsesor = '123455';
        //testLead.Name = 'Mary';
        testLead.MotherLastName = 'Doe';
        testLead.FatherLastName = 'Smith';
        testLead.phone = '1234567890';
        testLead.email = 'test@example.com';
        testLead.PostalCode = '12345';
        testLead.tipoDeLead = 'Posibilidad';
        testLead.salution = 'Sr.';
        testLead.recordType = 'Prospecto';
        
        Test.startTest();
        RestContext.request = new System.RestRequest();
        RestContext.response = new System.RestResponse();
        Map<String, String> headers = RestContext.request.headers;
        
        headers.put('Content-Type', 'application/json');
        
        RestContext.request.httpMethod = 'POST';
        
        String response = ACT_APICreateLead.createLead(testLead);
        Test.stopTest();
        
        Data_Structure_Handle_Lead.ResultWithLeads result = (Data_Structure_Handle_Lead.ResultWithLeads) JSON.deserialize(response, Data_Structure_Handle_Lead.ResultWithLeads.class);
        
        System.assertEquals(false, result.result, result.message);
        
    }
    
    @isTest
    static void testCreatePosibilidad_NopostalCode() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        testLead.claveAsesor = '123455';
        testLead.Name = 'Mary';
        testLead.MotherLastName = 'Doe';
        testLead.FatherLastName = 'Smith';
        testLead.phone = '1234567890';
        testLead.email = 'test@example.com';
        //testLead.PostalCode = '12345';
        testLead.tipoDeLead = 'Posibilidad';
        testLead.salution = 'Sr.';
        testLead.recordType = 'Prospecto';
        
        Test.startTest();
        RestContext.request = new System.RestRequest();
        RestContext.response = new System.RestResponse();
        Map<String, String> headers = RestContext.request.headers;
        
        headers.put('Content-Type', 'application/json');
        
        RestContext.request.httpMethod = 'POST';
        
        String response = ACT_APICreateLead.createLead(testLead);
        Test.stopTest();
        
        Data_Structure_Handle_Lead.ResultWithLeads result = (Data_Structure_Handle_Lead.ResultWithLeads) JSON.deserialize(response, Data_Structure_Handle_Lead.ResultWithLeads.class);
        
        System.assertEquals(false, result.result, result.message);
        
    }
    
    @isTest
    static void testCreatePosibilidad_NorecordType() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        testLead.claveAsesor = '123455';
        testLead.Name = 'Mary';
        testLead.MotherLastName = 'Doe';
        testLead.FatherLastName = 'Smith';
        testLead.phone = '1234567890';
        testLead.email = 'test@example.com';
        testLead.PostalCode = '12345';
        testLead.tipoDeLead = 'Posibilidad';
        testLead.salution = 'Sr.';
        //testLead.recordType = 'Prospecto';
        
        Test.startTest();
        RestContext.request = new System.RestRequest();
        RestContext.response = new System.RestResponse();
        Map<String, String> headers = RestContext.request.headers;
        
        headers.put('Content-Type', 'application/json');
        
        RestContext.request.httpMethod = 'POST';
        
        String response = ACT_APICreateLead.createLead(testLead);
        Test.stopTest();
        
        Data_Structure_Handle_Lead.ResultWithLeads result = (Data_Structure_Handle_Lead.ResultWithLeads) JSON.deserialize(response, Data_Structure_Handle_Lead.ResultWithLeads.class);
        
        System.assertEquals(false, result.result, result.message);
        
    }
    
     @isTest
    static void testCreateLead_Success() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        testLead.claveAsesor = '123455';
        testLead.Name = 'Mary';
        testLead.MotherLastName = 'Doe';
        testLead.FatherLastName = 'Smith';
        testLead.phone = '1234567890';
        testLead.email = 'test@example.com';
        testLead.PostalCode = '12345';
        
        Test.startTest();
        RestContext.request = new System.RestRequest();
        RestContext.response = new System.RestResponse();
        Map<String, String> headers = RestContext.request.headers;
        
        headers.put('Content-Type', 'application/json');
        
        RestContext.request.httpMethod = 'POST';
        
        String response = ACT_APICreateLead.createLead(testLead);
        Test.stopTest();
        
        Data_Structure_Handle_Lead.ResultWithLeads result = (Data_Structure_Handle_Lead.ResultWithLeads) JSON.deserialize(response, Data_Structure_Handle_Lead.ResultWithLeads.class);
        
        System.assertEquals(true, result.result, result.message);
        
    }

    
    @isTest
    static void testCreateLead_Failure_NoAdvisorId() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        testLead.claveAsesor = '3255555';
        testLead.Name = 'Mary';
        testLead.MotherLastName = 'Doe';
        testLead.FatherLastName = 'Smith';
        testLead.phone = '1234567890';
        testLead.email = 'test@example.com';
        testLead.PostalCode = '12345';
        
        Test.startTest();
        Data_Structure_Handle_Lead.ResultWithLeads result = ACT_Controller_Lead.createLead(testLead);
        Test.stopTest();
        
        System.assertEquals(false, result.result, 'Lead creation should fail without Advisor Id');
        System.assertEquals('There is no Asesor with that Clave Asesor.', result.message, 'Error message mismatch');
        
    }
    
    @isTest
    static void testCreateLead_Failure_NoMotherLastName() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        testLead.claveAsesor = '123455';
        testLead.Name = 'Mary';
        testLead.MotherLastName = ' ';
        testLead.FatherLastName = 'Smith';
        testLead.phone = '1234567890';
        testLead.email = 'test@example.com';
        testLead.PostalCode = '12345';
        
        Test.startTest();
        Data_Structure_Handle_Lead.ResultWithLeads result = ACT_Controller_Lead.createLead(testLead);
        Test.stopTest();
        
        System.assertEquals(false, result.result, 'Lead creation should fail without Advisor Id');
        System.assertEquals('The field Mother Last Name is required.', result.message, 'Error message mismatch');
        
    }
    
    @isTest
    static void testCreateLead_Failure_NoFatherLastName() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        testLead.claveAsesor = '123455';
        testLead.Name = 'Mary';
        testLead.MotherLastName = 'Perez';
        testLead.FatherLastName = '';
        testLead.phone = '1234567890';
        testLead.email = 'test@example.com';
        testLead.PostalCode = '12345';
        
        Test.startTest();
        Data_Structure_Handle_Lead.ResultWithLeads result = ACT_Controller_Lead.createLead(testLead);
        Test.stopTest();
        
        System.assertEquals(false, result.result, 'Lead creation should fail without Advisor Id');
        System.assertEquals('The field Father Last Name is required.', result.message, 'Error message mismatch');
        
    }
    
    @isTest
    static void testCreateLead_Failure_NoMobilePhone() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        testLead.claveAsesor = '123455';
        testLead.Name = 'Mary';
        testLead.MotherLastName = 'Perez';
        testLead.FatherLastName = 'Garcia';
        testLead.phone = '';
        testLead.email = 'test@example.com';
        testLead.PostalCode = '12345';
        
        Test.startTest();
        Data_Structure_Handle_Lead.ResultWithLeads result = ACT_Controller_Lead.createLead(testLead);
        Test.stopTest();
        
        System.assertEquals(false, result.result, 'Lead creation should fail without Advisor Id');
        System.assertEquals('The field Mobile Phone is required.', result.message, 'Error message mismatch');  
    }
    
    @isTest
    static void testCreateLead_Failure_NoName() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        testLead.claveAsesor = '123455';
        testLead.Name = '';
        testLead.MotherLastName = 'Perez';
        testLead.FatherLastName = 'Garcia';
        testLead.phone = '123456789';
        testLead.email = 'test@example.com';
        testLead.PostalCode = '12345';
        
        Test.startTest();
        Data_Structure_Handle_Lead.ResultWithLeads result = ACT_Controller_Lead.createLead(testLead);
        Test.stopTest();
        
        System.assertEquals(false, result.result, 'Lead creation should fail without Advisor Id');
        System.assertEquals('The field Lead Name is required.', result.message, 'Error message mismatch');
        
    }
    
    @isTest
    static void testCreateLead_Failure_NoEmail() {
        
        Data_Structure_Handle_Lead.LeadObject testLead = new Data_Structure_Handle_Lead.LeadObject();
        testLead.claveAsesor = '123455';
        testLead.Name = 'Maria';
        testLead.MotherLastName = 'Perez';
        testLead.FatherLastName = 'Garcia';
        testLead.phone = '123456789';
        testLead.email = '';
        testLead.PostalCode = '12345';
        
        Test.startTest();
        Data_Structure_Handle_Lead.ResultWithLeads result = ACT_Controller_Lead.createLead(testLead);
        Test.stopTest();
        
        System.assertEquals(false, result.result, 'Lead creation should fail without Email');
        System.assertEquals('The field Email is required.', result.message, 'Error message mismatch');
        
    }
    
    @isTest
    static void getLeadsWithNoasesorId() {
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/ACT_Leads';//'ACT_Leads?leadName=Dalila&idAsesor=9999';
        request.addParameter('leadName', 'Dalila');
        request.addParameter('idAsesor', '9999');
        request.httpMethod = 'GET';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        Data_Structure_Handle_Lead.ResponseWithRelatedLead resul = ACT_APICreateLead.doGet();
        Test.stopTest();
        
        System.assertEquals(resul.message, 'Id Asesor does not exists!');
        
    }
    
    @isTest
    static void LeadsNotFound() {
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/ACT_Leads';//'ACT_Leads?leadName=Dalila&idAsesor=9999';
        request.addParameter('leadName', 'Dalila');
        request.addParameter('idAsesor', '123455'); 
        request.httpMethod = 'GET';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        Data_Structure_Handle_Lead.ResponseWithRelatedLead resul = ACT_APICreateLead.doGet();
        System.debug('result '+resul);
        Test.stopTest();
        
        System.assertEquals(resul.message, 'No lead found!');
    }
    
    @isTest
    static void LeadsFound() {
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/ACT_Leads';//'ACT_Leads?leadName=Dalila&idAsesor=9999';
        request.addParameter('leadName', 'Mary');
        request.addParameter('idAsesor', '123455'); 
        request.httpMethod = 'GET';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        Data_Structure_Handle_Lead.ResponseWithRelatedLead resul = ACT_APICreateLead.doGet();
        Test.stopTest();
        
        System.assertEquals(resul.message, 'No lead found!');
    }
    
}