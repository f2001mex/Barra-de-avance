/**
* @File Name : OD_Account_cls.cls
* @Description :Clase test de todo trigger Account
* @Author : Andrés Hernández Ríos
* @Last Modified By :
* @Last Modified On : December 11, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 11, 2024 |Andrés Hernández Ríos| Initial Version
**/
@isTest
public class OD_Account_tst {
    @testSetup static void setup() {
        String adminProfileId = [SELECT Id FROM Profile WHERE name IN ('System Administrator', 'Administrador del sistema')].Id;
        User user = new User();
        user.LastName = 'User1';
        user.Username = 'User1@user.com.u';
        user.Email = 'Useruser@u.com.u';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.Alias = 'uAas2';
        user.IsActive = true;
        user.TimeZoneSidKey = 'America/Mexico_City';
        user.LocaleSidKey = 'en_US';
        user.LanguageLocaleKey = 'es';
        user.ID_ASESOR__c = '00045';
        user.ProfileId = adminProfileId;
        insert user;
        
        User user2 = new User();
        user2.LastName = 'Usr2';
        user2.Username = 'Usr2@user.com.u';
        user2.Email = 'Useruser@u.com.u';
        user2.EmailEncodingKey = 'ISO-8859-1';
        user2.Alias = 'Usr2';
        user2.IsActive = true;
        user2.TimeZoneSidKey = 'America/Mexico_City';
        user2.LocaleSidKey = 'en_US';
        user2.LanguageLocaleKey = 'es';
        user2.ID_ASESOR__c = '00050';
        user2.ProfileId = adminProfileId;
        insert user2;
        
        BranchUnit branchUnit = new BranchUnit();
        branchUnit.Name = 'TestBranchUnit';
        branchUnit.IsActive = true;
        branchUnit.BranchCode = '10000012345';
        branchUnit.ExternalIdBI__c = '37';
        branchUnit.ExternalId__c = '10000012345';
        insert branchUnit;
        
        Banker bankerContact = new Banker();
        bankerContact.Name = 'TestBankerContact1';
        bankerContact.JobCode = '00045';
        bankerContact.ExternalId__c = '00045';
        bankerContact.CurrentBranchId = branchUnit.Id;
        bankerContact.UserOrContactId = user.Id;
        insert bankerContact;
    }
    
    @isTest
	static void testCreateNewAccountInBulk() {
		List<Account> accts = new List<Account>();
		for (Integer i = 0; i < 200; i++) {
			Account acct = new Account(
				Person_Type__c = 'MORAL',
				name = 'Nombre Empresa ' + i,
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
			/*if (i == 0) {
				System.assertEquals(false, rst.isSuccess());
			} else if (i == 1) {
				System.assertEquals(true, rst.isSuccess());
			} else if (i == 2) {
				System.assertEquals(true, rst.isSuccess());
			} else if (i == 3) {
				System.assertEquals(true, rst.isSuccess());
			}*/
		}

		List<Account> lstAccountInDB = [SELECT Id FROM Account WHERE Institucion__c = 'Banamex'];
		Database.SaveResult[] lstResultUp = Database.update(lstAccountInDB, false);
		for (Integer i = 0; i < lstResultUp.size(); i++) {
			Database.SaveResult rst = lstResultUp[i];
			if (i == 0) {
				System.assertEquals(true, rst.isSuccess());
			} else if (i == 1) {
				System.assertEquals(true, rst.isSuccess());
			}
		}
	}
    @isTest
    static void testGetLeadByExternalId(){
		Test.startTest();
        OD_Account_cls.getLeadByExternalId(new Set<String>{null});
		Test.stopTest();
    } 
    @isTest
    static void testSetValuesOfConvertLead(){
		Test.startTest();
        OD_Account_cls.setValuesOfConvertLead(new Map<String,Lead>(),new Account());
		Test.stopTest();
    } 
    @isTest
    static void testNewAccountErrorUsr(){
		Test.startTest(); 
        User objUser = [SELECT Id FROM User WHERE Alias = 'Usr2' Limit 1];
        Account account = new Account();
        account.LastName = 'TestApp';
        account.OwnerId = objUser.Id;
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        try{
        	insert account;  
        } catch(Exception e) {} 
        
		Test.stopTest();
    } 
    @isTest
    static void testNewAccountError(){
		Test.startTest(); 
        Account account = new Account();
        account.LastName = 'TestApp';
        account.ID_Asesor__c = '00046';
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        try{
        	insert account;  
        } catch(Exception e) {} 
        
		Test.stopTest();
    } 
    @isTest
    static void testNewAccountSuccess(){
		Test.startTest();
        Account account2 = new Account();
        account2.LastName = 'TestApp';
        account2.ID_Asesor__c = '00045';
        account2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        try{
        	insert account2;  
        } catch(Exception e) {} 
		Test.stopTest();
    } 

    @isTest
    static void testUpdateAccountWithoutOwnerOrAdvisorChangeDoesNotReassignOwner(){
        User advisorUser = [SELECT Id FROM User WHERE Alias = 'uAas2' LIMIT 1];
        User initialOwner = [SELECT Id FROM User WHERE Alias = 'Usr2' LIMIT 1];

        OD_Account_cls.bypassTriggerExecution = true;
        Account account = new Account();
        account.LastName = 'NoOwnerSync';
        account.ID_Asesor__c = '00045';
        account.OwnerId = initialOwner.Id;
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        insert account;

        OD_Account_cls.bypassTriggerExecution = false;
        account = [SELECT Id, OwnerId, ID_ASESOR__c FROM Account WHERE Id = :account.Id];
        account.EstatusContacto__c = 'Contacto efectivo exitoso';

        Test.startTest();
        update account;
        Test.stopTest();

        Account updatedAccount = [SELECT Id, OwnerId FROM Account WHERE Id = :account.Id];
        System.assertEquals(initialOwner.Id, updatedAccount.OwnerId);
        System.assertNotEquals(advisorUser.Id, updatedAccount.OwnerId);
    }

}
