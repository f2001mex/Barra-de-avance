/**
 *   ------------------------------------------------------------------------------------------------
 *  Name     CR_ME_Encuestas_MedalliaTrigger
 *  Author   luis.felipe.ortiz@pwc.com
 *  Date     Created: 06/07/2023
 *  Group    PWC
 *   ------------------------------------------------------------------------------------------------
 *  Description CR_ME_Encuestas_Medallia__c trigger. This trigger uses the Kevin O'Hara trigger framework.
 *   ------------------------------------------------------------------------------------------------
 *  Changes
 *  06/07/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
trigger CR_ME_Encuestas_MedalliaTrigger on CR_ME_Encuestas_Medallia__c(before insert, after insert, before update, after update) {
	F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.label.CR_ME_Encuestas_MedalliaTrigger);
	if (triggerMetadata == null || triggerMetadata.F3_isActive__c) {
		new CR_ME_Encuestas_MedalliaTrigger_Handler().run();
	}
}