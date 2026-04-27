/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 29-01-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
@isTest
public class BIT_GetStatements_Response_Test {
	@IsTest
	static void testDeserialize() {
		BIT_GetStatements_Response testResponse = new BIT_GetStatements_Response();
		String jsonBody = '{"status": 200, "payload": {"date": [{"year": 2024, "yearExercise": 2023, "type": "tpTest"}]}, "messages": ["msg"]}';
		Test.startTest();
		testResponse.deserializeResponseBody(jsonBody);
		Test.stopTest();
	}
}