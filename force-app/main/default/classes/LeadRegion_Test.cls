@isTest
public with sharing class LeadRegion_Test {
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
			List<contact> lstContact = new List<Contact>();
			lstContact.add(new Contact(FirstName = 'test', LastName = 'Contact'));
			insert lstContact;
			Lead newLead = new Lead();
			newLead.FirstName = 'Test';
			newLead.LastName = 'Lead';
			newLead.PostalCode = '30000';
			newLead.Status = 'Asignado';
			newLead.OwnerId = ASESOR1.Id;
			newLead.FinServ__ExpressedInterest__c = 'Banca Soluciones';
			newLead.FinServ__ReferredByContact__c = lstContact[0].Id;
			insert newLead;
			Test.startTest();
			id jobId = Database.executeBatch(new LeadRegion_Batch());
			Test.stopTest();
			List<Lead> updatedLeads = [
				SELECT id, F3_Tipo_Banca__c, Branch_Unit__r.Name, Regi_n__r.Name, Divisi_n__r.Name, OwnerId
				FROM lead
			];
			for (Lead leadToCheck : updatedLeads) {
				System.assertEquals(ASESOR1.Id, leadToCheck.OwnerId);
				System.assertEquals(ASESOR1.UserRole.Name, leadToCheck.F3_Tipo_Banca__c);
				System.assertEquals('Test branch', leadToCheck.Branch_Unit__r.Name);
				System.assertEquals('Test region', leadToCheck.Regi_n__r.Name);
				System.assertEquals('Test division', leadToCheck.Divisi_n__r.Name);
			}
		}
	}

	@isTest
	static void ownerWithoutBranch() {
		User ASESOR2 = [SELECT id, ID_ASESOR__c, UserRole.Name FROM user WHERE LastName LIKE 'ASESOR2'];
		System.runAs(ASESOR2) {
			List<contact> lstContact = new List<Contact>();
			lstContact.add(new Contact(FirstName = 'test', LastName = 'Contact'));
			insert lstContact;
			Lead newLead = new Lead();
			newLead.FirstName = 'Test';
			newLead.LastName = 'Lead';
			newLead.PostalCode = '30000';
			newLead.Status = 'Asignado';
			newLead.OwnerId = ASESOR2.Id;
			newLead.FinServ__ExpressedInterest__c = 'Banca Soluciones';
			newLead.FinServ__ReferredByContact__c = lstContact[0].Id;
			insert newLead;
			Test.startTest();
			id jobId = Database.executeBatch(new LeadRegion_Batch());
			Test.stopTest();
			List<Lead> updatedLeads = [SELECT id, F3_Tipo_Banca__c, Branch_Unit__c, Regi_n__c, Divisi_n__c, OwnerId FROM lead];
			for (Lead leadToCheck : updatedLeads) {
				System.assertEquals(ASESOR2.Id, leadToCheck.OwnerId);
				System.assertEquals(null, leadToCheck.F3_Tipo_Banca__c);
				System.assertEquals(null, leadToCheck.Branch_Unit__c);
				System.assertEquals(null, leadToCheck.Regi_n__c);
				System.assertEquals(null, leadToCheck.Divisi_n__c);
			}
		}
	}
}