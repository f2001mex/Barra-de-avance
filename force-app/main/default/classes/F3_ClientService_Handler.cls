/**
 *   ------------------------------------------------------------------------------------------------
 * Name     F3_ClientService_Handler
 * Author   luis.felipe.ortiz@pwc.com
 * Date     Created: 12/08/2022
 * Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * Description Handler class for the F3_ClientService_Controller class
 *   ------------------------------------------------------------------------------------------------
 * Changes
 * 12/08/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public with sharing class F3_ClientService_Handler {
	static final Set<String> setLeadExternalId = new Set<String>();
	static final Schema.SObjectField accExternalField = Account.Client_ID__c.getDescribe().getSObjectField();
	static final Map<Integer, Map<String, Object>> insertionOrder = new Map<Integer, Map<String, Object>>{
		0 => new Map<String, Object>{ 'externalField' => accExternalField, 'sObject' => 'Account' }
	};
	/** ------------------------------------------------------------------------------------------------
	 * Description Deserialize the received JSON and upsert the Leads and Accounts received
	 *   ------------------------------------------------------------------------------------------------
	 * author   luis.felipe.ortiz@pwc.com
	 * date     12/08/2022
	 * param    String clientsJson : JSON with the account data
	 * return   Map<String, Map<String, Map<String,String>>>
	 * example  F3_ClientService_Handler.processData(RestContext.request.requestBody.toString())
	 * ------------------------------------------------------------------------------------------------**/
	static public Map<String,Object> processRequest(string clientsJson) {
		Map<String,Object> mapResponse= new Map<String,Object>();
		Map<String, List<SObject>> sObjectMap = F3_JsonToSobject_Service.jsonToSobject(clientsJson, 'crearActualizarCliente');
		if (sObjectMap.isEmpty()) {
			throw new F3_RestServices_Exception('Sin registros validos');
		}

		List<Lead> sourceLeads = leadsToUpdate(sObjectMap.get('Account'));
		Account[] lstAccountsUpdate = new List<Account>();
		Map<String,Account> mapAccountsUpdate = new Map<String,Account>();
		Map<String,Lead> mapConsecutiveByLead = new Map<String,Lead>();
		Set<String> setRecordTypes = new Set<String>();
		for(lead objLead :[SELECT ConvertedAccountId,F3_Consecutivo_ID__c,RecordType.Developername FROM LEAD WHERE F3_Consecutivo_ID__c IN :setLeadExternalId]){
			Account objAccount = new Account();
			objAccount.Id      = objLead.ConvertedAccountId;
			if(String.isNotBlank(objLead.ConvertedAccountId)) mapAccountsUpdate.put(objLead.F3_Consecutivo_ID__c,objAccount);
			if(String.isNotBlank(objLead.ConvertedAccountId)) mapConsecutiveByLead.put(objLead.F3_Consecutivo_ID__c,objLead);
			setRecordTypes.add(objLead.RecordType.Developername);
		}
		mapResponse.put('setRecordTypes',setRecordTypes);
		mapResponse.put('mapAccountsUpdate',mapAccountsUpdate);
		mapResponse.put('mapConsecutiveByLead',mapConsecutiveByLead);
		mapResponse.put('sObjectMap',sObjectMap);

		return mapResponse;
	}

	static public Map<String, Map<String, Map<String, String>>> processDataOld(Map<String, List<SObject>> sObjectMap) {
		Schema.SObjectField leadExternalField = Lead.F3_Consecutivo_ID__c.getDescribe().getSObjectField();
		Map<String, Map<String, Map<String, String>>> upsertResults = new Map<String, Map<String, Map<String, String>>>();
		if (sObjectMap.isEmpty()) {
			throw new F3_RestServices_Exception('Sin registros validos');
		}
		List<Lead> sourceLeads = leadsToUpdate(sObjectMap.get('Account'));
		for (Integer i = 0; i < insertionOrder.size(); i++) {
			if (sObjectMap.get((String) insertionOrder.get(i).get('sObject')) != null &&
				!sObjectMap.get((String) insertionOrder.get(i).get('sObject')).isEmpty()) {
				System.debug('···· processDataOld: '+sObjectMap.get((String) insertionOrder.get(i).get('sObject')));
				upsertResults.put((String) insertionOrder.get(i).get('sObject'),
					             (Map<String, Map<String, String>>) F3_Database_Utility.upsertRecords(
								 sObjectMap.get((String) insertionOrder.get(i).get('sObject')),
								 (Schema.SObjectField) insertionOrder.get(i).get('externalField'),
								 false,
								 true));
			}
		}
		if (!sourceLeads.isEmpty()) {
			upsertResults.put(
				'Lead',
				(Map<String, Map<String, String>>) F3_Database_Utility.upsertRecords(sourceLeads, leadExternalField, false, true)
			);
		}
		return upsertResults;
	}

	static public Map<String, Map<String, Map<String, String>>> processData(Map<String, List<SObject>> sObjectMap, Map<String,Account> mapAccountsUpdate, Map<String,Lead> mapConsecutiveByLead) {
		Map<String, Map<String, Map<String, String>>> upsertResults = new Map<String, Map<String, Map<String, String>>>();
		List<Account> lstAccountsUpdate = accountsToUpdate(sObjectMap.get('Account'), mapAccountsUpdate, mapConsecutiveByLead);
		System.debug('lstAccountsUpdate: '+lstAccountsUpdate);
		if(!lstAccountsUpdate.isEmpty()) upsertResults.put('Account',(Map<String, Map<String, String>>) F3_Database_Utility.upsertRecords(lstAccountsUpdate, null, false, true));
		return upsertResults;
	}

	/** ------------------------------------------------------------------------------------------------
	 * Description Change the stage of linked leads to 'Cerrada Ganada'
	 *   ------------------------------------------------------------------------------------------------
	 * author   luis.felipe.ortiz@pwc.com
	 * date     12/08/2022
	 * param    Set<String> leadIds : Set of Leads ID's
	 * return   List<Lead>
	 * example  leadsToUpdate(leadIds)
	 * ------------------------------------------------------------------------------------------------**/
	static private List<Lead> leadsToUpdate(List<Account> clientList) {
		Set<String> leadIds = new Set<String>();
		List<Lead> updatedLeads = new List<Lead>();
		for (Account client : clientList) {
			if (!String.isBlank(client.Prospecto_Origen__r.F3_Consecutivo_ID__c)) {
				leadIds.add(client.Prospecto_Origen__r.F3_Consecutivo_ID__c);
			}
		}
		leadIds.remove(null);
		for (String leadId : leadIds) {
			updatedLeads.add(new Lead(F3_Consecutivo_ID__c = leadId, Cliente_Creado__c = true));
			setLeadExternalId.add(leadId);
		}
		return updatedLeads;
	}
	static private List<Account> accountsToUpdate(List<Account> clientList, Map<String,Account> mapAccountsUpdate, Map<String,Lead> mapConsecutiveByLead) {
		Account[] lstResponse = new List<Account>();
		for(Account objAccount : clientList){
			String strExternalIdLead = objAccount.Prospecto_Origen__r.F3_Consecutivo_ID__c;
			if (String.isNotBlank(strExternalIdLead) && mapAccountsUpdate.get(strExternalIdLead) != null) {
				Account tmpAccount = new Account();
				tmpAccount.Id = mapAccountsUpdate.get(strExternalIdLead).Id;
				tmpAccount.Prospecto_Origen__c = mapConsecutiveByLead.get(strExternalIdLead).Id;
				tmpAccount.Client_ID__c = objAccount.Client_ID__c;
				tmpAccount.LastName  = objAccount.LastName;
				tmpAccount.FirstName = objAccount.FirstName;
				lstResponse.add(tmpAccount);
			}
		}
		if (lstResponse.isEmpty()) throw new F3_RestServices_Exception('ERR_ACT_ACC_001: No se han podido actualizar el cliente, esta pendiente convertir al prospecto. Notifique a Salesforce');
		
		return lstResponse;
	}
}