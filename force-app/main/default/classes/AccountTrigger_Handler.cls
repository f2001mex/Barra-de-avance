/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     AccountTrigger_Handler
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 10/12/2022
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Handler for the account trigger.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 10/12/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public with sharing class AccountTrigger_Handler extends TriggerHandler {
	list<Account> accountNew = Trigger.new;
	list<Account> accountOld = Trigger.Old;
	Map<id, Account> accountNewMap = ((Map<Id, Account>) (Trigger.NewMap));
	Map<id, Account> accountOldMap = ((Map<Id, Account>) (Trigger.OldMap));

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before inserting an account
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     10/12/2022
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeInsert() {
		AccountTrigger_Helper.CreateAccounts(accountNew);
		AccountTrigger_Helper.checkTotalPercent(accountNew);
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic after inserting an account
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     10/12/2022
	 * @param
	 * @return   void
	 * @example  afterInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void afterInsert() {
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before updating an account
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     10/12/2022
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeUpdate() {
		AccountTrigger_Helper.checkTotalPercent(accountNew);
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic after updating an account
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     10/12/2022
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void afterUpdate() {
	}
}