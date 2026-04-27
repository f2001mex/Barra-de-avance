/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_InsurancePolicyTrigger_Handler
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 31/01/2023
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Handler for the policy trigger.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 31/01/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public without sharing class F3_InsurancePolicyTrigger_Handler extends TriggerHandler {
	@TestVisible
	list<InsurancePolicy> policyNew = Trigger.new;
	list<InsurancePolicy> policyOld = Trigger.Old;
	Map<id, InsurancePolicy> policyNewMap = ((Map<Id, InsurancePolicy>) (Trigger.NewMap));
	Map<id, InsurancePolicy> policyOldMap = ((Map<Id, InsurancePolicy>) (Trigger.OldMap));

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before inserting a policy
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeInsert() {
		F3_InsurancePolicyTrigger_Helper.preparePoliciesInsert(policyNew);
		F3_InsurancePolicyTrigger_Helper.changeOwner(policyNew, policyOldMap);
		TriggerHandler.bypass('AccountTrigger_Handler');
		F3_InsurancePolicyTrigger_Helper.createAccountIfNotClient(policyNew);
		TriggerHandler.clearBypass('AccountTrigger_Handler');
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic after inserting a policy
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @param
	 * @return   void
	 * @example  afterInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void afterInsert() {
		// F3_InsurancePolicyTrigger_Helper.createInsuredContact(policyNew);
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before updating a policy
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeUpdate() {
		F3_InsurancePolicyTrigger_Helper.preparePoliciesUpdate(policyNew);
		F3_InsurancePolicyTrigger_Helper.changeOwner(policyNew, policyOldMap);
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic after updating a policy
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void afterUpdate() {
	}
}