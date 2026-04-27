/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 28-01-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
@isTest
public class BIT_GetConstancies_Request_Test {
	@IsTest
	static void testSerialize() {
		Map<String, Object> mapParameters = new Map<String, Object>();
		mapParameters.put('contractNumber', 'ctNum');
		BIT_GetConstancies_Request request = BIT_GetConstancies_Payload.getRequest(mapParameters);
		BIT_GetConstancies_Request testRequest = new BIT_GetConstancies_Request();
		Test.startTest();
		String testSerialize = testRequest.serializeRequestBody(request);
		Assert.isNotNull(testSerialize);
		Test.stopTest();
	}
}