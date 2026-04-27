/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     CreditTrigger
 * @Author   omar.espinosa@pwc.com
 * @Date     Created: 16/02/2022
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Credit trigger. This trigger uses the Kevin O'Hara trigger framework.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 16/02/2022 omar.espinosa@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public without sharing class CreditTrigger_Handler extends TriggerHandler {
	list<Credito__c> creditNew = Trigger.new;
	list<Credito__c> creditOld = Trigger.Old;
	Map<id, Credito__c> creditNewMap = ((Map<Id, Credito__c>) (Trigger.NewMap));
	Map<id, Credito__c> creditOldMap = ((Map<Id, Credito__c>) (Trigger.OldMap));

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before inserting a contract
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     03/11/2021
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeInsert() {
		CreditTrigger_Helper.changeOwner(creditNew, creditOldMap);
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before inserting a contract
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     03/11/2021
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeUpdate() {
		CreditTrigger_Helper.changeOwner(creditNew, creditOldMap);
	}
}