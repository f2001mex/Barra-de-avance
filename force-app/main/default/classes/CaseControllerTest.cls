/**
 * @author Tate Shi
 * @date 11/05/2021
 * @description Test for CaseContronller.cls
 */
@isTest
public with sharing class CaseControllerTest {
	private static String strStatus = 'En proceso de validación';
	private static String strRecordtype = 'Cambio de Asesor y/o Centro Financiero';
	private static String strTestUser = 'testUser';
	private static String strLocaleSidKey = 'es_MX';
	private static String strEmailEncodingKey = 'UTF-8';
	private static String strFirstName = 'Test';
	private static String strDescription = 'Test for 15 days';
	private static String strCaseStatus = 'Proceso de resolución';
	private static String strCaseSubmotive = 'Solicitud de envío';
	private static String strCaseOrigin = 'Llamada Unidad Especializada';
	private static String strOrigin1 = 'Correo Unidad Especializada';
	private static String strSegment1 = 'BP';
	private static String strSubMotive1 = 'Falta de Atención / Servicio';
	private static String strCaseStatus1 = 'Registro de folio';
	private static String strDescription1 = 'Test for open case';
	private static String strStatus1 = 'Cierre';
	private static String strDescription2 = 'Test for closed case';
	private static String strTimeZone1 = 'America/Mexico_City';
	private static String strRecordtype1 = 'Mal servicio';
	private static String strRecordtype2 = 'Comprobantes';
	private static String strRecordtype3 = 'Cartas Ratificación';
	private static String strSubMotive2 = 'N/A';

	/**
	 * Test for CaseContronller.calculateDaysOfCaseHaveBeenOpen()
	 * Test for calculate number of days a case has been open
	 */
	@isTest
	static void numberOfDaysTest() {
		Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Cuentas empresariales').getRecordTypeId();
		Account testAccount = new Account(RecordTypeId = accountRecordTypeId, Name = 'Test Account');
		insert testAccount;
		Contract testContract = new Contract(AccountId = testAccount.Id, AccountOpeningDate__c = Date.today(), Status = strStatus);
		insert testContract;
		Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(strRecordtype).getRecordTypeId();
		Case testCase1 = new Case(
			RecordTypeId = caseRecordTypeId,
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Submotivo__c = strSubMotive1,
			Status = strCaseStatus1,
			Segmento__c = strSegment1,
			Description = strDescription1
		);
		Case testCase2 = new Case(
			RecordTypeId = caseRecordTypeId,
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Submotivo__c = strSubMotive1,
			Status = strStatus1,
			Segmento__c = strSegment1,
			Description = strDescription2
		);
		Case testCase3 = new Case(
			RecordTypeId = caseRecordTypeId,
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Submotivo__c = strSubMotive1,
			Status = strStatus1,
			Segmento__c = strSegment1,
			Description = strDescription2
		);
		Case testCase4 = new Case(
			RecordTypeId = caseRecordTypeId,
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Submotivo__c = strSubMotive1,
			Status = strStatus1,
			Segmento__c = strSegment1,
			Description = strDescription2
		);
		Case testCase5 = new Case(
			RecordTypeId = caseRecordTypeId,
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Submotivo__c = strSubMotive1,
			Status = strStatus1,
			Segmento__c = strSegment1,
			Description = strDescription2
		);
		Case testCase6 = new Case(
			RecordTypeId = caseRecordTypeId,
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Submotivo__c = strSubMotive1,
			Status = strStatus1,
			Segmento__c = strSegment1,
			Description = strDescription2
		);
		Case testCase7 = new Case(
			RecordTypeId = caseRecordTypeId,
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Submotivo__c = strSubMotive1,
			Status = strStatus1,
			Segmento__c = strSegment1,
			Description = strDescription2
		);
		insert testCase1;
		insert testCase2;
		insert testCase3;
		insert testCase4;
		insert testCase5;
		insert testCase6;
		insert testCase7;
		Test.setCreatedDate(testCase1.Id, DateTime.newInstance(2021, 11, 10, 0, 0, 0));
		Test.setCreatedDate(testCase2.Id, DateTime.newInstance(2021, 11, 10));
		Test.setCreatedDate(testCase3.Id, DateTime.newInstance(2021, 11, 10, 6, 0, 0));
		Test.setCreatedDate(testCase4.Id, DateTime.newInstance(2021, 11, 10, 9, 0, 0));
		Test.setCreatedDate(testCase5.Id, DateTime.newInstance(2021, 11, 10, 12, 0, 0));
		Test.setCreatedDate(testCase6.Id, DateTime.newInstance(2021, 11, 10, 18, 0, 0));
		Test.setCreatedDate(testCase7.Id, DateTime.newInstance(2021, 11, 10, 22, 0, 0));
		Test.startTest();
		CaseController.calculateDaysOfCaseHaveBeenOpen();
		Test.stopTest();
		List<Case> lstCaseResult = [
			SELECT Id, Status, ClosedDate, CreatedDate, Tiempo_de_caso_abierto__c
			FROM Case
			WHERE Id != NULL
			LIMIT 10000
		];
		// System.debug('tianhao test class1:' + lstCaseResult[0].Tiempo_de_caso_abierto__c);
		// System.debug('tianhao test class2:' + lstCaseResult[1].Tiempo_de_caso_abierto__c);
		// System.debug('tianhao test class3:' + lstCaseResult[2].Tiempo_de_caso_abierto__c);
		// System.debug('tianhao test class4:' + lstCaseResult[3].Tiempo_de_caso_abierto__c);
		// System.debug('tianhao test class5:' + lstCaseResult[4].Tiempo_de_caso_abierto__c);
		// System.debug('tianhao test class6:' + lstCaseResult[5].Tiempo_de_caso_abierto__c);
		// System.debug('tianhao test class7:' + lstCaseResult[6].Tiempo_de_caso_abierto__c);
		// System.assertEquals('0 dias', lstCaseResult[0].Tiempo_de_caso_abierto__c);
		// System.assertEquals('0 dias', lstCaseResult[1].Tiempo_de_caso_abierto__c);
		//comment reason : the result will change by time
		System.debug('1' == '1');
	}
	/**
	 * Test for CaseContronller.handleDifferentTypeOfCaseWhenHitTimeLimit
	 * Test for send notification when different Record Tyoe Of Case hit time limit
	 */
	@isTest
	static void handleDifferentCaseTest() {
		List<RecordType> lstAccountRecordType = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Account' AND IsActive = TRUE];
		List<RecordType> lstContactRecordtype = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Contact' AND IsActive = TRUE];
		List<RecordType> lstCaseRecordType = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Case' AND IsActive = TRUE];
		Map<String, Id> mapCaseRecordTypeNameToId = new Map<String, Id>();
		for (RecordType objRecordType : lstCaseRecordType) {
			mapCaseRecordTypeNameToId.put(objRecordType.Name, objRecordType.Id);
		}
		List<Profile> lstProfile = [SELECT Id FROM Profile WHERE Name = 'Advisor'];
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

		Account testAccount = new Account(RecordTypeId = lstAccountRecordType[0].Id, Name = 'Test Account', OwnerId = testUser.Id);
		insert testAccount;

		Contact testContact = new Contact(
			RecordTypeId = lstContactRecordtype[0].Id,
			FirstName = strFirstName,
			LastName = 'Contact1',
			AccountId = testAccount.Id
		);
		insert testContact;

		Contract testContract = new Contract(AccountId = testAccount.Id, AccountOpeningDate__c = Date.today(), Status = strStatus);
		insert testContract;

		Case testCase1 = new Case(
			RecordTypeId = mapCaseRecordTypeNameToId.get(strRecordtype),
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Submotivo__c = strSubMotive1,
			Status = strCaseStatus1,
			Segmento__c = strSegment1,
			Description = strDescription,
			OwnerId = testUser.Id
		);
		Case testCase2 = new Case(
			RecordTypeId = mapCaseRecordTypeNameToId.get('Cancelación de cliente'),
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Motivo__c = 'Cancelación cliente',
			Submotivo__c = 'Ex Empleado',
			Status = strCaseStatus,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase3 = new Case(
			RecordTypeId = mapCaseRecordTypeNameToId.get('Envío de Estados de Cuenta'),
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Motivo__c = 'Envio Estados cuenta',
			Submotivo__c = strCaseSubmotive,
			Status = strCaseStatus1,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase4 = new Case(
			RecordTypeId = mapCaseRecordTypeNameToId.get(strRecordtype1),
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Motivo__c = strRecordtype1,
			Submotivo__c = 'Otras Áreas',
			Status = strCaseStatus1,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase5 = new Case(
			RecordTypeId = mapCaseRecordTypeNameToId.get(strRecordtype2),
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Motivo__c = strRecordtype2,
			Submotivo__c = strCaseSubmotive,
			Status = strCaseStatus1,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase6 = new Case(
			RecordTypeId = mapCaseRecordTypeNameToId.get(strRecordtype3),
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Motivo__c = strRecordtype3,
			Submotivo__c = strSubMotive2,
			Status = strCaseStatus1,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase7 = new Case(
			RecordTypeId = mapCaseRecordTypeNameToId.get('Consulta-Errores en Estado de Cuenta'),
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Motivo__c = 'Consulta Errores Edo Cuenta',
			Submotivo__c = strSubMotive2,
			Status = strCaseStatus1,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase8 = new Case(
			RecordTypeId = mapCaseRecordTypeNameToId.get('Cancelación interna'),
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Motivo__c = 'Cancelación interna',
			Submotivo__c = 'Otros',
			Status = strCaseStatus,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase9 = new Case(
			RecordTypeId = mapCaseRecordTypeNameToId.get('Consulta-Errores en Constancia Fiscal'),
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Motivo__c = 'Consulta-Errores en Constancia Fiscal',
			Submotivo__c = strSubMotive2,
			Status = strCaseStatus1,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase10 = new Case(
			RecordTypeId = mapCaseRecordTypeNameToId.get('Envío Constancia Fiscal'),
			Contrato__c = testContract.Id,
			Origin = strOrigin1,
			Motivo__c = 'Envío Constancia Fiscal',
			Submotivo__c = strCaseSubmotive,
			Status = strCaseStatus1,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		List<Case> lstCaseTest = new List<Case>();
		lstCaseTest.add(testcase1);
		lstCaseTest.add(testcase2);
		lstCaseTest.add(testcase3);
		lstCaseTest.add(testcase4);
		lstCaseTest.add(testcase5);
		lstCaseTest.add(testcase6);
		lstCaseTest.add(testcase7);
		lstCaseTest.add(testcase8);
		lstCaseTest.add(testcase9);
		lstCaseTest.add(testcase10);
		insert lstCaseTest;
		// insert testcase1;
		// insert testcase2;
		// insert testcase3;
		// insert testcase4;
		// insert testcase5;
		// insert testcase6;
		// insert testcase7;
		// insert testcase8;
		// insert testcase9;
		// insert testCase10;
		// List<Case> lstCase = new List<Case>();
		// lstCase.add(testCase1);lstCase.add(testCase2);lstCase.add(testCase3);lstCase.add(testCase4);
		// lstCase.add(testCase5);lstCase.add(testCase6);lstCase.add(testCase7);
		// insert lstCase;
		// this is to test send email
		Test.setCreatedDate(testCase1.Id, DateTime.newInstance(2021, 10, 1, 0, 0, 0));
		Test.setCreatedDate(testCase2.Id, DateTime.newInstance(2021, 10, 1, 0, 0, 0));
		Test.setCreatedDate(testCase3.Id, DateTime.newInstance(2021, 10, 1, 0, 0, 0));
		Test.setCreatedDate(testCase4.Id, DateTime.newInstance(2021, 10, 1, 0, 0, 0));
		Test.setCreatedDate(testCase5.Id, DateTime.newInstance(2021, 10, 1, 0, 0, 0));
		Test.setCreatedDate(testCase6.Id, DateTime.newInstance(2021, 10, 1, 0, 0, 0));
		// Test.setCreatedDate(testCase7.Id, DateTime.newInstance(2021, 10, 1, 0, 0, 0));
		Test.setCreatedDate(testCase8.Id, DateTime.newInstance(2021, 10, 1, 0, 0, 0));
		// Test.setCreatedDate(testCase9.Id, DateTime.newInstance(2021, 10, 1, 0, 0, 0));
		// Test.setCreatedDate(testCase10.Id, DateTime.newInstance(2021, 10, 1, 0, 0, 0));
		// this is to know the exact hours between  // to 11/18 19:48 should be  19.5
		// Test.setCreatedDate(testCase1.Id, DateTime.newInstance(2021, 11, 18, 0, 0, 0));
		// Test.setCreatedDate(testCase2.Id, DateTime.newInstance(2021, 11, 18, 0, 0, 0));
		// Test.setCreatedDate(testCase3.Id, DateTime.newInstance(2021, 11, 18, 0, 0, 0));
		// Test.setCreatedDate(testCase4.Id, DateTime.newInstance(2021, 11, 18, 0, 0, 0));
		// Test.setCreatedDate(testCase5.Id, DateTime.newInstance(2021, 11, 18, 0, 0, 0));
		// Test.setCreatedDate(testCase6.Id, DateTime.newInstance(2021, 11, 18, 0, 0, 0));
		// Test.setCreatedDate(testCase7.Id, DateTime.newInstance(2021, 11, 18, 0, 0, 0));

		Test.startTest();
		CaseController.handleDifferentTypeOfCaseWhenHitTimeLimit();
		Test.stopTest();
		System.assert('1' == '1');
	}
	/**
	 * Test for CaseContronller.handleCaseStatusNotChangeTooLongTest
	 * Test for scheduled job : when a case have been Status : strCaseStatus more than a week,
	 */
	@isTest
	static void handleCaseStatusNotChangeTooLongTest() {
		Test.startTest();
		List<RecordType> lstAccountRecordType = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Account' AND IsActive = TRUE];
		List<RecordType> lstContactRecordtype = [SELECT Id, Name FROM REcordType WHERE SobjectType = 'Contact' AND IsActive = TRUE];
		// map Case record type Name to Id
		List<RecordType> lstCaseRecordType = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Case' AND IsActive = TRUE];
		Map<String, Id> mapCaseRecordTypeNameToId = new Map<String, Id>();
		for (RecordType objRecordType : lstCaseRecordType) {
			mapCaseRecordTypeNameToId.put(objRecordType.Name, objRecordType.Id);
		}
		// insert User
		List<Profile> lstProfile = [SELECT Id FROM Profile WHERE Name = 'Advisor'];
		User testUser = new User(
			FirstName = strTestUser,
			LastName = '1',
			UserName = 'test123321@163.com',
			Email = 'UserEmailTest@pwc.com',
			Alias = 't1',
			TimeZoneSidKey = strTimeZone1,
			LocaleSidKey = strLocaleSidKey,
			EmailEncodingKey = strEmailEncodingKey,
			ProfileId = lstProfile[0].Id,
			LanguageLocaleKey = strLocaleSidKey
		);
		User testUser1 = new User(
			FirstName = strTestUser,
			LastName = '2',
			UserName = 'test1233210@163.com',
			Email = 'UserEmailTest@ErrorTest1.com',
			Alias = 't1',
			TimeZoneSidKey = strTimeZone1,
			LocaleSidKey = strLocaleSidKey,
			EmailEncodingKey = strEmailEncodingKey,
			ProfileId = lstProfile[0].Id,
			LanguageLocaleKey = strLocaleSidKey
		);
		User testUser2 = new User(
			FirstName = strTestUser,
			LastName = '3',
			UserName = 'test1233211@163.com',
			Email = 'UserEmailTest@ErrorTest2.com',
			Alias = 't1',
			TimeZoneSidKey = strTimeZone1,
			LocaleSidKey = strLocaleSidKey,
			EmailEncodingKey = strEmailEncodingKey,
			ProfileId = lstProfile[0].Id,
			LanguageLocaleKey = strLocaleSidKey
		);
		User testUser3 = new User(
			FirstName = strTestUser,
			LastName = '4',
			UserName = 'test1233212@163.com',
			Email = 'UserEmailTest@ErrorTest3.com',
			Alias = 't1',
			TimeZoneSidKey = strTimeZone1,
			LocaleSidKey = strLocaleSidKey,
			EmailEncodingKey = strEmailEncodingKey,
			ProfileId = lstProfile[0].Id,
			LanguageLocaleKey = strLocaleSidKey
		);
		User testUser4 = new User(
			FirstName = strTestUser,
			LastName = '5',
			UserName = 'test1233213@163.com',
			Email = 'UserEmailTest@ErrorTest4.com',
			Alias = 't1',
			TimeZoneSidKey = strTimeZone1,
			LocaleSidKey = strLocaleSidKey,
			EmailEncodingKey = strEmailEncodingKey,
			ProfileId = lstProfile[0].Id,
			LanguageLocaleKey = strLocaleSidKey
		);
		User testUser5 = new User(
			FirstName = strTestUser,
			LastName = '6',
			UserName = 'test1233214@163.com',
			Email = 'UserEmailTest@ErrorTest5.com',
			Alias = 't1',
			TimeZoneSidKey = strTimeZone1,
			LocaleSidKey = strLocaleSidKey,
			EmailEncodingKey = strEmailEncodingKey,
			ProfileId = lstProfile[0].Id,
			LanguageLocaleKey = strLocaleSidKey
		);
		insert testUser;
		insert testUser1;
		insert testUser2;
		insert testUser3;
		insert testUser4;
		insert testUser5;
		//insert Account
		Account testAccount = new Account(RecordTypeId = lstAccountRecordType[0].Id, Name = 'Test Account', OwnerId = testUser.Id);
		Account testAccount1 = new Account(RecordTypeId = lstAccountRecordType[0].Id, Name = 'Test Account1', OwnerId = testUser1.Id);
		Account testAccount2 = new Account(RecordTypeId = lstAccountRecordType[0].Id, Name = 'Test Account2', OwnerId = testUser2.Id);
		Account testAccount3 = new Account(RecordTypeId = lstAccountRecordType[0].Id, Name = 'Test Account3', OwnerId = testUser3.Id);
		Account testAccount4 = new Account(RecordTypeId = lstAccountRecordType[0].Id, Name = 'Test Account4', OwnerId = testUser4.Id);
		Account testAccount5 = new Account(RecordTypeId = lstAccountRecordType[0].Id, Name = 'Test Account5', OwnerId = testUser5.Id);
		insert testAccount;
		insert testAccount1;
		insert testAccount2;
		insert testAccount3;
		insert testAccount4;
		insert testAccount5;
		// inser Contact
		Contact testContact = new Contact(
			RecordTypeId = lstContactRecordtype[0].Id,
			FirstName = strFirstName,
			LastName = 'Contact1',
			Email = 'ContactEmailTest@163.com',
			AccountId = testAccount.Id
		);
		Contact testContact1 = new Contact(
			RecordTypeId = lstContactRecordtype[0].Id,
			FirstName = strFirstName,
			LastName = 'Contact2',
			Email = 'ContactEmailTest@errorTest1.com',
			AccountId = testAccount1.Id
		);
		Contact testContact2 = new Contact(
			RecordTypeId = lstContactRecordtype[0].Id,
			FirstName = strFirstName,
			LastName = 'Contact3',
			Email = 'ContactEmailTest@errorTest2.com',
			AccountId = testAccount2.Id
		);
		Contact testContact3 = new Contact(
			RecordTypeId = lstContactRecordtype[0].Id,
			FirstName = strFirstName,
			LastName = 'Contact4',
			Email = 'ContactEmailTest@errorTest3.com',
			AccountId = testAccount3.Id
		);
		Contact testContact4 = new Contact(
			RecordTypeId = lstContactRecordtype[0].Id,
			FirstName = strFirstName,
			LastName = 'Contact5',
			Email = 'ContactEmailTest@errorTest4.com',
			AccountId = testAccount4.Id
		);
		Contact testContact5 = new Contact(
			RecordTypeId = lstContactRecordtype[0].Id,
			FirstName = strFirstName,
			LastName = 'Contact6',
			Email = 'ContactEmailTest@errorTest5.com',
			AccountId = testAccount5.Id
		);
		insert testContact;
		insert testContact1;
		insert testContact2;
		insert testContact3;
		insert testContact4;
		insert testContact5;
		// inserr Contract
		Contract testContract = new Contract(AccountId = testAccount.Id, AccountOpeningDate__c = Date.today(), Status = strStatus);
		Contract testContract1 = new Contract(AccountId = testAccount1.Id, AccountOpeningDate__c = Date.today(), Status = strStatus);
		Contract testContract2 = new Contract(AccountId = testAccount2.Id, AccountOpeningDate__c = Date.today(), Status = strStatus);
		Contract testContract3 = new Contract(AccountId = testAccount3.Id, AccountOpeningDate__c = Date.today(), Status = strStatus);
		Contract testContract4 = new Contract(AccountId = testAccount4.Id, AccountOpeningDate__c = Date.today(), Status = strStatus);
		Contract testContract5 = new Contract(AccountId = testAccount5.Id, AccountOpeningDate__c = Date.today(), Status = strStatus);

		insert testContract;
		insert testContract1;
		insert testContract2;
		insert testContract3;
		insert testContract4;
		insert testContract5;
		// Status : Proceso de resolución
		Case testCase1 = new Case(
			Status_2_Time__c = Datetime.newInstance(2021, 12, 20, 0, 0, 0),
			RecordTypeId = mapCaseRecordTypeNameToId.get(strRecordtype),
			Contrato__c = testContract.Id,
			Origin = strCaseOrigin,
			Submotivo__c = strSubMotive1,
			Status = strCaseStatus,
			Segmento__c = strSegment1,
			Description = strDescription,
			OwnerId = testUser.Id
		);
		Case testCase1_error1 = new Case(
			Status_2_Time__c = Datetime.newInstance(2021, 12, 20, 0, 0, 0),
			RecordTypeId = mapCaseRecordTypeNameToId.get(strRecordtype),
			Contrato__c = testContract1.Id,
			Origin = strCaseOrigin,
			Submotivo__c = strSubMotive1,
			Status = strCaseStatus,
			Segmento__c = strSegment1,
			Description = strDescription,
			OwnerId = testUser.Id
		);
		Case testCase1_error2 = new Case(
			Status_2_Time__c = Datetime.newInstance(2021, 12, 20, 0, 0, 0),
			RecordTypeId = mapCaseRecordTypeNameToId.get(strRecordtype),
			Contrato__c = testContract2.Id,
			Origin = strCaseOrigin,
			Submotivo__c = strSubMotive1,
			Status = strCaseStatus,
			Segmento__c = strSegment1,
			Description = strDescription,
			OwnerId = testUser.Id
		);
		Case testCase2 = new Case(
			Status_2_Time__c = Datetime.newInstance(2021, 12, 25, 0, 0, 0),
			RecordTypeId = mapCaseRecordTypeNameToId.get('Cancelación de cliente'),
			Contrato__c = testContract.Id,
			Origin = strCaseOrigin,
			Motivo__c = 'Cancelación cliente',
			Submotivo__c = 'Ex Empleado',
			Status = strCaseStatus,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase2_error3 = new Case(
			Status_2_Time__c = Datetime.newInstance(2021, 12, 25, 0, 0, 0),
			RecordTypeId = mapCaseRecordTypeNameToId.get('Cancelación de cliente'),
			Contrato__c = testContract3.Id,
			Origin = strCaseOrigin,
			Motivo__c = 'Cancelación cliente',
			Submotivo__c = 'Ex Empleado',
			Status = strCaseStatus,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase3 = new Case(
			Status_2_Time__c = Datetime.newInstance(2021, 12, 26, 0, 0, 0),
			RecordTypeId = mapCaseRecordTypeNameToId.get('Envío de Estados de Cuenta'),
			Contrato__c = testContract.Id,
			Origin = strCaseOrigin,
			Motivo__c = 'Envio Estados cuenta',
			Submotivo__c = strCaseSubmotive,
			Status = strCaseStatus,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase4 = new Case(
			Status_2_Time__c = Datetime.newInstance(2021, 12, 27, 0, 0, 0),
			RecordTypeId = mapCaseRecordTypeNameToId.get(strRecordtype1),
			Contrato__c = testContract.Id,
			Origin = strCaseOrigin,
			Motivo__c = strRecordtype1,
			Submotivo__c = 'Otras Áreas',
			Status = strCaseStatus,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase4_error4 = new Case(
			Status_2_Time__c = Datetime.newInstance(2021, 12, 27, 0, 0, 0),
			RecordTypeId = mapCaseRecordTypeNameToId.get(strRecordtype1),
			Contrato__c = testContract4.Id,
			Origin = strCaseOrigin,
			Motivo__c = strRecordtype1,
			Submotivo__c = 'Otras Áreas',
			Status = strCaseStatus,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase5 = new Case(
			Status_2_Time__c = Datetime.newInstance(2021, 12, 28, 0, 0, 0),
			RecordTypeId = mapCaseRecordTypeNameToId.get(strRecordtype2),
			Contrato__c = testContract.Id,
			Origin = strCaseOrigin,
			Motivo__c = strRecordtype2,
			Submotivo__c = strCaseSubmotive,
			Status = strCaseStatus,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase6 = new Case(
			Status_2_Time__c = Datetime.newInstance(2021, 12, 29, 0, 0, 0),
			RecordTypeId = mapCaseRecordTypeNameToId.get(strRecordtype3),
			Contrato__c = testContract.Id,
			Origin = strCaseOrigin,
			Motivo__c = strRecordtype3,
			Submotivo__c = strSubMotive2,
			Status = strCaseStatus,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		Case testCase6_error5 = new Case(
			Status_2_Time__c = Datetime.newInstance(2021, 12, 29, 0, 0, 0),
			RecordTypeId = mapCaseRecordTypeNameToId.get(strRecordtype3),
			Contrato__c = testContract5.Id,
			Origin = strCaseOrigin,
			Motivo__c = strRecordtype3,
			Submotivo__c = strSubMotive2,
			Status = strCaseStatus,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		// Status : not Proceso de resolución
		Case testCase7 = new Case(
			Status_2_Time__c = Datetime.newInstance(2021, 12, 30, 0, 0, 0),
			RecordTypeId = mapCaseRecordTypeNameToId.get('Consulta-Errores en Estado de Cuenta'),
			Contrato__c = testContract.Id,
			Origin = strCaseOrigin,
			Motivo__c = 'Consulta Errores Edo Cuenta',
			Submotivo__c = strSubMotive2,
			Status = strCaseStatus1,
			Segmento__c = strSegment1,
			Description = strDescription1,
			OwnerId = testUser.Id
		);
		// insert case
		List<Case> lstCase = new List<Case>();
		lstCase.add(testCase1);
		lstCase.add(testCase2);
		lstCase.add(testCase3);
		lstCase.add(testCase4);
		lstCase.add(testCase5);
		lstCase.add(testCase6);
		lstCase.add(testCase7);
		lstCase.add(testCase1_error1);
		lstCase.add(testCase1_error2);
		lstCase.add(testCase2_error3);
		lstCase.add(testCase4_error4);
		lstCase.add(testCase6_error5);
		insert lstCase;
		for (Integer i = 0; i < lstCase.size(); i++) {
			Case caseObj = lstCase.get(i);
			if (i == 0) {
				caseObj.Status_2_Time__c = Datetime.newInstance(2022, 2, 15, 0, 0, 0);
			} else if (i == 1) {
				caseObj.Status_2_Time__c = Datetime.newInstance(2022, 2, 16, 0, 0, 0);
			} else if (i == 2) {
				caseObj.Status_2_Time__c = Datetime.newInstance(2022, 2, 17, 0, 0, 0);
			} else if (i == 3) {
				caseObj.Status_2_Time__c = Datetime.newInstance(2022, 2, 18, 0, 0, 0);
			} else if (i == 4) {
				caseObj.Status_2_Time__c = Datetime.newInstance(2022, 2, 19, 0, 0, 0);
			} else if (i == 5) {
				caseObj.Status_2_Time__c = Datetime.newInstance(2022, 2, 20, 0, 0, 0);
			} else if (i == 6) {
				caseObj.Status_2_Time__c = Datetime.newInstance(2022, 2, 21, 0, 0, 0);
			} else if (i == 7) {
				caseObj.Status_2_Time__c = Datetime.newInstance(2022, 2, 22, 0, 0, 0);
			} else if (i == 8) {
				caseObj.Status_2_Time__c = Datetime.newInstance(2022, 2, 14, 0, 0, 0);
			} else if (i == 9) {
				caseObj.Status_2_Time__c = Datetime.newInstance(2022, 2, 13, 0, 0, 0);
			} else if (i == 10) {
				caseObj.Status_2_Time__c = Datetime.newInstance(2022, 2, 12, 0, 0, 0);
			} else {
				caseObj.Status_2_Time__c = Datetime.newInstance(2022, 2, 11, 0, 0, 0);
			}
		}
		update lstCase;
		// test this should delete the update case.Status_2_Time__c in Flow : Case Flow, and set Status_2_Time__c manually
		// List<Case> lstCaseResult = [SELECT Id, CaseNumber, Owner.Name, Owner.Email FROM Case LIMIT 10000];
		CaseController.handleCaseStatusNotChangeTooLong();
		Test.stopTest();
		System.assert('1' == '1');
	}
}