/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     ContractTrigger_Handler
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 03/11/2021
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Handler for the contract trigger.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 03/11/2021 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public without sharing class ContractTrigger_Handler extends TriggerHandler {
	private static F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.label.F3_ContractTrigger);
	list<Contract> contractNew = Trigger.new;
	list<Contract> contractOld = Trigger.Old;
	Map<id, Contract> contractNewMap = ((Map<Id, Contract>) (Trigger.NewMap));
	Map<id, Contract> contractOldMap = ((Map<Id, Contract>) (Trigger.OldMap));

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
		for (Contract newContract : contractNew) {
			ContractTrigger_Helper.changeOwner(newContract, null);
			ContractTrigger_Helper.setContractBalances(newContract, null);
		}
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic after inserting a contract
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     03/11/2021
	 * @param
	 * @return   void
	 * @example  afterInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void afterInsert() {
		TriggerHandler.bypass('LeadTrigger_Handler');
		TriggerHandler.bypass('AccountTrigger_Handler');
		ContractTrigger_Helper.updateRelatedObjects(contractNew, contractOldMap);
		TriggerHandler.clearBypass('LeadTrigger_Handler');
		TriggerHandler.clearBypass('AccountTrigger_Handler');
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before updating a contract
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     03/11/2021
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeUpdate() {
		for (Contract newContract : contractNew) {
			ContractTrigger_Helper.changeOwner(newContract, contractOldMap.get(newContract.Id));
			ContractTrigger_Helper.setContractBalances(newContract, contractOldMap.get(newContract.Id));
		}
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic after updating a contract
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     03/11/2021
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void afterUpdate() {
		TriggerHandler.bypass('LeadTrigger_Handler');
		TriggerHandler.bypass('AccountTrigger_Handler');
		ContractTrigger_Helper.updateRelatedObjects(contractNew, contractOldMap);
		TriggerHandler.clearBypass('LeadTrigger_Handler');
		TriggerHandler.clearBypass('AccountTrigger_Handler');
	}
}