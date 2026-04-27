/**
 * @author Tate Shi
 * @create 10/09/2021
 * @description  Assigin Leads to Advisor
 */
public without sharing class AssignLeadToAdvisor {
	// Lead Status: New
	private static final String LEAD_STATUS_NEW = 'Asignado';
	// Lead Status:Converted
	private static final String LEAD_STATUS_CONVERTED = 'Convertido';
	// Lead Status: Unconverted
	private static final String LEAD_STATUS_UNCONVERTED = 'No Convertido';

	// Profile : Asesor Patrimonial
	private static final String PROFILE_ASESOR_PATRIMONIAL = 'Asesor Patrimonial';
	// Profile : Asesor Privada
	private static final String PROFILE_ASESOR_PRIVATE = 'Asesor Privada';
	// Profile : Asesor Soluciones
	private static final String PROFILE_ASESOR_SOLUTION = 'Asesor Soluciones';
	// Profile : Subdirector (Manager)
	private static final String PROFILE_MANAGER = 'Subdirector';

	// Lead.ExpressedInterest : Banca Patrimonial
	private static final String LEAD_EI_PATRIMONIAL = 'Banca Patrimonial';
	// Lead.ExpressedInterest : Banca Privada
	private static final String LEAD_EI_PRIVATE = 'Banca Privada';
	// Lead.ExpressedInterest : Banca Soluciones
	private static final String LEAD_EI_SOLUTION = 'Banca Soluciones';

	// Lead.Inversion_Inicial__c : Menos de $500,000
	private static final String LEAD_II_SOLUTION = 'Menos de $500,000';
	// Lead.Inversion_Inicial__c : Entre $500,000 y $1,500,000
	private static final String LEAD_II_PATRIMONIAL = 'Entre $500,000 y $1,500,000';
	// Lead.Inversion_Inicial__c : Más de $1,500,000
	private static final String LEAD_II_PRIVATE = 'Mas de $1,500,000';

	// Custom Label : Integration User
	private static String LABEL_INTEGRATION_USER = 'IntegrationUser';
	// Custom Label : Integration User
	private static String LABEL_MKT_USER = 'MC Connect-CRM';
	// Custom Label : The_Max_Capacity
	private static Integer intMaxCapacity = 50000;
	// Custom Label : The_Lowest_Effectiveness
	private static Double dbLowestEffectiveness = 0.1;

	// First Day Of this Month
	private static Date FIRST_DAY_OF_MONTH = Date.today().toStartOfMonth();

	// All Lead need Assign, include Lead from IntegrationUser and Lead need Reassign
	private static List<Lead> lstAllLeadNeedAssignGlobal = null;

	//Error Log : Category
	private static final String CATEGORY = 'Assignment Of The Lead';
	//Error Log : Error File Name
	private static final String ERROR_FILE = 'AssignLeadToAdvisor.cls';

	/**
	 * **Main Mathod**
	 * convert map<Id, Lead> to List<Lead>
	 * update Lead List
	 */
	/*public static void updateLeadList() {
        try {
            if (Label.The_Max_Capacity != null) {
                intMaxCapacity = Integer.valueOf(Label.The_Max_Capacity);
            }
            if (Label.The_Lowest_Effectiveness != null) {
                dbLowestEffectiveness = Double.valueOf(Label.The_Lowest_Effectiveness);
            }

            Datetime start = Datetime.now();
            // Get all Lead need Assign
            lstAllLeadNeedAssignGlobal = getAllLeadsNeedAssign();
            Datetime me1 = Datetime.now();
            // Get user Info, Map Id to User
            List<User> lstAllUser = getAllUser();
            Map<Id, User> mapAllUserInfo = new Map<Id, User>(lstAllUser);
            Datetime me2 = Datetime.now();
            // get Profile Id to Name
            Map<Id, String> mapProfileIdToNameGlobal = getMapProfileIdToName();
            Datetime me3 = Datetime.now();
            // map Banker Id to User, Banker must have a corresponding User
            Map<Id, User> mapBankerIdToUserGlobal = getMapBankerIdToUser(mapAllUserInfo);
            Datetime me4 = Datetime.now();

            // Banker Id with corresponding User
            List<Id> lstBankerGlobal = new List<Id>();
            lstBankerGlobal.addAll(mapBankerIdToUserGlobal.keySet());
            Datetime me5 = Datetime.now();
            // get Banker Amount of Open/Closed Opp/Lead
            Map<Id, List<Integer>> mapBankerIdToAmountGlobal = getMapBankerIdToAmount(lstBankerGlobal, mapBankerIdToUserGlobal);
            
            // lstBankerGlobal1 = getBankerListOfCorrectUserId();
            Map<Id, List<Id>> mapBranchUnitIdTolstBankerGlobal = getMapBranchUnitIdTolstBanker(mapProfileIdToNameGlobal,
                                                                                               mapBankerIdToUserGlobal,
                                                                                               lstBankerGlobal);
            Map<Id, List<Id>> mapBranchUnitIdTolstUserManagerGlobal = getMapBranchUnitIdTolstUserManager(mapAllUserInfo);
            Datetime me6 = Datetime.now();
            System.debug('Before assignment');
            Map<Id, Lead> mapLeadToUpdate = assignLeadToBanker(lstAllLeadNeedAssignGlobal, 
                                                               mapBranchUnitIdTolstUserManagerGlobal, 
                                                               mapBranchUnitIdTolstBankerGlobal,
                                                               mapProfileIdToNameGlobal,
                                                               mapBankerIdToUserGlobal,
                                                               mapBankerIdToAmountGlobal);
            Datetime me00 = Datetime.now();
            System.debug('After assignment');
            List<Lead> lstLeadToUpdate = mapLeadToUpdate.values();
            update lstLeadToUpdate;
            Datetime me7 = Datetime.now();
            //Write Log
            LogCommon.WriteLog(CATEGORY, ERROR_FILE, null, null);
            Datetime endoo = Datetime.now();
            System.debug('log time is : ' + (endoo.getTime() - me7.getTime()));
            System.debug('get update Lead list is : ' + (me00.getTime() - me6.getTime()));
            System.debug('update time is :' + (me7.getTime() - me00.getTime()));
            System.debug('get banker/manager time is : ' + (me6.getTime() - me5.getTime()));
            System.debug('getMapBankerIdToAmount time is : ' + (me5.getTime() - me4.getTime()));
            System.debug('getMapBankerIdToUser time is : ' + (me4.getTime() - me3.getTime()));
            System.debug('getMapProfileIdToName time is : ' + (me3.getTime() - me2.getTime()));
            System.debug('getAllUser time is : ' + (me2.getTime() - me1.getTime()));
            System.debug('getAllLeadsNeedAssign time is : ' + (me1.getTime() - start.getTime()));
            System.debug('all time is : ' + (endoo.getTime() - start.getTime()));
            System.debug('lstAllLeadNeedAssignGlobal.size() is : ' + lstAllLeadNeedAssignGlobal.size());
            System.debug('lstLeadToUpdate.size() is : ' + lstLeadToUpdate.size());
            for (integer i = 0; i < 20 ;i++) {
                System.debug('delevlop console still can\'t drag to the end, even use keyboard, write extra lines');
            }
        }
        catch(Exception e) {
            System.debug('Error1 Message : ' + e.getMessage());
            System.debug('Error1 Line No : ' + e.getLineNumber());

            // Write Log
            String strErrorMessage = e.getMessage();
            Integer intErrorLineNumber = e.getLineNumber();
            LogCommon.WriteLog(CATEGORY, ERROR_FILE, strErrorMessage, intErrorLineNumber);
        }
    }*/

	/**
	 * search for all PostalMapping
	 * @return List<PostalMapping__mdt>
	 */
	public static List<PostalMapping__mdt> getAllPostalMapping() {
		return [SELECT Id, Label, PostalCodeFrm__c, PostalCodeTo__c, Office__c FROM PostalMapping__mdt ORDER BY PostalCodeFrm__c ASC];
	}

	/**
	 * get all opportunity
	 * @return List<Opportunity>
	 */
	public static List<Opportunity> getAllOpportunity() {
		return [SELECT Id, Name, OwnerId, IsClosed, CloseDate, StageName, LastModifiedDate FROM Opportunity LIMIT 50000];
	}

	/**
	 * get all Lead
	 * @return List<Lead>
	 */
	public static List<Lead> getAllLead() {
		List<Lead> lstLead = [
			SELECT Id, Name, FinServ__ExpressedInterest__c, PostalCode, Status, OwnerId, LastModifiedDate
			FROM LEAD
			WHERE Id != NULL
			LIMIT 50000
		];
		return lstLead;
	}

	/**
	 * search for Leads with status as 'new' and CreatedBy Marketing Cloud
	 * @return Set<Lead Id>
	 */
	public static Set<Id> getNewLeadsToAssign() {
		Set<Id> resultIds = new Set<Id>();
		if (Label.Integration_User != null) {
			LABEL_INTEGRATION_USER = Label.Integration_User;
		}

		// String strUserId = null;
		List<User> lstUser = [SELECT Id FROM User WHERE Name = :LABEL_INTEGRATION_USER OR NAME = :LABEL_MKT_USER LIMIT 2];

		if (lstUser.size() > 0) {
			// strUserId = lstUser.get(0).Id;

			List<Lead> lstLead = [SELECT Id FROM LEAD WHERE Status = :LEAD_STATUS_NEW AND CreatedById IN :lstUser AND OwnerId IN :lstUser];
			for (Lead objLead : lstLead) {
				resultIds.add(objLead.Id);
			}
		}

		return resultIds;
	}

	/**
	 * search for Leads need to be reassigned
	 * remove current owner
	 * @return Set<Lead Id>
	 */
	public static Set<Id> getLeadsToReassign() {
		Set<Id> setLeadId24HNoDeal = new Set<Id>();
		// Select all the event of lead without dealing in past 24 hours
		Set<Id> setLeadIdFromEvent24HDeal = new Set<Id>();
		Set<Id> setLeadIdFromTask24HDeal = new Set<Id>();
		Datetime dt24HoursBefore = System.now() - 1;

		try {
			List<Event> lstEvent = [SELECT Id, WhoId FROM Event WHERE LastModifiedDate > :dt24HoursBefore];
			if (lstEvent.size() > 0) {
				for (Event objEvt : lstEvent) {
					if (objEvt.WhoId != null && objEvt.WhoId.getSobjectType() == Lead.getSobjectType()) {
						setLeadIdFromEvent24HDeal.add(objEvt.WhoId);
					}
				}
			}

			// Select all the tasks of leads without dealing in past 24 hours
			List<Task> lstTask = [SELECT Id, WhoId FROM Task WHERE LastModifiedDate > :dt24HoursBefore];
			// get both events and tasks of the lead without dealing in past 24 hours
			if (lstTask.size() > 0) {
				for (Task objTsk : lstTask) {
					if (objTsk.WhoId != null && objTsk.WhoId.getSobjectType() == Lead.getSobjectType()) {
						setLeadIdFromTask24HDeal.add(objTsk.WhoId);
					}
				}
			}

			// Select all the lead without dealing in past 24 hours

			List<User> lstUser = [SELECT Id FROM User WHERE Name = :LABEL_INTEGRATION_USER OR NAME = :LABEL_MKT_USER LIMIT 2];
			List<Lead> lstLead = [
				SELECT Id, OwnerId
				FROM Lead
				WHERE
					LastModifiedDate < :dt24HoursBefore
					AND status != :LEAD_STATUS_CONVERTED
					AND status != :LEAD_STATUS_UNCONVERTED
					AND CreatedById IN :lstUser
			];

			// get both events and tasks of the lead, and also leads without dealing in past 24 hours
			if (lstLead.size() > 0) {
				for (Lead objLd : lstLead) {
					if (setLeadIdFromEvent24HDeal.contains(objLd.Id) || setLeadIdFromTask24HDeal.contains(objLd.Id)) {
						continue;
					} else {
						setLeadId24HNoDeal.add(objLd.Id);
					}
				}
			}
		} catch (Exception e) {
			// System.debug('Error2 Message : ' + e.getMessage());
			// System.debug('Error2 Line No : ' + e.getLineNumber());
		}

		return setLeadId24HNoDeal;
	}

	/**
	 * get all the leads need to be assigned
	 * which means merge new Lead , Lead to be reassigned
	 * @return List<Lead>
	 */
	public static List<Lead> getAllLeadsNeedAssign() {
		// System.debug('---------------111111111111');
		Set<Id> setLeadId24HNoDeal = getLeadsToReassign();
		// System.debug('---------------222222222222222222');
		Set<Id> setAllLeadId = getNewLeadsToAssign();
		// System.debug('---------------3333333333333');
		setAllLeadId.addAll(setLeadId24HNoDeal);
		// System.debug('---------------4444444444');
		List<Lead> lstNeedAssign = [
			SELECT Id, Name, FinServ__ExpressedInterest__c, PostalCode, Status, OwnerId, Inversion_Inicial__c
			FROM Lead
			WHERE Id IN :setAllLeadId
		];

		return lstNeedAssign;
	}

	/**
	 * get all User include Normal Banker and Manager
	 * @return List<User>
	 */
	public static List<User> getAllUser() {
		List<User> lstAllAsesorUser = new List<User>();
		List<Profile> lstProfile = [
			SELECT Id
			FROM Profile
			WHERE
				Name = :PROFILE_ASESOR_PATRIMONIAL
				OR Name = :PROFILE_ASESOR_PRIVATE
				OR Name = :PROFILE_ASESOR_SOLUTION
				OR Name = :PROFILE_MANAGER
		];

		Set<Id> setProId = new Set<Id>();
		for (Profile pro : lstProfile) {
			setProId.add(pro.Id);
		}

		if (setProId.size() > 0) {
			lstAllAsesorUser = [
				SELECT Id, Name, ProfileId, UserRoleId, Division
				FROM User
				WHERE IsActive = TRUE AND ProfileId IN :setProId
			];
		}

		return lstAllAsesorUser;
	}

	/**
	 * get Availbale Banker
	 * Disponible__c = TRUE
	 * @return List<Banker>
	 */
	public static List<Banker> getAvailableBanker() {
		return [SELECT Id, Name, Level, UserOrContactId FROM Banker WHERE Disponible__c = TRUE];
	}

	/**
	 * get Banker Id To User
	 * @return Map<Banker Id, User >
	 */
	public static Map<Id, User> getMapBankerIdToUser(Map<Id, User> mapAllUserInfo) {
		Map<Id, User> mapBankerIdToUser = new Map<Id, User>();
		try {
			List<Banker> lstBanker = getAvailableBanker();
			Set<Id> setUserId = mapAllUserInfo.keySet();

			for (Banker objBanker : lstBanker) {
				// System.debug('dio debug : all banker' + objBanker.Id + ', ' + objBanker.Name);
				if (setUserId.contains(objBanker.UserOrContactId)) {
					// found User, legal Banker
					//mapping Banker Id --> User Id
					mapBankerIdToUser.put(objBanker.Id, mapAllUserInfo.get(objBanker.UserOrContactId));
				} else {
					// haven't found User , illegal Banker
					continue;
				}
			}
		} catch (Exception e) {
			// System.debug('Error4 Message : ' + e.getMessage());
			// System.debug('Error4 Line No : ' + e.getLineNumber());
		}
		return mapBankerIdToUser;
	}

	/**
	 * all legal Banker
	 * User Id Set contains Banker.UserOrContactId
	 * @return List<Banker Id>
	 */
	/*public static List<Id> getBankerListOfCorrectUserId() {
        List<Id> lstBankerId = new List<Id>();
        lstBankerId.addAll(mapBankerIdToUserGlobal.keySet());
        return lstBankerId;
    }*/

	/**
	 * map Banker Id To Amount of open/closed Lead/Opp
	 * @return Map<Id, List<Integer>>
	 */
	public static Map<Id, List<Integer>> getMapBankerIdToAmount(List<Id> lstBankerGlobal, Map<Id, User> mapBankerIdToUserGlobal) {
		Map<Id, List<Integer>> mapBankerIdToAmount = new Map<Id, List<Integer>>();
		List<Lead> lstLead = getAllLead();
		List<Opportunity> lstOpportunity = getAllOpportunity();

		for (Id objBankerId : lstBankerGlobal) {
			Integer Amount_Of_Open_Lead_Calendar_Month = 0;
			Integer Amount_Of_Closed_Lead_Calendar_Month = 0;
			Integer Amount_Of_Open_Opp_Calendar_Month = 0;
			Integer Amount_Of_Closed_Opp_Calendar_Month = 0;
			User objUser = mapBankerIdToUserGlobal.get(objBankerId);

			//calculate number Of Leads
			for (Lead objLead : lstLead) {
				String strLeadStatus = objLead.Status;
				//Lead Managed by current Banker, in current Calendar Month
				if (objLead.OwnerId == objUser.Id && objLead.LastModifiedDate >= FIRST_DAY_OF_MONTH) {
					//Open lead
					if (strLeadStatus != LEAD_STATUS_CONVERTED && strLeadStatus != LEAD_STATUS_UNCONVERTED) {
						Amount_Of_Open_Lead_Calendar_Month++;
						continue;
					}
					//Closed Lead
					if (strLeadStatus == LEAD_STATUS_CONVERTED || strLeadStatus == LEAD_STATUS_UNCONVERTED) {
						Amount_Of_Closed_Lead_Calendar_Month++;
						continue;
					}
				}
			}

			//calculate number of Opportunitys
			for (Opportunity objOpp : lstOpportunity) {
				Boolean blIsOppClosed = false;

				String strOppWonStageName = 'Cerrada Ganada';
				if (Label.Opp_Won_StageName != null) {
					strOppWonStageName = Label.Opp_Won_StageName;
				}

				if (objOpp.StageName == strOppWonStageName) {
					blIsOppClosed = true;
				}

				//Opp Managed by current Banker, in current Calendar Month
				if (objOpp.OwnerId == objUser.Id && objOpp.LastModifiedDate >= FIRST_DAY_OF_MONTH) {
					//Open Opp
					if (blIsOppClosed == false) {
						Amount_Of_Open_Opp_Calendar_Month++;
						continue;
					}
					//Colsed Opp
					if (blIsOppClosed == true) {
						Amount_Of_Closed_Opp_Calendar_Month++;
						continue;
					}
				}
			}

			List<Integer> lstAmount_Integer = new List<Integer>();
			lstAmount_Integer.add(Amount_Of_Open_Lead_Calendar_Month);
			lstAmount_Integer.add(Amount_Of_Closed_Lead_Calendar_Month);
			lstAmount_Integer.add(Amount_Of_Open_Opp_Calendar_Month);
			lstAmount_Integer.add(Amount_Of_Closed_Opp_Calendar_Month);
			//mapping Banker Id --> Number List
			mapBankerIdToAmount.put(objBankerId, lstAmount_Integer);
		}
		return mapBankerIdToAmount;
	}

	/**
	 * get all profile
	 * @return Map<Profile Id, Profile Name>
	 */
	public static Map<Id, String> getMapProfileIdToName() {
		List<Profile> lstProfile = [SELECT Id, Name FROM Profile LIMIT 50000];

		Map<Id, String> mapProfileIdToName = new Map<Id, String>();
		for (Profile objProfile : lstProfile) {
			mapProfileIdToName.put(objProfile.Id, objProfile.Name);
		}
		// System.debug('mapProfileIdToName is : ' + mapProfileIdToName);

		return mapProfileIdToName;
	}

	/**
	 * get All Branch Unit
	 * map Branch Unit Label To Id
	 * @return Map<Branch Unit Label, Branch Unit Id>
	 */
	public static Map<String, Id> mapBranchUnitLabelToId() {
		List<BranchUnit> lstAllBranchUnit = [
			SELECT Id, Name
			FROM BranchUnit
			WHERE isActive = TRUE
			// TOBE Continued if need time range
		];

		Map<String, Id> mapBULabelToId = new Map<String, Id>();

		for (Branchunit bu : lstAllBranchUnit) {
			mapBULabelToId.put(bu.Name, bu.Id);
		}

		return mapBULabelToId;
	}

	/**
	 * connect each Lead to Branch Unit by PostalCodemapping
	 * @return Map<LeadId, BranchUnitId List>
	 */
	public static Map<Id, List<Id>> getMapLeadToBranchUnitList(List<Lead> lstLeadNeedAssign) {
		//Map of Postal Code with Branch
		List<PostalMapping__mdt> lstPostalCodeMapping = getAllPostalMapping();
		//All Leads need to be assigned
		List<Lead> lstAllLead = lstLeadNeedAssign;
		//Lead with Error Log
		List<Lead> lstErrorLead = new List<Lead>();
		//Map<LeadId, BranchUnitId>
		Map<Id, List<Id>> mapLeadIdToBranchUnitIdList = new Map<Id, List<Id>>();

		//Map Branch Unit Label to Id
		Map<String, Id> mapBULabelToId = mapBranchUnitLabelToId();

		if (lstPostalCodeMapping != null && lstAllLead != null) {
			//connect each lead to branch by Postalmapping
			for (Lead objLd : lstAllLead) {
				String strLeadPostalCode = objLd.PostalCode.trim();
				Integer intLeadPostalCode = Integer.valueOf(strLeadPostalCode);
				Boolean blMapped = false;
				for (PostalMapping__mdt pcm : lstPostalCodeMapping) {
					String strFromPC = pcm.PostalCodeFrm__c.trim();
					String strEndPC = pcm.PostalCodeTo__c.trim();
					Integer intFromPC = Integer.valueOf(strFromPC);
					Integer intEndPC = Integer.valueOf(strEndPC);
					//found corresponding Branch Unit
					if (intLeadPostalCode >= intFromPC && intLeadPostalCode <= intEndPC) {
						blMapped = true;
						//pcm.office__c can contain multiple Branch Unit
						//one Lead - one or more Branch Unit Label

						List<String> lstBranchUnitLabel_str = pcm.Office__c.split('/');

						// Boolean blAnyError = false;
						List<Id> lstBranchUnitId = new List<Id>();

						// Add BranchUnit To List
						for (String strOffice : lstBranchUnitLabel_str) {
							//format
							strOffice = strOffice.trim();
							if (mapBULabelToId.get(strOffice) != null) {
								Id BranchUnitId = mapBULabelToId.get(strOffice);
								lstBranchUnitId.add(BranchUnitId);
							} else {
								// with correct PostalCode, but have no BU in current DB
								// blAnyError = true;
								// System.debug('Didn\'t find BranchUnit: ' + strOffice + ' in current DB');
								// lstErrorLead.add(objLd);
								continue;
								// break;
							}
						}

						if (lstBranchUnitId.size() == 0) {
							// System.debug('for Lead : ' + objLd.Name + ', have right PostalCode :' + objLd.PostalCode + ', but didn\'t find BranchUnit in current DB');
							lstErrorLead.add(objLd);
						} else {
							mapLeadIdToBranchUnitIdList.put(objLd.Id, lstBranchUnitId);
						}

						// if(!blAnyError){
						// Mapping Lead Id --> BranchUnit Id List
						// mapLeadIdToBranchUnitIdList.put(objLd.Id, lstBranchUnitId);
						// System.debug('tianhao for objleadname:' + objLd.Name);
						// System.debug('tianhao for lstBranchUnitId:' + lstBranchUnitId);
						// }
						break;
					}
				}
				// if the lead is not mapped
				if (!blMapped) {
					lstErrorLead.add(objLd);
				}
			}

			// write error log
			if (lstErrorLead.size() > 0) {
				String strErrorMessage = 'Lead List with WRONG PostalCode or NOT Found BU in current DB:\n';
				for (Lead objLead : lstErrorLead) {
					strErrorMessage += objLead.Id + ' : ' + objLead.Name + '   PC: ' + objLead.PostalCode + '\n';
				}
				LogCommon.writeLog(CATEGORY, ERROR_FILE, strErrorMessage, null);
			}
			// System.debug('lstErrorLead is : ' + lstErrorLead);
		}

		return mapLeadIdToBranchUnitIdList;
	}

	/**
	 * Branch Unit - Banker (Manager)
	 * @return Map<Branch Unit Id, List<Banker>>
	 */
	public static Map<Id, List<Id>> getMapBranchUnitIdTolstUserManager(Map<Id, User> mapAllUserInfo) {
		// Map<Branch Unit Id, List<Banker>>
		Map<Id, List<Id>> mapBranchUnitIdTolstManager = new Map<Id, List<Id>>();

		//select BranchUnit Id
		List<BranchUnit> lstBranchUnit = [SELECT Id, Name FROM BranchUnit WHERE isActive = TRUE];

		for (BranchUnit objBU : lstBranchUnit) {
			for (User objUser : mapAllUserInfo.values()) {
				String strDivision = objUser.Division;
				if (objBU.Name == strDivision) {
					if (mapBranchUnitIdTolstManager.get(objBU.Id) == null) {
						List<Id> lstUserId = new List<Id>();
						lstUserId.add(objUser.Id);
						// Mapping BranchUnitId --> User List (Manager)
						mapBranchUnitIdTolstManager.put(objBU.Id, lstUserId);
					} else {
						mapBranchUnitIdTolstManager.get(objBU.Id).add(objUser.Id);
					}
				}
			}
		}

		return mapBranchUnitIdTolstManager;
	}

	/**
	 * Manager Not included
	 * @return Map<Branch Unit Id, List<Banker>>
	 */
	public static Map<Id, List<Id>> getMapBranchUnitIdTolstBanker(
		Map<Id, String> mapProfileIdToNameGlobal,
		Map<Id, User> mapBankerIdToUserGlobal,
		List<Id> lstBankerGlobal
	) {
		//select BranchUnit Id
		List<BranchUnit> lstBranchUnitId = [SELECT Id, Name FROM BranchUnit WHERE isActive = TRUE];

		Set<Id> setBankerUnitId = (new Map<Id, BranchUnit>(lstBranchUnitId)).keySet();

		List<BranchUnitBusinessMember> lstBBM = [
			SELECT Id, BusinessUnitMemberId, BranchUnitId
			FROM BranchUnitBusinessMember
			WHERE BranchUnitId IN :setBankerUnitId
		];

		Map<Id, List<Id>> mapBranchUnitIdTolstBanker = new Map<Id, List<Id>>();

		for (BranchUnitBusinessMember bbm : lstBBM) {
			Id BankerId = bbm.BusinessUnitMemberId;
			Id BranchUnitId = bbm.BranchUnitId;

			//  remove Banker don`t match assignable condition : available, correct user FROM BBM
			if (!lstBankerGlobal.contains(BankerId)) {
				continue;
			}

			// remove Manager
			User objUser = mapBankerIdToUserGlobal.get(BankerId);
			Id UserProfileId = objUser.ProfileId;
			String strUserProfileName = mapProfileIdToNameGlobal.get(UserProfileId);
			if (strUserProfileName == PROFILE_MANAGER) {
				continue;
			}

			// no Banker list under the key Branch Unit
			if (mapBranchUnitIdTolstBanker.get(BranchUnitId) == null) {
				List<Id> lstBankerId = new List<Id>();
				lstBankerId.add(BankerId);
				mapBranchUnitIdTolstBanker.put(BranchUnitId, lstBankerId);
			} else {
				// have Banker List under the key Branch Unit
				// Mapping BranchUnit Id --> Banker Id List
				mapBranchUnitIdTolstBanker.get(BranchUnitId).add(BankerId);
			}
		}

		return mapBranchUnitIdTolstBanker;
	}

	/**
	 * remove Capacity Larger than 50
	 * sort Banker List by Effectiveness DES
	 * @return map<Branch Unit Id, List<Banker>>
	 */
	public static Map<Id, List<Id>> sortBankerInBranchUnitByEfficiency(
		Map<Id, List<Id>> mapBranchUnitIdTolstBankerAll,
		Map<Id, User> mapBankerIdToUserGlobal,
		Map<Id, List<Integer>> mapBankerIdToAmountGlobal
	) {
		//Map<Branch Unit Id, List<Banker>>, Manager not included
		Map<Id, List<Id>> mapBranchUnitIdTolstBanker = mapBranchUnitIdTolstBankerAll;
		for (Id key : mapBranchUnitIdTolstBanker.keySet()) {
			List<Id> lstBanker = mapBranchUnitIdTolstBanker.get(key);

			//remove Capacity larger than 50，Effectiveness less than 10%

			for (Integer i = lstBanker.size() - 1; i >= 0; i--) {
				Id objBankerId = lstBanker.get(i);
				// System.debug('current banker is : ' + objBankerId);
				User objUser = mapBankerIdToUserGlobal.get(objBankerId);
				// Banker without corresponding User
				if (objUser == null) {
					lstBanker.remove(i);
					continue;
				}

				Integer intOpenLead = 0;
				Integer intOpenOpp = 0;
				List<Integer> lstAmountGlobal = mapBankerIdToAmountGlobal.get(objBankerId);
				if (lstAmountGlobal != null && lstAmountGlobal.size() > 0) {
					intOpenLead = lstAmountGlobal[0];
					intOpenOpp = lstAmountGlobal[2];
				}

				Integer intOpenLeadOpp = intOpenLead + intOpenOpp;
				Integer intSummary = ActinverCommon.doSummaryForList(lstAmountGlobal);

				Double dbEffectiveness = 1;
				if (intSummary > 0 && (intSummary != intOpenLeadOpp)) {
					dbEffectiveness = (intSummary - intOpenLeadOpp) / Double.valueOf(intSummary);
				}

				// Capacity >= 50, Effectiveness < 10%
				// Label : The Max Capacoty, The Lowest Effectiveness
				// Integer intMaxCapacity = 50;
				// if (Label.The_Max_Capacity != null) {
				//     intMaxCapacity = Integer.valueOf(Label.The_Max_Capacity);
				// }

				// Double dbLowestEffectiveness = 0.1;
				// if (Label.The_Lowest_Effectiveness != null) {
				//     dbLowestEffectiveness = Double.valueOf(Label.The_Lowest_Effectiveness);
				// }

				if (intOpenLeadOpp >= intMaxCapacity || dbEffectiveness <= dbLowestEffectiveness) {
					lstBanker.remove(i);
					continue;
				}
			}

			// Sort the banker list
			if (lstBanker.size() > 1) {
				lstBanker = ActinverCommon.doQuickSort(lstBanker, mapBankerIdToAmountGlobal);
			}
			// System.debug('After remove: lstBanker2 ' + lstBanker);
			mapBranchUnitIdTolstBanker.put(key, lstBanker);
		}

		return mapBranchUnitIdTolstBanker;
	}

	/**
	 * recursive call
	 * find suitable Branch Unit in Branch Unit List
	 * return null if all Branch Units are not available
	 * @return List<Banker>
	 */
	public static List<Id> getSuitableBankerList(
		List<Id> lstBranchUnitId,
		Map<Id, List<Id>> mapBranchUnitIdTolstBankerOrigin,
		Map<Id, User> mapBankerIdToUserGlobal,
		Map<Id, List<Integer>> mapBankerIdToAmountGlobal
	) {
		List<Id> lstBranchUnitIdTmp = new List<Id>(lstBranchUnitId);
		//Map<Branch Unit Id, sorted Banker List>
		Map<Id, List<Id>> mapSortedBranchUnitIdTolstBanker = sortBankerInBranchUnitByEfficiency(
			mapBranchUnitIdTolstBankerOrigin,
			mapBankerIdToUserGlobal,
			mapBankerIdToAmountGlobal
		);
		// System.debug('Sub getSuitableBankerList 1: ' + mapSortedBranchUnitIdTolstBanker);

		if (lstBranchUnitIdTmp.size() > 0) {
			Integer intRandomIndex = Math.mod((Integer) (Math.random() * 1000000), lstBranchUnitIdTmp.size());
			List<Id> lstBanker = mapSortedBranchUnitIdTolstBanker.get(lstBranchUnitIdTmp[intRandomIndex]); // 已经去除Manager
			// System.debug('lstBanker is : ' + lstBanker);
			if (lstBanker != null && lstBanker.size() > 0) {
				// have banekr to assign
				return lstBanker;
			} else {
				// have no banker to assign
				lstBranchUnitIdTmp.remove(intRandomIndex);
				if (lstBranchUnitIdTmp.size() > 0) {
					return getSuitableBankerList(
						lstBranchUnitIdTmp,
						mapBranchUnitIdTolstBankerOrigin,
						mapBankerIdToUserGlobal,
						mapBankerIdToAmountGlobal
					);
				} else {
					return null;
				}
			}
		} else {
			return null;
		}
	}

	/**
	 * only used when getSuitableBnakerList return null
	 * find one Random Manager in Branch Unit List
	 * @return User Id (Manager)
	 */
	public static Id getManagerInBranchUnitList(List<Id> lstBranchUnitId, Map<Id, List<Id>> mapBranchUnitIdTolstUserManagerOrigin) {
		// System.debug('进入从BranchUnit获取Manager');
		Map<Id, List<Id>> mapBranchUnitIdTolstUserManager = mapBranchUnitIdTolstUserManagerOrigin;

		if (lstBranchUnitId.size() > 0) {
			Integer intRandomIndex = Math.mod((Integer) (Math.random() * 1000000), lstBranchUnitId.size());
			List<Id> lstUser_Manager = mapBranchUnitIdTolstUserManager.get(lstBranchUnitId[intRandomIndex]);
			if (lstUser_Manager != null && lstUser_Manager.size() > 0) {
				Integer intRandomIndexManager = Math.mod((Integer) (Math.random() * 1000000), lstUser_Manager.size());
				return lstUser_Manager[intRandomIndexManager];
			}

			// shouldn't be able to run to here, every Branch Unit should have Manager, Below are condition that one Branch Unit without Manager
			lstBranchUnitId.remove(intRandomIndex);
			return getManagerInBranchUnitList(lstBranchUnitId, mapBranchUnitIdTolstUserManagerOrigin);
		} else {
			// Every Branch Unit in BU List have no Manager.
			return null;
		}
	}

	/**
	 * assign Lead to Banker:
	 * Map: Lead Id - BranchUnit Id List - List of Banker List ,  Lead Id - Lead
	 * @return map<Lead Id, Lead>
	 */
	public static Map<Id, Lead> assignLeadToBanker(
		List<Lead> lstAllLeadNeedAssign,
		Map<Id, List<Id>> mapBranchUnitIdTolstUserManagerOrigin,
		Map<Id, List<Id>> mapBranchUnitIdTolstBankerOrigin,
		Map<Id, String> mapProfileIdToNameGlobal,
		Map<Id, User> mapBankerIdToUserGlobal,
		Map<Id, List<Integer>> mapBankerIdToAmountGlobal
	) {
		Map<Id, Lead> mapIdToLead = new Map<Id, Lead>();
		try {
			// Map<Lead Id, Branch Unit Id List> , Lead mapped with Postal Code
			Map<Id, List<Id>> mapLeadIdToBranchUnitIdList = getMapLeadToBranchUnitList(lstAllLeadNeedAssign);
			Map<Id, List<Id>> mapLeadIdToBranchUnitIdListForManager = new Map<Id, List<Id>>(mapLeadIdToBranchUnitIdList);

			//Map<Lead Id, Lead> , not match Postal Code yet
			mapIdToLead = new Map<Id, Lead>(lstAllLeadNeedAssign);
			// System.debug('Start Assign : All Lead need Assign is : ' + mapIdToLead);
			// System.debug('all Lead Size, mapIdToLead.size() is : '  + mapIdToLead.size());
			// System.debug('Lead with Right PostalCode is mapLeadIdToBranchUnitIdList is : ' + mapLeadIdToBranchUnitIdList);
			// System.debug('Size of Lead with Right PostalCode is mapLeadIdToBranchUnitIdList.size() is : ' + mapLeadIdToBranchUnitIdList.size());
			// System.debug('Lead with correct Postal Code is : ' + mapLeadIdToBranchUnitIdList.keySet());

			for (Id idLead : mapLeadIdToBranchUnitIdList.keySet()) {
				// System.debug('------enter LeadList Loop, get one Lead-----------');
				// System.debug('Current Lead is : ' + mapIdToLead.get(idLead));
				Lead objLead = mapIdToLead.get(idLead);
				Id oldLeadOwnerId = objLead.OwnerId;

				// Investment Amount & Expressed Interest
				String strLeadInversionInicial = objLead.Inversion_Inicial__c;
				String strLeadExpressedInterest = objLead.FinServ__ExpressedInterest__c;

				// User Recursion to find the suitable Branch Unit repeatedly.
				List<Id> lstBanker = new List<Id>();
				List<Id> lstBranchUnitId = mapLeadIdToBranchUnitIdList.get(idLead);
				// System.debug('Current Lead`s lstBranchUnitId is : ' + lstBranchUnitId);

				// size of lstBranchUnitId must bigger than 0 in actual, gets from metadata PostalMapping
				if (lstBranchUnitId != null && lstBranchUnitId.size() > 0) {
					lstBanker = getSuitableBankerList(
						lstBranchUnitId,
						mapBranchUnitIdTolstBankerOrigin,
						mapBankerIdToUserGlobal,
						mapBankerIdToAmountGlobal
					);
				}

				// System.debug('get a Random BU`s lstBanker is : ' + lstBanker);

				// have banker to assign in List
				if (lstBanker != null && lstBanker.size() > 0) {
					Boolean blIsAssigned = false;
					for (Id objBankerId : lstBanker) {
						// System.debug('+++++++++ enter BankerList Loop, get one Banker +++++++++++++++++');
						User objUser = mapBankerIdToUserGlobal.get(objBankerId);
						Id idUserProfileId = objUser.ProfileId;
						String strProfileName = mapProfileIdToNameGlobal.get(idUserProfileId);
						// match Inversion_Inicial__c
						if (strLeadInversionInicial != null) {
							// matched, assign
							if (
								(strLeadInversionInicial == LEAD_II_SOLUTION &&
								strProfileName == PROFILE_ASESOR_SOLUTION) ||
								(strLeadInversionInicial == LEAD_II_PATRIMONIAL &&
								strProfileName == PROFILE_ASESOR_PATRIMONIAL) ||
								(strLeadInversionInicial == LEAD_II_PRIVATE &&
								strProfileName == PROFILE_ASESOR_PRIVATE)
							) {
								mapIdToLead.get(idLead).OwnerId = objUser.Id;
								blIsAssigned = true;
								//Amount Of Open Lead ++
								mapBankerIdToAmountGlobal.get(objBankerId)[0]++;
								// System.debug('Lead.Investment Amount matched, assign');
								break;
							} else {
								// not matched , next banker
								// System.debug('Lead.Investment Amount & Banker\'s Corresponding User\' Profile not matched, looking for next Banker');
								continue;
							}
						} else {
							// Inversion_Inicial__c == null , match EI
							if (strLeadExpressedInterest == null) {
								// assign to the User corresponding to the first Banker in the Banker List
								mapIdToLead.get(idLead).OwnerId = mapBankerIdToUserGlobal.get(objBankerId).Id;
								blIsAssigned = true;
								// Amount Of Open Lead ++
								mapBankerIdToAmountGlobal.get(objBankerId)[0]++;
								// System.debug('Lead have no EI, Assign to User corresponding to the First Banker in BankerList');
								break;
							}

							// match Lead's EI and Profile
							if (
								(strLeadExpressedInterest == LEAD_EI_SOLUTION &&
								strProfileName == PROFILE_ASESOR_SOLUTION) ||
								(strLeadExpressedInterest == LEAD_EI_PRIVATE &&
								strProfileName == PROFILE_ASESOR_PRIVATE) ||
								(strLeadExpressedInterest == LEAD_EI_PATRIMONIAL &&
								strProfileName == PROFILE_ASESOR_PATRIMONIAL)
							) {
								mapIdToLead.get(idLead).OwnerId = mapBankerIdToUserGlobal.get(objBankerId).id;
								blIsAssigned = true;
								//Amount Of Open Lead ++
								mapBankerIdToAmountGlobal.get(objBankerId)[0]++;
								// System.debug('Lead.EI matched, assign');
								break;
							} else {
								// System.debug('Lead.EI has value but not matched, not assign --this.situation is EI not in the three Asesors');
								continue;
							}
						}
					}

					// System.debug('Main step2 : : ');
					// After traversing the Banker, if there is still no matching allocation, it will be allocated to the first Banker
					if (!blIsAssigned) {
						// System.debug('after BankerListLoop,not assigned, assign to the First(Highest Efficiency)');
						mapIdToLead.get(idLead).OwnerId = mapBankerIdToUserGlobal.get(lstBanker[0]).Id;
						blIsAssigned = true;
						//Amount Of Open Lead ++
						mapBankerIdToAmountGlobal.get(lstBanker[0])[0]++;
						// continue;
					}
				} else {
					// no Banker in List, Look for Manager
					// if the recursion is over and a suitable Branch Unit has not been found, assign to Manager of a Random Branch Unit
					// System.debug('============= don`t have any Banker at all ! enter looking for manager : ');
					Id userManagerId = null;
					lstBranchUnitId = mapLeadIdToBranchUnitIdListForManager.get(idLead);
					// System.debug('this should not change , equals to last BUid, lstBranchUnitId is : ' + lstBranchUnitId);

					// System.debug();
					if (lstBranchUnitId != null && lstBranchUnitId.size() > 0) {
						userManagerId = getManagerInBranchUnitList(lstBranchUnitId, mapBranchUnitIdTolstUserManagerOrigin);
						// System.debug('bankerManagerId is ' + userManagerId);
						if (userManagerId != null) {
							mapIdToLead.get(idLead).OwnerId = userManagerId;
							// System.debug('found Manager, Assign!');
							// continue;
							// Amount Of Open Lead ++
							// mapBankerIdToAmountGlobal.get(bankerManagerId)[0]++;
						}
						// have no manager
					}
				}
				// if Owner haven't change, remove lead from list to uodate
				Id newLeadOwnerId = mapIdToLead.get(idLead).OwnerId;
				// remove Lead which owner didn't change
				// System.debug(newLeadOwnerId + '   ' + newLeadOwnerId + '  ' + mapIdToLead.get(idLead));
				if (oldLeadOwnerId == newLeadOwnerId) {
					mapIdToLead.remove(idLead);
				}

				// System.debug('一条Lead结束，这时Lead为 : ' + mapIdToLead.get(idLead));
				// System.debug('end of LeadList Loop, enter next Lead');
				// System.debug('***********************************************************************************************');
			}
			// System.debug('There\'s no Lead Left, end Assignment Process');
		} catch (Exception e) {
			// System.debug('Error5 message : ' + e.getMessage());
			// System.debug('Error5 Line no : ' + e.getLineNumber());
		}
		// System.debug('after assiggn, the Lead to update is mapIdToLead : ' + mapIdToLead);

		return mapIdToLead;
	}

	/**
	 * send notification after Lead.Owner changed
	 */
	public static void sendNotificationAfterOwnerChanged(
		CustomNotificationType notificationType,
		Set<String> setStrRecipientsIds,
		String strTargetId,
		Lead objLead
	) {
		// Create a new custom notification
		Messaging.CustomNotification notification = new Messaging.CustomNotification();

		String strTitle = 'Title Lead Assignment';
		String strBody = 'Body Lead Assignment';
		if (Label.Lead_Noti_Title != null) {
			strTitle = Label.Lead_Noti_Title;
		}
		if (Label.Lead_noti_Body != null) {
			strBody = Label.Lead_Noti_Body;
		}

		// Set the contents for the notification
		notification.setTitle(strTitle);
		notification.setBody(strBody);

		// Set the notification type and target
		notification.setNotificationTypeId(notificationType.Id);
		notification.setTargetId(strTargetId);

		// Actually send the notification
		try {
			notification.send(setStrRecipientsIds);
		} catch (Exception e) {
			// System.debug('Problem sending notification: ' + e.getMessage());
		}
	}
}