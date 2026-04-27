/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Clase test		:   OD_ContractPhone_tgr_tst
* Description       :   Trigger para el objeto de telefono de contrato
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         06-Dic-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
trigger OD_ContractPhone_tgr on Telefono_de_Contrato__c (before insert, before update) {
    if(Trigger_Management__mdt.getInstance('TelefonoDeContratoTrigger').IsActive__c){
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                OD_ContractPhone_thr.beforeInsert(Trigger.new);
            }
            when BEFORE_UPDATE {
                OD_ContractPhone_thr.beforeUpdate(Trigger.new, Trigger.oldMap);
            }
        }
    }
}