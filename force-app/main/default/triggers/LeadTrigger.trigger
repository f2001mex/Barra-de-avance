/**
 *   ------------------------------------------------------------------------------------------------
 *  Name     LeadTrigger
 *  Author   Tate Shi
 *  Date     Created: 10/28/2021
 *  Group    PWC
 *   ------------------------------------------------------------------------------------------------
 *  Description Trigger on Lead.
 *   ------------------------------------------------------------------------------------------------
 *  Changes
 *  10/28/2021 Tate Shi
 *             Class creation.
 *  03/10/2022 luis.felipe.ortiz@pwc.com
 *             Addition of ON/OFF behavior based on metadata.
 *  03/10/2022 luis.felipe.ortiz@pwc.com
 *             Change framework to Kevin O'Hara's framework.
 *  22/05/2024 ivan.mora@pwc.com
 *             Add validation for guest users.
 *   ------------------------------------------------------------------------------------------------
 **/
trigger LeadTrigger on Lead(before insert, before update, after update, after insert) {
	F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.Label.F3_LeadTrigger);
	if (triggerMetadata == null || triggerMetadata.F3_isActive__c) {
		if(!Auth.CommunitiesUtil.isGuestUser()){
			new LeadTrigger_Handler().run();
		}
	}
}