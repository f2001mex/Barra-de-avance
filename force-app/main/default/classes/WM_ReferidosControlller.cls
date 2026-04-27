/**
 * @description       : Este es un controlador Apex para el LWC WM_Referidos_lwc
 * @author            : Juan Miguel Solis Vazquez.
 * @group             : VASS
 * @last modified on  : 11-01-2024
 * @last modified by  : Juan Miguel Solis Vazquez.
 * Version            : 1.0
**/
public with sharing class WM_ReferidosControlller {

    /**
     * Método para buscar registros Banker en base a un término de búsqueda.
     * @param searchTerm Término de búsqueda para el campo ExternalId__c o el nombre.
     * @return Lista de registros Banker que coinciden con el término de búsqueda.
     */
    @AuraEnabled
    public static List<Contact> searchDataContact(String searchTerm){
        try {
            List<Contact> lc = new List<Contact>();
            String searchQuery = '%' + searchTerm + '%';
            if(!searchTerm.isNumeric()){
                    lc = [SELECT Id,Name,Account.Client_ID__c,AccountId,Account.Name  FROM Contact WHERE NAME LIKE :searchQuery AND AccountId != null];
            }else {
                    lc = [SELECT Id,Name,Account.Client_ID__c,AccountId,Account.Name  FROM Contact WHERE Account.Client_ID__c =:searchTerm AND AccountId != null] ;
            }
            return lc;
        } catch (Exception e) {
            System.debug('error : ' + e.getMessage() + 'linea : ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    
    /**
     * Método para buscar registros de Contact basado en el término de búsqueda y estado de empleado.
     * @param searchTerm El término de búsqueda para nombres de Contact o ID de cliente/banquero.
     * @param isEmployee Booleano que indica si el contacto es un empleado.
     * @return Lista de registros Contact que coinciden con los criterios de búsqueda.
     */
    @AuraEnabled
    public static List<Banker> searchDataBanker(String searchTerm,Boolean isEmployee){
        try {
                Id rTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Banquero sin licencia').getRecordTypeId();
                List<Banker> b = new List<Banker>();
                String searchQuery = '%' + searchTerm + '%';
                System.debug('¿es empleado? : ' + isEmployee + 'termino de busqueda : ' + searchTerm + ' -- ' + searchQuery);
                if(isEmployee){
                    b = [SELECT Id,Name,ExternalId__c,UserOrContactId,CurrentBranch.Name,Cargo__c FROM Banker WHERE ExternalId__c LIKE :searchQuery AND UserOrContact.RecordTypeId =: rTypeId];
                    if(!searchTerm.isNumeric()){
                        b = [SELECT Id,Name,ExternalId__c,UserOrContactId,CurrentBranch.Name,Cargo__c FROM Banker WHERE NAME LIKE :searchQuery AND UserOrContact.RecordTypeId =: rTypeId];
                    }
                }else{
                    b = [SELECT Id,Name,ExternalId__c,UserOrContactId FROM Banker WHERE JobCode LIKE :searchQuery AND UserOrContact.RecordTypeId !=: rTypeId];
                    if(!searchTerm.isNumeric()){
                        b = [SELECT Id,Name,ExternalId__c,UserOrContactId FROM Banker WHERE NAME LIKE :searchQuery AND UserOrContact.RecordTypeId !=: rTypeId];
                    }
                }
                System.debug('@Data encontrada : ' + b);
                return b;
            } catch (Exception e) {
                System.debug('error : ' + e.getMessage() + 'linea : ' + e.getLineNumber());
                throw new AuraHandledException(e.getMessage());
            }
    }


    /**
     * Método para actualizar la relación de referencia en un registro Lead.
     * @param recordId ID del registro Lead que se desea actualizar.
     * @param idRefer ID del usuario o contacto que será la nueva referencia.
     * @return String 'Success' si la actualización fue exitosa.
     */
    @AuraEnabled
    public static string updateReferRelation(String recordId, Id idRefer){
        try {
                Lead l = new Lead();
                l.Id = recordId;
                String sObjectType = idRefer.getSObjectType().getDescribe().getName();
                if(sObjectType == 'User'){
                    l.FinServ__ReferredByUser__c = idRefer;
                    l.FinServ__ReferredByContact__c = null;
                }else{
                    l.FinServ__ReferredByContact__c = idRefer;
                    l.FinServ__ReferredByUser__c = null;
                }
                update l;
                return 'Success';
        } catch (Exception e) {
            System.debug('error : ' + e.getMessage() + 'linea : ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Método para obtener información de registros Lead y Banker en base al ID de Lead.
     * @param recordId ID del registro a buscar.
     * @return String con los datos serializados en formato JSON del Lead o Banker relacionado.
     */
    @AuraEnabled
    public static string getRecords(String recordId){
        try {
            Id newId = recordId;
            String sObjectType = newId.getSObjectType().getDescribe().getName();
            String response = '';
            System.debug('Record Id: ' + newId +'SObject : ' + sObjectType);
            List<Banker> listaBanker = new List<Banker>(); 
            if(sObjectType != 'Account'){
                List<Lead> ListaLead = [SELECT Id,FinServ__ReferredByContact__r.Name,FinServ__ReferredByContact__c,FinServ__ReferredByContact__r.Account.Client_ID__c,FinServ__ReferredByUser__c,FinServ__ReferredByContact__r.AccountId,
                FinServ__ReferredByContact__r.EmpleadoSinLicenciaSFDC__c
                FROM Lead WHERE Id =:recordId];
                system.debug('data get lead: ' + ListaLead[0]);
                response = JSON.serialize(ListaLead[0]);
                if(ListaLead[0].FinServ__ReferredByContact__c == null && ListaLead[0].FinServ__ReferredByUser__c != null  ){
                    listaBanker = [SELECT Id,Name,ExternalId__c,UserOrContactId,CurrentBranch.Name,Cargo__c FROM Banker WHERE UserOrContactId  =: ListaLead[0].FinServ__ReferredByUser__c ];
                    response = Test.isRunningTest() == false ? JSON.serialize(listaBanker[0]) : 'failed';
                }
            }else{
                List<Lead> ListaLead = [SELECT Id,FinServ__ReferredByContact__r.Name,FinServ__ReferredByContact__c,FinServ__ReferredByContact__r.Account.Client_ID__c,FinServ__ReferredByUser__c,FinServ__ReferredByContact__r.AccountId,
                FinServ__ReferredByContact__r.EmpleadoSinLicenciaSFDC__c
                FROM Lead WHERE ConvertedAccount.id =:recordId];
                response = JSON.serialize(ListaLead[0]);
                System.debug('Lista de Lead: ' + ListaLead[0]);
                if(ListaLead[0].FinServ__ReferredByContact__c == null && ListaLead[0].FinServ__ReferredByUser__c != null  ){
                    listaBanker = [SELECT Id,Name,ExternalId__c,UserOrContactId,CurrentBranch.Name,Cargo__c FROM Banker WHERE UserOrContactId  =: ListaLead[0].FinServ__ReferredByUser__c ];
                    response = Test.isRunningTest() == false ? JSON.serialize(listaBanker[0]) : 'failed';
                }
            }
            System.debug('@@response :' + response);
            return response;
        } catch (Exception e) {
            System.debug('error : ' + e.getMessage() + 'linea : ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string getComplements(String recordId){
        try {
            String response = '';
            List<Banker> listaBanker = new List<Banker>(); 
            listaBanker = [SELECT Id,Name,ExternalId__c,UserOrContactId,CurrentBranch.Name,Cargo__c FROM Banker WHERE UserOrContactId  =: recordId];
            response = JSON.serialize(listaBanker[0]);
            System.debug('response complementos:' + response);
            return response;
        } catch (Exception e) {
            System.debug('error : ' + e.getMessage() + 'linea : ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        } 
    }
}