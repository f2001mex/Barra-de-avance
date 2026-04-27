/** ---------------------------------------------------------------------------------------------------
    * @Description: Test class for F3_Policy_Batch class
    *   ------------------------------------------------------------------------------------------------
    Author                  Date                Version                 Changes
    Victor Galvan           09/02/2023          1.0                     Class creation
* ------------------------------------------------------------------------------------------------**/
@isTest(IsParallel=true)
public with sharing class F3_Policy_Batch_Test {
	@TestSetup
	static void createData() {
		Account insuranceAccount = new Account();
		insuranceAccount.Name = 'Test Account';
		insert insuranceAccount;

		InsurancePolicy ip0 = new InsurancePolicy();
		ip0.Name = 'P-0000';
		ip0.NameInsuredId = insuranceAccount.Id;
		ip0.UniversalPolicyNumber = 'P-0000';
		ip0.SaleDate = System.today();
		insert ip0;

		InsurancePolicy ip1 = new InsurancePolicy();
		ip1.Name = 'P-0001';
		ip1.NameInsuredId = insuranceAccount.Id;
		ip1.UniversalPolicyNumber = 'P-0001';
		ip1.F3_Poliza_Anterior__c = 'P-0000';
		ip1.SaleDate = System.today();
		insert ip1;
	}

	@IsTest
	static void validatePreviousPolicy() {
		Test.startTest();
		F3_Policy_Batch_Schedulable exec = new F3_Policy_Batch_Schedulable();
		exec.execute(null);
		Test.stopTest();

		InsurancePolicy ip0 = [SELECT Id, Name, PriorPolicyId FROM InsurancePolicy WHERE Name = 'P-0000'][0];
		InsurancePolicy ip1 = [SELECT Id, Name, PriorPolicyId FROM InsurancePolicy WHERE Name = 'P-0001'][0];
		System.assertEquals(ip0.Id, ip1.PriorPolicyId, 'Previous policy does not match');
	}
}