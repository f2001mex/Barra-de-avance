/**
 *   ------------------------------------------------------------------------------------------------
 * Name     F4_CaseOutsideWorkingHours_Handler
 * Author   ivan.mora@pwc.com
 * Date     Created: 09/26/2023
 * Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * Description Handler class for the F4_CaseOutsideWorkingHours_Controller class
 *   ------------------------------------------------------------------------------------------------
 * Changes
 * 09/26/2023 ivan.mora@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public with sharing class F4_CaseOutsideWorkingHours_Handler implements Callable{
	static final Schema.SObjectField contractExternalField = Contract.IDSap__c.getDescribe().getSObjectField();
	static final Map<Integer, Map<String, Object>> insertionOrder = new Map<Integer, Map<String, Object>>{
		0 => new Map<String, Object>{ 'externalField' => contractExternalField, 'sObject' => 'Case' }
	};
    static final Id CASE_CAT_RT = [SELECT Id, DeveloperName FROM RecordType 
                                   WHERE SObjectType = 'Case' and DeveloperName = 'CAT' LIMIT 1].Id;    
	/** ------------------------------------------------------------------------------------------------
	 * Description Deserialize the received JSON and creates a new Case
	 *   ------------------------------------------------------------------------------------------------
	 * author   ivan.mora@pwc.com
	 * date     09/26/2023
	 * param    String casesJson : JSON with the case data
	 * return   Map<String, Map<String, Map<String,String>>>
	 * example  F4_CaseOutsideWorkingHours_Handler.processData(RestContext.request.requestBody.toString())
	 * ------------------------------------------------------------------------------------------------**/
	public static List<Database.SaveResult> processData(string casesJson) {		
		//Map<String, Map<String, Map<String, String>>> insertResults = new Map<String, Map<String, Map<String, String>>>();
		List<Database.SaveResult> insertResults;
        Map<String, List<SObject>> sObjectMap = F3_JsonToSobject_Service.jsonToSobject(casesJson, 'crearCasoFueraHorario');
		System.debug(JSON.serializePretty(sObjectMap));

        if (sObjectMap.isEmpty()) {
			throw new F3_RestServices_Exception('Sin registros validos');
		}
		for (Integer i = 0; i < insertionOrder.size(); i++) {
			if (
				sObjectMap.get((String) insertionOrder.get(i).get('sObject')) != null &&
				!sObjectMap.get((String) insertionOrder.get(i).get('sObject')).isEmpty()
			) {
				insertResults = (List<Database.SaveResult>) F3_Database_Utility.insertRecords(
                    sObjectMap.get((String) insertionOrder.get(i).get('sObject')),
                    false,
                    false
                );
			}
		}
		return insertResults;
	}
	private SObject editCase(Case caseToInsert) {
		caseToInsert.Estado__c = 'Nuevo/Abierto';
		caseToInsert.RecordTypeId= CASE_CAT_RT;
		return caseToInsert;
	}

    public Object call(String action, Map<String, Object> args) {
		switch on action {
			when 'editCase' {
				return this.editCase((Case) args.get('newSObject'));
			}
			when else {
				return (SObject) args.get('newSObject');
			}
		}
	}
}