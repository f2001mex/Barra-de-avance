/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-06-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger ShiftTrigger on Shift (after insert) {
    F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.Label.SCH_ShiftTrigger);
    System.debug('Metadato: ' + triggerMetadata);
    if(triggerMetadata == null || triggerMetadata.F3_isActive__c) {
        new ShiftTrigger_Handler().run();
    }
}