/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Reingeniería scheduler
    Descripción     : Clase test de la clase SCH_SchedulerFunctions_cls

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2025-01-13      Salvador Ramírez	    Creación de la Clase.
*/
@isTest
public class SCH_SchedulerFunctions_test {
    @TestSetup
    static void makeData(){
        OD_Account_cls.bypassTriggerExecution = true;
        OD_Contract_cls.bypassTriggerExecution = true;
        User objUser = [SELECT ID, ID_ASESOR__c FROM USER WHERE ID = :UserInfo.getUserId()];
        objUser.ID_ASESOR__c = '1234';
        update objUser;
        Account objAcc = BIT_UtilityDataTest.createAccount();
        Contract objContract = BIT_UtilityDataTest.createContract(objAcc);
    }
    //Búsqueda por BP
    @isTest
    static void test_validarCuentaExistente1(){
        test.startTest();
        Object res = SCH_SchedulerFunctions_cls.validarCuentaExistente('123456789');
        test.stopTest();
    }
    //Búsqueda por contrato
    @isTest
    static void test_validarCuentaExistente2(){
        test.startTest();
        Object res = SCH_SchedulerFunctions_cls.validarCuentaExistente('142536');
        test.stopTest();
    }
    //Búsqueda por contrato erroneo
    @isTest
    static void test_validarCuentaExistente3(){
        test.startTest();
        Object res = SCH_SchedulerFunctions_cls.validarCuentaExistente('111222333');
        test.stopTest();
    }
    @isTest
    static void test_getDependentPicklistValues(){
        Test.startTest();
        Object res = SCH_SchedulerFunctions_cls.getDependentPicklistValues(Servicio__c.SubMotivo__c);
        Test.stopTest();
    }
    @isTest
    static void test_getDateTimeWithOffset(){
        Test.startTest();
        Object res = SCH_SchedulerFunctions_cls.getDateTimeWithOffset('America/Mexico City', DateTime.now());
        Test.stopTest();
    }
}