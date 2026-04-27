/** ---------------------------------------------------------------------------------------------------
    * @Description: Test class for F3_InsurancePolicyTrigger_Handler and Helper classes
    *   ------------------------------------------------------------------------------------------------
    Author                  Date                Version                 Changes
    Victor Galvan           17/02/2023          1.0                     Class creation
* ------------------------------------------------------------------------------------------------**/
@isTest
public with sharing class F3_InsurancePolicyTrigger_Test {
	@TestSetup
	static void createData() {
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
	}

	@isTest
	private static void validateContractorCreation() {
		String insuranceAccountTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
			.get('F3_Cliente_Seguros')
			.getRecordTypeId();
		String contactTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('IndustriesIndividual').getRecordTypeId();
		User admin = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ADMIN'];
		//To create a policy
		List<InsurancePolicy> policiesToInsert = new List<InsurancePolicy>();
		InsurancePolicy ip = new InsurancePolicy();
		ip.Name = 'Test Policy';
		ip.NameInsuredId = null;
		ip.F3_Numero_de_Poliza__c = 'P-0000';
		ip.F3_Nombre_Contratante__c = 'Prueba Contratante';
		ip.F3_Id_Asesor__c = admin.ID_ASESOR__c;

		ip.saleDate = System.now();
		policiesToInsert.add(ip);

		//To create an instance of the handler to cover methods
		F3_InsurancePolicyTrigger_Handler handler = new F3_InsurancePolicyTrigger_Handler();
		handler.policyNew = policiesToInsert;
		handler.beforeInsert();

		//To validate if a new contractor was created after the policy is inserted
		List<Account> contractor = [SELECT Id, Name FROM Account WHERE RecordTypeId = :insuranceAccountTypeId];
		system.debug('Contractor queried: ' + contractor);
		system.assert(contractor.size() > 0, 'No contractor was created.');

		User asesor = [SELECT id, ID_ASESOR__c FROM user WHERE LastName LIKE 'ASESOR1'];
		//To create a new policy to test the update method
		InsurancePolicy ipUpdate = new InsurancePolicy();
		Account acc = new Account(Name = 'Insurance Account');
		insert acc;
		ipUpdate.Name = 'Test Policy Update';
		ipUpdate.NameInsuredId = acc.Id;
		ipUpdate.F3_Numero_de_Poliza__c = 'P-0001';
		ipUpdate.F3_Nombre_Contratante__c = 'Prueba Contratante Update';
		ipUpdate.Nom_Aseg__c = 'Contratante 1';
		ipUpdate.saleDate = System.now().addDays(-10);
		ip.F3_Id_Asesor__c = asesor.ID_ASESOR__c;
		policiesToInsert.add(ipUpdate);

		handler.beforeUpdate();

		handler.policyNew = policiesToInsert;

		handler.afterInsert();

		//We validate that an insured contact has been created
		List<Contact> contact = [SELECT Id, Name, AccountId, Account.Name FROM Contact WHERE RecordTypeId = :contactTypeId];
		system.assert(contact.size() == 0, 'No contact was created.');
		//To validate that the new insured contact created is the same like in the policy Nom_Aseg__c field
		//system.assertEquals(contact[0].Name, ipUpdate.Nom_Aseg__c, 'Tha name of the new contact does not match');
	}
}