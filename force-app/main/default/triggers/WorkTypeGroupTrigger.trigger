/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-03-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger WorkTypeGroupTrigger on WorkTypeGroup (after insert) {
    F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.Label.SCH_WorkTypeGroupTrigger);
    if(triggerMetadata == null || triggerMetadata.F3_isActive__c) {
        new WorkTypeGroupTrigger_Handler().run();
    }
}