/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_ClientService_Test
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 23/11/2022
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Test for the F3_ClientService.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 23/11/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
@isTest
public with sharing class F3_ClientService_Test {
    
	@TestSetup
	static void makeData() {
        Id recordTypeIdWM = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('WealthManagement').getRecordTypeId(); 
        Profile wealtManagementProfile = [SELECT Id FROM Profile WHERE Name = 'Banquero Wealth Management' LIMIT 1];
		//insert User
		User testUserWM = new User(
			FirstName = 'WealtManagement',
			LastName = 'WealtManagement',
			UserName = 'WealtManagement@WM.com',
			Email = 'WealtManagement@WM.com',
			Alias = 't1',
			TimeZoneSidKey = 'America/Mexico_City',
			LocaleSidKey = 'es_MX',
			EmailEncodingKey = 'UTF-8',
			ProfileId = wealtManagementProfile.Id,
			LanguageLocaleKey = 'es_MX',
            ID_ASESOR__c = '000160371'
		);
        insert testUserWM;
        
        BranchUnit objBranchUnit = new BranchUnit();
        objBranchUnit.ExternalId__c = '001';
        objBranchUnit.ExternalIdBI__c ='1';
        objBranchUnit.Name = 'CF 001';
        insert objBranchUnit;
        
        Banker objBanker = new Banker();
        objBanker.Name = 'test';
        objBanker.CurrentBranchId = objBranchUnit.Id;
        objBanker.UserOrContactId = testUserWM.Id;
        objBanker.Disponible__c = true;
        objBanker.ExternalId__c = '000160371';
            
        insert objBanker;
        
        BranchUnitBusinessMember objBUBM = [SELECT Id FROM BranchUnitBusinessMember WHERE BranchUnit.ExternalId__c = '001' LIMIT 1];
        objBUBM.ExternalId__c = '001000160371';
        update objBUBM;
        
        Lead newLead = new Lead();
		newLead.FirstName = 'Test';
		newLead.LastName = 'Perez';
		newLead.Suffix = 'Mendoza';
		newLead.OportunidadDeProspecto__c = true;
		newLead.LeadSource = 'Referenciado Cliente';
		newLead.F3_Nacionalidad__c = 'MX';
		newLead.Pais_Nacimiento__c = 'MX';
		newLead.F3_CURP__c = 'MOCV780623HDFSRC02';
		newLead.F3_RFC__c = 'MOCV780623';
		newLead.Email = 'josue.per@vasscompany.com';
		newLead.ClienteCreadoDeProspecto__c = true;
		newLead.Status = 'Cerrado';
		newLead.Estado_Nacimiento__c = 'CHS';
		newLead.Prioridad__c = 'Baja';
		newLead.MobilePhone = '5544332299';
		newLead.Clasificacion_Persona__c = '4';
		newLead.MontoEstimadoDeInversion__c = 123;
		newLead.FechaEstimadaDeCierre__c = System.today().addDays(1);
		newLead.F3_Estado_Civil__c = '2';
		newLead.Fecha_Nacimiento_Prospecto__c = System.today().addyears(-40);
		newLead.Gender__c = '1';
		newLead.Tipo_de_Persona__c = '1';
		newLead.RecordTypeId = recordTypeIdWM;
		newLead.OwnerId = testUserWM.Id;
		newLead.F3_Consecutivo_ID__c = 'CRMPR-00000002';
		insert newLead;
	}
	@IsTest
	static void createClient() {
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest',
			Name = 'SFcrearActualizarCliente'
		);
		insert testSettings;
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		String requestBody = '{"clientes":[{"NUM_CLIENTE_PK":"1","NOMBRE":"Test","APELLIDO_PATERNO":"Client","PROSPECTOID":""}]}';
		request.requestUri = 'https://actinver--actidev.sandbox.my.salesforce.com/services/apexrest/crearActualizarCliente';
		request.httpMethod = 'PUT';
		request.requestBody = Blob.valueOf(requestBody);
		RestContext.request = request;
		RestContext.response = response;
		Test.startTest();
		F3_ClientService_Controller.insertUpdateClient();
		Test.stopTest();
		String responseBody = response.responseBody.toString();
		String expectedResponse = '{"Account":{"Errors Descriptions":{},"Stadistics":{"Errors":"0","Created":"1","Success":"1","Total":"1"}}}';
		System.assertEquals(expectedResponse, responseBody);
		List<Log__c> insertedLogs = [
			SELECT F3_Endpoint__c, F3_IntegrationName__c, F3_Request__c, F3_responseCode__c, F3_Response__c, F3_HTTP_Method__c
			FROM Log__c
		];
		System.assertEquals(1, insertedLogs.size());
		System.assertEquals(requestBody, insertedLogs[0].F3_Request__c);
		System.assertEquals('/services/apexrest/crearActualizarCliente', insertedLogs[0].F3_Endpoint__c);
		System.assertEquals('SFcrearActualizarCliente', insertedLogs[0].F3_IntegrationName__c);
		System.assertEquals('PUT', insertedLogs[0].F3_HTTP_Method__c);
		System.assertEquals('200', insertedLogs[0].F3_responseCode__c);
		System.assertEquals(expectedResponse, insertedLogs[0].F3_Response__c);
	}

	@IsTest
	static void testNoDataSent() {
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest',
			Name = 'SFcrearActualizarCliente'
		);
		insert testSettings;
		// Set up a test request
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		String requestBody = '{"clientes":[]}';
		request.requestUri = 'https://actinver--actidev.sandbox.my.salesforce.com/services/apexrest/crearActualizarCliente';
		request.httpMethod = 'PUT';
		request.requestBody = Blob.valueOf(requestBody);
		RestContext.request = request;
		RestContext.response = response;
		Test.startTest();
		F3_ClientService_Controller.insertUpdateClient();
		Test.stopTest();
		System.assert(response.responseBody.toString().contains('Sin registros validos'));
		List<Log__c> insertedLogs = [
			SELECT F3_Endpoint__c, F3_IntegrationName__c, F3_Request__c, F3_responseCode__c, F3_Response__c, F3_HTTP_Method__c
			FROM Log__c
		];
		System.assertEquals(1, insertedLogs.size());
		System.assertEquals(requestBody, insertedLogs[0].F3_Request__c);
		System.assertEquals('/services/apexrest/crearActualizarCliente', insertedLogs[0].F3_Endpoint__c);
		System.assertEquals('SFcrearActualizarCliente', insertedLogs[0].F3_IntegrationName__c);
		System.assertEquals('PUT', insertedLogs[0].F3_HTTP_Method__c);
		System.assertEquals('400', insertedLogs[0].F3_responseCode__c);
		System.assert(insertedLogs[0].F3_Response__c.contains('Sin registros validos'));
	}

	@IsTest
	static void createClientWithOriginLead() {
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest',
			Name = 'SFcrearActualizarCliente'
		);
		insert testSettings;
		List<contact> lstContact = new List<Contact>();
		lstContact.add(new Contact(FirstName = 'test', LastName = 'Contact'));
		insert lstContact;
		Lead newLead = new Lead();
		newLead.FirstName = 'Test';
		newLead.LastName = 'Lead';
		newLead.PostalCode = '30000';
		newLead.Status = 'Asignado';
		newLead.FinServ__ExpressedInterest__c = 'Banca Soluciones';
		newLead.FinServ__ReferredByContact__c = lstContact[0].Id;
		newLead.F3_Consecutivo_ID__c = 'CRMPR-00000001';
		insert newLead;
		Lead insertedLead = [SELECT Id, F3_Consecutivo_ID__c FROM Lead WHERE ID = :newLead.id LIMIT 1];
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		String requestBody =
			'{"clientes":[{"NUM_CLIENTE_PK":"1","NOMBRE":"Test","APELLIDO_PATERNO":"Client","PROSPECTOID":"' +
			String.valueOf(insertedLead.F3_Consecutivo_ID__c) +
			'"}]}';
		request.requestUri = 'https://actinver--actidev.sandbox.my.salesforce.com/services/apexrest/crearActualizarCliente';
		request.httpMethod = 'PUT';
		request.requestBody = Blob.valueOf(requestBody);
		RestContext.request = request;
		RestContext.response = response;
		Test.startTest();
		F3_ClientService_Controller.insertUpdateClient();
		Test.stopTest();
		String responseBody = response.responseBody.toString();
		String expectedResponse = '{"Lead":{"Errors Descriptions":{},"Stadistics":{"Errors":"0","Created":"0","Success":"1","Total":"1"}},"Account":{"Errors Descriptions":{},"Stadistics":{"Errors":"0","Created":"1","Success":"1","Total":"1"}}}';
		System.assertEquals(expectedResponse, responseBody);
		List<Log__c> insertedLogs = [
			SELECT F3_Endpoint__c, F3_IntegrationName__c, F3_Request__c, F3_responseCode__c, F3_Response__c, F3_HTTP_Method__c
			FROM Log__c
		];
		System.assertEquals(1, insertedLogs.size());
		System.assertEquals(requestBody, insertedLogs[0].F3_Request__c);
		System.assertEquals('/services/apexrest/crearActualizarCliente', insertedLogs[0].F3_Endpoint__c);
		System.assertEquals('SFcrearActualizarCliente', insertedLogs[0].F3_IntegrationName__c);
		System.assertEquals('PUT', insertedLogs[0].F3_HTTP_Method__c);
		System.assertEquals('200', insertedLogs[0].F3_responseCode__c);
		System.assertEquals(expectedResponse, insertedLogs[0].F3_Response__c);
	}

	@IsTest
	static void testException() {
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		request.requestUri = 'https://actinver--actidev.sandbox.my.salesforce.com/services/apexrest/crearActualizarCliente';
		request.httpMethod = 'PUT';
		request.requestBody = Blob.valueOf('');
		RestContext.request = request;
		RestContext.response = response;
		Test.startTest();
		F3_ClientService_Controller.insertUpdateClient();
		Test.stopTest();
		System.assertEquals(400, response.statusCode);
	}
    
    @isTest
    static void testProcessDataOld() {
        // Crear datos de prueba
        Account account = new Account(Name = 'Test Account', Client_ID__c = '12345');
        insert account;

        Map<String, List<SObject>> sObjectMap = new Map<String, List<SObject>>();
        sObjectMap.put('Account', new List<SObject>{ account });

        Test.startTest();
        // Ejecutar método
        Map<String, Map<String, Map<String, String>>> result = F3_ClientService_Handler.processDataOld(sObjectMap);
        Test.stopTest();

        // Validaciones
        System.assert(result != null, 'El resultado no debe ser nulo');
        System.assert(result.containsKey('Account'), 'El resultado debe contener el mapa de Account');
    }
    
	@IsTest
	static void createClientWithOriginLeadWM() {
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest',
			Name = 'SFcrearActualizarCliente'
		);
		insert testSettings;
		Lead insertedLead = [SELECT Id, F3_Consecutivo_ID__c FROM Lead WHERE F3_Consecutivo_ID__c = 'CRMPR-00000002' LIMIT 1];
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		String requestBody =
			'{"clientes":[{"NUM_CLIENTE_PK":"1","NOMBRE":"Test","APELLIDO_PATERNO":"Client","PROSPECTOID":"' +
			String.valueOf(insertedLead.F3_Consecutivo_ID__c) +
			'"}]}';
		request.requestUri = 'https://actinver--actidev.sandbox.my.salesforce.com/services/apexrest/crearActualizarCliente';
		request.httpMethod = 'PUT';
		request.requestBody = Blob.valueOf(requestBody);
		RestContext.request = request;
		RestContext.response = response;
		Test.startTest();
		F3_ClientService_Controller.insertUpdateClient();
		Test.stopTest();
	}

}