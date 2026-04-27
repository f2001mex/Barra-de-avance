/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-06-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ShiftTrigger_Handler extends TriggerHandler {
    List<Shift> lstShift = Trigger.new;
    @TestVisible
    protected override void afterInsert(){
        System.debug('Evento after insert');
        DefaultValuesScheduler__c objDefaultValues = SCH_ServiceUtility_Trigger.getCustomSettingDefaultValues();
        List<EngagementChannelType> lstChannels = SCH_ServiceUtility_Trigger.getChannels();
        ShiftTrigger_Helper.createShiftEngagementChannel(lstShift, lstChannels, objDefaultValues);
    }
}