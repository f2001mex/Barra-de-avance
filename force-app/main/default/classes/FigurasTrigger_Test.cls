@isTest
public with sharing class FigurasTrigger_Test {
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final integer that contains the number of contracts to create
	 * ------------------------------------------------------------------------------------------------**/
	static final Integer CONTRACTS_TO_CREATE = 2;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final integer that contains the number of FIGURAS_PER_CONTRACT to create
	 * ------------------------------------------------------------------------------------------------**/
	static final Integer FIGURAS_PER_CONTRACT = 100;
	/**
	 * --------------------------------------------------------------------------------------
	 * @Description Setup method for FigurasTrigger_Test
	 * --------------------------------------------------------------------------------------
	 * @Author   luis.felipe.ortiz@pwc.com
	 * @Date     Created: 18/03/2022
	 * @param
	 * @return void
	 * --------------------------------------------------------------------------------------
	 **/
	@TestSetup
	static void setup() {
		final String adminProfileId = [SELECT Id FROM Profile WHERE name IN ('System Administrator', 'Administrador del sistema')].Id;
		final Map<Schema.SObjectField, Object> mapFields = new Map<Schema.SObjectField, Object>{
			User.LastName => 'ADMIN',
			User.ProfileId => adminProfileId
		};
		UtilitiesDataTest.createUser(mapFields);
	}
	/**
	 * --------------------------------------------------------------------------------------
	 * @Description Test method that checks if the name is effectively trim to only 80 characters based on the fullname__c
	 * --------------------------------------------------------------------------------------
	 * @Author   luis.felipe.ortiz@pwc.com
	 * @Date     Created: 18/03/2022
	 * @param
	 * @return void
	 * --------------------------------------------------------------------------------------
	 **/
	@isTest
	public static void trimNameInsert() {
		final User ADMIN = [SELECT id FROM user WHERE LastName LIKE 'ADMIN'];
		System.runAs(ADMIN) {
			Test.startTest();
			List<Figuras_Relacionadas__c> figurasToInsert = UtilitiesDataTest.createFigurasRelacionadas(
				FIGURAS_PER_CONTRACT,
				CONTRACTS_TO_CREATE
			);
			for (Figuras_Relacionadas__c figura : figurasToInsert) {
				figura.FullName__c = UtilitiesDataTest.generateRandomString(100);
			}
			insert figurasToInsert;
			update figurasToInsert;
			Test.stopTest();
			List<Figuras_Relacionadas__c> figurasInserted = [SELECT Name, FullName__c FROM Figuras_Relacionadas__c];
			for (Figuras_Relacionadas__c figura : figurasInserted) {
				System.assertEquals(figura.FullName__c.substring(0, 80), figura.Name);
			}
		}
	}
	/**
	 * --------------------------------------------------------------------------------------
	 * @Description Test method that checks if an error is effectively being raised if there's
	 * no full name for the record and if the error is not truncating the trigger batch
	 * --------------------------------------------------------------------------------------
	 * @Author   luis.felipe.ortiz@pwc.com
	 * @Date     Created: 18/03/2022
	 * @param
	 * @return void
	 * --------------------------------------------------------------------------------------
	 **/
	@isTest
	public static void figurasNoName() {
		final User ADMIN = [SELECT id FROM user WHERE LastName LIKE 'ADMIN'];
		System.runAs(ADMIN) {
			Test.startTest();
			List<Figuras_Relacionadas__c> figurasToInsert = UtilitiesDataTest.createFigurasRelacionadas(
				FIGURAS_PER_CONTRACT,
				CONTRACTS_TO_CREATE
			);
			Integer counter = 0;
			for (Figuras_Relacionadas__c figura : figurasToInsert) {
				counter++;
				figura.FullName__c = counter > FIGURAS_PER_CONTRACT ? UtilitiesDataTest.generateRandomString(100) : null;
			}
			Database.SaveResult[] sr = Database.insert(figurasToInsert, false);
			Test.stopTest();
			Integer errorsGenerated = 0;
			for (Database.SaveResult result : sr) {
				if (!result.isSuccess()) {
					errorsGenerated++;
				}
			}
			System.assertEquals(FIGURAS_PER_CONTRACT, errorsGenerated);
			List<Figuras_Relacionadas__c> figurasInserted = [SELECT Name, FullName__c FROM Figuras_Relacionadas__c];
			System.assertEquals(FIGURAS_PER_CONTRACT, figurasInserted.size());
			for (Figuras_Relacionadas__c figura : figurasInserted) {
				System.assertEquals(figura.FullName__c.substring(0, 80), figura.Name);
			}
		}
	}
}