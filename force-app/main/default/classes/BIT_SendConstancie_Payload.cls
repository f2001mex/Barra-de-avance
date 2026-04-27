/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 02-01-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
public with sharing class BIT_SendConstancie_Payload {
	public static BIT_SendConstancie_Request getRequest(Map<String, Object> mapParameters) {
		BIT_SendConstancie_Request clsRequest = new BIT_SendConstancie_Request();
		BIT_SendConstancie_Request.Period objPeriod = new BIT_SendConstancie_Request.Period();
		clsRequest.contractNumber = String.valueOf(mapParameters.get('contractNumber')) ;
		clsRequest.password = String.valueOf(mapParameters.get('password'));
		objPeriod.year = String.valueOf(mapParameters.get('period'));
		clsRequest.period = objPeriod;
		return clsRequest;
	}
}