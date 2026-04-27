/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 17-12-2024
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
public with sharing class BIT_SendConstancie_Request implements RequestBody_cls {
	public String contractNumber;
	public String password;
	public Period period;
	public class Period {
		public String year;
	}
	public String serializeRequestBody(RequestBody_CLS requestBody) {
		return JSON.serialize((BIT_SendConstancie_Request) requestBody, true);
	}
}