/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Clase test		:   OD_ContractEmail_bch_tst
* Description       :   Batch para la validacion de los registros de correos de contrato que se encarga de la actualizacion de los registros.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         20-Nov-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class OD_ContractEmailCleaner_bch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Contract_Email__c, DatoContactoNoValido__c, DatoPalabraRestringida__c, NUM_CONTRATO__c FROM Correo_de_Contrato__c]);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Correo_de_Contrato__c> lstCorreos = (List<Correo_de_Contrato__c>) scope;

        List<Correo_de_Contrato__c> lstCorreosToUpdate = OD_ContractEmailCleaner_cls.ValidateAndUpdateRecords(lstCorreos);

        if (!lstCorreosToUpdate.isEmpty()) {
            update lstCorreosToUpdate;
        }
    }

    
    public void finish(Database.BatchableContext BC) {
        System.debug('Batch de limpieza de correos completado.');
    }
}