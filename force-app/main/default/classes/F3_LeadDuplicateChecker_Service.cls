/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_LeadDuplicateChecker_Service
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 01/01/2023
 * ------------------------------------------------------------------------------------------------
 * @Description Class to retrieve the duplicates of a lead based on Actinver's duplicate rules
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 01/01/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public without sharing class F3_LeadDuplicateChecker_Service {
	/** -----------------------------------------------------------------------------
	 * @Description retrieve the duplicates
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @return   List<Lead>
	 * example	 getDuplicates(String currentLeadEmail, String currentLeadPhone, Id currentLeadId)
	 **/
	@AuraEnabled(cacheable=true)
	public static List<Lead> getDuplicates(String currentLeadEmail, String currentLeadPhone, Id currentLeadId) {
		try {
			List<Lead> duplicateLeads;
			if (String.isNotBlank(currentLeadEmail) && String.isNotBlank(currentLeadPhone)) {
				duplicateLeads = [
					SELECT
						Id,
						CreatedDate,
						Phone,
						MobilePhone,
						Email,
						Name,
						Campaign__c,
						Campaign__r.Name,
						LeadSource,
						FinServ__ExpressedInterest__c,
						Inversion_Inicial__c,
						OwnerId,
						Owner.Name,
						Status,
						Miembro_de_l_nea_de_acci_n__c,
						Miembro_de_l_nea_de_acci_n__r.Name,
						CreatedById,
						CreatedBy.Name,
						PostalCode,
						F3_Consecutivo_ID__c,
						RecordTypeId,
						RecordType.Name
					FROM Lead
					WHERE Phone = :currentLeadPhone AND Email = :currentLeadEmail AND Id != :currentLeadId
				];
			} else {
				duplicateLeads = new List<Lead>();
			}
			return duplicateLeads;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}