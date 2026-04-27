/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 28-01-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
@isTest
public class BIT_GetTokenCF_Request_Test {
	@IsTest
	static void testSerialize() {
		Map<String, Object> mapParameters = new Map<String, Object>();
		mapParameters.put('userId', 'usr');
		mapParameters.put('password', 'pwd');
		BIT_GetTokenCF_Request request = BIT_GetTokenCF_Payload.getRequest(mapParameters);
		BIT_GetTokenCF_Request testRequest = new BIT_GetTokenCF_Request();
		Test.startTest();
		String testSerialize = testRequest.serializeRequestBody(request);
		Assert.isNotNull(testSerialize);
		Test.stopTest();
	}
}