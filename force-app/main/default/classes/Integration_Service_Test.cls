@isTest(IsParallel=true)
public with sharing class Integration_Service_Test {
	@IsTest
	public static void testFullCalloutSuccess() {
		F3_Integration_Service__mdt testMetadata = createMetadata();
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest'
		);
		Integration_Service.testSettings = new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings };
		Integration_Service.ServiceResponse response = Integration_Service.calloutService(
			'TestService',
			null,
			new Map<String, Object>{ 'change' => 'changed', 'Query.change' => 'error' },
			new Map<String, Object>{ 'change' => 'changed', 'Body.change' => 'error' },
			false
		);
		//verify service response
		System.assertEquals(1, ((Map<String, Object>) response.serviceResponse).size());
		System.assertEquals('success', ((Map<String, Object>) response.serviceResponse).get('Status'));
		System.assertEquals('200', response.serviceCode);
		System.assertEquals(System.Label.Success_200, response.serviceMessage);
		System.assertEquals(new Map<String, String>(), response.serviceHeaders);
		System.assert(response.logger != null);

		Map<Id, Log__c> insertedLogs = new Map<Id, Log__c>(
			[SELECT F3_Endpoint__c, F3_IntegrationName__c, F3_Request__c, F3_responseCode__c, F3_Response__c FROM Log__c]
		);
		System.assertEquals(2, insertedLogs.size());

		//verify service log
		Log__c serviceLog = insertedLogs.get(response.logger.serviceLog.id);
		System.assertEquals('testService.com', serviceLog.F3_Endpoint__c);
		System.assertEquals('TestService', serviceLog.F3_IntegrationName__c);
		System.assertEquals('{"parameter":"changed","delete":""}', serviceLog.F3_Request__c);
		System.assertEquals('200', serviceLog.F3_responseCode__c);
		System.assertEquals('{"Status":"success"}', serviceLog.F3_Response__c);
		//verify auth log
		insertedLogs.remove(response.logger.serviceLog.id);
		for (Id insertedLog : insertedLogs.keySet()) {
			Log__c authLog = insertedLogs.get(insertedLog);
			System.assertEquals('testAuth.com', authLog.F3_Endpoint__c);
			System.assertEquals('TestAuth', authLog.F3_IntegrationName__c);
			System.assertEquals(null, authLog.F3_Request__c);
			System.assertEquals('200', authLog.F3_responseCode__c);
			System.assertEquals('{"accessToken":"nNX51usqdS3CIjA1efGseilTSjZA"}', authLog.F3_Response__c);
		}
	}

	@IsTest
	public static void testFullCalloutServiceApexError() {
		try {
			Integration_Service.ServiceResponse response = Integration_Service.calloutService(
				'TestService',
				null,
				new Map<String, Object>{ 'change' => 'changed', 'Query.change' => 'error' },
				new Map<String, Object>{ 'change' => 'changed', 'Body.change' => 'error' },
				false
			);
		} catch (Exception e) {
			List<Log__c> insertedLogs = [
				SELECT F3_Endpoint__c, F3_IntegrationName__c, F3_Request__c, F3_responseCode__c, F3_Response__c
				FROM Log__c
			];
			System.assertEquals(0, insertedLogs.size());
			System.assertEquals('Integration_Handler.Integration_Service_Exception', e.getTypeName());
			System.assert(e.getMessage() == System.Label.Metadata_is_Blank);
		}

		//No service settings
		F3_Integration_Service__mdt testMetadata = createMetadata();
		Integration_Service.testSettings = new Map<String, Object>{ 'serviceMetadata' => testMetadata };
		try {
			Integration_Service.ServiceResponse response = Integration_Service.calloutService(
				'TestService',
				null,
				new Map<String, Object>{ 'change' => 'changed', 'Query.change' => 'error' },
				new Map<String, Object>{ 'change' => 'changed', 'Body.change' => 'error' },
				false
			);
		} catch (Exception e) {
			List<Log__c> insertedLogs = [
				SELECT F3_Endpoint__c, F3_IntegrationName__c, F3_Request__c, F3_responseCode__c, F3_Response__c
				FROM Log__c
			];
			System.assertEquals(0, insertedLogs.size());
			System.assertEquals('Integration_Handler.Integration_Service_Exception', e.getTypeName());
			System.assert(e.getMessage() == System.Label.Custom_Setting_is_Blank);
		}
	}

	private static F3_Integration_Service__mdt createMetadata() {
		F3_Integration_Service__mdt serviceMetadata = new F3_Integration_Service__mdt();
		serviceMetadata.F3_Mock_Response__c = '{"Status":"success"}';
		serviceMetadata.F3_Retrive_Mock__c = true;
		serviceMetadata.F3_Mock_Status_Code__c = 200;
		serviceMetadata.F3_Query_String_Input_Template__c = '';
		serviceMetadata.F3_Named_Credential__c = null;
		serviceMetadata.F3_Service_Setting__c = 'TestService';
		serviceMetadata.F3_Headers__c = '{"Content-Length":"0"}';
		serviceMetadata.F3_HTTP_Method__c = 'GET';
		serviceMetadata.F3_JSON_Input_Template__c = '{"parameter":"#change#","delete":"#delete#"}';
		serviceMetadata.F3_Authorization_Service__c = 'TestAuth';
		serviceMetadata.F3_Authorization_Class__c = 'F3_AccessToken_Utility';
		serviceMetadata.DeveloperName = 'TestService';
		return serviceMetadata;
	}
}