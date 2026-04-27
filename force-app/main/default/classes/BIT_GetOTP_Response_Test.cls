/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 28-01-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
@isTest
public class BIT_GetOTP_Response_Test {
	@IsTest
	static void testDeserialize() {
		BIT_GetOTP_Response testResponse = new BIT_GetOTP_Response();
		String jsonBody = '{"status": 200, "payload": {"id":12, "message": "test"}, "messages": ["testMsg"]}';
		Test.startTest();
		testResponse.deserializeResponseBody(jsonBody);
		Test.stopTest();
	}
}