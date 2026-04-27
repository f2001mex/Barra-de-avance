/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     ContractTrigger_test
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 03/11/2021
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description test class for the classes involved in the contract trigger
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 03/11/2021 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
@isTest
public with sharing class ContractTrigger_Test {
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final integer that contains the number of contracts to create
	 * ------------------------------------------------------------------------------------------------**/
	static final Integer CONTRACTS_TO_CREATE = 10;
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
			User.ID_ASESOR__c => '0000'
		};
		UtilitiesDataTest.createUser(mapFields);
		final Map<Schema.SObjectField, Object> mapFields01 = new Map<Schema.SObjectField, Object>{
			User.LastName => 'ASESOR1',
			User.ProfileId => adminProfileId,
			User.ID_ASESOR__c => '0001'
		};
		UtilitiesDataTest.createUser(mapFields01);
		final Map<Schema.SObjectField, Object> mapFields02 = new Map<Schema.SObjectField, Object>{
			User.LastName => 'ASESOR2',
			User.ProfileId => adminProfileId,
			User.ID_ASESOR__c => '0002'
		};
		UtilitiesDataTest.createUser(mapFields02);
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
	static void testInsertDefaultOwner() {
		User admin = [SELECT id FROM user WHERE LastName LIKE 'ADMIN'];
		System.runAs(admin) {
			List<Contract> contractsToInsert = UtilitiesDataTest.createContracts(CONTRACTS_TO_CREATE, null);
			Test.startTest();
			insert contractsToInsert;
			Test.stopTest();
			List<Contract> insertedContracts = [SELECT ID, Owner.name FROM Contract WHERE Id != NULL LIMIT 10000];
			for (Contract contract : insertedContracts) {
				System.assertEquals(DEFAULT_OWNER, contract.Owner.Name);
			}
			System.assert(insertedContracts.size() == CONTRACTS_TO_CREATE);
		}
	}

	/**
    * --------------------------------------------------------------------------------------
    * @Description Test method: checks that if given an "ID_ASESOR" that exists on the org,  
                   the owner of the contract goes to the selected user.
    * --------------------------------------------------------------------------------------
    * @Author   luis.felipe.ortiz@pwc.com
    * @Date     Created: 03/11/2021
    * @param 
    * @return void
    * --------------------------------------------------------------------------------------
    **/
	@isTest
	static void testInsertGivenOwnerExist() {
		User admin = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ADMIN'];
		System.runAs(admin) {
			List<Contract> contractsToInsert = UtilitiesDataTest.createContracts(CONTRACTS_TO_CREATE, null);
			for (Contract contract : contractsToInsert) {
				contract.ID_ASESOR__c = admin.ID_ASESOR__c;
			}
			Test.startTest();
			insert contractsToInsert;
			Test.stopTest();
			List<Contract> insertedContracts = [SELECT ID, Owner.name FROM Contract WHERE Id != NULL LIMIT 10000];
			for (Contract contract : insertedContracts) {
				System.assertEquals(admin.id, contract.OwnerId);
			}
			System.assert(insertedContracts.size() == CONTRACTS_TO_CREATE);
		}
	}

	/**
    * --------------------------------------------------------------------------------------
    * @Description Test method: checks that if given an "ID_ASESOR" that doesn't exists on  
                   the org, the owner of the contract goes to the default user.
    * --------------------------------------------------------------------------------------
    * @Author   luis.felipe.ortiz@pwc.com
    * @Date     Created: 03/11/2021
    * @param 
    * @return void
    * --------------------------------------------------------------------------------------
    **/
	@isTest
	static void testInsertGivenOwnerNotExist() {
		User admin = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ADMIN'];
		System.runAs(admin) {
			List<Contract> contractsToInsert = UtilitiesDataTest.createContracts(CONTRACTS_TO_CREATE, null);
			for (Contract contract : contractsToInsert) {
				contract.ID_ASESOR__c = '0003';
			}
			Test.startTest();
			insert contractsToInsert;
			Test.stopTest();
			List<Contract> insertedContracts = [SELECT ID, Owner.name FROM Contract WHERE Id != NULL LIMIT 10000];
			for (Contract contract : insertedContracts) {
				System.assertEquals(DEFAULT_OWNER, contract.Owner.Name);
			}
			System.assert(insertedContracts.size() == CONTRACTS_TO_CREATE);
		}
	}
	/**
    * --------------------------------------------------------------------------------------
    * @Description Test method: checks that if given an "ID_ASESOR" that exists on the org,  
                   the owner of the contract goes to the selected user.
    * --------------------------------------------------------------------------------------
    * @Author   luis.felipe.ortiz@pwc.com
    * @Date     Created: 03/11/2021
    * @param 
    * @return void
    * --------------------------------------------------------------------------------------
    **/
	@isTest
	static void testUpdateGivenOwnerExist() {
		User admin = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ADMIN'];
		System.runAs(admin) {
			Map<Schema.SObjectField, Object> mapFields = new Map<Schema.SObjectField, Object>{ contract.ID_ASESOR__c => '0002' };
			List<Contract> contractsToInsert = UtilitiesDataTest.createContracts(CONTRACTS_TO_CREATE, mapFields);
			Test.startTest();
			insert contractsToInsert;
			for (Contract contract : contractsToInsert) {
				contract.ID_ASESOR__c = admin.ID_ASESOR__c;
			}
			update contractsToInsert;
			Test.stopTest();
			List<Contract> updatedContracts = [SELECT ID, Owner.name FROM Contract WHERE Id != NULL LIMIT 10000];
			for (Contract contract : updatedContracts) {
				System.assertEquals(admin.id, contract.OwnerId);
			}
			System.assert(updatedContracts.size() == CONTRACTS_TO_CREATE);
		}
	}

	/**
    * --------------------------------------------------------------------------------------
    * @Description Test method: checks that if given an "ID_ASESOR" that exists on the org,  
                   the owner of the contract goes to the selected user.
    * --------------------------------------------------------------------------------------
    * @Author   luis.felipe.ortiz@pwc.com
    * @Date     Created: 03/11/2021
    * @param 
    * @return void
    * --------------------------------------------------------------------------------------
    **/
	@isTest
	static void testUpdateGivenOwnerNotExist() {
		User admin = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ADMIN'];
		System.runAs(admin) {
			Map<Schema.SObjectField, Object> mapFields = new Map<Schema.SObjectField, Object>{ contract.ID_ASESOR__c => '0002' };
			List<Contract> contractsToInsert = UtilitiesDataTest.createContracts(CONTRACTS_TO_CREATE, mapFields);
			Test.startTest();
			insert contractsToInsert;
			for (Contract contract : contractsToInsert) {
				contract.ID_ASESOR__c = '0003';
			}
			update contractsToInsert;
			Test.stopTest();
			List<Contract> updatedContracts = [SELECT ID, Owner.name FROM Contract WHERE Id != NULL LIMIT 10000];
			for (Contract contract : updatedContracts) {
				System.assertEquals(DEFAULT_OWNER, contract.Owner.name);
			}
			System.assert(updatedContracts.size() == CONTRACTS_TO_CREATE);
		}
	}

	/**
	 * --------------------------------------------------------------------------------------
	 * @Description Test method: checks that the ContractTrigger_Helper can't be instantiated
	 * --------------------------------------------------------------------------------------
	 * @Author   luis.felipe.ortiz@pwc.com
	 * @Date     Created: 03/11/2021
	 * @param
	 * @return void
	 * --------------------------------------------------------------------------------------
	 **/
	@isTest
	static void testPrivateConstructor() {
		User admin = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ADMIN'];
		System.runAs(admin) {
			try {
				new ContractTrigger_Helper();
			} catch (Exception e) {
				System.assert(e.getMessage().contains('Method is not visible'));
			}
		}
	}

	@isTest
	static void testHighestSumMoreThanOneExecutive() {
		User admin = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ADMIN'];
		User ASESOR1 = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ASESOR1'];
		User ASESOR2 = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ASESOR2'];
		System.runAs(admin) {
			List<Contract> contractToInsert = UtilitiesDataTest.createContracts(CONTRACTS_TO_CREATE, null);
			Double grandTotal = 0;
			for (Integer i = 0; i < CONTRACTS_TO_CREATE; i++) {
				if (i < CONTRACTS_TO_CREATE / 2) {
					contractToInsert[i].Saldo__c = '1000';
					contractToInsert[i].ID_ASESOR__c = ASESOR1.ID_ASESOR__c;
					grandTotal = grandTotal + Double.valueOf(contractToInsert[i].Saldo__c);
				} else {
					contractToInsert[i].Saldo__c = '500';
					contractToInsert[i].ID_ASESOR__c = ASESOR2.ID_ASESOR__c;
					grandTotal = grandTotal + Double.valueOf(contractToInsert[i].Saldo__c);
				}
			}
			Test.startTest();
			insert contractToInsert;
			Account insertedAccount = [
				SELECT ID, OwnerId, F3_Posicion_Global__c, Mas_de_un_asesor__c
				FROM Account
				WHERE ID = :contractToInsert[0].AccountId
			];
			System.assertEquals(true, insertedAccount.Mas_de_un_asesor__c);
			System.assertEquals(ASESOR1.Id, insertedAccount.OwnerId);
			System.assertEquals(grandTotal, insertedAccount.F3_Posicion_Global__c);
			for (Contract contract : contractToInsert) {
				if (contract.ID_ASESOR__c == ASESOR2.ID_ASESOR__c) {
					contract.Saldo__c = '1500';
				}
			}
			update contractToInsert;
			Test.stopTest();
			grandTotal = 0;
			for (Contract contract : contractToInsert) {
				grandTotal = grandTotal + Double.valueOf(contract.Saldo__c);
			}
			insertedAccount = [
				SELECT ID, OwnerId, F3_Posicion_Global__c, Mas_de_un_asesor__c
				FROM Account
				WHERE ID = :contractToInsert[0].AccountId
			][0];
			System.assertEquals(true, insertedAccount.Mas_de_un_asesor__c);
			System.assertEquals(ASESOR2.Id, insertedAccount.OwnerId);
			System.assertEquals(grandTotal, insertedAccount.F3_Posicion_Global__c);
		}
	}

	@isTest
	static void testHighestSumOneExecutive() {
		User admin = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ADMIN'];
		User ASESOR1 = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ASESOR1'];
		System.runAs(admin) {
			List<Contract> contractToInsert = UtilitiesDataTest.createContracts(CONTRACTS_TO_CREATE, null);
			Double grandTotal = 0;
			for (Integer i = 0; i < CONTRACTS_TO_CREATE; i++) {
				contractToInsert[i].Saldo__c = '1000';
				contractToInsert[i].ID_ASESOR__c = ASESOR1.ID_ASESOR__c;
				grandTotal = grandTotal + Double.valueOf(contractToInsert[i].Saldo__c);
			}
			Test.startTest();
			insert contractToInsert;
			Account insertedAccount = [
				SELECT ID, OwnerId, F3_Posicion_Global__c, Mas_de_un_asesor__c
				FROM Account
				WHERE ID = :contractToInsert[0].AccountId
			];
			Test.stopTest();
			System.assertEquals(false, insertedAccount.Mas_de_un_asesor__c);
			System.assertEquals(grandTotal, insertedAccount.F3_Posicion_Global__c);
			System.assertEquals(ASESOR1.Id, insertedAccount.OwnerId);
		}
	}

	@isTest
	static void testHighestSumOneAndThenMoreExecutives() {
		User admin = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ADMIN'];
		User ASESOR1 = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ASESOR1'];
		User ASESOR2 = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ASESOR2'];
		System.runAs(admin) {
			List<Contract> contractToInsert = UtilitiesDataTest.createContracts(CONTRACTS_TO_CREATE, null);
			Double grandTotal = 0;
			for (Integer i = 0; i < CONTRACTS_TO_CREATE; i++) {
				contractToInsert[i].Saldo__c = '1000';
				contractToInsert[i].ID_ASESOR__c = ASESOR1.ID_ASESOR__c;
				grandTotal = grandTotal + Double.valueOf(contractToInsert[i].Saldo__c);
			}
			Test.startTest();
			insert contractToInsert;
			Account insertedAccount = [
				SELECT ID, OwnerId, F3_Posicion_Global__c, Mas_de_un_asesor__c
				FROM Account
				WHERE ID = :contractToInsert[0].AccountId
			];
			System.assertEquals(false, insertedAccount.Mas_de_un_asesor__c);
			System.assertEquals(ASESOR1.Id, insertedAccount.OwnerId);
			System.assertEquals(grandTotal, insertedAccount.F3_Posicion_Global__c);
			for (Integer i = 0; i < CONTRACTS_TO_CREATE; i++) {
				if (i < CONTRACTS_TO_CREATE / 2) {
					contractToInsert[i].Saldo__c = '500';
					contractToInsert[i].ID_ASESOR__c = ASESOR1.ID_ASESOR__c;
					grandTotal = grandTotal + Double.valueOf(contractToInsert[i].Saldo__c);
				} else {
					contractToInsert[i].Saldo__c = '1000';
					contractToInsert[i].ID_ASESOR__c = ASESOR2.ID_ASESOR__c;
					grandTotal = grandTotal + Double.valueOf(contractToInsert[i].Saldo__c);
				}
			}
			update contractToInsert;
			Test.stopTest();
			grandTotal = 0;
			for (Contract contract : contractToInsert) {
				grandTotal = grandTotal + Double.valueOf(contract.Saldo__c);
			}
			insertedAccount = [
				SELECT ID, OwnerId, F3_Posicion_Global__c, Mas_de_un_asesor__c
				FROM Account
				WHERE ID = :contractToInsert[0].AccountId
			][0];
			System.assertEquals(true, insertedAccount.Mas_de_un_asesor__c);
			System.assertEquals(ASESOR2.Id, insertedAccount.OwnerId);
			System.assertEquals(grandTotal, insertedAccount.F3_Posicion_Global__c);
		}
	}

	@isTest
	static void testHighestSumMoreAndThenOneExecutives() {
		User admin = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ADMIN'];
		User ASESOR1 = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ASESOR1'];
		User ASESOR2 = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ASESOR2'];
		System.runAs(admin) {
			List<Contract> contractToInsert = UtilitiesDataTest.createContracts(CONTRACTS_TO_CREATE, null);
			Double grandTotal = 0;
			for (Integer i = 0; i < CONTRACTS_TO_CREATE; i++) {
				if (i < CONTRACTS_TO_CREATE / 2) {
					contractToInsert[i].Saldo__c = '500';
					contractToInsert[i].ID_ASESOR__c = ASESOR1.ID_ASESOR__c;
					grandTotal = grandTotal + Double.valueOf(contractToInsert[i].Saldo__c);
				} else {
					contractToInsert[i].Saldo__c = '1000';
					contractToInsert[i].ID_ASESOR__c = ASESOR2.ID_ASESOR__c;
					grandTotal = grandTotal + Double.valueOf(contractToInsert[i].Saldo__c);
				}
			}
			Test.startTest();
			insert contractToInsert;
			Account insertedAccount = [
				SELECT ID, OwnerId, F3_Posicion_Global__c, Mas_de_un_asesor__c
				FROM Account
				WHERE ID = :contractToInsert[0].AccountId
			];
			System.assertEquals(true, insertedAccount.Mas_de_un_asesor__c);
			System.assertEquals(ASESOR2.Id, insertedAccount.OwnerId);
			System.assertEquals(grandTotal, insertedAccount.F3_Posicion_Global__c);
			for (Integer i = 0; i < CONTRACTS_TO_CREATE; i++) {
				contractToInsert[i].Saldo__c = '1000';
				contractToInsert[i].ID_ASESOR__c = ASESOR1.ID_ASESOR__c;
				grandTotal = grandTotal + Double.valueOf(contractToInsert[i].Saldo__c);
			}
			update contractToInsert;
			Test.stopTest();
			grandTotal = 0;
			for (Contract contract : contractToInsert) {
				grandTotal = grandTotal + Double.valueOf(contract.Saldo__c);
			}
			insertedAccount = [
				SELECT ID, OwnerId, F3_Posicion_Global__c, Mas_de_un_asesor__c
				FROM Account
				WHERE ID = :contractToInsert[0].AccountId
			][0];
			System.assertEquals(false, insertedAccount.Mas_de_un_asesor__c);
			System.assertEquals(ASESOR1.Id, insertedAccount.OwnerId);
			System.assertEquals(grandTotal, insertedAccount.F3_Posicion_Global__c);
		}
	}

	@isTest
	static void testHighestSumWithIntegrationUser() {
		User admin = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ADMIN'];
		User ASESOR2 = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ASESOR2'];
		System.runAs(admin) {
			List<Contract> contractToInsert = UtilitiesDataTest.createContracts(CONTRACTS_TO_CREATE, null);
			Double grandTotal = 0;
			for (Integer i = 0; i < CONTRACTS_TO_CREATE; i++) {
				if (i < CONTRACTS_TO_CREATE / 2) {
					contractToInsert[i].Saldo__c = '1000';
					contractToInsert[i].ID_ASESOR__c = '0003';
					grandTotal = grandTotal + Double.valueOf(contractToInsert[i].Saldo__c);
				} else {
					contractToInsert[i].Saldo__c = '500';
					contractToInsert[i].ID_ASESOR__c = ASESOR2.ID_ASESOR__c;
					grandTotal = grandTotal + Double.valueOf(contractToInsert[i].Saldo__c);
				}
			}
			Test.startTest();
			insert contractToInsert;
			Account insertedAccount = [
				SELECT ID, OwnerId, F3_Posicion_Global__c, Mas_de_un_asesor__c
				FROM Account
				WHERE ID = :contractToInsert[0].AccountId
			];
			System.assertEquals(true, insertedAccount.Mas_de_un_asesor__c);
			System.assertEquals(grandTotal, insertedAccount.F3_Posicion_Global__c);
			System.assertEquals(ASESOR2.Id, insertedAccount.OwnerId);
			List<Contract> updatedContracts = [SELECT ID, OwnerId, Owner.Name FROM Contract WHERE ID_ASESOR__c = '0003'];
			for (Contract updatedContract : updatedContracts) {
				System.assertEquals(DEFAULT_OWNER, updatedContract.Owner.Name);
			}
			List<Contract> updatedContracts2 = [SELECT ID, OwnerId, Owner.Name FROM Contract WHERE OwnerId = :ASESOR2.Id];
			for (Contract updatedContract : updatedContracts2) {
				System.assertEquals(ASESOR2.Id, updatedContract.OwnerId);
			}
			Test.stopTest();
		}
	}
}