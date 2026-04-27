/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 29-01-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
@isTest
public class BIT_SendConstancie_Response_Test {
	@IsTest
	static void testDeserialize() {
		BIT_SendConstancie_Response testResponse = new BIT_SendConstancie_Response();
		String jsonBody = '{"status": 200, "payload": {"operationReference": "opRef","operationDateTime": "opDt"},"messages": ["Success"]}';
		Test.startTest();
		testResponse.deserializeResponseBody(jsonBody);
		Test.stopTest();
	}
}