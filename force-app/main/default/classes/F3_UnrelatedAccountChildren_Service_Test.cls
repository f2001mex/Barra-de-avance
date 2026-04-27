/** ---------------------------------------------------------------------------------------------------
    * @Description: Test class for F3_UnrelatedAccountChildren_Service class
    *   ------------------------------------------------------------------------------------------------
    Author                  Date                Version                 Changes
    Victor Galvan           21/02/2023          1.0                     Class creation
* ------------------------------------------------------------------------------------------------**/
@isTest(IsParallel=true)
public with sharing class F3_UnrelatedAccountChildren_Service_Test {
	@TestSetup
	static void createData() {
		List<Opportunity> listOpportunity = new List<Opportunity>();
		List<Account> listAccount = new List<Account>();
		String oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Financiamiento').getRecordTypeId();
		String leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Seguros_Prospecto').getRecordTypeId();

		Account acc = new Account();
		acc.Name = 'Test Account 1';
		listAccount.add(acc);
		insert listAccount;

		Opportunity op = new Opportunity();
		op.Name = 'Test Opportunity';
		op.AccountId = acc.Id;
		op.StageName = 'Formalización y Validación';
		op.RecordTypeId = oppRecordTypeId;
		op.ContractId = null;
		op.F3_Credito_Relacionado__c = null;
		op.CloseDate = Date.today();
		listOpportunity.add(op);

		Opportunity op1 = new Opportunity();
		op1.Name = 'Test Opportunity 2';
		op1.AccountId = acc.Id;
		op1.StageName = 'Formalización y Validación';
		op1.RecordTypeId = oppRecordTypeId;
		op1.ContractId = null;
		op1.F3_Credito_Relacionado__c = null;
		op1.CloseDate = Date.today();
		listOpportunity.add(op1);

		insert listOpportunity;

		Lead l = new Lead();
		l.FirstName = 'Test Lead';
		l.LastName = 'LastName';
		l.RecordTypeId = leadRecordTypeId;
		l.F3_RFC__c = 'RFC090803781';
		l.Status = 'Formalización y Validación';
		l.PostalCode = '20000';
		insert l;
	}

	@isTest
	private static void validateUnrelatedAccountOps() {
		List<Account> listAcc = [SELECT Id, Name FROM Account];
		List<Id> accIds = new List<Id>();
		for (Account a : listAcc) {
			accIds.add(a.id);
		}
		List<Opportunity> listOpp = F3_UnrelatedAccountChildren_Service.getUnrelatedAccountOpps(accIds);
		system.assert(listOpp.size() > 0, 'Opportunity List is empty');
	}

	@isTest
	private static void validateUnrelatedAccountLeads() {
		List<Lead> listLead = F3_UnrelatedAccountChildren_Service.getUnrelatedAccountLeads('RFC090803781');
		system.assert(listLead.size() > 0, 'Lead List is empty');
	}
}