/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 29-01-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
@isTest
public class BIT_SendStatements_Payload_Test {
	@IsTest
	static void testGetRequest() {
		Map<String, Object> mapParameters = new Map<String, Object>();
		mapParameters.put('contractNumber', 'ctNum');
		mapParameters.put('password', 'pwd');
		Test.startTest();
		BIT_SendStatements_Request testGet = BIT_SendStatements_Payload.getRequest(mapParameters);
		Assert.isNotNull(testGet);
		Test.stopTest();
	}
}