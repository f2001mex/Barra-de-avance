/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Clase test		:   OD_ContractEmail_tgr_tst
* Description       :   Trigger para el objeto de correo de contrato
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         21-Nov-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
trigger OD_ContractEmail_tgr on Correo_de_Contrato__c (before insert,before update) {

    if(Trigger_Management__mdt.getInstance('TelefonoDeContratoTrigger').IsActive__c){
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                OD_ContractEmail_thr.beforeInsert(Trigger.new);
            }
            when BEFORE_UPDATE{
                OD_ContractEmail_thr.beforeUpdate(Trigger.new,Trigger.oldMap);
            }
        }
    }
}