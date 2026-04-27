/**
 * @author Tate Shi
 * @date 11/29/2021
 * @description
 *     Test for LeadAssignBatch
 */
@isTest
public with sharing class LeadAssignBatchTest {
	private static String strFirstName = 'new Lead';
	private static String strNew = 'new';
	private static String strStatue = 'Asignado';
	@testSetup
	static void prepareData() {
		// System.debug(' Test setup start ');
		Datetime a = Datetime.now();
		// List<Event> eventList = new List<Event>();
		// List<Task> taskList = new List<Task>();
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
		// System.debug(' Test insert lstUser ');

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
		// System.debug(' Test insert lstBanker');

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
		// System.debug(' Test insert lstBranchUnit ');

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
		// System.debug(' Test insert lstAccount ');

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
		// System.debug(' Test insert lstOpp');

		//Create Contact data because of the field FinServ__ReferredByContact__c in lead(VALIDATION RULE)
		for (integer i = 0; i < 100; i++) {
			lstContact.add(new Contact(FirstName = 'test', LastName = 'Contact' + i));
		}
		insert lstContact;
		// System.debug(' Test insert Contact ');

		User itUser = new User();
		String INTERATION_USER = Label.Integration_User;
		itUser = [SELECT Id FROM User WHERE Name = :INTERATION_USER];
		System.runAs(itUser) {
			List<Lead> lstLead = new List<Lead>();
			for (Integer i = 0; i < 100; i++) {
				if (i < 30) {
					Lead leadTemp = new Lead();
					leadTemp.FirstName = strFirstName;
					leadTemp.LastName = strNew + i;
					leadTemp.PostalCode = '30000';
					leadTemp.Status = strStatue;
					leadTemp.OwnerId = itUser.Id;
					leadTemp.FinServ__ExpressedInterest__c = 'Banca Soluciones';
					leadTemp.FinServ__ReferredByContact__c = lstContact[Math.mod(i, 10)].Id;
					leadTemp.Inversion_Inicial__c = 'Menos de $500,000';
					lstLead.add(leadTemp);
				} else if (i < 60) {
					Lead leadTemp = new Lead();
					leadTemp.FirstName = strFirstName;
					leadTemp.LastName = strNew + i;
					leadTemp.PostalCode = '23555';
					leadTemp.Status = strStatue;
					leadTemp.OwnerId = itUser.Id;
					leadTemp.FinServ__ExpressedInterest__c = 'Banca Privada';
					leadTemp.FinServ__ReferredByContact__c = lstContact[Math.mod(i, 10)].Id;
					leadTemp.Inversion_Inicial__c = null;
					lstLead.add(leadTemp);
				} else if (i < 90) {
					Lead leadTemp = new Lead();
					leadTemp.FirstName = strFirstName;
					leadTemp.LastName = strNew + i;
					leadTemp.PostalCode = '23555';
					leadTemp.Status = strStatue;
					leadTemp.OwnerId = itUser.Id;
					leadTemp.FinServ__ExpressedInterest__c = 'Banca Patrimonial';
					leadTemp.FinServ__ReferredByContact__c = lstContact[Math.mod(i, 10)].Id;
					leadTemp.Inversion_Inicial__c = null;
					// 'Mas de $1,500,000';
					lstLead.add(leadTemp);
				} else {
					Lead leadTemp = new Lead();
					leadTemp.FirstName = strFirstName;
					leadTemp.LastName = strNew + i;
					leadTemp.PostalCode = '59999';
					leadTemp.Status = strStatue;
					leadTemp.OwnerId = itUser.Id;
					leadTemp.FinServ__ExpressedInterest__c = null;
					leadTemp.FinServ__ReferredByContact__c = lstContact[Math.mod(i, 10)].Id;
					leadTemp.Inversion_Inicial__c = null;
					lstLead.add(leadTemp);
				}
			}
			insert lstLead;
			// System.debug(' Test insert Lead ');
		}

		//create Banker and BranchUnit data

		Datetime b = Datetime.now();
		// System.debug('Test Make Date Time is **********************************************************************: ' + (b.getTime() - a.getTime())/1000);
	}

	@isTest
	static void testBatchLeadAssignment() {
		// System.debug('Test method test1()');
		Test.startTest();
		LeadAssignBatch leadAssignBatchObj = new LeadAssignBatch();
		// Datetime dt0 = Datetime.now();
		String jobId = Database.executeBatch(leadAssignBatchObj, 100);
		// Datetime dt1 = Datetime.now();
		// System.debug('In Test, Execute time is : ' + (dt1.getTime() - dt0.getTime()));
		System.assert(jobId != null);
		Test.stopTest();
	}
}