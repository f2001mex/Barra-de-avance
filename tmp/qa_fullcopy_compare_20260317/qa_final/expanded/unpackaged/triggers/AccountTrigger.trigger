/**
 *   ------------------------------------------------------------------------------------------------
 *  Name     AccountTrigger
 *  Author   Tate Shi
 *  Date     Created: 12/09/2021
 *  Group    PWC
 *   ------------------------------------------------------------------------------------------------
 *  Description Account trigger.
 *   ------------------------------------------------------------------------------------------------
 *  Changes
 *  12/09/2021 Tate Shi
 *             Class creation.
 *  03/10/2022 luis.felipe.ortiz@pwc.com
 *             Addition of ON/OFF behavior based on metadata.
 *  13/11/2024 andres.hernandez@vasscompany.com
 *             Realiza mejora framework en Trigger Contract agregando nueva Metadata
 *  23/06/2025 isaac.alonzo@vasscompany.com
 *             Se agrega la actualizacion de la fecha de siguiente contacto y visita para POSTVENTA      
 *  14/01/2026 Se agrega actualizacion de RecordType usando Metadata para evitar Código duro (Gerardo Bautista)
 *   ------------------------------------------------------------------------------------------------
 **/
trigger AccountTrigger on Account(before insert, before update, After insert, After update) {
    
    /*F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.label.F3_AccountTrigger);
    if (triggerMetadata == null || triggerMetadata.F3_isActive__c) {
        new AccountTrigger_Handler().run();
    }*/
    //Llamado de metadata para validar si esta activo el trigger que se va ejecutar
    Trigger_Management__mdt  triggerIsActive = Trigger_Management__mdt.getInstance(System.label.AccountTrigger);
    if (triggerIsActive != null && triggerIsActive.IsActive__c) {
        if (Trigger.isUpdate && Trigger.isBefore) {
            OD_Account_thr.onBeforeUpdate(Trigger.new,Trigger.oldMap);
            PSTA_Account_thr.onBeforeUpdate(Trigger.new,Trigger.oldMap);
            // Nuevo llamado para extraer el recordType
            AccountRecordTypeAssigner.apply(Trigger.new, Trigger.oldMap);
            
        }
        if (Trigger.isInsert && Trigger.isBefore) {
            OD_Account_thr.onBeforeInsert(Trigger.new);
            // Nuevo llamado para extraer el recordType
            AccountRecordTypeAssigner.apply(Trigger.new, null);
        }        
    }
}