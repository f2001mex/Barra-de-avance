/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 17-12-2024
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
public with sharing class BIT_SendStatements_Request implements RequestBody_cls {
	public String contractNumber;
	public String password;
	public List<Period> periods;
	public class Period {
		public String period;
	}
	public String serializeRequestBody(RequestBody_CLS requestBody) {
		return JSON.serialize((BIT_SendStatements_Request) requestBody, true);
	}
}