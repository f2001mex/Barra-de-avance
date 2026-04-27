/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase que almacenará únicamente las queries necesarias para obtener datos para el servicio de encuesta medallia

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-08-21      Salvador Ramírez        Creación de la Clase.
*/
public with sharing class BIT_SendMedalliaSurvey_soql {
    public static Visita__c getVisitaInfo(Id idVisita){
        return [SELECT 
                        Cuenta__c,
                        Cuenta__r.NAME,
                        Cuenta__r.PersonEmail,
                        Cuenta__r.Client_ID__c,
                        Cuenta__r.Enrollment_Status__c,
                        Cuenta__r.Phone,
                        Cuenta__r.FWY_Centro_Financiero__c,
                        Contrato__r.ContractNumber__c,
                        Contrato__r.Source__c,
                        Contrato__r.Status__c,
                        RecordType.NAME,
                        HoraEntradaVisita__c,
                        HoraSalida__c,
                        CentroFinanciero__r.Name,
                        Owner.NAME
                FROM VISITA__C 
                WHERE ID = :idVisita 
                LIMIT 1];
    }
    public static List<Telefono_de_Contrato__c> getPhonesFromContract(Id idContract){
        return [SELECT 
                    PRINCIPAL__C,
                    Phone_Type__c,
                    Phone__c,
                    CreatedDate 
                FROM Telefono_de_Contrato__c 
                WHERE IDSAP__C = :idContract];
    }
    public static List<Correo_de_Contrato__c> getEmailsFromContract(Id idContract){
        return [SELECT 
                    Contract_email__c,
                    Principal__c,
                    CreatedDate 
                FROM Correo_de_Contrato__c 
                WHERE NUM_CONTRATO__c = : idContract];
    }
    public static Servicio__c getFirstService(Id idVisita){
        return [SELECT 
                    Submotivo__c,
                    Motivo__c,
                    CreatedDate 
                FROM SERVICIO__C 
                WHERE Visita__c = :idVisita 
                ORDER BY CreatedDate ASC 
                LIMIT 1];
    }
}