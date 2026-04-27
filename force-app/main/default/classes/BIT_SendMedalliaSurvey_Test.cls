/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase test para las clases BIT_Medallia_Request, BIT_Medallia_Response, BIT_Medallia_payload, BIT_SendMedalliaSurvey_cls, BIT_SendMedalliaSurvey_ctr, BIT_SendMedalliaSurvey_soql.

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-09-17      Salvador Ramírez        Creación de la Clase.
*/
@IsTest
public class BIT_SendMedalliaSurvey_Test {
    @TestSetup
    static void makeData(){
        Account objAcc = BIT_UtilityDataTest.createAccount();
        Contract objContract = BIT_UtilityDataTest.createContract(objAcc);
        Telefono_de_Contrato__c objPhones = BIT_UtilityDataTest.createPhones(objContract);
        Correo_de_Contrato__c objEmails = BIT_UtilityDataTest.createEmails(objContract);
        BranchUnit objSuc = BIT_UtilityDataTest.createBranchUnit();
        Visita__c objVisita = BIT_UtilityDataTest.createVisita(objAcc, objContract, objSuc);
        Servicio__c objServ = BIT_UtilityDataTest.createServicio(objVisita);
    }
    @IsTest
    static void test1(){
        test.startTest();
            test.setMock(HttpCalloutMock.class, new BIT_SendMedalliaSurvey_Mockup());
            Visita__c visita = [SELECT ID, ETAPA__C, HoraSalida__c FROM VISITA__C LIMIT 1];
            visita.Etapa__c = 'Finalizado';
            Visita.HoraSalida__c = System.now();
            update Visita;
        test.stopTest();
    }
    static void test2(){
        test.startTest();
            test.setMock(HttpCalloutMock.class, new BIT_SendMedalliaSurvey_Mockup());
            Telefono_de_Contrato__c objTel = [SELECT id, principal__c FROM Telefono_de_Contrato__c LIMIT 1];
            objTel.principal__c = true;
            update objTel;
            Correo_de_Contrato__c objCorreo = [SELECT id, principal__c FROM Correo_de_Contrato__c LIMIT 1];
            objCorreo.principal__c = true;
            update objCorreo;
            Visita__c visita = [SELECT ID, ETAPA__C, HoraSalida__c FROM VISITA__C LIMIT 1];
            visita.Etapa__c = 'Finalizado';
            Visita.HoraSalida__c = System.now();
            update Visita;
        test.stopTest();
    }
    @isTest
    static void test3(){
        test.startTest();
        test.setMock(HttpCalloutMock.class, new BIT_SendMedalliaSurvey_Mockup());
        Visita__c objVisita = [SELECT ID, HoraSalida__c FROM VISITA__C LIMIT 1];
        objVisita.HoraSalida__c = System.now();
        update objVisita;
        BIT_SendMedalliaSurvey_ctr.callout(objVisita.Id);
        test.stopTest();
    }
    @isTest
    static void test4(){
        test.startTest();
        Set<Id> setIds = new Set<Id>();
        for(Visita__c objVisita : [SELECT ID FROM VISITA__C]){
            setIds.add(objVisita.Id);
        }
        System.Queueable job = new BIT_SendMedalliaSurvey_qbl(new map<String, Set<Id>>{'idVisita' => setIds});
        System.enqueueJob(job);
        test.stopTest();
    }
}