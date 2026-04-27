/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 28-01-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
@isTest
public class BIT_GetConstancies_Payload_Test {
	@IsTest
	static void testGetRequest() {
		Map<String, Object> mapParameters = new Map<String, Object>();
		mapParameters.put('contractNumber', 'ctNum');
		Test.startTest();
		BIT_GetConstancies_Request testGet = BIT_GetConstancies_Payload.getRequest(mapParameters);
		Assert.isNotNull(testGet);
		Test.stopTest();
	}
}