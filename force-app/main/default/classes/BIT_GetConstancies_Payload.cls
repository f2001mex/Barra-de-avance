/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 10-12-2024
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
public with sharing class BIT_GetConstancies_Payload {
	public static BIT_GetConstancies_Request getRequest(Map<String, Object> mapParameters) {
		BIT_GetConstancies_Request clsRequest = new BIT_GetConstancies_Request();
		clsRequest.contractNumber = (String) mapParameters.get('contractNumber');
		return clsRequest;
	}
}