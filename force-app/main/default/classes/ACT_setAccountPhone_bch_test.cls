/********************************************************************************** 
  Name: ACT_setAccountPhone_bch_test
  Description: Unit Test class for Apex Class ACT_setAccountPhone_bch
  ===================================================================================
  Information about changes (versions)
  ===================================================================================
  Version   Date                Author            Detail      Description
  1.0       2022-03-01          Antonio Gervacio  Creation    Creation
***********************************************************************************/
@isTest(IsParallel=true)
public class ACT_setAccountPhone_bch_test {
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

		Telefono_de_Contrato__c phoneOne = new Telefono_de_Contrato__c(
			IDSap__c = contractOne.Id,
			Phone__c = '5215533484002',
			MainFlag__c = 'X'
		);
		insert phoneOne;

		Telefono_de_Contrato__c phoneTwo = new Telefono_de_Contrato__c(
			IDSap__c = contractTwo.Id,
			Phone__c = '52155334840035215533484003521553348400',
			MainFlag__c = 'X'
		);
		insert phoneTwo;

		Test.startTest();
		Database.executeBatch(new ACT_setAccountPhone_bch());
		Test.stopTest();
	}
}