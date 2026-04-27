/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_BankerTrigger_Handler
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 23/11/2022
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Handler for the banker trigger.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 23/11/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public without sharing class F3_BankerTrigger_Handler extends TriggerHandler {
	list<Banker> bankersNewList = Trigger.new;
	list<Banker> bankersOldList = Trigger.old;
	Map<id, Banker> bankersNewMap = ((Map<Id, Banker>) (Trigger.newMap));
	Map<id, Banker> bankersOldMap = ((Map<Id, Banker>) (Trigger.oldMap));

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before inserting a banker
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeInsert() {
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic after inserting a banker
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   void
	 * @example  afterInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void afterInsert() {
		F3_BankerTrigger_Helper.updateUser(bankersNewList, bankersOldMap);
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before updating a banker
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
	 * @Description executes all the logic after updating a banker
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void afterUpdate() {
		F3_BankerTrigger_Helper.updateUser(bankersNewList, bankersOldMap);
	}
}