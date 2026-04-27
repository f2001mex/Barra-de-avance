/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_BranchUnitTrigger_Helper
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 23/11/2022
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Helper for the branch unit trigger.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 23/11/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public with sharing class F3_BranchUnitTrigger_Helper {
	private static F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.Label.F3_BranchUnitTrigger);

	/** ------------------------------------------------------------------------------------------------
	 * @Description logic to add or erase branches to Users
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   void
	 * @example  updateUser()
	 * ------------------------------------------------------------------------------------------------**/
	public static void updateUser(list<BranchUnit> branchUnitsNewList, Map<Id, BranchUnit> branchUnitsOldMap) {
		Set<String> branchesNames = new Set<String>();
		for (BranchUnit branch : branchUnitsNewList) {
			if (
				triggerMetadata.F3_Run_For_All_Changes__c == true ||
				(branch.Name != branchUnitsOldMap.get(branch.Id).Name ||
				branch.ParentBranchUnitId != branchUnitsOldMap.get(branch.Id).ParentBranchUnitId)
			) {
				branchesNames.add(branchUnitsOldMap.get(branch.Id).Name);
			}
		}
		List<Banker> bankersToProcess = [
			SELECT Id, Name, CurrentBranchId, UserOrContactId
			FROM Banker
			WHERE
				UserOrContactId IN (
					SELECT Id
					FROM User
					WHERE F3_Division__c IN :branchesNames OR F3_Region__c IN :branchesNames OR F3_Sucursal__c IN :branchesNames
				)
		];
		if (!bankersToProcess.isEmpty()) {
			F3_BankerTrigger_Helper.updateUser(bankersToProcess, null);
		}
	}

	/**
	 * @author Tate Shi
	 * @date 12/09/2021
	 * @description
	 *     check if BranchUnit.Name is duplicate
	 *     prevent duplicate value from Insert or Update
	 *     Issue #31
	 */
	public static void checkBranchUnitNameDuplication(list<BranchUnit> branchUnitsNewList) {
		List<BranchUnit> lstBranchUnit = [SELECT Name FROM BranchUnit];
		Set<String> setBUName = new Set<String>();
		for (BranchUnit objBU : lstBranchUnit) {
			setBUName.add(objBu.Name);
		}
		for (BranchUnit objBU : branchUnitsNewList) {
			if (setBUName != null && setBUName.contains(objBU.Name)) {
				objBU.addError(
					Label.ERR_MSG_BU_Name_Duplicate != null
						? Label.ERR_MSG_BU_Name_Duplicate
						: 'You can\'t have duplicate BranchUnit Name, Message From BranchUnit Trigger'
				);
			} else {
				setBUName.add(objBU.Name);
			}
		}
	}
}