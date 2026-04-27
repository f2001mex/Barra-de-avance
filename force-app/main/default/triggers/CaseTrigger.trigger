/**
 *   ------------------------------------------------------------------------------------------------
 *  Name     AccountTrigger
 *  Author   Jiale Zhang
 *  Date     Created: 11/23/2021
 *  Group    PWC
 *   ------------------------------------------------------------------------------------------------
 *  Description Trigger on Case Story 16 40 41.
 *   ------------------------------------------------------------------------------------------------
 *  Changes
 *  11/23/2021 Jiale Zhang
 *             Class creation.
 *  03/10/2022 luis.felipe.ortiz@pwc.com
 *             Addition of ON/OFF behavior based on metadata.
 *   ------------------------------------------------------------------------------------------------
 **/
trigger CaseTrigger on Case(before insert, before update) {
	F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.Label.F3_CaseTrigger);
	if (triggerMetadata == null || triggerMetadata.F3_isActive__c) {
		new Triggers().bind(Triggers.Evt.beforeInsert, new CaseHandler()).bind(Triggers.Evt.beforeUpdate, new CaseHandler()).manage();
	}
}