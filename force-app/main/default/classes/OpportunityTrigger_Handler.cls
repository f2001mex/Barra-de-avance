/**
 *   ------------------------------------------------------------------------------------------------
 * 
 * ------------------------------------------------------------------------------------------------
 * @Description Opportunity trigger Handler. This trigger uses the Kevin O'Hara trigger framework.
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0        03/12/2024       Oscar Alvarez                      Creación clase
*--------------------------------------------------------------------------
 **/
public with sharing class OpportunityTrigger_Handler extends TriggerHandler {
	list<Opportunity> opportunityNew = Trigger.new;
	list<Opportunity> opportunityOld = Trigger.Old;
	Map<id, Opportunity> opportunityNewMap = ((Map<Id, Opportunity>) (Trigger.NewMap));
	Map<id, Opportunity> opportunityOldMap = ((Map<Id, Opportunity>) (Trigger.OldMap));
	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before inserting a opportunity
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeInsert() {
		System.debug('LeadTrigger_Handler.beforeUpdate');
		OppotunityTrigger_Helper.branchUnitAssignment(opportunityNew);
		OppotunityTrigger_Helper.mappingContactDataToOpp(opportunityNew);// hotfix con alto sentido de urgencia 11 de julio
	}/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before inserting a lead
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeUpdate() {
		System.debug('LeadTrigger_Handler.beforeUpdate');
		OppotunityTrigger_Helper.branchUnitAssignment(opportunityNew, opportunityOldMap);
	}
 	/** ------------------------------------------------------------------------------------------------
	 * @Logica para a ejecutar posterior a una actualización
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void afterUpdate() {
		System.debug('OppotunityTrigger_Helper.afterUpdate');
		OppotunityTrigger_Helper.integrationWithSAP(opportunityNew, opportunityOldMap);
	}
}