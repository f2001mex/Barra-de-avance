public with sharing class CR_ME_Encuestas_MedalliaTrigger_Helper {
	public static void UpdateRelatedObject(list<CR_ME_Encuestas_Medallia__c> surveyNew, Map<id, CR_ME_Encuestas_Medallia__c> surveyOldMap) {
		Map<String, Account> accountsToUpdate = new Map<String, Account>();
		Map<String, Date> mostRecentSurvey = new Map<String, Date>();
		for (CR_ME_Encuestas_Medallia__c newSurvey : surveyNew) {
			if (!accountsToUpdate.containsKey(newSurvey.CR_ME_Cliente_unico__c)) {
				accountsToUpdate.put(
					newSurvey.CR_ME_Cliente_unico__c,
					new Account(
						Id = newSurvey.CR_ME_Cliente_unico__c,
						CR_ME_Probabilidad_Recomendar_Actinver__c = newSurvey.act_rel_ltr_scale11__c
					)
				);
				mostRecentSurvey.put(newSurvey.CR_ME_Cliente_unico__c, newSurvey.act_cdmx_date__c);
			} else if (newSurvey.act_cdmx_date__c > mostRecentSurvey.get(newSurvey.CR_ME_Cliente_unico__c)) {
				accountsToUpdate.put(
					newSurvey.CR_ME_Cliente_unico__c,
					new Account(
						Id = newSurvey.CR_ME_Cliente_unico__c,
						CR_ME_Probabilidad_Recomendar_Actinver__c = newSurvey.act_rel_ltr_scale11__c
					)
				);
				mostRecentSurvey.put(newSurvey.CR_ME_Cliente_unico__c, newSurvey.act_cdmx_date__c);
			}
		}
		if (!accountsToUpdate.isEmpty()) {
			update accountsToUpdate.values();
		}
	}
}