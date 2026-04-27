/** -------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     Integration_Handler
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 01/01/2023
 *   ------------------------------------------------------------------------------------------------
 * @Description Integration engine handler
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 01/01/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public with sharing class Integration_Handler {
	/** ------------------------------------------------------------------------------------------------
	 * @Description: F3_Integration_Service__mdt store the service metadata
	 * ------------------------------------------------------------------------------------------------**/
	private F3_Integration_Service__mdt serviceMetadata;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: F3_Integration_Service_Settings__c store the service settings
	 * ------------------------------------------------------------------------------------------------**/
	private F3_Integration_Service_Settings__c serviceSettings;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Store the name of the service
	 * ------------------------------------------------------------------------------------------------**/
	private String serviceName;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: request body If jsonTemplate is not going to be used
	 * ------------------------------------------------------------------------------------------------**/
	private String requestBody;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: query string data to replace the Query String Input Template parameters
	 * ------------------------------------------------------------------------------------------------**/
	private Map<String, Object> queryStringData;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: json template data to replace the JSON Input Template parameters
	 * ------------------------------------------------------------------------------------------------**/
	private Map<String, Object> bodyTemplateData;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Boolean to control if response is going to be parsed or not
	 * ------------------------------------------------------------------------------------------------**/
	private Boolean wantRawBody;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: List<Integration_Logger_Service> stores the logger instances created in the execution
	 * ------------------------------------------------------------------------------------------------**/
	public List<Integration_Logger_Service> loggerList = new List<Integration_Logger_Service>();

	/** -----------------------------------------------------------------------------
	 * @Description Integration_Handler constructor
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param	 String serviceName,
	 * @param	 String requestBody,
	 * @param	 Map<String, Object> queryStringData,
	 * @param	 Map<String, Object> bodyTemplateData,
	 * @param	 Boolean wantRawBody
	 * @return   void
	 * @example  Integration_Handler calloutExecution = new Integration_Handler();
	 **/
	public Integration_Handler(
		String serviceName,
		String requestBody,
		Map<String, Object> queryStringData,
		Map<String, Object> bodyTemplateData,
		Boolean wantRawBody,
		Map<String, Object> testSettings
	) {
		this.serviceName = serviceName;
		this.requestBody = requestBody;
		this.queryStringData = queryStringData;
		this.bodyTemplateData = bodyTemplateData;
		this.wantRawBody = wantRawBody;
		if (Test.isRunningTest() && testSettings != null) {
			this.serviceSettings = (F3_Integration_Service_Settings__c) testSettings.get('serviceSettings');
			this.serviceMetadata = (F3_Integration_Service__mdt) testSettings.get('serviceMetadata');
		}
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description orquestrate the lifecycle of the callout and check if the logger is enabled and log the request
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @return   Integration_Service.ServiceResponse
	 * @example  invoke();
	 * ------------------------------------------------------------------------------------------------**/
	public Integration_Service.ServiceResponse invoke() {
		Integration_Service.ServiceResponse serviceResponse = new Integration_Service.ServiceResponse();
		Integration_Logger_Service logger;
		String loggerResponse;
		HttpRequest request;
		try {
			serviceMetadata = getIntegrationMetadata(serviceName);
			serviceSettings = serviceSettings != null ? serviceSettings : F3_Integration_Service_Settings__c.getValues(serviceMetadata.F3_Service_Setting__c);
			if (serviceMetadata == null || serviceSettings == null) {
				String errorMessage = serviceMetadata == null ? System.Label.Metadata_is_Blank : System.Label.Custom_Setting_is_Blank;
				throw new Integration_Service_Exception(errorMessage);
			}
			request = constructRequest();
			System.debug('####request: '+ request);
			HttpResponse response = getServiceResponse(request);
			loggerResponse = response.getBody();
			System.debug('####loggerResponse: '+ JSON.serializePretty(response.getBody()));
			serviceResponse.serviceCode = String.valueOf(response.getStatusCode());
			serviceResponse.serviceMessage = setServiceMessage(response.getStatusCode());
			serviceResponse.ServiceResponse = setServiceResponse(loggerResponse, response.getStatusCode());
			serviceResponse.serviceHeaders = getResponseHeadersAsMap(response);
		} catch (CalloutException calloutError) {
			loggerResponse = calloutError.getMessage();
			serviceResponse.serviceCode = '500';
			serviceResponse.serviceMessage = loggerResponse;
			serviceResponse.ServiceResponse = loggerResponse + ' ' + calloutError.getTypeName();
		} catch (Integration_Auth_Exception authError) {
			request = null;
			serviceResponse.serviceCode = '500';
			serviceResponse.serviceMessage = authError.getMessage();
			serviceResponse.ServiceResponse = System.Label.Auth_Error_Title + ' ' + authError.getMessage() + ' ' + authError.getTypeName();
		} catch (Exception error) {
			throw new Integration_Service_Exception(error.getMessage());
		} finally {
			if (serviceSettings != null && serviceSettings.F3_Enable_Log__c && request != null) {
				Type logService = Type.forName('Integration_Logger_Service');
				logger = (Integration_Logger_Service) logService.newInstance();
				logger.addRequest(
					request.getBody(),
					request.getEndpoint(),
					serviceName,
					serviceMetadata.F3_Headers__c,
					request.getMethod(),
					serviceSettings.F3_Service_Type__c
				);
				logger.addResponse(serviceResponse.serviceCode, loggerResponse, JSON.serialize(serviceResponse.serviceHeaders));
				serviceResponse.logger = logger;
				loggerList.add(logger);
			}
		}
		return serviceResponse;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Checks if mock is enabled, if true: return mock, if false: makes the call and return response
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param	 HttpRequest request
	 * @return	 HttpResponse
	 * @example	 getServiceResponse(request);
	 * ------------------------------------------------------------------------------------------------**/
	private HttpResponse getServiceResponse(HttpRequest request) {
		HttpResponse response;
		if (serviceMetadata.F3_Retrive_Mock__c || Test.isRunningTest()) {
			if (serviceMetadata.F3_Mock_Status_Code__c == 500) {
				CalloutException calloutError = new CalloutException();
				calloutError.setMessage(serviceMetadata.F3_Mock_Response__c);
				throw calloutError;
			}
			response = mockCall();
		} else {
			Http http = new Http();
			response = http.send(request);
		}
		return response;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Gets the metadata of the required service
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param 	  	 String serviceName
	 * @return F3_Integration_Service__mdt
	 * @example F3_Integration_Service__mdt authServiceMetadata = getIntegrationMetadata(serviceMetadata.F3_Authorization_Service__c);
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private F3_Integration_Service__mdt getIntegrationMetadata(String serviceName) {
		F3_Integration_Service__mdt selectedMetadata;
		List<F3_Integration_Service__mdt> retrievedMetadata = [
			SELECT
				F3_Mock_Response__c,
				F3_Retrive_Mock__c,
				F3_Mock_Status_Code__c,
				F3_Query_String_Input_Template__c,
				F3_Named_Credential__c,
				F3_Service_Setting__c,
				F3_Headers__c,
				F3_HTTP_Method__c,
				F3_JSON_Input_Template__c,
				F3_Authorization_Service__c,
				F3_Authorization_Class__c,
				DeveloperName
			FROM F3_Integration_Service__mdt
			WHERE DeveloperName = :serviceName
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
		selectedMetadata = serviceMetadata != null ? serviceMetadata : !retrievedMetadata.isEmpty() ? retrievedMetadata[0] : null;
		return selectedMetadata;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Construction of the request
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @return	 HttpRequest
	 * @example	 constructRequest()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private HttpRequest constructRequest() {
		Map<String, Object> headersMap = constructRequestHeaders();
		HttpRequest request = new HttpRequest();
		request.setEndpoint(constructEndpoint(constructQueryString(queryStringData)));
		system.debug('####setEndpoint: ' + constructEndpoint(constructQueryString(queryStringData)));
		request.setMethod(serviceMetadata.F3_HTTP_Method__c);
		if ((headersMap != null && !headersMap.isEmpty())) {
			for (String headers : headersMap.keySet()) {
				request.setHeader(headers, headersMap.get(headers).toString());
			}
		}
		if (String.isNotBlank(requestBody)) {
			request.setBody(requestBody);
		} else if (
			String.isNotBlank(serviceMetadata.F3_JSON_Input_Template__c) && (bodyTemplateData != null && !bodyTemplateData.isEmpty())
		) {
			request.setBody(constructBodyByTemplate(bodyTemplateData));
		}
		return request;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Deserialize request headers to map
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @return	 Map<String, Object>
	 * @example	 constructRequestHeaders()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private Map<String, Object> constructRequestHeaders() {
		Map<String, Object> headersMap = String.isNotBlank(serviceMetadata.F3_Headers__c)
			? (Map<String, Object>) JSON.deserializeUntyped(serviceMetadata.F3_Headers__c)
			: new Map<String, Object>();
		if (serviceMetadata.F3_Authorization_Service__c != null) {
			Map<String, Object> authHeaders = getAuthHeaders();
			headersMap.putAll(authHeaders);
		}
		return headersMap;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Get auth headers for the request
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @return	 Map<String, Object>
	 * @example	 getAuthHeaders()
	 * ------------------------------------------------------------------------------------------------**/
	private Map<String, Object> getAuthHeaders() {
		Map<String, Object> testSettings;
		if (Test.isRunningTest()) {
			F3_Integration_Service_Settings__c authTestSettings = new F3_Integration_Service_Settings__c(
				F3_URL__c = 'testAuth.com',
				F3_Enable_Log__c = true,
				F3_Service_Type__c = 'ApexRest'
			);
			F3_Integration_Service__mdt authTestMetadata = new F3_Integration_Service__mdt();
			authTestMetadata.F3_Mock_Response__c = serviceMetadata.F3_Authorization_Service__c.contains('400')
				? 'Missing required parameters'
				: '{"accessToken":"nNX51usqdS3CIjA1efGseilTSjZA"}';
			authTestMetadata.F3_Retrive_Mock__c = true;
			authTestMetadata.F3_Mock_Status_Code__c = serviceMetadata.F3_Authorization_Service__c.contains('400') ? 400 : 200;
			authTestMetadata.F3_HTTP_Method__c = 'GET';
			authTestMetadata.DeveloperName = serviceMetadata.F3_Authorization_Service__c;
			testSettings = new Map<String, Object>{ 'serviceMetadata' => authTestMetadata, 'serviceSettings' => authTestSettings };
		}
		Integration_Handler authExecution = new Integration_Handler(
			serviceMetadata.F3_Authorization_Service__c,
			null,
			null,
			null,
			true,
			testSettings
		);
		Integration_Service.ServiceResponse authCallout = authExecution.invoke();
		if (authCallout.logger != null) {
			loggerList.addAll(authExecution.loggerList);
		}
		if (!authCallout.serviceCode.startsWith('2')) {
			throw new Integration_Auth_Exception(String.valueOf(authCallout.serviceResponse));
		}
		Type authClassName = Type.forName(serviceMetadata.F3_Authorization_Class__c);
		Integration_Auth_Interface authClass = (Integration_Auth_Interface) authClassName.newInstance();
		Map<String, Object> authHeaders = authClass.accessToken(String.valueOf(authCallout.serviceResponse));
		System.debug('#authHeaders: '+authHeaders);
		return authHeaders;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Construction of the body of the request
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param	 Map<String, Object> bodyTemplateData
	 * @return	 String
	 * @example	 constructBodyByTemplate(bodyTemplateData)
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private String constructBodyByTemplate(Map<String, Object> bodyTemplateData) {
		String builtBody = serviceMetadata.F3_JSON_Input_Template__c;
        List<String> accountFieldsList = Label.crearContratoPatrimonialAccountFields.split(',');
        System.debug('builtData: ' + builtBody);
		if (String.isNotBlank(builtBody) && (bodyTemplateData != null && !bodyTemplateData.isEmpty())) {
			for (String parameter : bodyTemplateData.keySet()) {
				if (builtBody.containsIgnoreCase('#' + parameter + '#')) {
					builtBody = builtBody.replace('#' + parameter + '#', String.valueOf(bodyTemplateData.get(parameter)));
				}
                //Nuevo , para obtener dinamicamente los valores de Account si es integracion desde oportunity
                 if (parameter.equalsIgnoreCase('Account') && serviceName == 'crearClienteContrato_Patrimonial') {
    				Account acc = (Account) bodyTemplateData.get(parameter);
    				if (acc != null) {
        				Map<String, Object> accountFields = new Map<String, Object>();
        				for (String fieldName : accountFieldsList) {
	            			Object fieldValue = acc.get(fieldName.trim());
            				accountFields.put('Account.' + fieldName.trim(), fieldValue);
        				}
        				for (String fieldKey : accountFields.keySet()) {
    						if (builtBody.containsIgnoreCase('#' + fieldKey + '#')) {
        						Object fieldValue = accountFields.get(fieldKey);
        						if (fieldValue != null) {
                                    fieldValue = fieldKey == 'Account.Nationality__c' ? Integration_Utils.obtenerValorApi('Lead','F3_Nacionalidad__c',String.valueOf(fieldValue)) : fieldValue;
            						fieldValue = fieldKey == 'Account.Person_Type__c' ? Integration_Utils.obtenerValorApi('Lead','Tipo_de_Persona__c',String.valueOf(fieldValue)) : fieldValue;
            						fieldValue = fieldKey == 'Account.Birth_City__c' ? Integration_Utils.obtenerValorApi('Lead','Estado_Nacimiento__c',String.valueOf(fieldValue)) : fieldValue;
            						builtBody = builtBody.replace('#' + fieldKey + '#', String.valueOf(fieldValue));
        						}
    						}
						}
	    			}
				}
			}
		}
		builtBody = String.isNotBlank(builtBody) ? builtBody.replaceAll('#.+?#', '') : builtBody;
		return builtBody;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Deserialize response to a collection
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param	 String responseBody
	 * @param	 String collectionType
	 * @return	 Object
	 * @example	 getResponseAsCollection(responseBody, 'Map')
	 * ------------------------------------------------------------------------------------------------**/
	private Object getResponseAsCollection(String responseBody, String collectionType) {
		Object collection;
		if (collectionType == 'Map') {
			collection = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		} else if (collectionType == 'List') {
			collection = (List<Object>) JSON.deserializeUntyped(responseBody);
		}
		return collection;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Deserialize response headers to a map
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param	 HttpResponse response
	 * @return	 Map<String, String>
	 * @example	 getResponseHeadersAsMap(response);
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private Map<String, String> getResponseHeadersAsMap(HttpResponse response) {
		Map<String, String> headersMap = new Map<String, String>();
		for (String headKey : response.getHeaderKeys()) {
			headersMap.put(headKey, String.valueOf(response.getHeader(headKey)));
		}
		return headersMap;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description	Construction of query string
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param	 Map<String, Object> queryStringData
	 * @return	 String
	 * @example	 constructQueryString(queryStringData)
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private String constructQueryString(Map<String, Object> queryStringData) {
		String queryString = serviceMetadata.F3_Query_String_Input_Template__c;
		if (String.isNotBlank(queryString) && (queryStringData != null && !queryStringData.isEmpty())) {
			for (String parameter : queryStringData.keySet()) {
				if (queryString.containsIgnoreCase('#' + parameter + '#')) {
					queryString = queryString.replace('#' + parameter + '#', String.valueOf(queryStringData.get(parameter)));
				}
			}
		}
		queryString = String.isNotBlank(queryString) ? queryString.replaceAll('#.+?#', '') : queryString;
		return queryString;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Construction of the endpoint
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param	 String queryString
	 * @return	 String
	 * @example	 constructEndpoint(queryString)
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private String constructEndpoint(String queryString) {
		String endpoint = String.isBlank(serviceMetadata.F3_Named_Credential__c)
			? serviceSettings != null ? queryString != null ? serviceSettings.F3_URL__c + queryString : serviceSettings.F3_URL__c : null
			: queryString != null
					? 'callout:' + serviceMetadata.F3_Named_Credential__c + queryString
					: 'callout:' + serviceMetadata.F3_Named_Credential__c;
		if (String.isBlank(endpoint)) {
			throw new Integration_Service_Exception(System.Label.Endpoint_is_Blank);
		}
		return endpoint;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Set a generic message to display
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param	 Integer statusCode
	 * @return	 String
	 * @example	 setServiceMessage(statusCode)
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private String setServiceMessage(Integer statusCode) {
		String serviceMessage;
		if (String.valueOf(statusCode).startsWithIgnoreCase('2')) {
			serviceMessage = System.Label.Success_200;
		} else if (statusCode == 400) {
			serviceMessage = System.Label.Error_400;
		} else if (statusCode == 404) {
			serviceMessage = System.Label.Error_404;
		} else if (statusCode == 500) {
			serviceMessage = System.Label.Error_500;
		} else {
			serviceMessage = System.Label.Error_Generic;
		}
		return serviceMessage;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Set the response to return
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param	 String responseBody
	 * @param	 Integer statusCode
	 * @return	 Object
	 * @example	 setServiceResponse(responseBody, statusCode)
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private Object setServiceResponse(String responseBody, Integer statusCode) {
		Object serviceResponse;
		if (statusCode != 204 && String.isNotBlank(responseBody)) {
			try {
				if (wantRawBody) {
					serviceResponse = responseBody;
				} else {
					serviceResponse = getResponseAsCollection(responseBody, 'Map');
				}
			} catch (Exception error) {
				if (error.getMessage().contains('List<')) {
					serviceResponse = getResponseAsCollection(responseBody, 'List');
				} else {
					serviceResponse = responseBody;
				}
			}
		}
		return serviceResponse;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Create a mock response
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @return	 HttpResponse
	 * @example	 mockCall()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private HttpResponse mockCall() {
		HttpResponse response = new HttpResponse();
		if (String.isNotBlank(serviceMetadata.F3_Mock_Response__c)) {
			response.setBody(serviceMetadata.F3_Mock_Response__c);
		}
		if (String.isNotBlank(String.valueOf(serviceMetadata.F3_Mock_Status_Code__c))) {
			response.setStatusCode(integer.valueOf(serviceMetadata.F3_Mock_Status_Code__c));
		}
		return response;
	}

	/** -------------------------------------------------------------------------------------------------
	 *   ------------------------------------------------------------------------------------------------
	 * @Name     Integration_Service_Exception
	 * @Author   luis.felipe.ortiz@pwc.com
	 * @Date     Created: 01/01/2023
	 *   ------------------------------------------------------------------------------------------------
	 * @Description Integration engine exception class
	 *   ------------------------------------------------------------------------------------------------
	 * @Changes
	 * 01/01/2023 luis.felipe.ortiz@pwc.com
	 *             Class creation.
	 *   ------------------------------------------------------------------------------------------------
	 **/
	public class Integration_Service_Exception extends Exception {
	}

	/** -------------------------------------------------------------------------------------------------
	 *   ------------------------------------------------------------------------------------------------
	 * @Name     Integration_Auth_Exception
	 * @Author   luis.felipe.ortiz@pwc.com
	 * @Date     Created: 01/01/2023
	 *   ------------------------------------------------------------------------------------------------
	 * @Description Auth exception class
	 *   ------------------------------------------------------------------------------------------------
	 * @Changes
	 * 01/01/2023 luis.felipe.ortiz@pwc.com
	 *             Class creation.
	 *   ------------------------------------------------------------------------------------------------
	 **/
	private class Integration_Auth_Exception extends Exception {
	}
}