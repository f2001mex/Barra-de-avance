/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Clase test		:   OD_ContractPhoneCleaner_bch_tst
* Description       :   Batch para la validacion de los registros de telefonos de contrato que se encarga de la actualizacion de los registros.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         06-Dic-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class OD_ContractPhoneCleaner_bch implements Database.Batchable<sObject>{

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Lada__c, LadaBackup__c, Area_Code__c, AreaCodeBackup__c, IDSap__c, Phone__c, PhoneBackup__c, DatoCodigoAreaNoValido__c, DatoLadaNoValida__c, DatoTelefonoNoValido__c, DatoContactoNoValido__c  FROM Telefono_de_Contrato__c]);

    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Telefono_de_Contrato__c> lstTelefonos = (List<Telefono_de_Contrato__c>) scope;

        List<Telefono_de_Contrato__c> lstTelefonosToUpdate = OD_ContractPhoneCleaner_cls.ValidateAndUpdateRecords(lstTelefonos);

        if (!lstTelefonosToUpdate.isEmpty()) {
            update lstTelefonosToUpdate;
        }
    }

    
    public void finish(Database.BatchableContext BC) {
        System.debug('Batch de limpieza de correos completado.');
    }
}