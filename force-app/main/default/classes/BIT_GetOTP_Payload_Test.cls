/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 28-01-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
@isTest
public class BIT_GetOTP_Payload_Test {
	@IsTest
	static void testGetRequest() {
		Map<String, Object> mapParameters = new Map<String, Object>();
		mapParameters.put('clientNumber', 1234);
		mapParameters.put('lastDigitsPhoneNumber', '9876');
		mapParameters.put('mailNotificationFlag', 'true');
		Test.startTest();
		BIT_GetOTP_Request testGet = BIT_GetOTP_Payload.getRequest(mapParameters);
		Assert.isNotNull(testGet);
		Test.stopTest();
	}
}