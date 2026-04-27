/**
 *   ------------------------------------------------------------------------------------------------
 * Name     F3_ContractService_Handler
 * Author   luis.felipe.ortiz@pwc.com
 * Date     Created: 10/17/2022
 * Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * Description Handler class for the F3_ContractService_Controller class
 *   ------------------------------------------------------------------------------------------------
 * Changes
 * 10/17/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public with sharing class F3_ContractService_Handler implements Callable {
	static final Schema.SObjectField contractExternalField = Contract.IDSap__c.getDescribe().getSObjectField();
	static final Schema.SObjectField phoneExternalField = Telefono_de_Contrato__c.Phone_ID__c.getDescribe().getSObjectField();
	static final Schema.SObjectField mailExternalField = Correo_de_Contrato__c.Email_ID__c.getDescribe().getSObjectField();
	static final Schema.SObjectField figuraExternalField = Figuras_Relacionadas__c.Role_ID__c.getDescribe().getSObjectField();
	static final Schema.SObjectField addressExternalField = Direcci_n_de_Contrato__c.Direction_ID__c.getDescribe().getSObjectField();
	static final Map<Integer, Map<String, Object>> insertionOrder = new Map<Integer, Map<String, Object>>{
		0 => new Map<String, Object>{ 'externalField' => contractExternalField, 'sObject' => 'Contract' },
		1 => new Map<String, Object>{ 'externalField' => addressExternalField, 'sObject' => 'Direcci_n_de_Contrato__c' },
		2 => new Map<String, Object>{ 'externalField' => phoneExternalField, 'sObject' => 'Telefono_de_Contrato__c' },
		3 => new Map<String, Object>{ 'externalField' => mailExternalField, 'sObject' => 'Correo_de_Contrato__c' },
		4 => new Map<String, Object>{ 'externalField' => figuraExternalField, 'sObject' => 'Figuras_Relacionadas__c' }
	};
	/** ------------------------------------------------------------------------------------------------
	 * Description Deserialize the received JSON and upsert the Contract with it's related records
	 *   ------------------------------------------------------------------------------------------------
	 * author   luis.felipe.ortiz@pwc.com
	 * date     10/17/2022
	 * param    String contractsJson : JSON with the account data
	 * return   Map<String, Map<String, Map<String,String>>>
	 * example  F3_ContractService_Handler.processData(RestContext.request.requestBody.toString())
	 * ------------------------------------------------------------------------------------------------**/
	static public Map<String, Map<String, Map<String, String>>> processData(string contractsJson) {
		Schema.SObjectField leadExternalField = Lead.F3_Consecutivo_ID__c.getDescribe().getSObjectField();
		Schema.SObjectField oppExternalField = Opportunity.F3_Consecutivo_ID__c.getDescribe().getSObjectField();
		Map<String, Map<String, Map<String, String>>> upsertResults = new Map<String, Map<String, Map<String, String>>>();
		Map<String, List<SObject>> sObjectMap = F3_JsonToSobject_Service.jsonToSobject(contractsJson, 'crearActualizarContrato');
		System.debug(JSON.serializePretty(sObjectMap));
		if (sObjectMap.isEmpty()) {
			throw new F3_RestServices_Exception('Sin registros validos');
		}
		for (Integer i = 0; i < insertionOrder.size(); i++) {
			if (
				sObjectMap.get((String) insertionOrder.get(i).get('sObject')) != null &&
				!sObjectMap.get((String) insertionOrder.get(i).get('sObject')).isEmpty()
			) {
				upsertResults.put(
					(String) insertionOrder.get(i).get('sObject'),
					(Map<String, Map<String, String>>) F3_Database_Utility.upsertRecords(
						sObjectMap.get((String) insertionOrder.get(i).get('sObject')),
						(Schema.SObjectField) insertionOrder.get(i).get('externalField'),
						false,
						true
					)
				);
			}
		}
		Map<String, List<SObject>> relateds = relatedsToUpdate(sObjectMap.get('Contract'));
		if (!relateds.get('Opportunity').isEmpty()) {
			upsertResults.put(
				'Opportunity',
				(Map<String, Map<String, String>>) F3_Database_Utility.upsertRecords(
					relateds.get('Opportunity'),
					oppExternalField,
					false,
					true
				)
			);
		}
		if (!relateds.get('Lead').isEmpty()) {
			upsertResults.put(
				'Lead',
				(Map<String, Map<String, String>>) F3_Database_Utility.upsertRecords(relateds.get('Lead'), leadExternalField, false, true)
			);
		}
		return upsertResults;
	}

	/** ------------------------------------------------------------------------------------------------
	 * Description Change the stage of linked opps to 'Cerrada Ganada'
	 *   ------------------------------------------------------------------------------------------------
	 * author   luis.felipe.ortiz@pwc.com
	 * date     12/08/2022
	 * param    Set<String> oppIds : Set of Oppss ID's
	 * return   List<Opportunity>
	 * example  oppsToUpdate(oppIds)
	 * ------------------------------------------------------------------------------------------------**/
	static private Map<String, List<SObject>> relatedsToUpdate(List<Contract> contractList) {
		Set<String> oppIds = new Set<String>();
		Set<String> leadIds = new Set<String>();
		List<Opportunity> updatedOppss = new List<Opportunity>();
		List<Lead> updatedLeads = new List<Lead>();
		for (Contract contract : contractList) {
			if (!String.isBlank(contract.F3_Source_Opportunity__r.F3_Consecutivo_ID__c)) {
				oppIds.add(contract.F3_Source_Opportunity__r.F3_Consecutivo_ID__c);
			}
			if (!String.isBlank(contract.F3_prospecto_origen__r.F3_Consecutivo_ID__c)) {
				leadIds.add(contract.F3_prospecto_origen__r.F3_Consecutivo_ID__c);
			}
		}
		leadIds.remove(null);
		for (String leadId : leadIds) {
			updatedLeads.add(new Lead(F3_Consecutivo_ID__c = leadId, F3_Contrato_Creado__c = true));
		}
		oppIds.remove(null);
		for (String oppId : oppIds) {
			updatedOppss.add(new Opportunity(F3_Consecutivo_ID__c = oppId, Contrato_Creado__c = true));
		}
		return new Map<String, List<SObject>>{ 'Opportunity' => updatedOppss, 'Lead' => updatedLeads };
	}

	private SObject editContract(Contract contractToInsert) {
		contractToInsert.BusinessUnitNumber__c = String.isNotBlank(contractToInsert.BusinessUnitNumber__c)
			? contractToInsert.BusinessUnitNumber__c == '999'
					? '1'
					: contractToInsert.BusinessUnitNumber__c == '998' ? '2' : contractToInsert.BusinessUnitNumber__c
			: null;
		return contractToInsert;
	}

	public Object call(String action, Map<String, Object> args) {
		switch on action {
			when 'editContract' {
				return this.editContract((Contract) args.get('newSObject'));
			}
			when else {
				return (SObject) args.get('newSObject');
			}
		}
	}
}