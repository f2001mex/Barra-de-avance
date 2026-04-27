/**
 * @author Jiale Zhang
 * @date 11/29/2021
 * @description
 *      test CaseHandler
 */
@isTest
public with sharing class CaseHandlerTest {
	private static String strCaseStatus = 'Proceso de callback';
	private static String strTestUser = 'testUser';
	private static String strLocaleSidKey = 'es_MX';
	private static String strEmailEncodingKey = 'UTF-8';
	private static String strTimeZone1 = 'America/Mexico_City';

	@TestSetup
	static void makeData() {
		// List<User> lstUserMock = [SELECT Id,Name FROM USER WHERE Name = 'Executive UNE Test Shi'];
		List<Profile> lstProfile = [SELECT Id FROM Profile WHERE Name = 'Ejecutivo UNE'];
		User testUser = new User(
			FirstName = strTestUser,
			LastName = '1',
			UserName = 'test123321@163.com',
			Email = 'huayang.shi@pwc.com',
			Alias = 't1',
			TimeZoneSidKey = strTimeZone1,
			LocaleSidKey = strLocaleSidKey,
			EmailEncodingKey = strEmailEncodingKey,
			ProfileId = lstProfile[0].Id,
			LanguageLocaleKey = strLocaleSidKey
		);
		insert testUser;

		Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Cuentas empresariales').getRecordTypeId();
		Account testAccount = new Account(RecordTypeId = accountRecordTypeId, Name = 'Test Account', OwnerId = testUser.Id);
		insert testAccount;
		Contact testContact = new Contact(Email = 'jiale.zhang@pwc.com', AccountId = testAccount.Id, LastName = 'testContact');
		insert testContact;
		Contract testContract = new Contract(
			AccountId = testAccount.Id,
			AccountOpeningDate__c = Date.today(),
			Status = 'En proceso de validación'
		);
		insert testContract;

		Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
			.get('Cambio de Asesor y/o Centro Financiero')
			.getRecordTypeId();

		List<String> lstStatus = new List<String>();
		//in apex, it's a single line just means lstStatus[0] = Registro... ,lstStatus[1] = 'Proceso de re..' .....
		lstStatus.add('Registro_de_folio');
		lstStatus.add('Proceso de resolución');
		lstStatus.add(strCaseStatus);
		lstStatus.add('Cierre');

		List<Case> lstCase = new List<Case>();
		for (Integer i = 0; i < lstStatus.size(); i++) {
			String strDescription = '';
			if (i == 3) {
				strDescription = 'Test for closed case';
			} else {
				strDescription = 'Test for open case';
			}
			lstCase.add(
				new Case(
					//REQUIRED_FIELD_MISSING, Required fields are missing: [Contrato__c, Submotivo__c]: [Contrato__c, Submotivo__c]
					OwnerId = testUser.Id,
					Origin = 'Correo Unidad Especializada',
					RecordTypeId = caseRecordTypeId,
					Contrato__c = testContract.Id,
					Submotivo__c = 'Falta de Atención / Servicio',
					Status = lstStatus[i],
					Cancelacion_de_caso__c = 'No_sigue_proceso',
					Segmento__c = 'BP',
					Centro_Financiero__c = 'AGS AGUASCALIENTES NTE 509',
					Entidad_Federativa__c = 'Zacatecas',
					ContactId = testContact.Id,
					AccountId = testAccount.Id,
					Description = strDescription,
					Asesor__c = testAccount.OwnerId
				)
			);
		}
		//for test story 40 part 2
		lstCase.add(
			new Case(
				OwnerId = testUser.Id,
				Origin = 'Correo Unidad Especializada',
				RecordTypeId = caseRecordTypeId,
				Contrato__c = testContract.Id,
				Submotivo__c = 'Falta de Atención / Servicio',
				Status = strCaseStatus,
				Cancelacion_de_caso__c = 'Si_cancela_folio',
				Segmento__c = 'BP',
				Centro_Financiero__c = 'AGS AGUASCALIENTES NTE 509',
				Entidad_Federativa__c = 'Zacatecas',
				ContactId = testContact.Id,
				AccountId = testAccount.Id,
				Description = 'this is for story 40 test',
				Asesor__c = null
			)
		);
		insert lstCase;
	}
	@isTest
	public static void executecaseHandlerTest() {
		// List<User> lstUserMock = [SELECT Id,Name FROM USER WHERE Name = 'Executive UNE Test Shi'];
		List<User> lstUserMock = [SELECT Id, Name FROM USer WHERE UserName = 'test123321@163.com' LIMIT 1];
		Test.startTest();
		List<Case> lstCase = [SELECT Status, Asesor__c FROM Case WHERE Id != NULL LIMIT 10000];
		//List<Case> lstCase = [SELECT Status FROM Case];
		// System.debug('lstCase is :' + lstCase);
		System.runAs(lstUserMock[0]) {
			//test story 41 part1
			lstCase[3].Status = strCaseStatus;
			// error report update lstCase
			lstCase[3].Asesor__c = null;
			Database.update(lstCase, false);
			System.assertEquals(strCaseStatus, lstCase[3].Status);
		}
		//test story 41 part 2 (else logic)
		lstCase[3].Status = strCaseStatus;
		lstCase[3].Area_apoyo__c = 'Crédito';
		lstCase[3].Cor_doc_apoyo__c = true;
		lstCase[3].Sol_Corr__c = true;
		lstCase[3].Notif_Directores__c = true;
		lstCase[3].Recep_form_dire__c = true;
		lstCase[3].Sol_Auditoria__c = true;
		update lstCase;
		System.assertEquals(strCaseStatus, lstCase[3].Status);
		// turn back
		lstCase[3].Status = 'Cierre';
		update lstCase;
		//test story 40
		lstCase[1].Cancelacion_de_caso__c = 'Si_cancela_folio';
		update lstCase;
		System.assertEquals('Proceso de resolución', lstCase[1].Status);
		//turn back
		//lstCase[1].Status = 'Proceso de resolución';
		//update lstCase;
		System.runAs(lstUserMock[0]) {
			//test story 16
			lstCase[2].Status = 'Registro_de_folio';
			//error invoke
			//update lstCase;
			Database.update(lstCase, false);
			System.assertEquals('Registro_de_folio', lstCase[2].Status);
		}
		//test story 40 part 2;
		System.assertEquals('Cierre', lstCase[4].Status);
		// System.debug('see +++++++++++++++++++++++++++++++++++' + lstCase[1].Asesor__c + 'see +++++++++_____' + lstCase[2].Asesor__c + ' se safaweqwewq ' + lstCase[4].Asesor__c);
		Test.stopTest();
	}
}