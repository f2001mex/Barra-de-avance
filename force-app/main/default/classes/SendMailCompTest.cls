@isTest
public with sharing class SendMailCompTest {
	@TestSetup
	static void makeData() {
		Id recordTypeIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Cliente Banca Privada').getRecordTypeId();
		Account objAcc = new Account();
		objAcc.FirstName = 'test';
		objAcc.LastName = 'Acc';
		objAcc.RecordTypeId = recordTypeIdAccount;
		objAcc.PersonEmail = 'abc@dd.com';
		insert objAcc;

		Opportunity objOpp = new Opportunity();
		objOpp.AccountId = objAcc.Id;
		objOpp.Name = 'testOpp';
		objOpp.StageName = 'Contacto inicial';
		objOpp.CloseDate = System.today();
		insert objOpp;

		// Id recordTypeIdUser = Schema.SObjectType.User.getRecordTypeInfosByName().get('Dio Xi').getRecordTypeId();
		List<Profile> lstProfile = [SELECT Id FROM Profile WHERE Name = 'Asesor Soluciones' LIMIT 1];
		User objUser = new User();
		objUser.ProfileId = lstProfile[0].Id;
		objUser.Division = 'AGS AGUASCALIENTES NTE 509';
		objUser.Username = 'userTest@dd.com';
		objUser.LastName = 'User';
		// objUser.RecordTypeId = recordTypeIdUser;
		objUser.Email = 'abcd@dd.com';
		objUser.Alias = 'AutoZ';
		objUser.TimeZoneSidKey = 'Asia/Shanghai';
		objUser.LocaleSidKey = 'en_US';
		objUser.EmailEncodingKey = 'UTF-8';
		objUser.LanguageLocaleKey = 'en_US';
		objUser.IsActive = true;
		insert objUser;

		Contact objCon = new Contact();
		objCon.FirstName = 'test';
		objCon.LastName = 'Contact';
		insert objCon;

		Lead objLead = new Lead();
		objLead.OwnerId = objUser.Id;
		objLead.FirstName = 'test';
		objLead.LastName = 'Lead';
		objLead.Company = 'test Lead';
		objLead.PostalCode = '20555';
		objLead.status = 'Asignado';
		objLead.FinServ__ReferredByUser__c = objUser.Id;
		insert objLead;

		// List<ContentVersion> lstVer = [SELECT ContentDocumentId FROM ContentVersion WHERE Id != null LIMIT 1];

		// ContentDocument objCD = [SELECT Id, Title FROM ContentDocument WHERE Title = 'Insurance_Console_appicon' LIMIT 1];

		// ContentDocumentLink objLink = new ContentDocumentLink();
		// objLink.LinkedEntityId = objLead.Id;
		// objLink.ContentDocumentId = objCD.Id;
		// insert objLink;
	}

	@isTest
	public static void doSendMailCompTest1() {
		List<Opportunity> lstOpp = [SELECT ID FROM Opportunity WHERE Id != NULL LIMIT 1];
		String strId1 = lstOpp[0].Id;
		List<Lead> lstLead = [SELECT ID FROM Lead LIMIT 1];
		String strId2 = lstLead[0].Id;

		Test.startTest();
		Map<String, Object> result1 = SendMailCtrl.doSendMailCommon('Opps_Email_Template', strId1);
		// Map<String, Object> result2 = SendMailCtrl.doSendMailCommon('Lead_Email_Template', strId2);
		EmailTemplate mailtemp = [SELECT Id, DeveloperName FROM EmailTemplate LIMIT 1];
		Map<String, Object> result2 = SendMailCtrl.doSendMailCommon(mailtemp.DeveloperName, strId2);
		Test.stopTest();
		System.assert(result1 != null || result2 != null);
	}

	@isTest
	public static void returnRecordTypeTest() {
		Lead lObj = [SELECT Id FROM Lead WHERE Id != NULL LIMIT 1];
		Test.startTest();
		String strResult = SendMailCtrl.returnRecordType(lObj.Id);
		Test.stopTest();
		System.assert(strResult != null);
	}
}