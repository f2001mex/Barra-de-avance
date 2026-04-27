/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase test de la clase BIT_UtilityDataTest

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2025-01-20     Salvador Ramírez        Creación de la Clase.
*/
@isTest
public  class BIT_UtilityDataTest_Test {
    @isTest
    static void test_VisitProcess(){
        OD_Account_cls.bypassTriggerExecution = true;
        OD_Contract_cls.bypassTriggerExecution = true;
        User objUser = [SELECT ID, ID_ASESOR__c FROM USER WHERE ID = :UserInfo.getUserId()];
        objUser.ID_ASESOR__c = '1234';
        update objUser;
        Test.startTest();
        Account objAcc = BIT_UtilityDataTest.createAccount();
        Contract objContract = BIT_UtilityDataTest.createContract(objAcc);
        Telefono_de_Contrato__c objTels = BIT_UtilityDataTest.createPhones(objContract);
        Correo_de_Contrato__c objEmail = BIT_UtilityDataTest.createEmails(objContract);
        BranchUnit objSuc = BIT_UtilityDataTest.createBranchUnit();
        Visita__c objVisita = BIT_UtilityDataTest.createVisita(objAcc, objContract, objSuc);
        Servicio__c objServ = BIT_UtilityDataTest.createServicio(objVisita);
        CR_ME_Encuestas_Medallia__c objEncuesta = BIT_UtilityDataTest.createMedalliaSurvey(objAcc);
        Test.stopTest();
    }
    @isTest
    static void test_instanceMock4Services(){
        Test.startTest();
        Map<String, String> endpointsMap = BIT_UtilityDataTest.getEndpointsMap();
        BIT_UtilityDataTest.instanceMock4Services(true, false, endpointsMap);
        Test.stopTest();
    }
}