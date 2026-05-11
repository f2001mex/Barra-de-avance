/**
 *   ------------------------------------------------------------------------------------------------
 *  Name     ContractTrigger
 *  Author   luis.felipe.ortiz@pwc.com
 *  Date     Created: 03/11/2021
 *  Group    PWC
 *   ------------------------------------------------------------------------------------------------
 *  Description Contract trigger. This trigger uses the Kevin O'Hara trigger framework.
 *   ------------------------------------------------------------------------------------------------
 *  Changes
 *  03/11/2021 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *  03/10/2022 luis.felipe.ortiz@pwc.com
 *             Addition of ON/OFF behavior based on metadata.
 *  08/11/2024 andres.hernandez@vasscompany.com
 *             Realiza mejora framework en Trigger Contract agregando nueva Metadata
 * 			  
 *   ------------------------------------------------------------------------------------------------
 **/
trigger ContractTrigger on Contract(before insert, after insert, before update, after update) {
    /*
	F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.label.F3_ContractTrigger);
	if (triggerMetadata == null || triggerMetadata.F3_isActive__c) {
		new ContractTrigger_Handler().run();
	}
    */
    //Llamado de metadata para validar si esta activo el trigger que se va ejecutar
    Trigger_Management__mdt  triggerIsActive = Trigger_Management__mdt.getInstance(System.label.ContractTrigger);
    if (triggerIsActive != null && triggerIsActive.IsActive__c) {
        if (Trigger.isInsert && Trigger.isBefore) {
            OD_Contract_thr.onBeforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate && Trigger.isBefore) {
            OD_Contract_thr.onBeforeUpdate(Trigger.new);
        }
    }    
}