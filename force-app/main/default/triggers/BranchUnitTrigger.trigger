/**
 *   ------------------------------------------------------------------------------------------------
 *  Name     AccountTrigger
 *  Author   Tate Shi
 *  Date     Created: 12/09/2021
 *  Group    PWC
 *   ------------------------------------------------------------------------------------------------
 *  Description Trigger on BranchUnit.
 *   ------------------------------------------------------------------------------------------------
 *  Changes
 *  12/09/2021 Tate Shi
 *             Class creation.
 *  03/10/2022 luis.felipe.ortiz@pwc.com
 *             Addition of ON/OFF behavior based on metadata.
 *   ------------------------------------------------------------------------------------------------
 **/
trigger BranchUnitTrigger on BranchUnit(before insert, after insert, before update, after update) {
	F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.Label.F3_BranchUnitTrigger);
	if (triggerMetadata == null || triggerMetadata.F3_isActive__c) {
		new F3_BranchUnitTrigger_Handler().run();
	}
}