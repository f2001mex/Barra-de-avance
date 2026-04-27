/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 28-01-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
@isTest
public class BIT_GetOTP_Request_Test {
	@IsTest
	static void testSerialize() {
		Map<String, Object> mapParameters = new Map<String, Object>();
		mapParameters.put('clientNumber', 1234);
		mapParameters.put('lastDigitsPhoneNumber', '9876');
		mapParameters.put('mailNotificationFlag', 'true');
		BIT_GetOTP_Request request = BIT_GetOTP_Payload.getRequest(mapParameters);
		BIT_GetOTP_Request testRequest = new BIT_GetOTP_Request();
		Test.startTest();
		String testSerialize = testRequest.serializeRequestBody(request);
		Assert.isNotNull(testSerialize);
		Test.stopTest();
	}
}