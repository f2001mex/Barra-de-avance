/**
 *   ------------------------------------------------------------------------------------------------
 *  Name     CreditTrigger
 *  Author   luis.felipe.ortiz@pwc.com
 *  Date     Created: 16/02/2022
 *  Group    PWC
 *   ------------------------------------------------------------------------------------------------
 *  Description Credito__c trigger. This trigger uses the Kevin O'Hara trigger framework.
 *   ------------------------------------------------------------------------------------------------
 *  Changes
 *  16/02/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *  03/10/2022 luis.felipe.ortiz@pwc.com
 *             Addition of ON/OFF behavior based on metadata.
 *   ------------------------------------------------------------------------------------------------
 **/
trigger CreditTrigger on Credito__c(before insert, before update) {
	F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.Label.F3_CreditTrigger);
	if (triggerMetadata == null || triggerMetadata.F3_isActive__c) {
		new CreditTrigger_Handler().run();
	}
}