/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_UnrelatedAccountChildren_Service
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 01/01/2023
 * ------------------------------------------------------------------------------------------------
 * @Description Class to get the unrelated opps and leads of the account
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 01/01/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public with sharing class F3_UnrelatedAccountChildren_Service {
	/** -----------------------------------------------------------------------------
	 * @Description retrieve the open Financing and Insurance opps of the accounts
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @return   List<Opportunity>
	 * example	getUnrelatedAccountOpps(List<Id> accountIds)
	 **/
	@AuraEnabled(cacheable=true)
	public static List<Opportunity> getUnrelatedAccountOpps(List<Id> accountIds) {
		return [
			SELECT
				Id,
				RecordType.Name,
				StageName,
				F3_Consecutivo_ID__c,
				OwnerId,
				Owner.Name,
				Name,
				F3_No_Poliza_Seguros__c,
				Poliza_de_Seguros_Creada__c,
				Credito_Creado__c,
				AccountId
			FROM Opportunity
			WHERE
				ContractId = NULL
				AND F3_Credito_Relacionado__c = NULL
				AND RecordType.Name IN ('Financiamiento', 'Seguros')
				AND StageName = 'Formalización y Validación'
				AND AccountId IN :accountIds
		];
	}

	/** -----------------------------------------------------------------------------
	 * @Description retrieve the probable insurance source leads of the account
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @return   List<Opportunity>
	 * example	getUnrelatedAccountOpps(List<Id> accountIds)
	 **/
	@AuraEnabled(cacheable=true)
	public static List<Lead> getUnrelatedAccountLeads(String accountRFC) {
		return String.isBlank(accountRFC)
			? new List<Lead>()
			: [
					SELECT
						Id,
						RecordType.Name,
						Status,
						F3_Consecutivo_ID__c,
						OwnerId,
						Owner.Name,
						Name,
						Productos_ofertados__c,
						F3_No_Poliza_Seguros__c,
						Poliza_de_Seguros_Creada__c
					FROM Lead
					WHERE F3_RFC__c = :accountRFC AND RecordType.Name IN ('Seguros Prospecto') AND Status = 'Formalización y Validación'
			  ];
	}
}