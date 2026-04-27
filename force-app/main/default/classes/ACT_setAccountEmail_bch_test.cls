/********************************************************************************** 
  Name: ACT_setAccountEmail_bch_test
  Description: Unit Test class for Apex Class ACT_setAccountEmail_bch
  ===================================================================================
  Information about changes (versions)
  ===================================================================================
  Version   Date                Author            Detail      Description
  1.0       2022-02-28          Antonio Gervacio  Creation    Creation
***********************************************************************************/
@isTest(IsParallel=true)
public class ACT_setAccountEmail_bch_test {
	@isTest
	static void testMethodOne() {
		Account acc = new Account(Name = 'Account Test');
		insert acc;

		Account personAcc = new Account(FirstName = 'Person Account', LastName = 'TEST');
		insert personAcc;

		Contract contractOne = new Contract(AccountId = acc.Id, AccountOpeningDate__c = System.today());
		insert contractOne;

		Contract contractTwo = new Contract(AccountId = personAcc.Id, AccountOpeningDate__c = System.today());
		insert contractTwo;

		Correo_de_Contrato__c emailOne = new Correo_de_Contrato__c(
			NUM_CONTRATO__c = contractOne.Id,
			Contract_email__c = 'test@test.com',
			MainFlag__c = 'X'
		);
		insert emailOne;

		Correo_de_Contrato__c emailTwo = new Correo_de_Contrato__c(
			NUM_CONTRATO__c = contractTwo.Id,
			Contract_email__c = 'test@test.com',
			MainFlag__c = 'X'
		);
		insert emailTwo;

		Test.startTest();
		Database.executeBatch(new ACT_setAccountEmail_bch());
		Test.stopTest();
	}
}