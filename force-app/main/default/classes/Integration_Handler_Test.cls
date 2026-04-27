@isTest(IsParallel=true)
public with sharing class Integration_Handler_Test {
	@IsTest
	public static void testMockCall() {
		Integration_Handler calloutExecution = new Integration_Handler(
			'TestService',
			null,
			null,
			null,
			true,
			new Map<String, Object>{ 'serviceMetadata' => createMetadata() }
		);
		HttpResponse response = calloutExecution.mockCall();
		System.assertEquals('{"Status":"success"}', response.getBody());
		System.assertEquals(200, response.getStatusCode());
	}

	@IsTest
	public static void testSetResponse() {
		// Raw response
		Integration_Handler calloutExecution = new Integration_Handler('TestService', null, null, null, true, null);
		Object rawResponse = calloutExecution.setServiceResponse('{"Status":"success"}', 200);
		System.assertEquals('{"Status":"success"}', rawResponse);
		Object response204WBody = calloutExecution.setServiceResponse('{"Status":"success"}', 204);
		System.assertEquals(null, response204WBody);
		Object response204NoBody = calloutExecution.setServiceResponse(null, 204);
		System.assertEquals(null, response204NoBody);

		// Casted response
		calloutExecution = new Integration_Handler('TestService', null, null, null, false, null);
		Object mapResponse = calloutExecution.setServiceResponse('{"Status":"success"}', 200);
		System.assertEquals('success', ((Map<String, Object>) mapResponse).get('Status'));
		Object ListResponse = calloutExecution.setServiceResponse('["success"]', 200);
		System.assertEquals('success', ((List<Object>) ListResponse)[0]);
		Object StringResponse = calloutExecution.setServiceResponse('success', 200);
		System.assertEquals('success', StringResponse);
	}

	@IsTest
	public static void testSetMessage() {
		Integration_Handler calloutExecution = new Integration_Handler('TestService', null, null, null, true, null);
		String success200 = calloutExecution.setServiceMessage(200);
		String error400 = calloutExecution.setServiceMessage(400);
		String error404 = calloutExecution.setServiceMessage(404);
		String error500 = calloutExecution.setServiceMessage(500);
		String errorGeneric = calloutExecution.setServiceMessage(503);
		System.assertEquals(System.Label.Success_200, success200);
		System.assertEquals(System.Label.Error_400, error400);
		System.assertEquals(System.Label.Error_404, error404);
		System.assertEquals(System.Label.Error_500, error500);
		System.assertEquals(System.Label.Error_Generic, errorGeneric);
	}

	@IsTest
	public static void testConstructEndpoint() {
		F3_Integration_Service__mdt testMetadata = createMetadata();
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest'
		);
		Integration_Handler calloutExecution = new Integration_Handler(
			'TestService',
			null,
			null,
			null,
			true,
			new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings }
		);
		String rawEndpoint = calloutExecution.constructEndpoint(calloutExecution.constructQueryString(null));
		System.assertEquals('testService.com', rawEndpoint);
		testMetadata.F3_Query_String_Input_Template__c = '?parameter=#change#&delete=#deleted#';
		calloutExecution = new Integration_Handler(
			'TestService',
			null,
			null,
			null,
			true,
			new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings }
		);
		String endpointWithQuerystring = calloutExecution.constructEndpoint(
			calloutExecution.constructQueryString(new Map<String, Object>{ 'User.change' => 'error', 'change' => 'changed' })
		);
		System.assertEquals('testService.com?parameter=changed&delete=', endpointWithQuerystring);

		//Test endpoint adding a named credential api name
		testMetadata.F3_Named_Credential__c = 'TestServiceNC';
		calloutExecution = new Integration_Handler(
			'TestServiceNC',
			null,
			null,
			null,
			true,
			new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings }
		);
		String endpointNameCredentialWithQuerystring = calloutExecution.constructEndpoint(
			calloutExecution.constructQueryString(new Map<String, Object>{ 'User.change' => 'error', 'change' => 'changed' })
		);
		System.assertEquals('callout:TestServiceNC?parameter=changed&delete=', endpointNameCredentialWithQuerystring);
		testMetadata.F3_Query_String_Input_Template__c = null;
		calloutExecution = new Integration_Handler(
			'TestServiceNC',
			null,
			null,
			null,
			true,
			new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings }
		);
		String endpointNameCredential = calloutExecution.constructEndpoint(calloutExecution.constructQueryString(null));
		System.assertEquals('callout:TestServiceNC', endpointNameCredential);

		// Test no endpoint nor named credential
		try {
			testSettings.F3_URL__c = null;
			testMetadata.F3_Named_Credential__c = null;
			calloutExecution = new Integration_Handler(
				'TestService',
				null,
				null,
				null,
				true,
				new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings }
			);
			String noEndpoint = calloutExecution.constructEndpoint(calloutExecution.constructQueryString(null));
		} catch (Exception e) {
			System.assertEquals('Integration_Handler.Integration_Service_Exception', e.getTypeName());
			System.assertEquals(System.Label.Endpoint_is_Blank, e.getMessage());
		}
	}

	@IsTest
	public static void testResponseHeadersToMap() {
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setHeader('Content-Length', '0');
		Integration_Handler calloutExecution = new Integration_Handler('TestService', null, null, null, true, null);
		Map<String, String> responseHeaders = calloutExecution.getResponseHeadersAsMap(response);
		System.assertEquals(2, responseHeaders.size());
		System.assertEquals('application/json', responseHeaders.get('Content-Type'));
		System.assertEquals('0', responseHeaders.get('Content-Length'));
	}

	@IsTest
	public static void testConstructBody() {
		F3_Integration_Service__mdt testMetadata = createMetadata();
		Integration_Handler calloutExecution = new Integration_Handler(
			'TestService',
			null,
			null,
			null,
			true,
			new Map<String, Object>{ 'serviceMetadata' => testMetadata }
		);
		String body = calloutExecution.constructBodyByTemplate(new Map<String, Object>{ 'change' => 'changed', 'User.change' => 'error' });
		System.assertEquals('{"parameter":"changed","delete":""}', body);

		//No data for the template
		String bodyNoData = calloutExecution.constructBodyByTemplate(null);
		System.assertEquals('{"parameter":"","delete":""}', bodyNoData);

		//No body template
		testMetadata.F3_JSON_Input_Template__c = null;
		calloutExecution = new Integration_Handler(
			'TestService',
			null,
			null,
			null,
			true,
			new Map<String, Object>{ 'serviceMetadata' => testMetadata }
		);
		String bodyNoTemplate = calloutExecution.constructBodyByTemplate(
			new Map<String, Object>{ 'change' => 'changed', 'User.change' => 'error' }
		);
		System.assertEquals(null, bodyNoTemplate);
	}

	@IsTest
	public static void testConstructHeaders() {
		//Headers and get Auth header
		F3_Integration_Service__mdt testMetadata = createMetadata();
		Integration_Handler calloutExecution = new Integration_Handler(
			'TestService',
			null,
			null,
			null,
			true,
			new Map<String, Object>{ 'serviceMetadata' => testMetadata }
		);
		Map<String, Object> requestHeadersWithAuth = calloutExecution.constructRequestHeaders();
		System.assertEquals(2, requestHeadersWithAuth.size());
		System.assertEquals('Bearer nNX51usqdS3CIjA1efGseilTSjZA', requestHeadersWithAuth.get('Authorization'));
		System.assertEquals('0', requestHeadersWithAuth.get('Content-Length'));

		//Headers and fail auth header retrieval
		try {
			testMetadata.F3_Authorization_Service__c = 'TestAuth500';
			calloutExecution = new Integration_Handler(
				'TestService',
				null,
				null,
				null,
				true,
				new Map<String, Object>{ 'serviceMetadata' => testMetadata }
			);
			Map<String, Object> errorRequest = calloutExecution.constructRequestHeaders();
		} catch (Exception e) {
			System.assertEquals('Integration_Handler.Integration_Auth_Exception', e.getTypeName());
		}

		//Headers without Auth header
		testMetadata.F3_Authorization_Service__c = null;
		calloutExecution = new Integration_Handler(
			'TestService',
			null,
			null,
			null,
			true,
			new Map<String, Object>{ 'serviceMetadata' => testMetadata }
		);
		Map<String, Object> requestHeadersNoAuth = calloutExecution.constructRequestHeaders();
		System.assertEquals(1, requestHeadersNoAuth.size());
		System.assertEquals('0', requestHeadersNoAuth.get('Content-Length'));
	}

	@IsTest
	public static void testQuery() {
		Integration_Handler calloutExecution = new Integration_Handler('TestService', null, null, null, true, null);
		F3_Integration_Service__mdt testMetadata = calloutExecution.getIntegrationMetadata('TestService');
		System.assert(testMetadata == null, 'No metadata is retrieved nor given, ergo the null value');
	}

	@IsTest
	public static void testFullCalloutSuccess() {
		F3_Integration_Service__mdt testMetadata = createMetadata();
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest'
		);
		Integration_Handler calloutExecution = new Integration_Handler(
			'TestService',
			null,
			new Map<String, Object>{ 'change' => 'changed', 'Query.change' => 'error' },
			new Map<String, Object>{ 'change' => 'changed', 'Body.change' => 'error' },
			false,
			new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings }
		);
		Integration_Service.ServiceResponse response = calloutExecution.invoke();
		//verify service response
		System.assertEquals(1, ((Map<String, Object>) response.serviceResponse).size());
		System.assertEquals('success', ((Map<String, Object>) response.serviceResponse).get('Status'));
		System.assertEquals('200', response.serviceCode);
		System.assertEquals(System.Label.Success_200, response.serviceMessage);
		System.assertEquals(new Map<String, String>(), response.serviceHeaders);
		System.assert(response.logger != null);
		System.assertEquals(2, calloutExecution.loggerList.size());
		//verify auth log
		System.assertEquals('testAuth.com', calloutExecution.loggerList[0].serviceLog.F3_Endpoint__c);
		System.assertEquals('TestAuth', calloutExecution.loggerList[0].serviceLog.F3_IntegrationName__c);
		System.assertEquals(null, calloutExecution.loggerList[0].serviceLog.F3_Request__c);
		System.assertEquals('200', calloutExecution.loggerList[0].serviceLog.F3_responseCode__c);
		System.assertEquals('{"accessToken":"nNX51usqdS3CIjA1efGseilTSjZA"}', calloutExecution.loggerList[0].serviceLog.F3_Response__c);
		//verify service log
		System.assertEquals('testService.com', calloutExecution.loggerList[1].serviceLog.F3_Endpoint__c);
		System.assertEquals('TestService', calloutExecution.loggerList[1].serviceLog.F3_IntegrationName__c);
		System.assertEquals('{"parameter":"changed","delete":""}', calloutExecution.loggerList[1].serviceLog.F3_Request__c);
		System.assertEquals('200', calloutExecution.loggerList[1].serviceLog.F3_responseCode__c);
		System.assertEquals('{"Status":"success"}', calloutExecution.loggerList[1].serviceLog.F3_Response__c);
		System.assertEquals(response.logger, calloutExecution.loggerList[1]);
	}

	@IsTest
	public static void testFullCalloutWithGivenBodySuccess() {
		F3_Integration_Service__mdt testMetadata = createMetadata();
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest'
		);
		Integration_Handler calloutExecution = new Integration_Handler(
			'TestService',
			'{"s":"d"}',
			null,
			null,
			true,
			new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings }
		);
		Integration_Service.ServiceResponse response = calloutExecution.invoke();
		System.assertEquals('200', response.serviceCode);
		System.assertEquals('{"Status":"success"}', response.serviceResponse);
		System.assertEquals(2, calloutExecution.loggerList.size());
		System.assertEquals(System.Label.Success_200, response.serviceMessage);
		System.assertEquals(new Map<String, String>(), response.serviceHeaders);
		System.assert(response.logger != null);
		System.assertEquals(2, calloutExecution.loggerList.size());
		System.assertEquals(response.logger, calloutExecution.loggerList[1]);
	}

	@IsTest
	public static void testFullCalloutResponseStringSuccess() {
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest'
		);
		F3_Integration_Service__mdt testMetadata = createMetadata();
		testMetadata.F3_Mock_Response__c = 'success';
		Integration_Handler calloutExecution = new Integration_Handler(
			'TestService',
			null,
			new Map<String, Object>{ 'change' => 'changed', 'Query.change' => 'error' },
			new Map<String, Object>{ 'change' => 'changed', 'Body.change' => 'error' },
			false,
			new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings }
		);
		Integration_Service.ServiceResponse response = calloutExecution.invoke();
		System.assertEquals('200', response.serviceCode);
		System.assertEquals('success', response.serviceResponse);
		System.assertEquals(System.Label.Success_200, response.serviceMessage);
		System.assertEquals(new Map<String, String>(), response.serviceHeaders);
		System.assert(response.logger != null);
		System.assertEquals(2, calloutExecution.loggerList.size());
		System.assertEquals(response.logger, calloutExecution.loggerList[1]);
	}

	@IsTest
	public static void testFullCalloutEndpointError() {
		Integration_Handler calloutExecution;
		try {
			F3_Integration_Service__mdt testMetadata = createMetadata();
			F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
				F3_URL__c = null,
				F3_Enable_Log__c = true,
				F3_Service_Type__c = 'ApexRest'
			);
			calloutExecution = new Integration_Handler(
				'TestService',
				null,
				null,
				null,
				true,
				new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings }
			);
			Integration_Service.ServiceResponse response = calloutExecution.invoke();
		} catch (Exception e) {
			System.assertEquals(0, calloutExecution.loggerList.size());
			System.assertEquals('Integration_Handler.Integration_Service_Exception', e.getTypeName());
			System.assertEquals(System.Label.Endpoint_is_Blank, e.getMessage());
		}
	}

	@IsTest
	public static void testFullCalloutAuthError() {
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest'
		);
		F3_Integration_Service__mdt testMetadata = createMetadata();
		testMetadata.F3_Authorization_Service__c = 'TestAuth400';
		Integration_Handler calloutExecution = new Integration_Handler(
			'TestService',
			null,
			null,
			null,
			true,
			new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings }
		);
		Integration_Service.ServiceResponse response = calloutExecution.invoke();
		System.assertEquals('500', response.serviceCode);
		System.assertEquals(
			System.Label.Auth_Error_Title + ' ' + 'Missing required parameters' + ' ' + 'Integration_Handler.Integration_Auth_Exception',
			response.serviceResponse
		);
		System.assertEquals(null, response.serviceHeaders);
		System.assertEquals('Missing required parameters', response.serviceMessage);
		System.assertEquals(1, calloutExecution.loggerList.size());
		System.assert(response.logger == null);
		System.assertEquals('testAuth.com', calloutExecution.loggerList[0].serviceLog.F3_Endpoint__c);
		System.assertEquals('TestAuth400', calloutExecution.loggerList[0].serviceLog.F3_IntegrationName__c);
		System.assertEquals(null, calloutExecution.loggerList[0].serviceLog.F3_Request__c);
		System.assertEquals('400', calloutExecution.loggerList[0].serviceLog.F3_responseCode__c);
		System.assertEquals('Missing required parameters', calloutExecution.loggerList[0].serviceLog.F3_Response__c);
	}

	@IsTest
	public static void testFullCalloutServiceDataError() {
		//No service metadata
		Integration_Handler calloutExecution = new Integration_Handler('TestService', null, null, null, true, null);
		try {
			Integration_Service.ServiceResponse response = calloutExecution.invoke();
		} catch (Exception e) {
			System.assertEquals(0, calloutExecution.loggerList.size());
			System.assertEquals('Integration_Handler.Integration_Service_Exception', e.getTypeName());
		}

		//No service settings
		F3_Integration_Service__mdt testMetadata = createMetadata();
		calloutExecution = new Integration_Handler(
			'TestService',
			null,
			null,
			null,
			true,
			new Map<String, Object>{ 'serviceMetadata' => testMetadata }
		);
		try {
			Integration_Service.ServiceResponse response = calloutExecution.invoke();
		} catch (Exception e) {
			System.assertEquals(0, calloutExecution.loggerList.size());
			System.assertEquals('Integration_Handler.Integration_Service_Exception', e.getTypeName());
			System.assert(e.getMessage() == System.Label.Custom_Setting_is_Blank);
		}
	}

	@IsTest
	public static void testFullCalloutRestException() {
		F3_Integration_Service__mdt testMetadata = createMetadata();
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest'
		);
		testMetadata = createMetadata();
		testMetadata.F3_Mock_Status_Code__c = 500;
		testMetadata.F3_Mock_Response__c = 'Read Timeout';
		Integration_Handler calloutExecution = new Integration_Handler(
			'TestService',
			null,
			new Map<String, Object>{ 'change' => 'changed', 'Query.change' => 'error' },
			new Map<String, Object>{ 'change' => 'changed', 'Body.change' => 'error' },
			false,
			new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings }
		);
		Integration_Service.ServiceResponse response = calloutExecution.invoke();
		//verify service response
		System.assertEquals('500', response.serviceCode);
		System.assertEquals('Read Timeout', response.serviceMessage);
		System.assertEquals(null, response.serviceHeaders);
		System.assertEquals('Read Timeout System.CalloutException', response.serviceResponse);
		System.assertEquals(2, calloutExecution.loggerList.size());

		//verify auth log
		System.assertEquals('testAuth.com', calloutExecution.loggerList[0].serviceLog.F3_Endpoint__c);
		System.assertEquals('TestAuth', calloutExecution.loggerList[0].serviceLog.F3_IntegrationName__c);
		System.assertEquals(null, calloutExecution.loggerList[0].serviceLog.F3_Request__c);
		System.assertEquals('200', calloutExecution.loggerList[0].serviceLog.F3_responseCode__c);
		System.assertEquals('{"accessToken":"nNX51usqdS3CIjA1efGseilTSjZA"}', calloutExecution.loggerList[0].serviceLog.F3_Response__c);

		//verify service log
		System.assertEquals('testService.com', calloutExecution.loggerList[1].serviceLog.F3_Endpoint__c);
		System.assertEquals('TestService', calloutExecution.loggerList[1].serviceLog.F3_IntegrationName__c);
		System.assertEquals('{"parameter":"changed","delete":""}', calloutExecution.loggerList[1].serviceLog.F3_Request__c);
		System.assertEquals('500', calloutExecution.loggerList[1].serviceLog.F3_responseCode__c);
		System.assertEquals('Read Timeout', calloutExecution.loggerList[1].serviceLog.F3_Response__c);
		System.assert(response.logger != null);
		System.assertEquals(response.logger, calloutExecution.loggerList[1]);
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