/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_BankerTrigger_Helper
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 23/11/2022
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Helper for the banker trigger.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 23/11/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public without sharing class F3_BankerTrigger_Helper {
	private static final String USER_PREFIX;
	private static final Map<Id, BranchUnit> BRANCHES;
	private static F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.Label.F3_BankerTrigger);
	static {
		USER_PREFIX = Schema.SObjectType.User.getKeyPrefix();
		BRANCHES = fillBranches();
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description logic to add or erase branches to Users
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   void
	 * @example  updateUser()
	 * ------------------------------------------------------------------------------------------------**/
	public static void updateUser(list<Banker> bankersNew, Map<Id, Banker> bankersOldMap) {
		List<User> usersToUpdate = new List<User>();
		for (Banker banker : bankersNew) {
			if (
				bankersOldMap == null &&
				banker.CurrentBranchId != null &&
				banker.UserOrContactId != null &&
				((String) banker.UserOrContactId).startsWith(USER_PREFIX) == true
			) {
				usersToUpdate.add(addBranchUser(banker));
			} else if (
				bankersOldMap != null &&
				banker.CurrentBranchId != null &&
				banker.UserOrContactId != null &&
				((String) banker.UserOrContactId).startsWith(USER_PREFIX) == true &&
				(triggerMetadata.F3_Run_For_All_Changes__c == true ||
				(banker.CurrentBranchId != bankersOldMap.get(banker.Id).CurrentBranchId ||
				banker.UserOrContactId != bankersOldMap.get(banker.Id).UserOrContactId))
			) {
				usersToUpdate.add(addBranchUser(banker));
			}
			if (
				bankersOldMap != null &&
				(banker.UserOrContactId != bankersOldMap.get(banker.Id).UserOrContactId ||
				banker.CurrentBranchId == null) &&
				bankersOldMap.get(banker.Id).UserOrContactId != null &&
				((String) bankersOldMap.get(banker.Id).UserOrContactId).startsWith(USER_PREFIX) == true
			) {
				usersToUpdate.add(eraseBranchUser(bankersOldMap.get(banker.Id)));
			}
		}
		if (!usersToUpdate.isEmpty()) {
			updateUsers(JSON.serialize(usersToUpdate));
		}
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description add branches to user
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   void
	 * @example  addBranchUser()
	 * ------------------------------------------------------------------------------------------------**/
	private static User addBranchUser(Banker banker) {
		BranchUnit currentBranch = BRANCHES.get(banker.CurrentBranchId);
		return new User(
			Id = banker.UserOrContactId,
			F3_Sucursal__c = currentBranch.Name,
			F3_Region__c = currentBranch.ParentBranchUnit.name,
			F3_Division__c = currentBranch.ParentBranchUnit.ParentBranchUnit.name
		);
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description erase branches to user
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   void
	 * @example  eraseBranchUser()
	 * ------------------------------------------------------------------------------------------------**/
	private static User eraseBranchUser(Banker banker) {
		return new User(Id = banker.UserOrContactId, F3_Sucursal__c = null, F3_Region__c = null, F3_Division__c = null);
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Fill map with branches
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   void
	 * @example  fillBranches()
	 * ------------------------------------------------------------------------------------------------**/
	private static Map<Id, BranchUnit> fillBranches() {
		Map<Id, BranchUnit> branchesMap = new Map<Id, BranchUnit>(
			[SELECT name, ParentBranchUnit.name, ParentBranchUnit.ParentBranchUnit.name FROM BranchUnit]
		);
		return branchesMap;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description future method to update users to avoid DML exception of upserting system object with
	 *  custom one's in the same transaction
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   void
	 * @example  fillBranches()
	 * ------------------------------------------------------------------------------------------------**/
	@future
	private static void updateUsers(String usersData) {
		List<User> usersToUpdate = (List<User>) JSON.deserialize(usersData, List<User>.class);
		update usersToUpdate;
	}
}