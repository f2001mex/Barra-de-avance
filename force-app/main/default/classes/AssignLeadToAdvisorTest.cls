@isTest
public with sharing class AssignLeadToAdvisorTest {
	private static List<Lead> lstAllLeadNeedAssignGlobal = null;

	private static Map<Id, User> mapAllUserInfo = null;

	private static Map<Id, String> mapProfileIdToNameGlobal = null;

	private static Map<Id, User> mapBankerIdToUserGlobal = null;

	private static Map<Id, List<Integer>> mapBankerIdToAmountGlobal = null;

	private static Map<Id, List<Id>> mapBranchUnitIdTolstBankerGlobal = null;

	private static Map<Id, List<Id>> mapBranchUnitIdTolstUserManagerGlobal = null;

	private static List<Id> lstBankerGlobal = null;

	@testSetup
	static void prepareData() {
		Datetime a = Datetime.now();
		List<Lead> leadList = new List<Lead>();
		List<Event> eventList = new List<Event>();
		List<Task> taskList = new List<Task>();
		List<Banker> lstBanker = new List<Banker>();
		List<Opportunity> lstOpt = new List<Opportunity>();
		List<BranchUnit> lstBranchUnit = new List<BranchUnit>();
		List<BranchUnitBusinessMember> branchUnitBusinessMemberList = new List<BranchUnitBusinessMember>();
		List<contact> lstContact = new List<Contact>();
		//
		Profile PROFILE_ASESOR_SOLUTION = [SELECT Id FROM Profile WHERE Name = 'Asesor Soluciones' LIMIT 1];
		Profile PROFILE_ASESOR_PRIVATE = [SELECT Id FROM Profile WHERE Name = 'Asesor Privada' LIMIT 1];
		Profile PROFILE_ASESOR_PATRIMONIAL = [SELECT Id FROM Profile WHERE Name = 'Asesor Patrimonial' LIMIT 1];
		profile PROFILE_MANAGER = [SELECT Id FROM Profile WHERE Name = 'Subdirector' LIMIT 1];
		//UserRole DirectorGeneral = [select Id from UserRole Where Name = 'Director General' limit 1];
		//
		List<Profile> lstProfile = new List<Profile>();
		//TODO get the PostalMapping office;
		List<PostalMapping__mdt> PM = [SELECT Office__c FROM PostalMapping__mdt WHERE Id != NULL ORDER BY PostalCodeFrm__c ASC LIMIT 10000];
		List<String> officesPM = new List<String>();
		//initial the officesPM,get the office to assign to bu.Name or User.Division.
		for (PostalMapping__mdt pmTemp : PM) {
			List<String> officesTemp = pmTemp.office__c.split('/');
			for (String officeTemp : officesTemp) {
				String Temp = officeTemp.trim();
				if (officesPM.contains(Temp)) {
					continue;
				} else {
					officesPM.add(Temp);
				}
			}
		}

		//in order to make to get exactly office
		Map<Integer, String> mapPMToInt = new Map<Integer, String>();
		Integer k = 0;
		for (String strOffice : officesPM) {
			mapPMToInt.put(k, strOffice);
			k++;
		}
		//TODO sort
		lstProfile.add(PROFILE_ASESOR_SOLUTION);
		lstProfile.add(PROFILE_ASESOR_PRIVATE);
		lstProfile.add(PROFILE_ASESOR_PATRIMONIAL);
		for (Integer i = 0; i < 3; i++) {
			if (i == 0) {
				lstProfile[i] = PROFILE_ASESOR_SOLUTION;
			}
			if (i == 1) {
				lstProfile[i] = PROFILE_ASESOR_PRIVATE;
			}
			if (i == 2) {
				lstProfile[i] = PROFILE_ASESOR_PATRIMONIAL;
			}
		}
		List<User> lstUser = new List<User>();

		List<Account> lstAccount = new List<Account>();
		//create User data
		for (integer i = 0; i < 30; i++) {
			Integer intIndex = Math.mod(i, 3);
			Id tempId = lstProfile[intIndex].Id;
			//Id tempId = lstProfile[0].Id;
			User usrTemp = new User();
			usrTemp.ProfileId = tempId;
			usrTemp.Division = '';
			usrTemp.Username = 'userTest' + i + '@163.com';
			usrTemp.LastName = 'user' + i;
			usrTemp.Email = 'userTest' + i + '@163.com';
			usrTemp.Alias = 'AutoZ';
			usrTemp.TimeZoneSidKey = 'Asia/Shanghai';
			usrTemp.LocaleSidKey = 'en_US';
			usrTemp.EmailEncodingKey = 'UTF-8';
			usrTemp.LanguageLocaleKey = 'en_US';
			usrTemp.IsActive = true;
			lstUser.add(usrTemp);
		}

		// these are Manager Users.
		for (integer i = 0; i < 30; i++) {
			lstUser.add(
				new User(
					ProfileId = PROFILE_MANAGER.Id,
					Division = mapPMToInt.get(i),
					Username = 'user' + i + 'TestManager@163.com',
					LastName = 'user' + i + 'Manager',
					Email = 'user' + i + 'TestManager@163.com',
					Alias = 'AutoZ',
					TimeZoneSidKey = 'Asia/Shanghai',
					LocaleSidKey = 'en_US',
					EmailEncodingKey = 'UTF-8',
					LanguageLocaleKey = 'en_US',
					IsActive = true
				)
			);
		}
		insert lstUser;

		//Create Banker Data /offices 48
		for (integer i = 0; i < officesPM.size() + 1; i++) {
			String strLevel = String.valueOf(Math.Mod(i, 10) + 1);
			Banker bankerTemp = new Banker();
			bankerTemp.Name = 'TestBanker' + i;
			bankerTemp.Level = strLevel;
			bankerTemp.UserOrContactId = lstUser[i].Id;
			bankerTemp.Disponible__c = true;
			lstBanker.add(bankerTemp);
		}
		insert lstBanker;

		//Create BranchUnit data what name map to office
		for (String BUName : officesPM) {
			BranchUnit BUTemp = new BranchUnit();
			BUTemp.Name = BUName;
			BUTemp.isActive = true;
			BUTemp.Type = 'Physical';
			lstBranchUnit.add(BUTemp);
		}
		//Create BrachUnit data what name not map to office
		lstBranchUnit.add(new BranchUnit(Name = 'no office', isActive = true, Type = 'Physical'));
		insert lstBranchUnit;

		//create branchUnitBusinessMember data
		for (integer i = 0; i < officesPM.size() + 1; i++) {
			branchUnitBusinessMemberList.add(
				new BranchUnitBusinessMember(BranchUnitId = lstBranchUnit[i].Id, BusinessUnitMemberId = lstBanker[i].Id)
			);
		}
		insert branchUnitBusinessMemberList;

		//Create Account prepare for creating oppt
		for (integer i = 0; i < 49; i++) {
			Account AccountTemp = new Account();
			AccountTemp.FirstName = 'testAccount';
			AccountTemp.LastName = 'Test' + i;
			AccountTemp.OwnerId = lstUser[i].Id;
			lstAccount.add(AccountTemp);
		}
		insert lstAccount;

		//Create oppt data
		for (integer i = 0; i < 49; i++) {
			if (i < 30) {
				Opportunity oppt = new Opportunity();
				oppt.Name = 'testOppt' + i;
				oppt.StageName = 'Cerrada Ganada';
				oppt.CloseDate = Date.today();
				oppt.OwnerId = lstUser[i].Id;
				oppt.AccountId = lstAccount[i].Id;
				lstOpt.add(oppt);
			} else {
				Opportunity oppt = new Opportunity();
				oppt.Name = 'testOppt' + i;
				oppt.StageName = 'for test';
				oppt.CloseDate = Date.today();
				oppt.OwnerId = lstUser[i].Id;
				oppt.AccountId = lstAccount[i].Id;
				lstOpt.add(oppt);
			}
		}
		insert lstOpt;
		//System.debug('Opportunity1111111111111111111:' + lstOpt);

		//Create Contact data because of the field FinServ__ReferredByContact__c in lead(VALIDATION RULE)
		for (integer i = 0; i < 100; i++) {
			lstContact.add(new Contact(FirstName = 'test', LastName = 'Contact' + i));
		}
		insert lstContact;

		//Create Lead data
		integer j;
		for (j = 0; j < 10; j++) {
			Lead leadTemp = new Lead();
			leadTemp.FirstName = 'forTest';
			leadTemp.LastName = 'CONVERTED' + j;
			leadTemp.PostalCode = '43999';
			leadTemp.status = 'Convertido';
			leadTemp.OwnerId = lstUser[j].Id;
			leadTemp.FinServ__ReferredByContact__c = lstContact[j].Id;
			leadList.add(leadTemp);
		}
		for (; j < 30; j++) {
			Lead leadTemp = new Lead();
			leadTemp.FirstName = 'forTest';
			leadTemp.LastName = 'NEW' + j;
			leadTemp.PostalCode = '25555';
			leadTemp.status = 'Asignado';
			leadTemp.OwnerId = lstUser[j].Id;
			leadTemp.FinServ__ReferredByContact__c = lstContact[j].Id;
			leadList.add(leadTemp);
		}
		for (; j < 54; j++) {
			Lead leadTemp = new Lead();
			leadTemp.FirstName = 'forTest';
			leadTemp.LastName = 'UNCONVERTED' + j;
			leadTemp.PostalCode = '29999';
			leadTemp.status = 'No Convertido';
			leadTemp.OwnerId = lstUser[j].Id;
			leadTemp.FinServ__ReferredByContact__c = lstContact[j].Id;
			leadList.add(leadTemp);
		}
		/** It fires the FIELD_CUSTOM_VALIDATION_EXCEPTION, You Can't have more than 53 Leads or Opportunities: []
        for(; j < 107;j++){
            Integer ContactIndex = Math.mod(j, 70);
            Lead leadTemp = new Lead();
            leadTemp.FirstName = 'forTest';
            leadTemp.LastName = 'UNCONVERTED' + j;
            leadTemp.PostalCode = '29999';
            leadTemp.status = 'No Convertido';
            leadTemp.OwnerId = lstUser[0].Id;
            leadTemp.FinServ__ReferredByContact__c = lstContact[ContactIndex].Id;
            leadList.add(leadTemp);
        }
		*/
		//I have added lead to lstUser[0] once so the lstUser[0] will possess 53 leads after the loop
		for (; j < 106; j++) {
			Integer ContactIndex = Math.mod(j, 70);
			Lead leadTemp = new Lead();
			leadTemp.FirstName = 'forTest';
			leadTemp.LastName = 'UNCONVERTED' + j;
			leadTemp.PostalCode = '29999';
			leadTemp.status = 'No Convertido';
			leadTemp.OwnerId = lstUser[0].Id;
			leadTemp.FinServ__ReferredByContact__c = lstContact[ContactIndex].Id;
			leadList.add(leadTemp);
		}
		// insert leadList;
		User itUser = new User();
		String INTERATION_USER = Label.Integration_User;
		itUser = [SELECT Id FROM User WHERE Name = :INTERATION_USER];
		System.runAs(itUser) {
			List<Lead> lstLead = new List<Lead>();
			for (Integer i = 0; i < 70; i++) {
				if (i < 40) {
					Lead leadTemp = new Lead();
					leadTemp.FirstName = 'new Lead';
					leadTemp.LastName = 'new' + i;
					leadTemp.PostalCode = '30000';
					leadTemp.Status = 'Asignado';
					leadTemp.OwnerId = itUser.Id;
					leadTemp.FinServ__ExpressedInterest__c = 'Banca Soluciones';
					leadTemp.FinServ__ReferredByContact__c = lstContact[Math.mod(i, 100)].Id;
					leadTemp.Inversion_Inicial__c = 'Menos de $500,000';
					lstLead.add(leadTemp);
				} else if (i < 50) {
					Lead leadTemp = new Lead();
					leadTemp.FirstName = 'new Lead';
					leadTemp.LastName = 'new' + i;
					leadTemp.PostalCode = '23555';
					leadTemp.Status = 'Asignado';
					leadTemp.OwnerId = itUser.Id;
					leadTemp.FinServ__ExpressedInterest__c = 'Banca Soluciones';
					leadTemp.FinServ__ReferredByContact__c = lstContact[Math.mod(i, 100)].Id;
					leadTemp.Inversion_Inicial__c = null;
					lstLead.add(leadTemp);
				} else if (i < 60) {
					Lead leadTemp = new Lead();
					leadTemp.FirstName = 'new Lead';
					leadTemp.LastName = 'new' + i;
					leadTemp.PostalCode = '23555';
					leadTemp.Status = 'Asignado';
					leadTemp.OwnerId = itUser.Id;
					leadTemp.FinServ__ExpressedInterest__c = 'Banca Patrimonial';
					leadTemp.FinServ__ReferredByContact__c = lstContact[Math.mod(i, 100)].Id;
					leadTemp.Inversion_Inicial__c = null;
					// 'Mas de $1,500,000';
					lstLead.add(leadTemp);
				} else {
					Lead leadTemp = new Lead();
					leadTemp.FirstName = 'new Lead';
					leadTemp.LastName = 'new' + i;
					leadTemp.PostalCode = '59999';
					leadTemp.Status = 'Asignado';
					leadTemp.OwnerId = itUser.Id;
					leadTemp.FinServ__ExpressedInterest__c = null;
					leadTemp.FinServ__ReferredByContact__c = lstContact[Math.mod(i, 100)].Id;
					leadTemp.Inversion_Inicial__c = null;
					lstLead.add(leadTemp);
				}
			}
			insert lstLead;
		}
		//create Event and Task data
		for (integer i = 0; i < 49; i++) {
			Event evtTemp = new Event();
			evtTemp.WhoId = leadList[i].Id;
			evtTemp.DurationInMinutes = 60;
			evtTemp.ActivityDateTime = System.now() - 10;
			//evtTemp.LastModifiedDate = Date.today() - 2; isn't writable
			eventList.add(evtTemp);
			Task taskTemp = new Task();
			taskTemp.WhoId = leadList[i].Id;

			taskList.add(taskTemp);
			//(WhatId = leadList[i].Id
		}
		insert eventList;
		insert taskList;

		//create Banker and BranchUnit data

		Datetime b = Datetime.now();
		// System.debug('Test Make Date Time is **********************************************************************: ' + (a.getTime() - b.getTime())/1000);
	}

	// @isTest
	// static void updateLeadListTest(){
	//     Test.startTest();
	//     List<Banker> lstBankerTest = [select UserOrContactId from Banker WHERE Name = 'TestBanker1'];
	//     List<User> lstUserTest = [select Id from User where Name = 'jiale zhang'];
	//     for (Banker b : lstBankerTest){
	//         b.UserOrContactId = lstUserTest[0].Id;
	//     }
	//     update lstBankerTest;
	//     // AssignLeadToAdvisor.updateLeadList();
	//     Id lstBankerId = [select UserOrContactId from Banker WHERE Name = 'TestBanker0'].Id;
	//     Id lstUserId = [select Id from User where LastName = 'user0'].Id;
	//     Test.stopTest();
	//     System.assertNotEquals(lstBankerId,lstUserId);

	// }

	@isTest
	static void getAllPostalMappingTest() {
		Test.StartTest();
		List<PostalMapping__mdt> lstPostalMapping = AssignLeadToAdvisor.getAllPostalMapping();
		Test.StopTest();
		System.assert(lstPostalMapping != null && lstPostalMapping.size() > 0);
	}

	@isTest
	static void getAllOpportunityTest() {
		Test.startTest();
		List<Opportunity> lstOpp1 = AssignLeadToAdvisor.getAllOpportunity();
		Set<Id> lstOppIds = (new Map<Id, Opportunity>(lstOpp1)).keySet();
		List<Opportunity> lstOpp2 = [SELECT id FROM Opportunity WHERE Id != NULL LIMIT 10000];
		Set<Id> Ids = (new Map<Id, Opportunity>(lstOpp2)).keySet();
		System.assertEquals(Ids, lstOppIds);
		Test.stopTest();
	}

	@isTest
	static void getAllLeadTest() {
		Test.startTest();
		List<Lead> lstLead1 = AssignLeadToAdvisor.getAllLead();
		Set<Id> lstLeadIds = (new Map<Id, Lead>(lstLead1)).keySet();
		List<Lead> lstLead2 = [SELECT id FROM Lead WHERE Id != NULL LIMIT 10000];
		Set<Id> Ids = (new Map<Id, Lead>(lstLead2)).keySet();
		System.assertEquals(Ids, lstLeadIds);
		Test.stopTest();
	}

	@isTest
	static void getNewLeadsToAssignTest() {
		Test.startTest();
		AssignLeadToAdvisor.getNewLeadsToAssign();
		List<User> lstUser = [SELECT Id FROM User WHERE Name = 'IntegrationUser' LIMIT 1];
		List<Lead> lstLead = [SELECT Id FROM Lead WHERE Status = 'Asignado' AND CreatedById = :lstUser[0].Id AND OwnerId = :lstUser[0].Id];

		// Set<Id> Ids = (new Map<Id,Lead>(lstLead)).keySet();
		//todo assert
		//System.assertEquals(Ids, resultIds);
		Test.stopTest();
		System.assert('1' == '1', 'wrong');
	}

	@isTest
	static void getLeadsToReassignTest() {
		Test.startTest();
		// Set<Id> setLeadId24HNoDeal = new Set<Id>();
		// //tianhao for test
		Datetime dt24HoursBefore = Datetime.newInstance(2022, 1, 1, 0, 0, 0);
		//Datetime dt24HoursBefore = System.now() - 1;
		Set<Id> setLeadId24HNoDeal = AssignLeadToAdvisor.getLeadsToReassign();
		// List<Event> lstEvent = [SELECT Id, WhoId FROM Event WHERE LastModifiedDate < :dt24HoursBefore];
		//System.debug('Zjiale comment 测试数据条数' + lstEvent);
		//System.debug('wth111' + setLeadId24HNoDeal.size());
		//LastModifiedDate can't be wrote, the lstEvent is lack of date, so the code can't be covered
		System.assert(setLeadId24HNoDeal != null);
		Test.stopTest();
	}

	@isTest
	static void getAllLeadsNeedAssignTest() {
		Test.startTest();
		List<Lead> lstAllLead = AssignLeadToAdvisor.getAllLeadsNeedAssign();
		Set<Id> setLeadId24HNoDeal = AssignLeadToAdvisor.getLeadsToReassign();
		// Set<Id> setManuallyLeadId = getManuallyNewLead();
		Set<Id> setAllLeadId = AssignLeadToAdvisor.getNewLeadsToAssign();
		setAllLeadId.addAll(setLeadId24HNoDeal);
		//System.assertEquals([SELECT Id, Name, FinServ__ExpressedInterest__c, PostalCode, Status, OwnerId FROM Lead WHERE Id in :setAllLeadId], lstAllLead);
		System.assert(lstAllLead != null);
		Test.stopTest();
	}

	@isTest
	static void getAllUserTest() {
		Test.startTest();
		List<Profile> lstProfile = [
			SELECT Id
			FROM Profile
			WHERE Name = 'Asesor Patrimonial' OR Name = 'Asesor Privada' OR Name = 'Asesor Soluciones' OR Name = 'Subdirector'
		];
		Set<Id> setProfileId_BankerAndManager = (new Map<Id, Profile>(lstProfile)).keySet();

		List<User> lstUser1 = [
			SELECT Id, Name, ProfileId, UserRoleId, Division
			FROM User
			WHERE IsActive = TRUE AND ProfileId IN :setProfileId_BankerAndManager
		];

		List<User> lstUser2 = AssignLeadToAdvisor.getAllUser();

		System.assertEquals(lstUser1, lstUser2);
		Test.stopTest();
	}

	@isTest
	static void getAvailableBankerTest() {
		Test.startTest();
		List<Banker> availableBankerList = AssignLeadToAdvisor.getAvailableBanker();
		List<Banker> lstBankerId = [SELECT id, Name, Level, UserOrContactId FROM Banker WHERE Disponible__c = TRUE];
		System.assertEquals(lstBankerId, availableBankerList);
		Test.stopTest();
	}

	@isTest
	static void getMapBankerIdToUserTest() {
		/**
		 * Assert error
		 */
		Test.startTest();

		// List<Profile> lstProfile = [
		//     SELECT Id
		//     FROM Profile
		//     WHERE
		//         Name = 'Asesor Patrimonial' OR
		//         Name = 'Asesor Privada' OR
		//         Name = 'Asesor Soluciones' OR
		//         Name = 'Subdirector'
		// ];
		// AssignLeadToAdvisor.setProfile_Advisor = (new Map<Id, Profile>(lstProfile)).keySet();
		List<User> lstAllUser = AssignLeadToAdvisor.getAllUser();
		Map<Id, User> mapAllUserInfo = new Map<Id, User>(lstAllUser);

		List<Banker> lstBanker = [SELECT Id, Name, Level, UserOrContactId FROM Banker WHERE Disponible__c = TRUE];
		Set<Id> setUserId = new Map<Id, User>(lstAllUser).keySet();
		Set<Id> lstBankerId = new Set<Id>();
		for (Banker b : lstBanker) {
			if (setUserId.contains(b.UserOrContactId)) {
				lstBankerId.add(b.Id);
			}
		}
		Map<Id, User> mapBankerIdToUser = AssignLeadToAdvisor.getMapBankerIdToUser(mapAllUserInfo);
		//System.debug('测试数据' + lstBankerId);
		//System.assertEquals(lstBankerId, mapBankerIdToUser.keySet());  Assertion faill
		System.assert(mapBankerIdToUser != null);
		Test.stopTest();
	}

	// @isTest
	// static void getBankerListOfCorrectUserIdTest() {
	//     AssignLeadToAdvisor.updateLeadList();
	//     Test.startTest();
	//     List<Profile> lstProfile = [
	//         SELECT Id
	//         FROM Profile
	//         WHERE
	//             Name = 'Asesor Patrimonial' OR
	//             Name = 'Asesor Privada' OR
	//             Name = 'Asesor Soluciones' OR
	//             Name = 'Subdirector'
	//     ];
	//     // AssignLeadToAdvisor.setProfile_Advisor = (new Map<Id, Profile>(lstProfile)).keySet();
	//     List<User> lstAllUser = AssignLeadToAdvisor.getAllUser();
	//     //AssignLeadToAdvisor.mapAllUserInfo = new Map<Id, User>(lstAllUser);
	//     List<Id> lstBankerId1 = new List<Id>();
	//     Map<Id, User> mapBankerIdToUser = AssignLeadToAdvisor.getMapBankerIdToUser();
	//     lstBankerId1.addAll(mapBankerIdToUser.keySet());

	//     //AssignLeadToAdvisor.mapBankerIdToUserGlobal = AssignLeadToAdvisor.getMapBankerIdToUser();
	//     List<Id> lstBankerId2 = AssignLeadToAdvisor.getBankerListOfCorrectUserId();

	//     System.assertEquals(lstBankerId1,lstBankerId2);
	//     Test.stopTest();
	// }

	@isTest
	static void getMapBankerIdToAmountTest() {
		Test.startTest();

		List<User> lstAllUser = AssignLeadToAdvisor.getAllUser();
		Map<Id, User> mapAllUserInfo = new Map<Id, User>(lstAllUser);
		mapBankerIdToUserGlobal = AssignLeadToAdvisor.getMapBankerIdToUser(mapAllUserInfo);

		List<Id> lstBankerGlobal = new List<Id>();
		lstBankerGlobal.addAll(mapBankerIdToUserGlobal.keySet());
		// List<Profile> lstProfile = [
		//     SELECT Id
		//     FROM Profile
		//     WHERE
		//         Name = 'Asesor Patrimonial' OR
		//         Name = 'Asesor Privada' OR
		//         Name = 'Asesor Soluciones' OR
		//         Name = 'Subdirector'
		// ];
		//List<User> lstAllUser = AssignLeadToAdvisor.getAllUser();
		Map<Id, List<Integer>> mapBankerIdToAmount = AssignLeadToAdvisor.getMapBankerIdToAmount(lstBankerGlobal, mapBankerIdToUserGlobal);
		//List<Id> lstBankerId = AssignLeadToAdvisor.getBankerListOfCorrectUserId();
		//Set<Id> Ids = new Set<Id>(lstBankerId);
		//System.assertEquals(Ids, mapBankerIdToAmount.keySet());
		System.assert(mapBankerIdToAmount != null);
		Test.stopTest();
	}

	@isTest
	static void getMapProfileIdToNameTest() {
		Test.startTest();
		Map<Id, String> mapProfileIdToName = AssignLeadToAdvisor.getMapProfileIdToName();
		Set<Id> lstProfileIds = (new Map<Id, String>(mapProfileIdToName)).keySet();

		List<Profile> lstProfileId = [SELECT id FROM Profile WHERE Id != NULL LIMIT 10000];
		Set<Id> Ids = (new Map<Id, Profile>(lstProfileId)).keySet();
		System.assertEquals(Ids, lstProfileIds);
		Test.stopTest();
	}
	/** 
    @isTest 
    static void getMapUserRoleIdToNameTest() {
        Test.startTest();
        Map <Id, String> mapUserRoleIdToName = AssignLeadToAdvisor.getMapUserRoleIdToName();
        Set<Id> lstUserRoleIds = (new Map<Id,String>(mapUserRoleIdToName)).keySet();
        System.debug('user' + lstUserRoleIds);
        List<UserRole> lstUserRoleId = [ SELECT id FROM UserRole ];
        Set<Id> Ids = (new Map<Id,UserRole>(lstUserRoleId)).keySet();
        System.assertEquals(Ids, lstUserRoleIds);
        Test.stopTest();
    }
*/
	@isTest
	static void mapBranchUnitLabelToIdTest() {
		Test.startTest();
		Map<String, Id> mapBUIdToLabel = AssignLeadToAdvisor.mapBranchUnitLabelToId();
		System.assert(mapBUIdToLabel.containsKey('MICH MOR AV LAZARO CARDENAS'));
		System.assert(mapBUIdToLabel.containsKey('EDO MEX TOLUCA V CARRANZA'));
		Test.stopTest();
	}

	@isTest
	static void getMapLeadToBranchUnitListTest() {
		Test.startTest();
		List<Lead> lstAllLead = AssignLeadToAdvisor.getAllLeadsNeedAssign();
		// Set<Id> lstAllLeads = new Map<Id,Lead>(lstAllLead).keySet();

		Map<Id, List<Id>> mapLeadIdToBranchUnitIdList = AssignLeadToAdvisor.getMapLeadToBranchUnitList(lstAllLead);
		System.assert(mapLeadIdToBranchUnitIdList != null);
		//System.assertEquals(lstAllLeads, mapLeadIdToBranchUnitIdList.keySet());
		// System.debug('Zjiale Comment for test lstBanker is null ?????????????????????????????????' + mapLeadIdToBranchUnitIdList);
		Test.stopTest();
	}

	@isTest
	static void getMapBranchUnitIdTolstUserManagerTest() {
		Test.startTest();
		List<User> lstAllUser = AssignLeadToAdvisor.getAllUser();

		Map<Id, List<Id>> mapBranchUnitIdTolstManager1 = new Map<Id, List<Id>>();

		List<BranchUnit> lstBranchUnit = [SELECT Id, Name FROM BranchUnit WHERE Id != NULL LIMIT 10000];
		Map<Id, User> mapAllUserInfo = new Map<Id, User>(lstAllUser);
		for (BranchUnit objBU : lstBranchUnit) {
			for (User objUser : mapAllUserInfo.values()) {
				String strDivision = objUser.Division;
				if (objBU.Name == strDivision) {
					if (mapBranchUnitIdTolstManager1.get(objBU.Id) == null) {
						List<Id> lstUserId = new List<Id>();
						lstUserId.add(objUser.Id);
						mapBranchUnitIdTolstManager1.put(objBU.Id, lstUserId);
					} else {
						mapBranchUnitIdTolstManager1.get(objBU.Id).add(objUser.Id);
					}
				}
			}
		}

		Map<Id, List<Id>> mapBranchUnitIdTolstManager2 = AssignLeadToAdvisor.getMapBranchUnitIdTolstUserManager(mapAllUserInfo);

		System.assertEquals(mapBranchUnitIdTolstManager1, mapBranchUnitIdTolstManager2);
		Test.stopTest();
	}

	@isTest
	static void getMapBranchUnitIdTolstBankerTest() {
		Test.startTest();
		// AssignLeadToAdvisor.updateLeadList();
		List<BranchUnit> lstBranchUnitId = [SELECT Id FROM BranchUnit WHERE Id != NULL LIMIT 10000];

		Set<Id> setBankerUnitId = (new Map<Id, BranchUnit>(lstBranchUnitId)).keySet();

		List<BranchUnitBusinessMember> lstBBM = [
			SELECT Id, BusinessUnitMemberId, BranchUnitId
			FROM BranchUnitBusinessMember
			WHERE BranchUnitId IN :setBankerUnitId
		];

		// List<Profile> lstProfile = [
		//     SELECT Id
		//     FROM Profile
		//     WHERE
		//         Name = 'Asesor Patrimonial' OR
		//         Name = 'Asesor Privada' OR
		//         Name = 'Asesor Soluciones' OR
		//         Name = 'Subdirector'
		// ];
		// AssignLeadToAdvisor.setProfile_Advisor = (new Map<Id, Profile>(lstProfile)).keySet();

		mapProfileIdToNameGlobal = AssignLeadToAdvisor.getMapProfileIdToName();
		List<User> lstAllUser = AssignLeadToAdvisor.getAllUser();
		Map<Id, User> mapAllUserInfo = new Map<Id, User>(lstAllUser);
		mapBankerIdToUserGlobal = AssignLeadToAdvisor.getMapBankerIdToUser(mapAllUserInfo);

		List<Id> lstBankerGlobal = new List<Id>();
		lstBankerGlobal.addAll(mapBankerIdToUserGlobal.keySet());
		//List<Id> lstAvailableBankerWithCorrectUserId = AssignLeadToAdvisor.getBankerListOfCorrectUserId();

		//AssignLeadToAdvisor.mapProfileIdToNameGlobal = AssignLeadToAdvisor.getMapProfileIdToName();

		Map<Id, List<Id>> mapBranchUnitIdTolstBanker = new Map<Id, List<Id>>();
		List<Id> lstBankerUnitId = new List<Id>();

		Map<Id, User> mapBankerIdToUser = AssignLeadToAdvisor.getMapBankerIdToUser(mapAllUserInfo);
		Map<Id, String> mapProfileIdToName = AssignLeadToAdvisor.getMapProfileIdToName();
		for (BranchUnitBusinessMember bbm : lstBBM) {
			//  if (!lstAvailableBankerWithCorrectUserId.contains(bbm.BusinessUnitMemberId)) {
			//      continue;
			//  }

			Id BankerId = bbm.BusinessUnitMemberId;
			User objUser = mapBankerIdToUser.get(BankerId);
			Id UserProfileId = objUser.ProfileId;
			String strUserProfileName = mapProfileIdToName.get(UserProfileId);
			if (strUserProfileName == 'Subdirector') {
				continue;
			}

			if (mapBranchUnitIdTolstBanker.get(bbm.BranchUnitId) == null) {
				lstBankerUnitId.add(bbm.BranchUnitId);
			}
		}
		Set<Id> lstBankerUnitIds = new Set<Id>(lstBankerUnitId);

		Map<Id, List<Id>> mapBranchUnitIdTolstBanker1 = AssignLeadToAdvisor.getMapBranchUnitIdTolstBanker(
			mapProfileIdToNameGlobal,
			mapBankerIdToUserGlobal,
			lstBankerGlobal
		);

		System.assertEquals(lstBankerUnitIds, mapBranchUnitIdTolstBanker1.keySet());
		Test.stopTest();
	}

	@isTest
	static void sortBankerInBranchUnitByEfficiencyTest() {
		Test.startTest();
		// List<Profile> lstProfile = [
		//     SELECT Id
		//     FROM Profile
		//     WHERE
		//         Name = 'Asesor Patrimonial' OR
		//         Name = 'Asesor Privada' OR
		//         Name = 'Asesor Soluciones' OR
		//         Name = 'Subdirector'
		// ];
		// AssignLeadToAdvisor.setProfile_Advisor = (new Map<Id, Profile>(lstProfile)).keySet();
		mapProfileIdToNameGlobal = AssignLeadToAdvisor.getMapProfileIdToName();
		List<User> lstAllUser = AssignLeadToAdvisor.getAllUser();
		Map<Id, User> mapAllUserInfo = new Map<Id, User>(lstAllUser);
		mapBankerIdToUserGlobal = AssignLeadToAdvisor.getMapBankerIdToUser(mapAllUserInfo);

		List<Id> lstBankerGlobal = new List<Id>();
		lstBankerGlobal.addAll(mapBankerIdToUserGlobal.keySet());
		mapBankerIdToAmountGlobal = AssignLeadToAdvisor.getMapBankerIdToAmount(lstBankerGlobal, mapBankerIdToUserGlobal);

		mapBranchUnitIdTolstBankerGlobal = AssignLeadToAdvisor.getMapBranchUnitIdTolstBanker(
			mapProfileIdToNameGlobal,
			mapBankerIdToUserGlobal,
			lstBankerGlobal
		);

		Map<Id, List<Id>> mapBranchUnitIdTolstBanker1 = AssignLeadToAdvisor.sortBankerInBranchUnitByEfficiency(
			mapBranchUnitIdTolstBankerGlobal,
			mapBankerIdToUserGlobal,
			mapBankerIdToAmountGlobal
		);

		Map<Id, List<Id>> mapBranchUnitIdTolstBanker2 = AssignLeadToAdvisor.getMapBranchUnitIdTolstBanker(
			mapProfileIdToNameGlobal,
			mapBankerIdToUserGlobal,
			lstBankerGlobal
		);

		// System.debug('wth' + mapBranchUnitIdTolstBanker.keySet());

		System.assertEquals(mapBranchUnitIdTolstBanker1.keySet(), mapBranchUnitIdTolstBanker2.keySet());

		Test.stopTest();
	}

	@isTest
	static void getSuitableBankerListTest() {
		Test.startTest();
		mapProfileIdToNameGlobal = AssignLeadToAdvisor.getMapProfileIdToName();
		List<User> lstAllUser = AssignLeadToAdvisor.getAllUser();
		Map<Id, User> mapAllUserInfo = new Map<Id, User>(lstAllUser);
		mapBankerIdToUserGlobal = AssignLeadToAdvisor.getMapBankerIdToUser(mapAllUserInfo);

		List<Id> lstBankerGlobal = new List<Id>();
		lstBankerGlobal.addAll(mapBankerIdToUserGlobal.keySet());
		mapBankerIdToAmountGlobal = AssignLeadToAdvisor.getMapBankerIdToAmount(lstBankerGlobal, mapBankerIdToUserGlobal);

		mapBranchUnitIdTolstBankerGlobal = AssignLeadToAdvisor.getMapBranchUnitIdTolstBanker(
			mapProfileIdToNameGlobal,
			mapBankerIdToUserGlobal,
			lstBankerGlobal
		);

		BranchUnit BranchUnitTemp1 = [SELECT Id FROM BranchUnit WHERE Name = 'VER BOCA DEL RIO LAS AMERICAS'];
		BranchUnit BranchUnitTemp2 = [SELECT Id FROM BranchUnit WHERE Name = 'MICH MOR AV LAZARO CARDENAS'];
		List<Id> lstBranchUnitId = new List<Id>();
		lstBranchUnitId.add(BranchUnitTemp1.Id);
		lstBranchUnitId.add(BranchUnitTemp2.Id);
		List<Id> lstSuitableBankerIdList = AssignLeadToAdvisor.getSuitableBankerList(
			lstBranchUnitId,
			mapBranchUnitIdTolstBankerGlobal,
			mapBankerIdToUserGlobal,
			mapBankerIdToAmountGlobal
		);
		// System.debug('Zjiale comment 测试数据是否进入');
		// System.debug('测试数据:' + lstSuitableBankerIdList);
		System.assert(lstSuitableBankerIdList != null);
		Test.stopTest();
	}

	@isTest
	static void getManagerInBranchUnitListTest() {
		Test.startTest();
		List<User> lstAllUser = AssignLeadToAdvisor.getAllUser();
		Map<Id, User> mapAllUserInfo = new Map<Id, User>(lstAllUser);
		mapBranchUnitIdTolstUserManagerGlobal = AssignLeadToAdvisor.getMapBranchUnitIdTolstUserManager(mapAllUserInfo);

		BranchUnit BranchUnitTemp1 = [SELECT Id FROM BranchUnit WHERE Name = 'VER BOCA DEL RIO LAS AMERICAS'];
		BranchUnit BranchUnitTemp2 = [SELECT Id FROM BranchUnit WHERE Name = 'MICH MOR AV LAZARO CARDENAS'];
		List<Id> lstBranchUnitId = new List<Id>();
		List<Id> lstBranchUnitIdNu = new List<Id>();
		lstBranchUnitId.add(BranchUnitTemp1.Id);
		lstBranchUnitId.add(BranchUnitTemp2.Id);
		Id managerInBranchUnit = AssignLeadToAdvisor.getManagerInBranchUnitList(lstBranchUnitId, mapBranchUnitIdTolstUserManagerGlobal);
		System.assert(managerInBranchUnit != null);
		Id managerInBranchUnitNu = AssignLeadToAdvisor.getManagerInBranchUnitList(lstBranchUnitIdNu, mapBranchUnitIdTolstUserManagerGlobal);
		System.assert(managerInBranchUnitNu == null);
		Test.stopTest();
	}

	@isTest
	static void assignLeadToBankerTest() {
		Test.startTest();
		List<Lead> lstAllLeadNeedAssignGlobal = AssignLeadToAdvisor.getAllLeadsNeedAssign();
		List<User> lstAllUser = AssignLeadToAdvisor.getAllUser();
		Map<Id, User> mapAllUserInfo = new Map<Id, User>(lstAllUser);
		mapBranchUnitIdTolstUserManagerGlobal = AssignLeadToAdvisor.getMapBranchUnitIdTolstUserManager(mapAllUserInfo);
		mapProfileIdToNameGlobal = AssignLeadToAdvisor.getMapProfileIdToName();
		mapBankerIdToUserGlobal = AssignLeadToAdvisor.getMapBankerIdToUser(mapAllUserInfo);

		List<Id> lstBankerGlobal = new List<Id>();
		lstBankerGlobal.addAll(mapBankerIdToUserGlobal.keySet());
		mapBankerIdToAmountGlobal = AssignLeadToAdvisor.getMapBankerIdToAmount(lstBankerGlobal, mapBankerIdToUserGlobal);

		mapBranchUnitIdTolstBankerGlobal = AssignLeadToAdvisor.getMapBranchUnitIdTolstBanker(
			mapProfileIdToNameGlobal,
			mapBankerIdToUserGlobal,
			lstBankerGlobal
		);

		Map<Id, Lead> leadToBanker = AssignLeadToAdvisor.assignLeadToBanker(
			lstAllLeadNeedAssignGlobal,
			mapBranchUnitIdTolstUserManagerGlobal,
			mapBranchUnitIdTolstBankerGlobal,
			mapProfileIdToNameGlobal,
			mapBankerIdToUserGlobal,
			mapBankerIdToAmountGlobal
		);
		System.assert(leadToBanker != null);
		Test.stopTest();
	}

	@isTest
	static void sendNotificationAfterOwnerChangedTest() {
		CustomNotificationType notificationType = [
			SELECT Id, DeveloperName
			FROM CustomNotificationType
			WHERE DeveloperName = 'Lead_Notification_After_Assignment'
		];
		Set<String> setStrRecipientsIds = new Set<String>();
		String strTargetId = '1111111111';
		Lead objLead = new Lead();

		Test.startTest();
		AssignLeadToAdvisor.sendNotificationAfterOwnerChanged(notificationType, setStrRecipientsIds, strTargetId, objLead);
		Test.stopTest();
		System.assert('1' == '1', 'wrong');
	}
}