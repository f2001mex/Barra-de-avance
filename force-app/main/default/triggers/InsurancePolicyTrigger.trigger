/**
 *   ------------------------------------------------------------------------------------------------
 *  Name     InsurancePolicyTrigger
 *  Author   luis.felipe.ortiz@pwc.com
 *  Date     Created: 18/03/2022
 *  Group    PWC
 *   ------------------------------------------------------------------------------------------------
 *  Description InsurancePolicy trigger. This trigger uses the Kevin O'Hara trigger framework.
 *   ------------------------------------------------------------------------------------------------
 *  Changes
 *  31/01/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
trigger InsurancePolicyTrigger on InsurancePolicy(before insert, after insert, before update, after update) {
	F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.Label.F3_InsurancePolicyTrigger);
	if (triggerMetadata == null || triggerMetadata.F3_isActive__c) {
		new F3_InsurancePolicyTrigger_Handler().run();
	}
}