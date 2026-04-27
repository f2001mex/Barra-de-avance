@isTest
public with sharing class opportunityRegion_Test {
	@TestSetup
	public static void setup() {
		UserRole role = new UserRole(DeveloperName = 'TestDivision', Name = 'Test Division');
		insert role;
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
			User.ID_ASESOR__c => '0001',
			User.UserRoleId => role.id
		};
		User ASESOR1 = UtilitiesDataTest.createUser(mapFields01);
		final Map<Schema.SObjectField, Object> mapFields02 = new Map<Schema.SObjectField, Object>{
			User.LastName => 'ASESOR2',
			User.ProfileId => adminProfileId,
			User.ID_ASESOR__c => '0002'
		};
		User ASESOR2 = UtilitiesDataTest.createUser(mapFields02);
		System.runAs(admin) {
			BranchUnit division = new BranchUnit(Name = 'Test division');
			insert division;
			BranchUnit region = new BranchUnit(Name = 'Test region', ParentBranchUnitId = division.id);
			insert region;
			BranchUnit branch = new BranchUnit(Name = 'Test branch', ParentBranchUnitId = region.id);
			insert branch;
			List<Banker> bankers = new List<Banker>{ new Banker(Name = 'Asesor 1', UserOrContactId = ASESOR1.id) };
			insert bankers;
			BranchUnitBusinessMember branchMember = new BranchUnitBusinessMember(
				BranchUnitId = branch.id,
				BusinessUnitMemberId = bankers[0].id
			);
			insert branchMember;
		}
	}

	@isTest
	static void ownerWithBranch() {
		User ASESOR1 = [SELECT id, ID_ASESOR__c, UserRole.Name FROM user WHERE LastName LIKE 'ASESOR1'];
		System.runAs(ASESOR1) {
			Account masterAccount = new Account(LastName = 'Prueba');
			insert masterAccount;
			Opportunity newOpportunity = new Opportunity();
			newOpportunity.Name = 'Test Opportunity';
			newOpportunity.AccountId = masterAccount.id;
			newOpportunity.StageName = 'Identificar Necesidades';
			newOpportunity.CloseDate = date.parse('09/10/2023');
			newOpportunity.OwnerId = ASESOR1.Id;
			insert newOpportunity;
			Test.startTest();
			id jobId = Database.executeBatch(new OpportunityRegion_Batch());
			Test.stopTest();
			List<Opportunity> updatedOpportunities = [
				SELECT id, Branch_Unit__r.Name, Regi_n__r.Name, Divisi_n__r.Name, OwnerId
				FROM opportunity
			];
			for (Opportunity opportunityToCheck : updatedOpportunities) {
				System.assertEquals(ASESOR1.Id, opportunityToCheck.OwnerId);
				System.assertEquals('Test branch', opportunityToCheck.Branch_Unit__r.Name);
				System.assertEquals('Test region', opportunityToCheck.Regi_n__r.Name);
				System.assertEquals('Test division', opportunityToCheck.Divisi_n__r.Name);
			}
		}
	}

	@isTest
	static void ownerWithoutBranch() {
		User ASESOR2 = [SELECT id, ID_ASESOR__c, UserRole.Name FROM user WHERE LastName LIKE 'ASESOR2'];
		System.runAs(ASESOR2) {
			Account masterAccount = new Account(LastName = 'Prueba');
			insert masterAccount;
			Opportunity newOpportunity = new Opportunity();
			newOpportunity.Name = 'Test Opportunity';
			newOpportunity.AccountId = masterAccount.id;
			newOpportunity.StageName = 'Identificar Necesidades';
			newOpportunity.CloseDate = date.parse('09/10/2023');
			newOpportunity.OwnerId = ASESOR2.Id;
			insert newOpportunity;
			Test.startTest();
			id jobId = Database.executeBatch(new OpportunityRegion_Batch());
			Test.stopTest();
			List<Opportunity> updatedOpportunities = [SELECT id, Branch_Unit__c, Regi_n__c, Divisi_n__c, OwnerId FROM opportunity];
			for (Opportunity opportunityToCheck : updatedOpportunities) {
				System.assertEquals(ASESOR2.Id, opportunityToCheck.OwnerId);
				System.assertEquals(null, opportunityToCheck.Branch_Unit__c);
				System.assertEquals(null, opportunityToCheck.Regi_n__c);
				System.assertEquals(null, opportunityToCheck.Divisi_n__c);
			}
		}
	}
}