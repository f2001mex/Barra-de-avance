/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Reingeniería scheduler
    Descripción     : Clase test de clase SCH_ValidaCuentaExistente

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2025-01-13      Salvador Ramírez	    Creación de la Clase.
*/
@isTest
public class SCH_ValidaCuentaExistente_Test {
    @TestSetup
    static void makeData(){
        OD_Account_cls.bypassTriggerExecution = true;
        OD_Contract_cls.bypassTriggerExecution = true;
        User objUser = [SELECT ID, ID_ASESOR__c FROM USER WHERE ID = :UserInfo.getUserId()];
        objUser.ID_ASESOR__c = '1234';
        update objUser;
        Account objAcc = BIT_UtilityDataTest.createAccount();
        Contract objContract = BIT_UtilityDataTest.createContract(objAcc);
        Telefono_de_Contrato__c objTel = BIT_UtilityDataTest.createPhones(objContract);
        Correo_de_Contrato__c objMail = BIT_UtilityDataTest.createEmails(objContract);
    }
    @isTest
    static void test_validaCuentaExistente(){
        List<SCH_ValidaCuentaExistente.Response> wpList = new List<SCH_ValidaCuentaExistente.Response>();
        List<SCH_ValidaCuentaExistente.objCuenta> lstCuentas = new List<SCH_ValidaCuentaExistente.objCuenta>();
        SCH_ValidaCuentaExistente.objCuenta objCuenta = new SCH_ValidaCuentaExistente.objCuenta();
        objCuenta.BPOrContract = '123456789';
        lstCuentas.add(objCuenta);
        test.startTest();
        wpList = SCH_ValidaCuentaExistente.validaCuentaExistente(lstCuentas);
        test.stopTest();
    }
}