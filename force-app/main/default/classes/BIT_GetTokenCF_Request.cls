/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 06-12-2024
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
public with sharing class BIT_GetTokenCF_Request implements RequestBody_cls {
	public String userId;
	public String password;
	public String serializeRequestBody(RequestBody_CLS requestBody) {
		return JSON.serialize((BIT_GetTokenCF_Request) requestBody, true);
	}
}