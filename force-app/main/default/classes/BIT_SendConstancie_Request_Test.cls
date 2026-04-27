/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 29-01-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
@isTest
public class BIT_SendConstancie_Request_Test {
	@IsTest
	static void testSerialize() {
		Map<String, Object> mapParameters = new Map<String, Object>();
		mapParameters.put('contractNumber', 'ctNum');
		mapParameters.put('password', 'pwd');
		mapParameters.put('period', 'prd');
		BIT_SendConstancie_Request request = BIT_SendConstancie_Payload.getRequest(mapParameters);
		BIT_SendConstancie_Request testRequest = new BIT_SendConstancie_Request();
		Test.startTest();
		String testSerialize = testRequest.serializeRequestBody(request);
		Assert.isNotNull(testSerialize);
		Test.stopTest();
	}
}