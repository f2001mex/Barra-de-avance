/**
* @File Name : OD_BatchAssignContracts_bch.cls
* @Description :Clase batch para proceso los contratos que aun no han sigo asignados algun usuario con licencia
* @Author : Andrés Hernandez Rios
* @Last Modified By :
* @Last Modified On : December 6, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 6, 2024 |Andrés Hernández Ríos| Initial Version
**/
public without sharing class OD_BatchAssignAccounts_bch implements Database.Batchable<SObject> {
    public static String DEFAULT_USER_NAME = Service_Utility_Trigger.DEFAULT_USER_NAME;
    public String query;
    
    //CONSTRUCTOR, CONSTRUIMOS LA QUERY PARA CONTRATOS    
    public OD_BatchAssignAccounts_bch() {
        query = 'SELECT Id, OwnerId, ID_ASESOR__c,RecordTypeId FROM Account WHERE ID_ASESOR__c != null AND Owner.Name =:DEFAULT_USER_NAME';
    }

    //INICIA LA EJECUCIÓN DEL BATCH
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    //PROCESO LOS CONTRATOS RECIBIDOS, ESTOS EN UNA LISTA MANDADA A UNA CLASE SOBJECTLIST
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        //LLAMAR CLASE QUE RECIBIRA LA LISTA DE LOS CONTRATOS
        system.debug('*************BATCH ACCOUNT INICIALIZADO*************');
        OD_AssignUserOwners_cls.processRecords(scope);
    }
    //FINALIZA LA EJECUCIÓN DEL BATCH
    public void finish(Database.BatchableContext bc) {
        System.debug('*************BATCH OD_BatchAssignAccounts_bch FINALIZADO*************');
    }
}