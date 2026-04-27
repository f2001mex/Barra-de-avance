@RestResource(urlMapping='/leadconsult/*')
global with sharing class ACT_LeadAPI {
	@HttpGet
	global static Integer getLeadCountByOwner() {
		RestRequest req = RestContext.request;
		RestResponse res = RestContext.response;
		String LeadId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);

		List<Lead_Web_Service_Setting__mdt> customMetadataRecords = [SELECT Status__c FROM Lead_Web_Service_Setting__mdt];

		Set<String> validStatusValues = new Set<String>();
		for (Lead_Web_Service_Setting__mdt record : customMetadataRecords) {
			validStatusValues.add(record.Status__c);
		}

		List<AggregateResult> aggregateResults = [
			SELECT COUNT(Id) Total
			FROM Lead
			    WHERE OwnerId IN (SELECT Id FROM User WHERE ID_ASESOR__c = :LeadId) AND Status IN :validStatusValues
		];

		if (!aggregateResults.isEmpty()) {
			return (Integer) aggregateResults[0].get('Total');
		} else {
			return 0;
		}
	}
}