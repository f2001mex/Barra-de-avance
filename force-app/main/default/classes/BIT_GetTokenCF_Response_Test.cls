/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 28-01-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
@isTest
public class BIT_GetTokenCF_Response_Test {
	@IsTest
	static void testDeserialize() {
		BIT_GetTokenCF_Response testResponse = new BIT_GetTokenCF_Response();
		String jsonBody = '{"accessToken": "tkn", "clientId": "cnId", "tokenType": "tknTp", "issuedAt": "issAt", "expiresIn": "expIn", "status": "sts", "scopes": "scs"}';
		Test.startTest();
		testResponse.deserializeResponseBody(jsonBody);
		Test.stopTest();
	}
}