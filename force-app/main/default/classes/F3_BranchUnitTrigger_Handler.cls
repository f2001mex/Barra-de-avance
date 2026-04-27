/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_BranchUnitTrigger_Handler
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 23/11/2022
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Handler for the branchUnit trigger.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 23/11/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public without sharing class F3_BranchUnitTrigger_Handler extends TriggerHandler {
	list<BranchUnit> branchUnitsNewList = Trigger.new;
	list<BranchUnit> branchUnitsOldList = Trigger.old;
	Map<id, BranchUnit> branchUnitsNewMap = ((Map<Id, BranchUnit>) (Trigger.newMap));
	Map<id, BranchUnit> branchUnitsOldMap = ((Map<Id, BranchUnit>) (Trigger.oldMap));

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before inserting a branchUnit
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeInsert() {
		F3_BranchUnitTrigger_Helper.checkBranchUnitNameDuplication(branchUnitsNewList);
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic after inserting a branchUnit
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   void
	 * @example  afterInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void afterInsert() {
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before updating a branchUnit
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeUpdate() {
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic after updating a branchUnit
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void afterUpdate() {
		F3_BranchUnitTrigger_Helper.updateUser(branchUnitsNewList, branchUnitsOldMap);
	}
}