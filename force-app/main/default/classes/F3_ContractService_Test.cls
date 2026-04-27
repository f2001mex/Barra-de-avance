/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_ContractService_Test
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 23/11/2022
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Test for the F3_ContractService.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 23/11/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
@isTest(IsParallel=true)
public with sharing class F3_ContractService_Test {
	@IsTest
	static void createContract() {
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest',
			Name = 'SFcrearActualizarContrato'
		);
		insert testSettings;
		String recordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Cliente Banca Privada').getRecordTypeId();
		final Map<Schema.SObjectField, Object> mapFields = new Map<Schema.SObjectField, Object>{ Account.RecordTypeId => recordTypeID };
		Map<String, List<SObject>> accOpps = UtilitiesDataTest.createAccountOpportunities(1, 1, mapFields, null);
		List<Account> insertedAccounts = accOpps.get('Account');
		List<Opportunity> oppsToInsert = accOpps.get('Opportunity');
		insert oppsToInsert;
		String oppAutoNumber = [SELECT F3_Consecutivo_ID__c FROM Opportunity WHERE Id = :oppsToInsert[0].Id LIMIT 1].F3_Consecutivo_ID__c;
		// Set up a test request
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		String requestBody =
			'{"contratos":[{"NUM_CONTRATO_PK":"2022101706","OPORTUNIDADID":"' +
			oppAutoNumber +
			'","NUM_UNIDAD_NEGOCIO_PK":"1","NUM_CLIENTE":"' +
			insertedAccounts[0].Client_Id__c +
			'","NUM_ASESOR":"2505","ESTATUS_CONTRATO":"CC05","FECHA_APERTURA":"01/12/2000","TIPO_CONTRATO":"01","SUB_TIPO_CONTRATO":"01","DESC_CONTRATO":"CONTRATO MARCO DE PRODUCTOS Y SERVICIOS BANCARIOS MÚLTIPLES","DESC_SUB_TIPO_CONTRATO":"SUB TIPO CONTRATO MARCO DE PRODUCTOS Y SERVICIOS BANCARIOS MÚLTIPLES","CANAL_APERTURA":"","FLG_MERCADEO":"X","FLG_PUBLICIDAD_ACTINVER":"X","FLG_OFF_COMER_MERCA":"X","FLG_DATOS_PERSONALES_SENSIBLES":"X","FLG_OFF_COMER_PRIVACIDAD":"X","FLG_INVITACION_EVENTOS":"","FLG_ACTIVIDADES_RECREATIVAS":"X","FLG_DATOS_TERCEROS":"X","IDIOMA_ESTADO_CUENTA":"X","telefonos":[{"NUM_CONTRATO_PK":"2022101706","NUM_UNIDAD_NEGOCIO_PK":"1","NUM_TIPO_TELEFONO_PK":"1","NUM_PRIORIDAD_PK":1,"TIPO_TELEFONO":"02","TELEFONO":"5541418585","LADA":"52","CODIGO_AREA":"001","FLG_PRINCIPAL":"X"}],"correos":[{"NUM_CONTRATO_PK":"2022101706","NUM_PRIORIDAD_PK":1,"CORREO_ELECTRONICO":"test@test.com","FLG_PRINCIPAL":"X"}],"direcciones":[{"NUM_CONTRATO_PK":"2022101706","NUM_TIPO_DIRECCION_PK":"1","NUM_PRIORIDAD_PK":1,"TIPO_DIRECCION":"Fiscal","CALLE":"Del Carmen","NUM_INT":"A1","NUM_EXT":"23","COLONIA":"Chimalistac","DELEGACION":"AO","CODIGO_POSTAL":"01070","ESTADO":"CDMX","PAIS":"MX"}],"figuras":[{"NUM_INTERLOCUTOR_PK":"AO","NUM_TIPO_FIGURA_PK":"01070","NUM_CONTRATO_PK":"2022101706","TIPO_FIGURA":"23","NOMBRE_COMPLETO":"Chimalistac","RFC":"A1XXXXXXXX","ACTIVIDAD_ECONOMICA":"Del Carmen","GENERO":"Fiscal"}]}]}';
		request.requestUri = 'https://actinver--actidev.sandbox.my.salesforce.com/services/apexrest/crearActualizarContrato';
		request.httpMethod = 'PUT';
		request.requestBody = Blob.valueOf(requestBody);
		RestContext.request = request;
		RestContext.response = response;
		Test.startTest();
		F3_ContractService_Controller.upsertContractAndRelated();
		Test.stopTest();
		String expectedResponse = '{"Opportunity":{"Errors Descriptions":{},"Stadistics":{"Errors":"0","Created":"0","Success":"1","Total":"1"}},"Figuras_Relacionadas__c":{"Errors Descriptions":{},"Stadistics":{"Errors":"0","Created":"1","Success":"1","Total":"1"}},"Correo_de_Contrato__c":{"Errors Descriptions":{},"Stadistics":{"Errors":"0","Created":"1","Success":"1","Total":"1"}},"Telefono_de_Contrato__c":{"Errors Descriptions":{},"Stadistics":{"Errors":"0","Created":"1","Success":"1","Total":"1"}},"Direcci_n_de_Contrato__c":{"Errors Descriptions":{},"Stadistics":{"Errors":"0","Created":"1","Success":"1","Total":"1"}},"Contract":{"Errors Descriptions":{},"Stadistics":{"Errors":"0","Created":"1","Success":"1","Total":"1"}}}';
		System.assertEquals(expectedResponse, response.responseBody.toString());
		List<Log__c> insertedLogs = [
			SELECT F3_Endpoint__c, F3_IntegrationName__c, F3_Request__c, F3_responseCode__c, F3_Response__c, F3_HTTP_Method__c
			FROM Log__c
		];
		System.assertEquals(1, insertedLogs.size());
		System.assertEquals(requestBody, insertedLogs[0].F3_Request__c);
		System.assertEquals('/services/apexrest/crearActualizarContrato', insertedLogs[0].F3_Endpoint__c);
		System.assertEquals('SFcrearActualizarContrato', insertedLogs[0].F3_IntegrationName__c);
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
			Name = 'SFcrearActualizarContrato'
		);
		insert testSettings;
		// Set up a test request
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		String requestBody = '{"contratos":[]}';
		request.requestUri = 'https://actinver--actidev.sandbox.my.salesforce.com/services/apexrest/crearActualizarContrato';
		request.httpMethod = 'PUT';
		request.requestBody = Blob.valueOf(requestBody);
		RestContext.request = request;
		RestContext.response = response;
		Test.startTest();
		F3_ContractService_Controller.upsertContractAndRelated();
		Test.stopTest();
		System.assert(response.responseBody.toString().contains('Sin registros validos'));
		List<Log__c> insertedLogs = [
			SELECT F3_Endpoint__c, F3_IntegrationName__c, F3_Request__c, F3_responseCode__c, F3_Response__c, F3_HTTP_Method__c
			FROM Log__c
		];
		System.assertEquals(1, insertedLogs.size());
		System.assertEquals(requestBody, insertedLogs[0].F3_Request__c);
		System.assertEquals('/services/apexrest/crearActualizarContrato', insertedLogs[0].F3_Endpoint__c);
		System.assertEquals('SFcrearActualizarContrato', insertedLogs[0].F3_IntegrationName__c);
		System.assertEquals('PUT', insertedLogs[0].F3_HTTP_Method__c);
		System.assertEquals('400', insertedLogs[0].F3_responseCode__c);
		System.assert(insertedLogs[0].F3_Response__c.contains('Sin registros validos'));
	}

	@IsTest
	static void testException() {
		// Set up a test request
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		request.requestUri = 'https://actinver--actidev.sandbox.my.salesforce.com/services/apexrest/crearActualizarContrato';
		request.httpMethod = 'PUT';
		request.requestBody = Blob.valueOf('');
		RestContext.request = request;
		RestContext.response = response;
		Test.startTest();
		F3_ContractService_Controller.upsertContractAndRelated();
		Test.stopTest();
		System.assertEquals(400, response.statusCode);
	}
}