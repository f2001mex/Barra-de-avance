/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 17-12-2024
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
public with sharing class BIT_SendConstancie_Response implements ResponseBody_cls {
	public Integer status;
	public Payload payload;
	public List<String> messages;
	public class Payload {
		public String operationReference;
		public String operationDateTime;
	}
	public ResponseBody_CLS deserializeResponseBody(String jsonBody) {
		return (BIT_SendConstancie_Response) JSON.deserialize(jsonBody, BIT_SendConstancie_Response.class);
	}
}