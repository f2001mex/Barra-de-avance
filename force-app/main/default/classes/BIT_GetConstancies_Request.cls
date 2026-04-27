/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 10-12-2024
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
public with sharing class BIT_GetConstancies_Request implements RequestBody_cls {
	public String contractNumber;
	public String serializeRequestBody(RequestBody_CLS requestBody) {
		return JSON.serialize((BIT_GetConstancies_Request) requestBody, true);
	}
}