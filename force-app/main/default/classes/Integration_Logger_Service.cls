/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     Integration_Logger_Service
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 01/01/2023
 *   ------------------------------------------------------------------------------------------------
 * @Description Integration Logger engine
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 01/01/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public with sharing class Integration_Logger_Service {
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Log__c Instance
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private Log__c serviceLog;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: List<ContentVersion> that stores the attachments of the serviceLog
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private List<ContentVersion> logFiles = new List<ContentVersion>();
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Final Integer to control the maximum size of Request and Response fields
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private final Integer TEXT_MAX_SIZE = Integer.valueOf(System.Label.Log_Text_Max_Size);

	/** -----------------------------------------------------------------------------
	 * @Description Logger constructor
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @return   void
	 * @example  logger = (Integration_Logger_Service) logService.newInstance();
	 **/
	public Integration_Logger_Service() {
		createLogObject();
	}

	/** -----------------------------------------------------------------------------
	 * @Description add the request to the Log Object. If request size is bigger than TEXT_MAX_SIZE
	 * trims the request to the size and store the full request in a file
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param    String requestBody, String endpoint, String integrationName, String headers, String method, String serviceType
	 * @return   void
	 * @example  logger.addRequest(request.getBody(),request.getEndpoint(),serviceName,serviceMetadata.F3_Headers__c,request.getMethod(),serviceSettings.F3_Service_Type__c);
	 **/
	public void addRequest(String requestBody, String endpoint, String integrationName, String headers, String method, String serviceType) {
		serviceLog.F3_Endpoint__c = endpoint;
		serviceLog.F3_IntegrationName__c = integrationName;
		serviceLog.F3_RequestHeaders__c = headers;
		serviceLog.F3_HTTP_Method__c = method;
		serviceLog.F3_Service_Type__c = serviceType;
		if (String.isNotBlank(requestBody)) {
			Boolean requestRightSize = requestBody.length() <= TEXT_MAX_SIZE;
			serviceLog.F3_Request__c = requestRightSize ? requestBody : requestBody.left(TEXT_MAX_SIZE);
			if (requestRightSize || Test.isRunningTest()) {
				createFile(requestBody, System.Label.Request_File_Title + serviceLog.F3_IntegrationName__c);
			}
		}
	}

	/** -----------------------------------------------------------------------------
	 * @Description add the response to the Log Object. If response size is bigger than TEXT_MAX_SIZE
	 * trims the response to the size and store the full response in a file
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param    String responseCode, String responseBody, String headers
	 * @return   void
	 * @example  logger.addResponse(result.serviceCode, response.getBody(), JSON.serialize(result.serviceHeaders));
	 **/
	public void addResponse(String responseCode, String responseBody, String headers) {
		serviceLog.F3_responseCode__c = responseCode;
		serviceLog.F3_ResponseHeaders__c = headers;
		if (String.isNotBlank(responseBody)) {
			Boolean responseRightSize = responseBody.length() <= TEXT_MAX_SIZE;
			serviceLog.F3_Response__c = responseRightSize ? responseBody : responseBody.left(TEXT_MAX_SIZE);
			if (responseRightSize == false || Test.isRunningTest()) {
				createFile(responseBody, System.Label.Response_File_Title + serviceLog.F3_IntegrationName__c);
			}
		}
	}

	/** -----------------------------------------------------------------------------
	 * @Description if needed, add extra fields to the Log Object
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param    Map<Schema.SObjectField, Object> logMapFields
	 * @return   void
	 * @example  logger.addExtraFields(logMapFields);
	 **/
	public void addExtraFields(Map<Schema.SObjectField, Object> logMapFields) {
		logMapFields.remove(Log__c.F3_Response__c);
		logMapFields.remove(Log__c.F3_Request__c);
		if (logMapFields != null && !logMapFields.isEmpty()) {
			for (Schema.SObjectField field : logMapFields.keySet()) {
				serviceLog.put(field, logMapFields.get(field));
			}
		}
	}

	/** -----------------------------------------------------------------------------
	 * @Description upsert the Log Object and add the attachments
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @return   void
	 * @example  logger.upsertLogger();
	 **/
	public void upsertLogger() {
		upsert serviceLog;
		linkFilesToObject();
	}

	/** -----------------------------------------------------------------------------
	 * @Description call to the async executeAsyncUpsertLog method
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @return   void
	 * @example  logger.asyncUpsertLogger();
	 **/
	public void asyncUpsertLogger() {
		executeAsyncUpsertLog(JSON.serialize(serviceLog));
	}

	/** -----------------------------------------------------------------------------
	 * @Description async upsert of the Log Object. It doesn't create attachments due to future method nature.
	 * If attachment creation may occur, best to use the Synchronous version
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param	 String logToInsert
	 * @return   void
	 * @example  executeAsyncUpsertLog(JSON.serialize(serviceLog));
	 **/
	@future
	private static void executeAsyncUpsertLog(String logToInsert) {
		Log__c serviceLog = (Log__c) JSON.deserialize(logToInsert, Log__c.class);
		upsert serviceLog;
	}

	/** -----------------------------------------------------------------------------
	 * @Description creation of the ContentVersion object
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param	 String body
	 * @param	 String name
	 * @return   void
	 * @example  createFile(requestBody, 'Request_' + serviceLog.F3_IntegrationName__c);
	 **/
	private void createFile(String body, String name) {
		ContentVersion version = new ContentVersion();
		version.versionData = Blob.valueOf(body);
		version.title = name + '_' + String.valueOf(System.now());
		version.pathOnClient = '/' + name + '_' + String.valueOf(System.now()) + '.txt';
		logFiles.add(version);
	}

	/** -----------------------------------------------------------------------------
	 * @Description Create the ContentDocumentLink to relate the files to the object
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @return   void
	 * @example  logger.linkFilesToObject();
	 **/
	private void linkFilesToObject() {
		if (logFiles.size() > 0) {
			List<ContentDocumentLink> fileLinks = new List<ContentDocumentLink>();
			List<Id> filesIds = new List<Id>();
			insert logFiles;
			for (ContentVersion file : logFiles) {
				filesIds.add(file.Id);
			}
			Map<Id, ContentVersion> contentVersionsMap = new Map<ID, ContentVersion>(
				[SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :filesIds]
			);
			for (ContentVersion file : logFiles) {
				ContentDocumentLink docLink = new ContentDocumentLink();
				docLink.ContentDocumentId = contentVersionsMap.get(file.id).ContentDocumentId;
				docLink.ShareType = 'I';
				docLink.LinkedEntityId = serviceLog.Id;
				fileLinks.add(docLink);
			}
			insert fileLinks;
			logFiles.clear();
		}
	}

	/** -----------------------------------------------------------------------------
	 * @Description creation of the Log object
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @return   void
	 * @example  createLogObject();
	 **/
	private void createLogObject() {
		String logRecordTypeId = Schema.SObjectType.Log__c.getRecordTypeInfosByDeveloperName()
			.get(System.Label.Log_Record_Type)
			.getRecordTypeId();
		serviceLog = new Log__c();
		serviceLog.RecordTypeId = logRecordTypeId;
	}
}