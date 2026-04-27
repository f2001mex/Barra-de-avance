/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_SendDataToSAP_Helper
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 19/10/2022
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Helper class for the F3_SendDataToSAP_Controller class
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 19/10/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public with sharing class F3_SendDataToSAP_Helper {
	public static String updateOpps(List<String> returnedOpps) {
		try {
			String updatedOppsInfo;
			List<Opportunity> oppsToUpdate = new List<Opportunity>();
			for (String jsonObj : returnedOpps) {
				oppsToUpdate.add(new Opportunity(id = jsonObj, F3_isCreatedInSAP__c = true));
			}
			Database.upsert(oppsToUpdate);
			return updatedOppsInfo;
		} catch (Exception e) {
			throw new F3_RestServices_Exception(e.getMessage());
		}
	}
}