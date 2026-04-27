/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_Enrolamiento_Test
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 23/11/2022
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Test for the F3_Enrolamiento.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 23/11/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
@IsTest
private class F3_Enrolamiento_Test {
	@testSetup
	static void dataSetup() {
		Account acc = new Account();
		acc.Client_ID__c = '1234567890123';
		acc.Industry = 'Agriculture';
		acc.Name = 'Test';
		insert acc;
	}
	@IsTest
	static void updateEnrolamiento() {
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest',
			Name = 'SFcrearActualizarEnrolamiento'
		);
		insert testSettings;
		// Set up a test request
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		request.requestUri = 'https://actinver--actidev.sandbox.my.salesforce.com/services/apexrest/crearActualizarEnrolamiento';
		request.httpMethod = 'POST';
		request.requestBody = Blob.valueOf(
			'{"clientes": [{"cliente": {"NUM_CLIENTE_PK": "1234567890123","Estatus": "Nalle","TIPO": "Moreno"}}]}'
		);
		RestContext.request = request;
		RestContext.response = response;
		Test.startTest();
		F3_Enrolamiento_Controller.insertUpdateClient();
		Test.stopTest();
		String responseBody = response.responseBody.toString();
		System.assertEquals(true, responseBody.substring(responseBody.indexOf('Account')).contains('"Success":"1"'));
		List<Log__c> insertedLogs = [
			SELECT F3_Endpoint__c, F3_IntegrationName__c, F3_Request__c, F3_responseCode__c, F3_Response__c, F3_HTTP_Method__c
			FROM Log__c
		];
		System.assertEquals(1, insertedLogs.size());
	}

	@IsTest
	static void updateEnrolamientoError() {
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest',
			Name = 'SFcrearActualizarEnrolamiento'
		);
		insert testSettings;
		// Set up a test request
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		request.requestUri = 'https://actinver--actidev.sandbox.my.salesforce.com/services/apexrest/crearActualizarEnrolamiento';
		request.httpMethod = 'POST';
		request.requestBody = Blob.valueOf('{"clientes": []}');
		RestContext.request = request;
		RestContext.response = response;
		Test.startTest();
		F3_Enrolamiento_Controller.insertUpdateClient();
		Test.stopTest();
		String responseBody = response.responseBody.toString();
		System.assert(response.responseBody.toString().contains('"Mensaje"'));
		List<Log__c> insertedLogs = [
			SELECT F3_Endpoint__c, F3_IntegrationName__c, F3_Request__c, F3_responseCode__c, F3_Response__c, F3_HTTP_Method__c
			FROM Log__c
		];
		System.assertEquals(1, insertedLogs.size());
		System.assertEquals('400', insertedLogs[0].F3_responseCode__c);
	}
}