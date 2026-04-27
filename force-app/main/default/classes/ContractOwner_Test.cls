@isTest
public with sharing class ContractOwner_Test {
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
			User.ProfileId => adminProfileId
		};
		UtilitiesDataTest.createUser(mapFields);
	}

	@isTest
	static void testChangeOwner() {
		User admin = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ADMIN'];
		final String adminProfileId = [SELECT Id FROM Profile WHERE name IN ('System Administrator', 'Administrador del sistema')].Id;
		System.runAs(admin) {
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
			List<Contract> contractsToInsert = UtilitiesDataTest.createContracts(CONTRACTS_TO_CREATE, null);
			for (Contract contract : contractsToInsert) {
				contract.ID_ASESOR__c = '0001';
			}
			insert contractsToInsert;
			List<Contract> contractsToInsert2 = UtilitiesDataTest.createContracts(CONTRACTS_TO_CREATE, null);
			for (Contract contract : contractsToInsert2) {
				contract.ID_ASESOR__c = '0002';
			}
			insert contractsToInsert2;
			List<Contract> contractsToInsert3 = UtilitiesDataTest.createContracts(CONTRACTS_TO_CREATE, null);
			for (Contract contract : contractsToInsert3) {
				contract.ID_ASESOR__c = '0003';
			}
			insert contractsToInsert3;
			for (Contract contract : contractsToInsert) {
				contract.OwnerId = admin.Id;
			}
			update contractsToInsert;
			for (Contract contract : contractsToInsert2) {
				contract.OwnerId = admin.Id;
			}
			update contractsToInsert2;
			for (Contract contract : contractsToInsert3) {
				contract.OwnerId = admin.Id;
			}
			update contractsToInsert3;
			List<Contract> insertedContracts = [SELECT id, OwnerId, Owner.Name, Owner.ID_ASESOR__c, ID_ASESOR__c FROM Contract];
			System.assertEquals(30, insertedContracts.size());
			for (Contract contractToCheck : insertedContracts) {
				System.assertEquals(admin.Id, contractToCheck.OwnerId);
			}
			Test.startTest();
			ContractOwner_Batch changeBatch = new ContractOwner_Batch();
			id jobId = Database.executeBatch(changeBatch);
			Test.stopTest();
			List<Contract> insertedContractsAsesor1 = [
				SELECT id, OwnerId, ID_ASESOR__c
				FROM Contract
				WHERE ID_ASESOR__c = :ASESOR1.ID_ASESOR__c AND OwnerId = :ASESOR1.Id
			];
			System.assertEquals(CONTRACTS_TO_CREATE, insertedContractsAsesor1.size());
			List<Contract> insertedContractsAsesor2 = [
				SELECT id, OwnerId, ID_ASESOR__c
				FROM Contract
				WHERE ID_ASESOR__c = :ASESOR2.ID_ASESOR__c AND OwnerId = :ASESOR2.Id
			];
			System.assertEquals(CONTRACTS_TO_CREATE, insertedContractsAsesor2.size());
			List<Contract> insertedContractsAsesor3 = [
				SELECT id, OwnerId, Owner.Name, ID_ASESOR__c
				FROM Contract
				WHERE ID_ASESOR__c = '0003'
			];
			System.assertEquals(CONTRACTS_TO_CREATE, insertedContractsAsesor3.size());
			for (Contract contractAsesor : insertedContractsAsesor3) {
				System.assertEquals(DEFAULT_OWNER, contractAsesor.Owner.Name);
				System.assertEquals('0003', contractAsesor.ID_ASESOR__c);
			}
		}
	}
}