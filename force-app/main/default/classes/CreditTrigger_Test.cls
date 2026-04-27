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
public with sharing class CreditTrigger_Test {
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final integer that contains the number of contracts to create
	 * ------------------------------------------------------------------------------------------------**/
	static final Integer CREDITS_TO_CREATE = 10;
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
		final User DEFAULT_OWNER_ID = [SELECT id FROM user WHERE LastName LIKE :DEFAULT_OWNER];
		System.runAs(admin) {
			List<Credito__c> creditsToInsert = UtilitiesDataTest.createCredits(CREDITS_TO_CREATE, null);
			Test.startTest();
			insert creditsToInsert;
			Test.stopTest();
			List<Credito__c> insertedCredits = [SELECT ID, OwnerId FROM Credito__c];
			for (Credito__c credit : insertedCredits) {
				System.assertEquals(DEFAULT_OWNER_ID.Id, credit.OwnerId);
			}
			System.assert(insertedCredits.size() == CREDITS_TO_CREATE);
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
			List<Credito__c> creditsToInsert = UtilitiesDataTest.createCredits(CREDITS_TO_CREATE, null);
			for (Credito__c credit : creditsToInsert) {
				credit.NUM_ASESOR__c = admin.ID_ASESOR__c;
			}
			Test.startTest();
			insert creditsToInsert;
			Test.stopTest();
			List<Credito__c> insertedCredits = [SELECT ID, Owner.name FROM Credito__c];
			for (Credito__c credit : insertedCredits) {
				System.assertEquals(admin.id, credit.OwnerId);
			}
			System.assert(insertedCredits.size() == CREDITS_TO_CREATE);
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
		final User DEFAULT_OWNER_ID = [SELECT id FROM user WHERE LastName LIKE :DEFAULT_OWNER];
		System.runAs(admin) {
			List<Credito__c> creditsToInsert = UtilitiesDataTest.createCredits(CREDITS_TO_CREATE, null);
			for (Credito__c credit : creditsToInsert) {
				credit.NUM_ASESOR__c = '0002';
			}
			Test.startTest();
			insert creditsToInsert;
			Test.stopTest();
			List<Credito__c> insertedCredits = [SELECT ID, Owner.name, OwnerId FROM Credito__c];
			System.debug(JSON.serializePretty(insertedCredits));
			for (Credito__c credit : insertedCredits) {
				System.assertEquals(DEFAULT_OWNER_ID.id, credit.OwnerId);
			}
			System.assert(insertedCredits.size() == CREDITS_TO_CREATE);
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
	static void testUpdateGivenOwner() {
		User admin = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ADMIN'];
		System.runAs(admin) {
			List<Credito__c> creditsToInsert = UtilitiesDataTest.createCredits(CREDITS_TO_CREATE, null);
			for (Credito__c credit : creditsToInsert) {
				credit.NUM_ASESOR__c = '0002';
			}
			Test.startTest();
			insert creditsToInsert;
			for (Credito__c credit : creditsToInsert) {
				credit.NUM_ASESOR__c = admin.ID_ASESOR__c;
			}
			update creditsToInsert;
			Test.stopTest();
			List<Credito__c> updatedCredits = [SELECT ID, Owner.name FROM Credito__c];
			for (Credito__c credit : updatedCredits) {
				System.assertEquals(admin.id, credit.OwnerId);
			}
			System.assert(updatedCredits.size() == CREDITS_TO_CREATE);
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
		User admin = [SELECT id, ID_ASESOR__c FROM user WHERE email LIKE '%user@u.com.u'];
		System.runAs(admin) {
			try {
				CreditTrigger_Helper creditHelper = new CreditTrigger_Helper();
			} catch (Exception e) {
				System.assert(e.getMessage().contains('Method is not visible'));
			}
		}
	}
}