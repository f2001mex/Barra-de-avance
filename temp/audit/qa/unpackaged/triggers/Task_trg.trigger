/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-25-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger Task_trg on Task (after update) {
    System.debug('*******Va a iniciar trigger');
    Trigger_Management__mdt  triggerIsActive = Trigger_Management__mdt.getInstance(System.label.TaskTrigger);
    if(triggerIsActive != null && triggerIsActive.IsActive__c){
        System.debug('******Trigger activo, inicia');
        if(Trigger.isUpdate && Trigger.isAfter){
            Task_thr.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}