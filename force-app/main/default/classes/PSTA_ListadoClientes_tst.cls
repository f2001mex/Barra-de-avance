/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
* Project           :   Post Venta
* Clase principal   :   PSTA_ListadoClientes_cls
* Description       :   Clase que ejecuta
*******************************************************************************/
@isTest
public class PSTA_ListadoClientes_tst {
    @TestSetup
    static void makeData(){
        Object objConfig = PSTA_TestDataFactory.createConfiguracionContactoActinver();
        BranchUnit objBranch = PSTA_TestDataFactory.createBranchUnit();
        Banker objBanker = PSTA_TestDataFactory.createBanker(objBranch.Id, System.UserInfo.getUserId());
        BranchUnitBusinessMember objBUBM = PSTA_TestDataFactory.getBranchUnitBusinessMember(objBanker.Id, objBranch.Id);
        List<Account> lstAcc = PSTA_TestDataFactory.createAccounts(1, objBUBM.Id, true);
    }
    @isTest
    static void test_actualizarFechaSiguienteContacto(){
        Account objAcc = [SELECT ID, FechaSiguienteContacto__c, FechaUltimoContacto__c, Segmento__c FROM Account LIMIT 1];
        objAcc.FechaUltimoContacto__c = System.today();
        objAcc.Segmento__c = 'Privada';
        Account objAccCopy = new Account(FechaUltimoContacto__c = System.today().addDays(-30));
        List<Account> lstAccount = new List<Account>();
        lstAccount.add(objAcc);
        Map<Id, Account> mapAcc = new Map<Id,Account>{objAcc.Id => objAccCopy};
        Test.startTest();
            PSTA_ListadoClientes_cls.actualizarFechaSiguienteContacto(lstAccount, mapAcc);
        Test.stopTest();
    }
    @isTest
    static void test_actualizarFechaSiguienteVisita(){
        Account objAcc = [SELECT ID, FechaSiguienteVisita__c, FechaSiguienteContacto__c, Segmento__c FROM Account LIMIT 1];
        objAcc.FechaUltimaVisita__c = System.today();
        objAcc.Segmento__c = 'Privada';
        Account objAccCopy = new Account(FechaUltimaVisita__c = System.today().addDays(-30));
        List<Account> lstAccount = new List<Account>();
        lstAccount.add(objAcc);
        Map<Id, Account> mapAcc = new Map<Id,Account>{objAcc.Id => objAccCopy};
        Test.startTest();
            PSTA_ListadoClientes_cls.actualizarFechaSiguienteVisita(lstAccount, mapAcc);
        Test.stopTest();
    }
    @isTest
    static void test_actualizarFechaNoQuiereSerContactado(){
        Account objAcc = [SELECT ID, EstatusContacto__c, FechaNoRequiereSerContacto__c, Segmento__c FROM Account LIMIT 1];
        objAcc.EstatusContacto__c = 'Cliente no quiere ser contactado';
        objAcc.FechaNoRequiereSerContacto__c = System.today();
        objAcc.Segmento__c = 'Privada';
        Account objAccCopy = new Account(EstatusContacto__c = 'Contacto efectivo exitoso', FechaNoRequiereSerContacto__c = System.today().addDays(-30));
        List<Account> lstAccount = new List<Account>();
        lstAccount.add(objAcc);
        Map<Id, Account> mapAcc = new Map<Id,Account>{objAcc.Id => objAccCopy};
        Test.startTest();
            PSTA_ListadoClientes_cls.actualizarFechaNoQuiereSerContactado(lstAccount, mapAcc);
        Test.stopTest();
    }
}