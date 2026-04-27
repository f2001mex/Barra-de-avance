/**
 * @author Tate Shi
 * @date 12/09/2021
 * @description
 *      Used in BranchUnitTrigger.trigger
 */
public with sharing class BranchUnitHandler implements Triggers.Handler {
	List<BranchUnit> lstNewBranchUnit = (List<BranchUnit>) Trigger.new;

	private String Err_MSG_DUPLICATE_BU_NAME = 'You can\'t have duplicate BranchUnit Name, Message From BranchUnit Trigger';

	public void handle() {
		if ((Trigger.isInsert) && Trigger.isBefore) {
			checkBranchUnitNameDuplication();
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
	public void checkBranchUnitNameDuplication() {
		// get Label : ERR_MSG_BU_Name_Duplicate
		if (Label.ERR_MSG_BU_Name_Duplicate != null) {
			Err_MSG_DUPLICATE_BU_NAME = Label.ERR_MSG_BU_Name_Duplicate;
		}

		// get all BranchUnit Name
		List<BranchUnit> lstBranchUnit = [SELECT Id, Name FROM BranchUnit WHERE Id != NULL LIMIT 10000];
		Set<String> setBUName = new Set<String>();
		for (BranchUnit objBU : lstBranchUnit) {
			setBUName.add(objBu.Name);
		}

		// check new case list, see if BU Name ]duplicate
		for (BranchUnit objBU : lstNewBranchUnit) {
			// duplicated, add error message
			if (setBUName != null && setBUName.contains(objBU.Name)) {
				objBU.addError(Err_MSG_DUPLICATE_BU_NAME);
			}
			// not duplicate, add to DB(mock)
			else {
				setBUName.add(objBU.Name);
			}
		}
	}
}