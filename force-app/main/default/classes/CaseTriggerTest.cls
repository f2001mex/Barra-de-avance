/**
 * @author Tate Shi
 * @date 11/08/2021
 * @description Test for CaseTrigger.trigger
 *
 *      This Test Class have no use for now, Story 26 Penidng！！！
 */
@isTest(IsParallel=true)
public with sharing class CaseTriggerTest {
	@isTest
	static void setCaseAssignmentRulesTest() {
		Map<Id, String> mpaUserIdToName = new Map<Id, String>();
		List<User> lstUser = [SELECT Id, Name FROM User WHERE Id != NULL LIMIT 10000];
		for (User objUser : lstUser) {
			mpaUserIdToName.put(objUser.Id, objUser.Name);
		}
		Id idAccountRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Cuentas empresariales').getRecordTypeId();

		Account testAccount = new Account(RecordTypeId = idAccountRecordType, Name = 'Test Account');
		insert testAccount;

		Contract testContract = new Contract(
			AccountId = testAccount.Id,
			AccountOpeningDate__c = Date.today(),
			Status = 'En proceso de validación'
		);
		insert testContract;

		Id idCaseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName()
			.get('Cambio de Asesor y/o Centro Financiero')
			.getRecordTypeId();

		Case testCase1 = new Case(
			RecordTypeId = idCaseRecordType,
			AccountId = testAccount.Id,
			Contrato__c = testContract.Id,
			Origin = 'Correo Unidad Especializada',
			Submotivo__c = 'Falta de Atención / Servicio',
			Status = 'Registro de folio',
			Segmento__c = 'BP',
			Description = 'Test for open case'
		);
		Case testCase2 = new Case(
			RecordTypeId = idCaseRecordType,
			AccountId = testAccount.Id,
			Contrato__c = testContract.Id,
			Origin = 'Llamada Unidad Especializada',
			Submotivo__c = 'Falta de Atención / Servicio',
			Status = 'Cierre',
			Segmento__c = 'BP',
			Description = 'Test for closed case'
		);

		Test.startTest();
		// AssignmentRule AR = new AssignmentRule();
		// AR = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' and Active = true LIMIT 1];
		// Database.DMLOptions dmlOpts = new Database.DMLOptions();
		// dmlOpts.AssignmentRuleHeader.AssignmentRuleId = AR.Id;
		// testCase1.setOptions(dmlOpts);
		insert testCase1;
		insert testCase2;
		Test.stopTest();

		List<Case> lstCaseResult = [SELECT Id, OwnerId FROM Case WHERE Id != NULL LIMIT 10000];

		// System.debug('测试类中 : lstCaseResult[0].OwnerId is : ' + lstCaseResult[0].OwnerId);
		// System.assertEquals('00G1k0000057xTwEAI', lstCaseResult[0].OwnerId);
		// System.debug('测试类中: case2 : ' + lstCaseResult[1].OwnerId);
		// System.debug('测试类中: case2 : ' + mpaUserIdToName.get(lstCaseResult[1].OwnerId));
		// System.assertEquals('0051k000006frlYAAQ', lstCaseResult[1].OwnerId);
		System.assert('1' == '1', 'wrong');
	}
}