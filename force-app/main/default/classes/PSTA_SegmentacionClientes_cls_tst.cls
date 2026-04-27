/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Description       :   Clase test para la clase PSTA_SegmentacionClientes_cls
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         28-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@isTest
public class PSTA_SegmentacionClientes_cls_tst {
    @testSetup
    public static void testSetup() {
        // Configuración base
        ConfiguracionActinver__c configContratos = PSTA_TestDataFactory.createConfiguracionContratosActinver();
        ConfiguracionActinver__c configContacto = PSTA_TestDataFactory.createConfiguracionContactoActinver();
        ConfiguracionActinver__c configReactivo = PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();
        
        User user = PSTA_TestDataFactory.createUser();
        BranchUnit branchunit = PSTA_TestDataFactory.createBranchUnit();
        Banker bankero = PSTA_TestDataFactory.createBanker(branchunit.Id, user.Id);
        BranchUnitBusinessMember banqueroAsignado = PSTA_TestDataFactory.getBranchUnitBusinessMember(bankero.Id, branchunit.Id);
        
        // Crear cuentas con diferentes características
        List<Account> cuentas = PSTA_TestDataFactory.createAccounts(3, banqueroAsignado.Id, true);
        
        // Crear contratos asociados
        List<Id> accountIds = new List<Id>();
        for(Account acc : cuentas) {
            accountIds.add(acc.Id);
        }
        List<Contract> contratos = PSTA_TestDataFactory.createContracts(accountIds, banqueroAsignado.ExternalId__c, true, banqueroAsignado.Id);
    }

    @isTest
    static void testSegmentacionClientes_IntegracionCompleta() {
        // Obtener datos de prueba
        List<Account> cuentas = [SELECT Id,  
                  FechaUltimoContacto__c,  
                  BanqueroAsignado__c,  
                  SaldoIntegral__c,  
                  Name,  
                  Segmento__c,  
                  TYPEOF BanqueroAsignado__r.BusinessUnitMember  
                  WHEN Banker THEN Division__c, ExternalId__c, Id, Cargo__c  
                  END  FROM Account];


        Set<Id> setIdCuentas = new Set<Id>();
        for (Account acc : cuentas) {
            setIdCuentas.add(acc.Id);
        }
        List<Contract> contratos = [SELECT Id, 
                ContractNumber, 
                Status,
                TypeOfContract__c, 
                StartDate, 
                Saldo__c,
                AccountOpeningDate__c,
                AccountId
                FROM Contract
                WHERE AccountId IN :setIdCuentas];
        
        Test.startTest();
        //Map<Id, Account> resultado = PSTA_SegmentacionClientes_cls.segmentacionClientes(cuentas, contratos);
        PSTA_SegmentacionClientes_cls.segmentacionClientes(cuentas);
        Test.stopTest();
        
        
    }

    /*@isTest
    static void testOrganizarContratosPorCuenta() {
        // Obtener datos de prueba
        List<Contract> contratos = [SELECT Id, AccountId FROM Contract];
        Set<Id> accountIds = new Set<Id>();
        for(Contract con : contratos) {
            accountIds.add(con.AccountId);
        }
        
        Test.startTest();
        Map<Id, List<Contract>> resultado = PSTA_SegmentacionClientes_cls.organizarContratosPorCuenta(contratos);
        Test.stopTest();
        
        
    }*/

    @isTest
    static void testUpdateRecords_Exitoso() {
        // Crear cuentas de prueba
        List<Account> cuentas = PSTA_TestDataFactory.createAccounts(2, null, false);
        for(Account acc : cuentas) {
            acc.Segmento__c = 'Privada';
        }
        insert cuentas;
        
        Map<Id, Account> mapCuentas = new Map<Id, Account>(cuentas);
        
        Test.startTest();
        //PSTA_SegmentacionClientes_cls.updateRecords(cuentas, mapCuentas);
        PSTA_SegmentacionClientes_cls.updateRecords(cuentas);
        Test.stopTest();
        
        
    }

    @isTest
    static void testUpdateRecords_ConError() {
        // Forzar error (cuenta sin nombre requerido)
        List<Account> cuentas = new List<Account>{
            new Account(Segmento__c = 'Privada') // Falta Name que es requerido
        };
        Map<Id, Account> mapCuentas = new Map<Id, Account>();
        for(Account acc : cuentas) {
            mapCuentas.put(acc.Id, acc);
        }
        
        Test.startTest();
        //PSTA_SegmentacionClientes_cls.updateRecords(cuentas, mapCuentas);
        PSTA_SegmentacionClientes_cls.updateRecords(cuentas);
        Test.stopTest();
        
    }

    
}