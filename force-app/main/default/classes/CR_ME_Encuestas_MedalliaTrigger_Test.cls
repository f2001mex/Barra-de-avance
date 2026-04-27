@IsTest
public with sharing class CR_ME_Encuestas_MedalliaTrigger_Test {
	@IsTest
	public static void TestUpdateAccount() {
		Account newAccount = new Account(LastName = 'Prueba ', Client_Id__c = '0000001');
		List<CR_ME_Encuestas_Medallia__c> newSurveys = new List<CR_ME_Encuestas_Medallia__c>();
		for (Integer i = 0; i < 3; i++) {
			newSurveys.add(
				new CR_ME_Encuestas_Medallia__c(
					surveyid__c = '000' + i,
					CR_ME_Cliente_unico__r = new Account(Client_Id__c = newAccount.Client_Id__c),
					act_cdmx_date__c = Date.newInstance(2023, 7, 12 + i),
					act_rel_ltr_scale11__c = i + 1
				)
			);
		}
		insert newAccount;
		insert newSurveys;
		newAccount = [SELECT Id, Client_Id__c, CR_ME_Probabilidad_Recomendar_Actinver__c FROM Account WHERE Id = :newAccount.id];
		Assert.areEqual(3, newAccount.CR_ME_Probabilidad_Recomendar_Actinver__c);
	}
}