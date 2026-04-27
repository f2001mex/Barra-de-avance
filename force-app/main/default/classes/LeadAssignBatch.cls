/**
 * @author Tate Shi
 * @date 11/29/2021
 * @description
 *     run Lead Assignment Batchly
 *     because if run AssignLeadToAdviosr.update() directly, it will exceed CPU limit for more than 60 Leads
 *     batch can run 200 Leads in 25 seconds, and assign 2000 Leads in 10 Batches
 */
public without sharing class LeadAssignBatch implements Database.Batchable<Lead> {
	// Custom Notification
	CustomNotificationType notificationType = null;
	// Map<Profile Id, Profile Name>
	private Map<Id, String> mapProfileIdToNameGlobal = null;
	// Map<Banker Id, User Id>
	private Map<Id, User> mapBankerIdToUserGlobal = null;
	// Map<Banker Id, List<Integer>> List:Amount of open/closed Opp/Lead
	private Map<Id, List<Integer>> mapBankerIdToAmountGlobal = null;
	//List<Branch Unit Id, list<Banker Id>>
	private Map<Id, List<Id>> mapBranchUnitIdTolstBankerGlobal = null;
	//List<Branch Uint Id, List<User Id(Manager Id)>>
	private Map<Id, List<Id>> mapBranchUnitIdTolstUserManagerGlobal = null;
	//Error Log : Category
	private final String CATEGORY = 'Assignment Of The Lead';
	//Error Log : Error File Name
	private final String ERROR_FILE = 'AssignLeadToAdvisor.cls';

	/**
	 * constructor
	 */
	public LeadAssignBatch() {
		notificationType = [
			SELECT Id, DeveloperName
			FROM CustomNotificationType
			WHERE DeveloperName = 'Lead_Notification_After_Assignment'
		];

		Datetime dt0 = Datetime.now();
		List<User> lstAllUser = AssignLeadToAdvisor.getAllUser();
		Map<Id, User> mapAllUserInfo = new Map<Id, User>(lstAllUser);
		// get Profile Id to Name
		mapProfileIdToNameGlobal = AssignLeadToAdvisor.getMapProfileIdToName();
		// map Banker Id to User, Banker must have a corresponding User
		mapBankerIdToUserGlobal = AssignLeadToAdvisor.getMapBankerIdToUser(mapAllUserInfo);
		// Banker Id with corresponding User
		List<Id> lstBankerGlobal = new List<Id>();
		lstBankerGlobal.addAll(mapBankerIdToUserGlobal.keySet());
		// get Banker Amount of Open/Closed Opp/Lead
		mapBankerIdToAmountGlobal = AssignLeadToAdvisor.getMapBankerIdToAmount(lstBankerGlobal, mapBankerIdToUserGlobal);

		mapBranchUnitIdTolstBankerGlobal = AssignLeadToAdvisor.getMapBranchUnitIdTolstBanker(
			mapProfileIdToNameGlobal,
			mapBankerIdToUserGlobal,
			lstBankerGlobal
		);
		mapBranchUnitIdTolstUserManagerGlobal = AssignLeadToAdvisor.getMapBranchUnitIdTolstUserManager(mapAllUserInfo);
		Datetime dt1 = Datetime.now();
		// System.debug('Batch constructor time is : ' + (dt1.getTime() - dt0.getTime()));
	}

	/**
	 * Batch Start
	 */
	public List<Lead> start(Database.BatchableContext BC) {
		// Datetime dt0 = Datetime.now();
		// Get all the leads without any deal over 24 hours
		Set<Id> setLeadId24HNoDeal = AssignLeadToAdvisor.getLeadsToReassign();
		// Get all the leads from marketing cloud transfered by Integration User
		Set<Id> setAllLeadId = AssignLeadToAdvisor.getNewLeadsToAssign();
		// Merge all the id of leads
		setAllLeadId.addAll(setLeadId24HNoDeal);
		setAllLeadId.remove(null);

		List<Lead> lstNeedAssign = new List<Lead>();

		if (setAllLeadId.size() > 0) {
			lstNeedAssign = [
				SELECT Id, Name, FinServ__ExpressedInterest__c, PostalCode, Status, OwnerId, Inversion_Inicial__c
				FROM Lead
				WHERE Id IN :setAllLeadId
			];
		}
		// Datetime dt1 = Datetime.now();
		// System.debug('Batch start time is : ' + (dt1.getTime() - dt0.getTime()));
		return lstNeedAssign;
	}

	/**
	 * Batch execute
	 */
	public void execute(Database.BatchableContext BC, List<Lead> lstLeadBatch) {
		try {
			Datetime dt0 = Datetime.now();
			Map<Id, Lead> mapLeadToUpdate = AssignLeadToAdvisor.assignLeadToBanker(
				lstLeadBatch,
				mapBranchUnitIdTolstUserManagerGlobal,
				mapBranchUnitIdTolstBankerGlobal,
				mapProfileIdToNameGlobal,
				mapBankerIdToUserGlobal,
				mapBankerIdToAmountGlobal
			);

			Datetime dt1 = Datetime.now();
			List<Lead> lstLeadToUpdate = mapLeadToUpdate.values();
			// System.debug('lstLead is : ' + lstLeadToUpdate);
			update lstLeadToUpdate;

			// send notification
			for (Lead objLead : lstLeadToUpdate) {
				Set<String> setStrRecipientsIds = new Set<String>();
				setStrRecipientsIds.add(objLead.OwnerId);
				String strTargetId = objLead.Id;
				AssignLeadToAdvisor.sendNotificationAfterOwnerChanged(notificationType, setStrRecipientsIds, strTargetId, objLead);
			}

			Datetime dt2 = Datetime.now();
			LogCommon.WriteLog(CATEGORY, ERROR_FILE, null, null);
			Datetime dt3 = Datetime.now();
			// System.debug('Assign time is : ' + (dt1.getTime() - dt0.getTime()));
			// System.debug('Update time is : ' + (dt2.getTime() - dt1.getTime()));
			// System.debug('log write time is : ' + (dt3.getTime() - dt2.getTime()));
			// System.debug('execute time is : ' + (dt3.getTime() - dt0.getTime()));
		} catch (Exception e) {
			// Write Log
			String strErrorMessage = e.getMessage();
			Integer intErrorLineNumber = e.getLineNumber();
			LogCommon.WriteLog(CATEGORY, ERROR_FILE, strErrorMessage, intErrorLineNumber);
		}
	}

	/**
	 * Batch finish
	 */
	public void finish(Database.BatchableContext BC) {
	}
}