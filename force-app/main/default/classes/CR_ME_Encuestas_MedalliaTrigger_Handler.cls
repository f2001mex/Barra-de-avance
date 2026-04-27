/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     CR_ME_Encuestas_MedalliaTrigger_Handler
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 06/07/2023
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Handler for the CR_ME_Encuestas_Medallia__c trigger.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 06/07/2023  luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public without sharing class CR_ME_Encuestas_MedalliaTrigger_Handler extends TriggerHandler {
	list<CR_ME_Encuestas_Medallia__c> surveyNew = Trigger.new;
	list<CR_ME_Encuestas_Medallia__c> surveyOld = Trigger.Old;
	Map<id, CR_ME_Encuestas_Medallia__c> surveyNewMap = ((Map<Id, CR_ME_Encuestas_Medallia__c>) (Trigger.NewMap));
	Map<id, CR_ME_Encuestas_Medallia__c> surveyOldMap = ((Map<Id, CR_ME_Encuestas_Medallia__c>) (Trigger.OldMap));

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before inserting a survey
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     06/07/2023
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeInsert() {
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic after inserting a survey
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     06/07/2023
	 * @param
	 * @return   void
	 * @example  afterInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void afterInsert() {
		TriggerHandler.bypass('AccountTrigger_Handler');
		CR_ME_Encuestas_MedalliaTrigger_Helper.UpdateRelatedObject(surveyNew, surveyOldMap);
		TriggerHandler.clearBypass('AccountTrigger_Handler');
	}
}