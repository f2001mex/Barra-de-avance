/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 06-12-2024
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
public with sharing class BIT_GetTokenCF_Payload {
	public static BIT_GetTokenCF_Request getRequest(Map<String, Object> mapParameters) {
		BIT_GetTokenCF_Request clsRequest = new BIT_GetTokenCF_Request();
		clsRequest.userId = (String) mapParameters.get('userId');
		clsRequest.password = (String) mapParameters.get('password');
		return clsRequest;
	}
}