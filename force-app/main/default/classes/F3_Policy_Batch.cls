/** ---------------------------------------------------------------------------------------------------
    * @Description: Class batch that relates previous policies after they are created in the load process
    *   ------------------------------------------------------------------------------------------------
    Author                  Date                Version                 Changes
    Victor Galvan           07/02/2023          1.0                     Class creation
* ------------------------------------------------------------------------------------------------**/
public with sharing class F3_Policy_Batch implements Database.Batchable<sObject>, Database.Stateful {
	public String query;
	set<Id> setIdsToSearch = new Set<Id>();
	set<String> setPoliciesToSearch = new Set<String>();
	static Map<String, Id> policiesMap;
	List<InsurancePolicy> policiesToUpdate = new List<InsurancePolicy>();

	public F3_Policy_Batch(String query) {
		this.query = !String.isBlank(query)
			? query
			: 'SELECT Id, Name, PriorPolicyId, F3_Poliza_Anterior__c FROM InsurancePolicy WHERE F3_Poliza_Anterior__c != null AND PriorPolicyId = null';
	}
	public F3_Policy_Batch() {
		this.query = 'SELECT Id, Name, PriorPolicyId, F3_Poliza_Anterior__c FROM InsurancePolicy WHERE F3_Poliza_Anterior__c != null AND PriorPolicyId = null';
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description retrieves all the policies that does not have a parent policy (ParentPolicyId)
	 *   ------------------------------------------------------------------------------------------------
	 * @author   victor.galvan.chavez@pwc.com
	 * @date     09/02/2023
	 * @param
	 * @return   Map<string, string>
	 * @example  fillPoliciesMap(set<String> policyNames)
	 * ------------------------------------------------------------------------------------------------**/
	private static Map<string, string> fillPoliciesMap(set<String> policyNames) {
		if (policiesMap == null) {
			policiesMap = new Map<String, Id>();
			final List<InsurancePolicy> policiesToSearch = [
				SELECT Id, Name, ParentPolicyId
				FROM InsurancePolicy
				WHERE Name IN :policyNames
			];
			for (InsurancePolicy ip : policiesToSearch) {
				policiesMap.put(ip.Name, ip.Id);
			}
		}
		System.debug('### Policies Map returned: ' + policiesMap);
		return policiesMap;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		System.debug('### query for F3_Policy_Batch: ' + query);
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext bc, List<InsurancePolicy> scope) {
		try {
			if (!scope.isEmpty()) {
				set<String> setPoliciesNamesToSearch = new Set<String>();
				for (InsurancePolicy ip : scope) {
					setPoliciesNamesToSearch.add(ip.F3_Poliza_Anterior__c);
				}
				fillPoliciesMap(setPoliciesNamesToSearch);
				for (InsurancePolicy ip2 : scope) {
					String idToAssignS = policiesMap.get(ip2.F3_Poliza_Anterior__c);
					if (idToAssignS != null && idToAssignS != '') {
						ip2.PriorPolicyId = (Id) idToAssignS;
						policiesToUpdate.add(ip2);
					}
				}
				update policiesToUpdate;
			}
		} catch (Exception ex) {
			Log__c log = new Log__c(
				Category__c = 'Policy Batch',
				ErrorMessage__c = ex.getMessage(),
				Objeto__c = 'InsurancePolicy',
				Estado__c = 'Error'
			);
			insert log;
		}
	}

	public void finish(Database.BatchableContext bc) {
		Log__c log = new Log__c(
			Category__c = 'Policy Batch',
			ErrorMessage__c = 'Process ended. There were ' + policiesToUpdate.size() + ' updates.',
			Objeto__c = 'InsurancePolicy',
			Estado__c = 'Éxito'
		);
		insert log;
	}
}