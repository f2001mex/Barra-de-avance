/**
 *   ------------------------------------------------------------------------------------------------
 *  Name     BankerTrigger
 *  Author   luis.felipe.ortiz@pwc.com
 *  Date     Created: 03/11/2021
 *  Group    PWC
 *   ------------------------------------------------------------------------------------------------
 *  Description Banker trigger. This trigger uses the Kevin O'Hara trigger framework.
 *   ------------------------------------------------------------------------------------------------
 *  Changes
 *  23/11/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   08/11/2024 andres.hernandez@vasscompany.com
 *   Realiza mejora framework en Trigger Contract agregando nueva Metadata
 * 			  
 *   ------------------------------------------------------------------------------------------------
 **/
trigger BankerTrigger on Banker(before insert, after insert, before update, after update) {
    /*
	F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.Label.F3_BankerTrigger);
	if (triggerMetadata == null || triggerMetadata.F3_isActive__c) {
		new F3_BankerTrigger_Handler().run();
	}*/
    //Llamado de metadata para validar si esta activo el trigger que se va ejecutar
    Trigger_Management__mdt  triggerIsActive = Trigger_Management__mdt.getInstance(System.label.BankerTrigger);
    if (triggerIsActive != null && triggerIsActive.IsActive__c) {
        if (Trigger.isInsert && Trigger.isBefore) {
            OD_Banker_thr.onBeforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate && Trigger.isBefore) {
            OD_Banker_thr.onBeforeUpdate(Trigger.new,Trigger.oldMap);
        }
        if (Trigger.isUpdate && Trigger.isAfter) {
            OD_Banker_thr.onAfterUpdate(Trigger.new,Trigger.oldMap);
        }
    }  
}