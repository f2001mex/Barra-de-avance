/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 13-12-2024
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
public with sharing class BIT_GetStatements_Payload {
	public static BIT_GestStatements_Request getRequest(Map<String, Object> mapParameters) {
		BIT_GestStatements_Request clsRequest = new BIT_GestStatements_Request();
		clsRequest.contractNumber = (String) mapParameters.get('contractNumber');
		return clsRequest;
	}
}