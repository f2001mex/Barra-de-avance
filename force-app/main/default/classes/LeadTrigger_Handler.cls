/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     LeadTrigger_Handler
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 22/06/2023
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Lead trigger Handler. This trigger uses the Kevin O'Hara trigger framework.
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         16/02/2022       luis.felipe.ortiz@pwc.com          Class creation.
 * 2.0         15/11/2024       Oscar Alvarez                      Se integra nueva metodo para el after update
*--------------------------------------------------------------------------
 **/
public with sharing class LeadTrigger_Handler extends TriggerHandler {
	list<Lead> leadNew = Trigger.new;
	list<Lead> leadOld = Trigger.Old;
	Map<id, Lead> leadNewMap = ((Map<Id, Lead>) (Trigger.NewMap));
	Map<id, Lead> leadOldMap = ((Map<Id, Lead>) (Trigger.OldMap));

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before inserting a lead
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     22/06/2023
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
    protected override void beforeInsert() {
        System.debug('LeadTrigger_Handler.beforeInsert');
        LeadTrigger_Helper.preventAssignedLeadLargerThanTheMaxManual(leadNew);
        LeadTrigger_Helper.branchUnitAssignment(leadNew);
        ACT_LeadTriggerHandler.processLeadPhones(leadNew);
    }
    @TestVisible
	protected override void AfterInsert() {
        System.debug('LeadTrigger_Handler.AfterInsert');
        LeadTrigger_Helper.LeadsAssignmentProcess(leadNew);
		//LeadTrigger_Helper.postalCodeAssigment(leadNew);
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before inserting a lead
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     22/06/2023
	 * @param
	 * @return   void
	 * @example  beforeUpdate()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
    protected override void beforeUpdate() {
        System.debug('LeadTrigger_Handler.beforeUpdate');
        LeadTrigger_Helper.preventAssignedLeadLargerThanTheMaxManual(leadNew);
        LeadTrigger_Helper.SetConversionDate(leadNew, leadOldMap);
        LeadTrigger_Helper.branchUnitAssignment(leadNew, leadOldMap);
        ACT_LeadTriggerHandler.processLeadPhones(leadNew);
    }
	/** ------------------------------------------------------------------------------------------------
	 * @Logica para a ejecutar posterior a una actualización
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void afterUpdate() {
		System.debug('LeadTrigger_Handler.afterUpdate');
		LeadTrigger_Helper.integrationWithSAP(leadNew, leadOldMap);
	}
}