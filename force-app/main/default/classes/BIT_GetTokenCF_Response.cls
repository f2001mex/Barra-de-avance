/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 28-01-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
public with sharing class BIT_GetTokenCF_Response implements ResponseBody_cls {
	Public String accessToken;
	Public String clientId;
	Public String tokenType;
	Public String issuedAt;
	Public String expiresIn;
	Public String status;
	Public String scopes;
	public ResponseBody_CLS deserializeResponseBody(String jsonBody) {
		return (BIT_GetTokenCF_Response) JSON.deserialize(jsonBody, BIT_GetTokenCF_Response.class);
	}
}