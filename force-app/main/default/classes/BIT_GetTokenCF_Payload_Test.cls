/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 28-01-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
@isTest
public class BIT_GetTokenCF_Payload_Test {
	@IsTest
	static void testGetRequest() {
		Map<String, Object> mapParameters = new Map<String, Object>();
		mapParameters.put('userId', 'usr');
		mapParameters.put('password', 'pwd');
		Test.startTest();
		BIT_GetTokenCF_Request testGet = BIT_GetTokenCF_Payload.getRequest(mapParameters);
		Assert.isNotNull(testGet);
		Test.stopTest();
	}
}