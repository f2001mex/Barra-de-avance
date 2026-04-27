/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_BankerTrigger_Test
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 23/11/2022
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Test for the banker trigger.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 23/11/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
@isTest
public with sharing class F3_BankerTrigger_Test {
	@TestSetup
	public static void setup() {
		String adminProfileId = [SELECT Id FROM Profile WHERE name IN ('System Administrator', 'Administrador del sistema')].Id;
		Map<String, User> users = new Map<String, User>();
		List<Banker> bankers = new List<Banker>();
		List<BranchUnitBusinessMember> branchMembers = new List<BranchUnitBusinessMember>();
		users.put(
			'admin',
			UtilitiesDataTest.createUser(
				new Map<Schema.SObjectField, Object>{
					User.LastName => 'ADMIN',
					User.ProfileId => adminProfileId,
					User.ID_ASESOR__c => '0000'
				}
			)
		);
		users.put(
			'executive1',
			UtilitiesDataTest.createUser(
				new Map<Schema.SObjectField, Object>{
					User.LastName => 'ASESOR1',
					User.ProfileId => adminProfileId,
					User.ID_ASESOR__c => '0001'
				}
			)
		);
		users.put(
			'executive2',
			UtilitiesDataTest.createUser(
				new Map<Schema.SObjectField, Object>{
					User.LastName => 'ASESOR2',
					User.ProfileId => adminProfileId,
					User.ID_ASESOR__c => '0002'
				}
			)
		);
		users.put(
			'executive3',
			UtilitiesDataTest.createUser(
				new Map<Schema.SObjectField, Object>{
					User.LastName => 'ASESOR3',
					User.ProfileId => adminProfileId,
					User.ID_ASESOR__c => '0002',
					User.F3_Sucursal__c => 'Sucursal',
					User.F3_Region__c => 'Region',
					User.F3_Division__c => 'Division'
				}
			)
		);
		BranchUnit division = UtilitiesDataTest.createBranches(
			1,
			new Map<Schema.SObjectField, Object>{ BranchUnit.BranchCode => 'PRB_0003', BranchUnit.Name => 'Division' }
		)[0];
		insert division;
		BranchUnit region = UtilitiesDataTest.createBranches(
			1,
			new Map<Schema.SObjectField, Object>{
				BranchUnit.BranchCode => 'PRB_0002',
				BranchUnit.Name => 'Region',
				BranchUnit.ParentBranchUnitId => division.Id
			}
		)[0];
		insert region;
		BranchUnit sucursal = UtilitiesDataTest.createBranches(
			1,
			new Map<Schema.SObjectField, Object>{
				BranchUnit.BranchCode => 'PRB_0001',
				BranchUnit.Name => 'Sucursal',
				BranchUnit.ParentBranchUnitId => region.Id
			}
		)[0];
		insert sucursal;
		for (String userKey : users.keySet()) {
			bankers.add(
				UtilitiesDataTest.createBankers(
					1,
					new Map<Schema.SObjectField, Object>{
						Banker.UserOrContactId => users.get(userKey).Id,
						Banker.Name => users.get(userKey).LastName
					}
				)[0]
			);
		}
		Contact newContact = new Contact(FirstName = 'test', LastName = 'Contact');
		insert newContact;
		bankers.add(
			UtilitiesDataTest.createBankers(
				1,
				new Map<Schema.SObjectField, Object>{ Banker.UserOrContactId => newContact.Id, Banker.Name => newContact.LastName }
			)[0]
		);
		insert bankers;
		for (Banker banker : bankers) {
			System.debug(sucursal.id);
			branchMembers.add(new BranchUnitBusinessMember(BranchUnitId = sucursal.id, BusinessUnitMemberId = banker.id, IsActive = true));
		}
		for (Banker banker : bankers) {
			branchMembers.add(new BranchUnitBusinessMember(BranchUnitId = region.id, BusinessUnitMemberId = banker.id, IsActive = true));
		}
		for (Banker banker : bankers) {
			branchMembers.add(new BranchUnitBusinessMember(BranchUnitId = division.id, BusinessUnitMemberId = banker.id, IsActive = true));
		}
		insert branchMembers;
	}

	@IsTest
	private static void verifyAddBranch() {
		Banker firstBanker = [SELECT Name, UserOrContactId, CurrentBranchId FROM Banker WHERE Name = 'ADMIN' LIMIT 1];
		BranchUnit branch = [SELECT Id FROM BranchUnit WHERE Name = 'Sucursal' LIMIT 1];
		firstBanker.CurrentBranchId = branch.id;
		Test.startTest();
		update firstBanker;
		Test.stopTest();
		User firstUser = [
			SELECT Id, F3_Sucursal__c, F3_Region__c, F3_Division__c
			FROM User
			WHERE Id = :firstBanker.UserOrContactId
			LIMIT 1
		];
		System.assertEquals('Sucursal', firstUser.F3_Sucursal__c);
		System.assertEquals('Region', firstUser.F3_Region__c);
		System.assertEquals('Division', firstUser.F3_Division__c);
	}

	@IsTest
	private static void verifyAddRegion() {
		Banker secondBanker = [SELECT Name, UserOrContactId, CurrentBranchId FROM Banker WHERE Name = 'ASESOR1' LIMIT 1];
		BranchUnit region = [SELECT Id FROM BranchUnit WHERE Name = 'Region' LIMIT 1];
		secondBanker.CurrentBranchId = region.id;
		Test.startTest();
		update secondBanker;
		Test.stopTest();
		User secondUser = [
			SELECT Id, F3_Sucursal__c, F3_Region__c, F3_Division__c
			FROM User
			WHERE Id = :secondBanker.UserOrContactId
			LIMIT 1
		];
		System.assertEquals('Region', secondUser.F3_Sucursal__c);
		System.assertEquals('Division', secondUser.F3_Region__c);
		System.assertEquals(null, secondUser.F3_Division__c);
	}

	@IsTest
	private static void verifyAddDivision() {
		Banker thirdBanker = [SELECT Name, UserOrContactId, CurrentBranchId FROM Banker WHERE Name = 'ASESOR2' LIMIT 1];
		BranchUnit division = [SELECT Id FROM BranchUnit WHERE Name = 'Division' LIMIT 1];
		thirdBanker.CurrentBranchId = division.id;
		Test.startTest();
		update thirdBanker;
		Test.stopTest();
		User thirdUser = [
			SELECT Id, F3_Sucursal__c, F3_Region__c, F3_Division__c
			FROM User
			WHERE Id = :thirdBanker.UserOrContactId
			LIMIT 1
		];
		System.assertEquals('Division', thirdUser.F3_Sucursal__c);
		System.assertEquals(null, thirdUser.F3_Region__c);
		System.assertEquals(null, thirdUser.F3_Division__c);
	}

	@IsTest
	private static void verifyEraseBranch() {
		Banker fourthBanker = [SELECT Name, UserOrContactId, CurrentBranchId FROM Banker WHERE Name = 'ASESOR3' LIMIT 1];
		User fourthUser = [
			SELECT Id, F3_Sucursal__c, F3_Region__c, F3_Division__c
			FROM User
			WHERE Id = :fourthBanker.UserOrContactId
			LIMIT 1
		];
		System.assertEquals('Sucursal', fourthUser.F3_Sucursal__c);
		System.assertEquals('Region', fourthUser.F3_Region__c);
		System.assertEquals('Division', fourthUser.F3_Division__c);
		fourthBanker.CurrentBranchId = null;
		Test.startTest();
		update fourthBanker;
		Test.stopTest();
		fourthUser = [SELECT Id, F3_Sucursal__c, F3_Region__c, F3_Division__c FROM User WHERE Id = :fourthBanker.UserOrContactId LIMIT 1];
		System.assertEquals(null, fourthUser.F3_Sucursal__c);
		System.assertEquals(null, fourthUser.F3_Region__c);
		System.assertEquals(null, fourthUser.F3_Division__c);
	}

	@IsTest
	private static void verifyNoRunForContact() {
		Banker fourthBanker = [SELECT Name, UserOrContactId, CurrentBranchId FROM Banker WHERE Name = 'Contact' LIMIT 1];
		BranchUnit branch = [SELECT Id FROM BranchUnit WHERE Name = 'Sucursal' LIMIT 1];
		fourthBanker.CurrentBranchId = branch.id;
		Integer dmlCount = Limits.getDmlStatements();
		Test.startTest();
		update fourthBanker;
		Test.stopTest();
		Integer dmlCountAfter = Limits.getDmlStatements();
		System.assertEquals(
			dmlCount,
			dmlCountAfter,
			'If contact is avoided in trigger, just one dml operation has to be done (banker), instead of two (banker and user)'
		);
	}
}