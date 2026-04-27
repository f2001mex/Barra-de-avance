/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Clase test		:   OD_ContractEmail_tgr_tst
* Description       :   Handler para el trigger OD_ContractEmail_tgr en el objeto de correo de contrato
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         21-Nov-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public with sharing class OD_ContractEmail_thr {
    
    public static Boolean bypassTriggerBeforeInsertExecution = false;

    /**
    * @description Metodo que actualiza los valores de los registros nuevos antes de insertarlos. Actualmente valida la estructura, la relacion existente de un contrato y la existencia de palabras restringidas en el/los registro/s nuevo/s
    * @param TriggerNew Lista de nuevos registros de correo de contrato.
    **/
    public static void beforeInsert(List<Correo_de_Contrato__c> TriggerNew) {

        if (bypassTriggerBeforeInsertExecution) return;

        List<Correo_de_Contrato__c> lstCorreosToUpdate = OD_ContractEmailCleaner_cls.ValidateAndUpdateRecords(TriggerNew);

        return;
    }

    public static void beforeUpdate(List<Correo_de_Contrato__c> TriggerNew, Map<Id, Correo_de_Contrato__c> oldMap){
        if (bypassTriggerBeforeInsertExecution) {
            return;
        }

        List<Correo_de_Contrato__c> recordsToProcess = new List<Correo_de_Contrato__c>();

        for (Correo_de_Contrato__c newRec : TriggerNew) {
            Correo_de_Contrato__c oldRec = oldMap.get(newRec.Id);
            
            // Validamos si cambiaron los campos específicos
            if (oldRec.Contract_email__c != newRec.Contract_email__c || oldRec.NUM_CONTRATO__c != newRec.NUM_CONTRATO__c) {
                recordsToProcess.add(newRec);
            }
        }

        List<Correo_de_Contrato__c> lstPhonesToUpdate = OD_ContractEmailCleaner_cls.ValidateAndUpdateRecords(recordsToProcess);

        return;
    }
}