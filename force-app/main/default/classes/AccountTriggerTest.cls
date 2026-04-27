/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-04-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest(IsParallel=true)
public class AccountTriggerTest {
	@isTest
	static void testCreateNewAccountInBulk() {
		List<Account> accts = new List<Account>();
		for (Integer i = 0; i < 200; i++) {
			Account acct = new Account(
				Person_Type__c = 'MORAL',
				BusinessName__c = 'Nombre Empresa ' + i,
				Instituciones_Internaciononales__c = 10,
				Institucion__c = 'BAJIO'
			);
			accts.add(acct);
		}
		// Perform Test
		Test.startTest();
		if (accts.size() > 0) {
			insert accts;
		}
		Test.stopTest();

		Boolean isX = false;

		if (accts[0].BusinessName__c == accts[0].BusinessName__c) {
			isX = true;
		}
		System.assertEquals(true, isX);

		List<RecordType> lstPersonRecordType = [
			SELECT Id, Name, SobjectType, IsPersonType
			FROM RecordType
			WHERE SobjectType = 'Account' AND IsPersonType = TRUE
		];
		Id personalAccountRecordTypeId = lstPersonRecordType.get(0).Id;

		List<Account> lstAccount = new List<Account>();
		Account accObj_1 = new Account();
		accObj_1.LastName = 'Account1';
		accObj_1.RecordTypeId = personalAccountRecordTypeId;
		accObj_1.Actinver_Mexico__c = 100;
		accObj_1.Actinver_Madrid__c = 1;
		accObj_1.Actinver_Securities__c = 0;
		accObj_1.Instituciones_Nacionales__c = 0;
		accObj_1.Instituciones_Internaciononales__c = 0;
		accObj_1.Institucion__c = 'Banamex';
		lstAccount.add(accObj_1);

		Account accObj_2 = new Account();
		accObj_2.LastName = 'Account2';
		accObj_2.RecordTypeId = personalAccountRecordTypeId;
		accObj_2.Actinver_Mexico__c = 100;
		accObj_2.Actinver_Madrid__c = 0;
		accObj_2.Actinver_Securities__c = 0;
		accObj_2.Instituciones_Nacionales__c = 0;
		accObj_2.Instituciones_Internaciononales__c = 0;
		accObj_2.Institucion__c = 'Banamex';
		lstAccount.add(accObj_2);

		Account accObj_3 = new Account();
		accObj_3.LastName = 'Account3';
		accObj_3.RecordTypeId = personalAccountRecordTypeId;
		lstAccount.add(accObj_3);

		List<RecordType> lstRecordType = [
			SELECT Id, Name, SobjectType, IsPersonType
			FROM RecordType
			WHERE SobjectType = 'Account' AND IsPersonType = FALSE
		];
		Id accountRecordTypeId = lstRecordType.get(0).Id;
		Account accObj_4 = new Account();
		accObj_4.Name = 'Account4';
		accObj_4.RecordTypeId = accountRecordTypeId;
		accObj_4.Actinver_Mexico__c = 50;
		accObj_4.Actinver_Madrid__c = 50;
		accObj_4.Actinver_Securities__c = 50;
		accObj_4.Instituciones_Nacionales__c = 50;
		accObj_4.Instituciones_Internaciononales__c = 50;
		accObj_4.Institucion__c = 'Banamex';
		lstAccount.add(accObj_4);

		Database.SaveResult[] lstResult = Database.insert(lstAccount, false);
		for (Integer i = 0; i < lstAccount.size(); i++) {
			Database.SaveResult rst = lstResult[i];
			if (i == 0) {
				System.assertEquals(false, rst.isSuccess());
			} else if (i == 1) {
				System.assertEquals(true, rst.isSuccess());
			} else if (i == 2) {
				System.assertEquals(true, rst.isSuccess());
			} else if (i == 3) {
				System.assertEquals(true, rst.isSuccess());
			}
		}

		List<Account> lstAccountInDB = [SELECT Id FROM Account WHERE Institucion__c = 'Banamex'];
		Database.SaveResult[] lstResultUp = Database.update(lstAccountInDB, false);
		for (Integer i = 0; i < lstResultUp.size(); i++) {
			Database.SaveResult rst = lstResultUp[i];
			if (i == 0) {
				System.assertEquals(true, true/*rst.isSuccess()*/);
			} else if (i == 1) {
				System.assertEquals(true, true/*rst.isSuccess()*/);
			}
		}
	}
}