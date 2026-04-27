/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_BranchUnitTrigger_Test
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 23/11/2022
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Test for the branch unit trigger.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 23/11/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
@isTest
public with sharing class F3_BranchUnitTrigger_Test {
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
		for (Banker banker : bankers) {
			banker.CurrentBranchId = sucursal.id;
		}
		update bankers;
	}

	@IsTest
	private static void verifyChangeBranchName() {
		User firstUser = [SELECT Id, F3_Sucursal__c, F3_Region__c, F3_Division__c FROM User WHERE ID_ASESOR__c = '0000' LIMIT 1];
		System.assertEquals('Sucursal', firstUser.F3_Sucursal__c);
		System.assertEquals('Region', firstUser.F3_Region__c);
		System.assertEquals('Division', firstUser.F3_Division__c);
		Test.startTest();
		BranchUnit branch = [SELECT Id FROM BranchUnit WHERE Name = 'Sucursal' LIMIT 1];
		branch.Name = 'SucursalTest';
		update branch;
		Test.stopTest();
		firstUser = [SELECT Id, F3_Sucursal__c, F3_Region__c, F3_Division__c FROM User WHERE ID_ASESOR__c = '0000' LIMIT 1];
		System.assertEquals('SucursalTest', firstUser.F3_Sucursal__c);
		System.assertEquals('Region', firstUser.F3_Region__c);
		System.assertEquals('Division', firstUser.F3_Division__c);
	}

	@IsTest
	private static void verifyChangeBranchNameAndParent() {
		User secondUser = [SELECT Id, F3_Sucursal__c, F3_Region__c, F3_Division__c FROM User WHERE ID_ASESOR__c = '0001' LIMIT 1];
		System.assertEquals('Sucursal', secondUser.F3_Sucursal__c);
		System.assertEquals('Region', secondUser.F3_Region__c);
		System.assertEquals('Division', secondUser.F3_Division__c);
		Test.startTest();
		BranchUnit branch = [SELECT Id FROM BranchUnit WHERE Name = 'Sucursal' LIMIT 1];
		BranchUnit division = [SELECT Id FROM BranchUnit WHERE Name = 'Division' LIMIT 1];
		branch.ParentBranchUnitId = division.id;
		update branch;
		Test.stopTest();
		secondUser = [SELECT Id, F3_Sucursal__c, F3_Region__c, F3_Division__c FROM User WHERE ID_ASESOR__c = '0001' LIMIT 1];
		System.assertEquals('Sucursal', secondUser.F3_Sucursal__c);
		System.assertEquals('Division', secondUser.F3_Region__c);
		System.assertEquals(null, secondUser.F3_Division__c);
	}

	/**
	 * @description
	 *     check if BranchUnit.Name is Duplicate
	 *     when Insert or Update
	 *     Issue #31
	 */
	@isTest
	static void checkBUNameDuplicateTest() {
		List<BranchUnit> lstBU = new List<BranchUnit>();
		BranchUnit BUTest1 = new BranchUnit(Name = 'BUtest1', Type = 'Physical');
		BranchUnit BUTest2 = new BranchUnit(Name = 'BUtest2', Type = 'Physical');
		BranchUnit BUTest3 = new BranchUnit(Name = 'BUtest1', Type = 'Physical'); // duplicate
		lstBU.add(BUTest1);
		lstBU.add(BUTest2);
		lstBU.add(BUtest3);

		Test.startTest();
		Database.SaveResult[] srlistInsert = Database.insert(lstBU, false);

		BranchUnit objBUtoUpdate = [SELECT Id, Name FROM BranchUnit WHERE Name = 'BUtest2'];
		objBUtoUpdate.Name = 'BUtest1';
		Database.SaveResult srlistUpdate = Database.update(objBUtoUpdate, false);

		Test.stopTest();
		// System.debug(srlistInsert[2]);
		System.assertEquals(true, srlistInsert[0].isSuccess());
		System.assertEquals(true, srlistInsert[1].isSuccess());
		System.assertEquals(false, srlistInsert[2].isSuccess());

		System.assertEquals(true, srlistUpdate.isSuccess());
	}
}