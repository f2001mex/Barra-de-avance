/**
 * @description       : Clase que almacenará únicamente las queries necesarias para obtener datos de la clase controlador PV_FileUpload_ctr
 * @author            : Martin Martinez
 * @group             : 
 * @last modified on  : 09-15-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class PV_FileUpload_soql {

    public static Task getTask(Id idTask){
        return [SELECT 
                        AccountId, 
                        Account.Name,
                        Account.Client_ID__c,
                        Account.Owner.ID_ASESOR__c, account.Owner.name,
                        ClienteNoQuiereSerContactado__c,
                        DeveloperName__c,
                        RefenciaOpenText__c,WhoId
                FROM Task 
                WHERE ID = :idTask 
                LIMIT 1];
    }

    public static Boolean getCadence(String developerNameCadence) {
        List<ActionCadence> cadences = [
            SELECT Id, RequiereCargaEvidencia__c
            FROM ActionCadence
            WHERE State = 'Active'
            AND DeveloperName__c = :developerNameCadence LIMIT 1
        ];
        return !cadences.isEmpty() && cadences[0].RequiereCargaEvidencia__c;
    }  

    public static Contract getContract(Id idContract){
        return [SELECT 
                        Id, 
                        Source__c,
                        ContractNumber__c,
                        PlaneacionFinancieraCompletada__c,
                        PropuestaInversionCompletada__c
                FROM Contract 
                WHERE ID = :idContract 
                LIMIT 1];
    }

    public static ContentVersion getVersionFile(Id idDocument){
        return [SELECT 
                        VersionData, 
                        Title, 
                        FileExtension
                FROM ContentVersion
                WHERE ContentDocumentId = :idDocument
                ORDER BY CreatedDate DESC
                LIMIT 1];
    }

    public static ContentDocument getDocument(Id idDocument){
        return [SELECT 
                        Id
                FROM ContentDocument 
                WHERE Id = :idDocument
                LIMIT 1];
    }

    public static List<Contract> getListContractAccount(Id idAccount, String developerName){
        String baseQuery = 'SELECT Id, ContractNumber__c ' +
                        'FROM Contract ' +
                        'WHERE AccountId = :idAccount ';

        /*if (developerName == PSTA_UtilityClass.DEVELOPERNAME_PLANEACION_FINANCIERA) {
            baseQuery += 'AND PlaneacionFinancieraCompletada__c = false ';
        }else if (developerName == PSTA_UtilityClass.DEVELOPERNAME_PROPUESTA_INVERSION) {
            baseQuery += 'AND PropuestaInversionCompletada__c = false ';
        }*/

        return Database.query(baseQuery);
    }

}