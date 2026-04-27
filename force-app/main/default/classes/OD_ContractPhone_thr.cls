/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Clase test		:   OD_ContractPhone_tgr_tst
* Description       :   Handler para el trigger OD_ContractPhone_tgr en el objeto de telefono de contrato
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         21-Nov-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public with sharing class OD_ContractPhone_thr {

    public static Boolean bypassTriggerBeforeInsertExecution = false;


    public static void beforeInsert(List<Telefono_de_Contrato__c> TriggerNew) {

        if (bypassTriggerBeforeInsertExecution) {
            return;
        }

        List<Telefono_de_Contrato__c> lstPhonesToUpdate = OD_ContractPhoneCleaner_cls.ValidateAndUpdateRecords(TriggerNew);
        ACT_ContractPhone_hdl.buildContractPhones(TriggerNew);

        return;
    }

    public static void beforeUpdate(List<Telefono_de_Contrato__c> TriggerNew, Map<Id, Telefono_de_Contrato__c> oldMap){
        if (bypassTriggerBeforeInsertExecution) {
            return;
        }

        List<Telefono_de_Contrato__c> recordsToProcess = new List<Telefono_de_Contrato__c>();

        for (Telefono_de_Contrato__c newRec : TriggerNew) {
            Telefono_de_Contrato__c oldRec = oldMap.get(newRec.Id);
            
            // Validamos si cambiaron los campos específicos
            if (oldRec.Lada__c != newRec.Lada__c || oldRec.Phone__c != newRec.Phone__c || oldRec.Area_Code__c != newRec.Area_Code__c || oldRec.IDSap__c != newRec.IDSap__c) {
                recordsToProcess.add(newRec);
            }
        }

        List<Telefono_de_Contrato__c> lstPhonesToUpdate = OD_ContractPhoneCleaner_cls.ValidateAndUpdateRecords(recordsToProcess);
        ACT_ContractPhone_hdl.buildContractPhones(TriggerNew);

        return;
    }

    
}