/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 31-12-2024
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
public with sharing class BIT_SendStatements_Payload {
	public static BIT_SendStatements_Request getRequest(Map<String, Object> mapParameters) {
		BIT_SendStatements_Request clsRequest = new BIT_SendStatements_Request();
		List<BIT_SendStatements_Request.Period> lstPeriods = new List<BIT_SendStatements_Request.Period>();
		clsRequest.contractNumber = (String) mapParameters.get('contractNumber');
		clsRequest.password = (String) mapParameters.get('password');
		for (String keyParam: mapParameters.keySet()) {
			if (keyParam.contains('period')) {
				BIT_SendStatements_Request.Period objPeriod = new BIT_SendStatements_Request.Period();
				objPeriod.period = String.valueOf(mapParameters.get(keyParam));
				lstPeriods.add(objPeriod);
			}
		}
		clsRequest.periods = lstPeriods;
		return clsRequest;
	}
}