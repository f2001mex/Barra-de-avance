/**
 *   ------------------------------------------------------------------------------------------------
 *  Name     FigurasTrigger
 *  Author   luis.felipe.ortiz@pwc.com
 *  Date     Created: 18/03/2022
 *  Group    PWC
 *   ------------------------------------------------------------------------------------------------
 *  Description Figuras Relacionadas trigger. This trigger uses the Kevin O'Hara trigger framework.
 *   ------------------------------------------------------------------------------------------------
 *  Changes
 *  18/03/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *  03/10/2022 luis.felipe.ortiz@pwc.com
 *             Addition of ON/OFF behavior based on metadata.
 *   ------------------------------------------------------------------------------------------------
 **/
trigger FigurasTrigger on Figuras_Relacionadas__c(before insert, before update) {
	F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.Label.F3_FigurasTrigger);
	if (triggerMetadata == null || triggerMetadata.F3_isActive__c) {
		new FigurasTrigger_Handler().run();
	}
}