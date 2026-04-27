@isTest
public with sharing class ContractChangeOwner_Test {
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final integer that contains the number of contracts to create
	 * ------------------------------------------------------------------------------------------------**/
	static final Integer CONTRACTS_TO_CREATE = 2;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final integer that contains the number of contracts to create
	 * ------------------------------------------------------------------------------------------------**/
	static final Integer ACCOUNTS_TO_CREATE = 1;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final String that contains the value of the name field of the default owner
	 * ------------------------------------------------------------------------------------------------**/
	static final String DEFAULT_OWNER = 'IntegrationUser';
	/**
	 * --------------------------------------------------------------------------------------
	 * @Description Setup method for ContractTrigger_Test
	 * --------------------------------------------------------------------------------------
	 * @Author   luis.felipe.ortiz@pwc.com
	 * @Date     Created: 03/11/2021
	 * @param
	 * @return void
	 * --------------------------------------------------------------------------------------
	 **/
	@TestSetup
	public static void setup() {
		final String adminProfileId = [SELECT Id FROM Profile WHERE name IN ('System Administrator', 'Administrador del sistema')].Id;
		final Map<Schema.SObjectField, Object> mapFields = new Map<Schema.SObjectField, Object>{
			User.LastName => 'ADMIN',
			User.ProfileId => adminProfileId,
			User.ID_ASESOR__c => ''
		};
		User Admin = UtilitiesDataTest.createUser(mapFields);
		final Map<Schema.SObjectField, Object> mapFields01 = new Map<Schema.SObjectField, Object>{
			User.LastName => 'ASESOR1',
			User.ProfileId => adminProfileId,
			User.ID_ASESOR__c => '0001'
		};
		User ASESOR1 = UtilitiesDataTest.createUser(mapFields01);
		final Map<Schema.SObjectField, Object> mapFields02 = new Map<Schema.SObjectField, Object>{
			User.LastName => 'ASESOR2',
			User.ProfileId => adminProfileId,
			User.ID_ASESOR__c => '0002'
		};
		User ASESOR2 = UtilitiesDataTest.createUser(mapFields02);
		System.runAs(admin) {
		}
	}
	/**
    * --------------------------------------------------------------------------------------
    * @Description Test method: checks that if no given "ID_ASESOR" the owner of the contract
                   goes to the default user.
    * --------------------------------------------------------------------------------------
    * @Author   luis.felipe.ortiz@pwc.com
    * @Date     Created: 03/11/2021
    * @param 
    * @return void
    * --------------------------------------------------------------------------------------
    **/
	@isTest
	static void testMoreThan1User() {
		User admin = [SELECT id FROM user WHERE LastName LIKE 'ADMIN'];
		User ASESOR1 = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ASESOR1'];
		User ASESOR2 = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ASESOR2'];
		System.runAs(admin) {
			Map<String, List<SObject>> contractsMoreThan1User = UtilitiesDataTest.createAccountContracts(
				ACCOUNTS_TO_CREATE,
				CONTRACTS_TO_CREATE,
				null,
				null
			);
			List<Contract> contractsList = contractsMoreThan1User.get('Contract');
			for (Integer i = 0; i < contractsList.size(); i++) {
				contractsList[i].ID_ASESOR__c = i < CONTRACTS_TO_CREATE / 2 ? ASESOR1.ID_ASESOR__c : ASESOR2.ID_ASESOR__c;
			}
			insert contractsList;
			Test.startTest();
			ContractChangeOwner_Batch changeBatch = new ContractChangeOwner_Batch();
			id jobId = Database.executeBatch(changeBatch);
			Test.stopTest();
			List<Account> defaultUserAccounts = [SELECT Id FROM Account WHERE Owner.Name = :DEFAULT_OWNER];
			List<Contract> asesor1Contracts = [SELECT Id FROM Contract WHERE OwnerId = :ASESOR1.Id];
			List<Contract> asesor2Contracts = [SELECT Id FROM Contract WHERE OwnerId = :ASESOR2.Id];
			List<Contract> allContracts = [SELECT Id, OwnerId FROM Contract];
			System.assertEquals(ACCOUNTS_TO_CREATE, defaultUserAccounts.size());
			System.assertEquals(CONTRACTS_TO_CREATE / 2, asesor1Contracts.size());
			System.assertEquals(CONTRACTS_TO_CREATE / 2, asesor2Contracts.size());
			Set<Id> asesores = new Set<Id>();
			for (Contract contract : allContracts) {
				asesores.add(contract.OwnerId);
			}
			System.assertEquals(2, asesores.size());
		}
	}

	@isTest
	static void testOnlyOneUser() {
		User admin = [SELECT id FROM user WHERE LastName LIKE 'ADMIN'];
		User ASESOR1 = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ASESOR1'];
		System.runAs(admin) {
			final Map<Schema.SObjectField, Object> contractFields = new Map<Schema.SObjectField, Object>{
				Contract.ID_ASESOR__c => ASESOR1.ID_ASESOR__c
			};
			Map<String, List<SObject>> contractsOnly1User = UtilitiesDataTest.createAccountContracts(
				ACCOUNTS_TO_CREATE,
				CONTRACTS_TO_CREATE,
				null,
				contractFields
			);
			insert contractsOnly1User.get('Contract');
			Test.startTest();
			ContractChangeOwner_Batch changeBatch = new ContractChangeOwner_Batch();
			id jobId = Database.executeBatch(changeBatch);
			Test.stopTest();
			List<Account> rightIdAccounts = [SELECT Id FROM Account WHERE OwnerId = :ASESOR1.Id];
			List<Contract> rightIdContracts = [SELECT Id FROM Contract WHERE OwnerId = :ASESOR1.Id];
			List<Contract> allContracts = [SELECT Id, OwnerId FROM Contract];
			System.assertEquals(ACCOUNTS_TO_CREATE, rightIdAccounts.size());
			System.assertEquals(CONTRACTS_TO_CREATE, rightIdContracts.size());
			Set<Id> asesores = new Set<Id>();
			for (Contract contract : allContracts) {
				asesores.add(contract.OwnerId);
			}
			System.assertEquals(1, asesores.size());
		}
	}
}