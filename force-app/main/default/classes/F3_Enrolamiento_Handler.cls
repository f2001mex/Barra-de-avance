/**
 *   ------------------------------------------------------------------------------------------------
 * Name     F3_Enrolamiento_Handler
 * Author   omar.espinosa@pwc.com
 * Date     Created: 24/08/2022
 * Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * Description Handler class for the F3_Enrolamiento_Handler class
 *   ------------------------------------------------------------------------------------------------
 * Changes
 * 24/08/2022 omar.espinosa@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public with sharing class F3_Enrolamiento_Handler {
	/** ------------------------------------------------------------------------------------------------
	 * Description Deserialize the received JSON and upsert the Accounts received
	 *   ------------------------------------------------------------------------------------------------
	 * author   omar.espinosa@pwc.com
	 * date     24/08/2022
	 * param    String clientsJson : JSON with the account data
	 * return   Map<String, Map<String, Map<String,String>>>
	 * example  F3_Enrolamiento_Handler.processData(RestContext.request.requestBody.toString())
	 * ------------------------------------------------------------------------------------------------**/
	static public Map<String, Map<String, Map<String, String>>> processData(string clientsJson) {
		Schema.SObjectField accExternalField = Account.Client_ID__c.getDescribe().getSObjectField();

		Map<String, Map<String, Map<String, String>>> upsertResults = new Map<String, Map<String, Map<String, String>>>();
		Map<String, List<SObject>> sObjectMap = F3_JsonToSobject_Service.jsonToSobject(clientsJson, 'crearActualizarEnrolamientoSF');
		List<Account> clientList = sObjectMap.get('Account');

		Map<String, Map<String, String>> upsertedAccounts = (Map<String, Map<String, String>>) F3_Database_Utility.upsertRecords(
			sObjectMap.get('Account'),
			accExternalField,
			false,
			true
		);
		return upsertResults = new Map<String, Map<String, Map<String, String>>>{ 'Account' => upsertedAccounts };
	}
}