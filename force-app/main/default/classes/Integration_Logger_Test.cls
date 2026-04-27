@isTest(IsParallel=true)
public with sharing class Integration_Logger_Test {
	@isTest(SeeAllData=false)
	static void createInstance() {
		String logRecordTypeId = Schema.SObjectType.Log__c.getRecordTypeInfosByDeveloperName()
			.get(System.Label.Log_Record_Type)
			.getRecordTypeId();
		Integration_Logger_Service logger = new Integration_Logger_Service();
		System.assert(logRecordTypeId != null);
		System.assert(logger.serviceLog != null);
		System.assertEquals(logRecordTypeId, logger.serviceLog.RecordTypeId);
		System.assertEquals(0, logger.logFiles.size());
		verifyRequest(logger);
		System.assertEquals(1, logger.logFiles.size());
		verifyResponse(logger);
		System.assertEquals(2, logger.logFiles.size());
		verifyExtraFields(logger);
		logger.upsertLogger();
		List<Log__c> insertedLogs = [SELECT Id FROM Log__c];
		System.assertEquals(1, insertedLogs.size());
		List<ContentVersion> insertedFiles = [SELECT Id FROM ContentVersion];
		System.assertEquals(2, insertedFiles.size());
		List<ContentDocumentLink> insertedLinks = [
			SELECT Id, LinkedEntityId, ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :insertedLogs[0].Id
		];
		System.assertEquals(2, insertedLinks.size());
		for (ContentDocumentLink link : insertedLinks) {
			System.assert(link.ContentDocumentId != null);
		}
	}

	@isTest(SeeAllData=false)
	static void createAsyncInstance() {
		String logRecordTypeId = Schema.SObjectType.Log__c.getRecordTypeInfosByDeveloperName()
			.get(System.Label.Log_Record_Type)
			.getRecordTypeId();
		Integration_Logger_Service logger = new Integration_Logger_Service();
		System.assert(logRecordTypeId != null);
		System.assert(logger.serviceLog != null);
		System.assertEquals(logRecordTypeId, logger.serviceLog.RecordTypeId);
		System.assertEquals(0, logger.logFiles.size());
		verifyRequest(logger);
		System.assertEquals(1, logger.logFiles.size());
		verifyResponse(logger);
		System.assertEquals(2, logger.logFiles.size());
		verifyExtraFields(logger);
		Test.startTest();
		logger.asyncUpsertLogger();
		Test.stopTest();
		List<Log__c> insertedLogs = [SELECT Id FROM Log__c];
		System.assertEquals(1, insertedLogs.size());
		List<ContentVersion> insertedFiles = [SELECT Id FROM ContentVersion];
		System.assertEquals(0, insertedFiles.size());
		List<ContentDocumentLink> insertedLinks = [
			SELECT Id, LinkedEntityId, ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :insertedLogs[0].Id
		];
		System.assertEquals(0, insertedLinks.size());
	}

	private static void verifyRequest(Integration_Logger_Service logger) {
		String requestBody = '{"x":"1"}';
		String endpoint = 'test.com';
		String integrationName = 'Test Case';
		String headers = '{"Authorization":"Basic 12345"}';
		String method = 'PUT';
		String serviceType = 'External Service';
		logger.addRequest(requestBody, endpoint, integrationName, headers, method, serviceType);
		System.assertEquals(requestBody.left(logger.TEXT_MAX_SIZE), logger.serviceLog.F3_Request__c);
		System.assertEquals(endpoint, logger.serviceLog.F3_Endpoint__c);
		System.assertEquals(integrationName, logger.serviceLog.F3_IntegrationName__c);
		System.assertEquals(headers, logger.serviceLog.F3_RequestHeaders__c);
		System.assertEquals(method, logger.serviceLog.F3_HTTP_Method__c);
		System.assertEquals(serviceType, logger.serviceLog.F3_Service_Type__c);
	}

	private static void verifyResponse(Integration_Logger_Service logger) {
		String responseBody = '{"y":"2"}';
		String responseCode = '200';
		String headers = '{"Success":"true"}';
		logger.addResponse(responseCode, responseBody, headers);
		System.assertEquals(responseBody.left(logger.TEXT_MAX_SIZE), logger.serviceLog.F3_Response__c);
		System.assertEquals(responseCode, logger.serviceLog.F3_responseCode__c);
		System.assertEquals(headers, logger.serviceLog.F3_ResponseHeaders__c);
	}

	private static void verifyExtraFields(Integration_Logger_Service logger) {
		System.assertEquals('{"Success":"true"}', logger.serviceLog.F3_ResponseHeaders__c);
		String responseBody = '{"z":"3"}';
		String headers = '{"Changed":"true"}';
		Map<Schema.SObjectField, Object> extraFields = new Map<Schema.SObjectField, Object>{
			Log__c.F3_Response__c => responseBody,
			Log__c.F3_ResponseHeaders__c => headers
		};
		logger.addExtraFields(extraFields);
		System.assert(responseBody != logger.serviceLog.F3_Response__c);
		System.assertEquals('{"y":"2"}', logger.serviceLog.F3_Response__c);
		System.assertEquals(headers, logger.serviceLog.F3_ResponseHeaders__c);
	}
}