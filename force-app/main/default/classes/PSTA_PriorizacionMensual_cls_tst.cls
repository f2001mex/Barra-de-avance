/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Description       :   Clase test de la clase PSTA_PriorizacionMensual_cls
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         28-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@isTest
public class PSTA_PriorizacionMensual_cls_tst {
    
    @testSetup
    public static void testSetup() {
        // Configuración base
        ConfiguracionActinver__c configPrivada = PSTA_TestDataFactory.createConfiguracionContactoActinver();
        User user = PSTA_TestDataFactory.createUser();
        BranchUnit branchunit = PSTA_TestDataFactory.createBranchUnit();
        Banker bankero = PSTA_TestDataFactory.createBanker(branchunit.Id, user.Id);
        BranchUnitBusinessMember banqueroAsignado = PSTA_TestDataFactory.getBranchUnitBusinessMember(bankero.Id, branchunit.Id);
        
        // Crear cuentas con diferentes características para pruebas
        List<Account> cuentas = new List<Account>();
        for(Integer i = 0; i < 5; i++) {
            Account acc = new Account(
                Name = 'Cuenta Test ' + i,
                Segmento__c = 'Privada',
                BanqueroAsignado__c = banqueroAsignado.Id,
                FechaSiguienteContacto__c = System.today().addDays(-i * 10), // Fechas diferentes para probar priorización
                FechaSiguienteVisita__c = System.today().addDays(-i * 10),
                SaldoIntegral__c = (100000 * (i + 1)) // Saldos diferentes para probar ordenamiento
            );
            cuentas.add(acc);
        }
        
        OD_Account_cls.bypassTriggerExecution = true;

        insert cuentas;
        
        // Configurar Business Hours mock
        Id BusinessHourshId = [SELECT Id,Name FROM BusinessHours WHERE Name ='Postventa'].Id;
    }

    @isTest
    static void testAgrupacionBanqueroPorCuentas() {
        // Obtener datos de prueba
        List<Account> cuentas = [SELECT Id,  
                  FechaUltimoContacto__c,  
                  BanqueroAsignado__c,  
                  SaldoIntegral__c,  
                  Name,  
                  Segmento__c, FechaSiguienteContacto__c, FechaSiguienteVisita__c,
                  TYPEOF BanqueroAsignado__r.BusinessUnitMember  
                  WHEN Banker THEN Division__c, ExternalId__c, Id, Cargo__c  
                  END  FROM Account];
        
        Test.startTest();
        /*Map<Id, List<Account>> mapCuentasPorAsesor = new Map<Id, List<Account>>();
        PSTA_PriorizacionMensual_cls.agrupacionBanqueroPorCuentas(cuentas, mapCuentasPorAsesor);*/
        Map<String, ConfiguracionActinver__c> mapConfigPorSegmento = PSTA_PriorizacionDiaria_cls.obtenerSegmentoPorConfig();
        PSTA_PriorizacionMensual_cls.agrupacionBanqueroPorCuentas(cuentas, mapConfigPorSegmento);
        Test.stopTest();
        
    }

    @isTest
    static void testDebePriorizarContacto_CuentaCumpleFrecuencia() {
        
        ConfiguracionActinver__c config = [SELECT Id, FrecuenciaContacto__c, RangoMontoMaximo__c, RangoMontoMinimo__c FROM ConfiguracionActinver__c LIMIT 1];
        Account cuenta = new Account(
            FechaSiguienteContacto__c = Date.today().addDays(-((Integer)config.FrecuenciaContacto__c + 1))
        );
        
        Test.startTest();
        Boolean resultado = PSTA_PriorizacionMensual_cls.debePriorizarContacto(cuenta, config, Date.today());
        Test.stopTest();
        
    }

    @isTest
    static void testDebePriorizarContacto_CuentaCumpleRango() {
        
        ConfiguracionActinver__c config = [SELECT Id, FrecuenciaContacto__c, RangoMontoMaximo__c, RangoMontoMinimo__c FROM ConfiguracionActinver__c LIMIT 1];
        Account cuenta = new Account(
            FechaSiguienteContacto__c = Date.today().addDays(-((Integer)config.FrecuenciaContacto__c + 1)),
            SaldoIntegral__c = 10000
        );
        
        Test.startTest();
        Boolean resultado = PSTA_PriorizacionMensual_cls.debePriorizarContacto(cuenta, config, Date.today());
        Test.stopTest();
        
    }

    @isTest
    static void testPriorizarCuentas_DeberiaPriorizarSegunConfig() {
        
        // Obtener datos de prueba
        List<Account> cuentas = [SELECT Id, Segmento__c, BanqueroAsignado__c, SaldoIntegral__c, FechaSiguienteContacto__c 
                               FROM Account ORDER BY SaldoIntegral__c DESC];
        Banker bankero = [SELECT Id FROM Banker LIMIT 1];
        
        Map<Id, List<Account>> mapCuentasPorAsesor = new Map<Id, List<Account>>();
        mapCuentasPorAsesor.put(bankero.Id, cuentas);
        
        Map<String, ConfiguracionActinver__c> mapConfiguraciones = PSTA_PriorizacionMensual_cls.obtenerSegmentoPorConfig();
        
        Test.startTest();
        List<Account> cuentasPriorizadas = PSTA_PriorizacionMensual_cls.priorizarCuentas(
            new List<Id>{bankero.Id}, 
            mapCuentasPorAsesor, 
            mapConfiguraciones
        );
        Test.stopTest();
        
        
    }

    /*@isTest
    static void testPriorizarCuentas_ReinicioContacto() {
        
        // Obtener datos de prueba
        List<Account> cuentas = [SELECT Id, Segmento__c, BanqueroAsignado__c, SaldoIntegral__c, FechaSiguienteContacto__c, ContactoPriorizadoEsteMes__c 
                               FROM Account ORDER BY SaldoIntegral__c DESC];
        
        Map<Id, Account> mapCuentasAActualizar = new Map<Id, Account>();
        
        Test.startTest();
        PSTA_PriorizacionMensual_cls.procesarReinicioPrioridadMensual(
            cuentas, 
            mapCuentasAActualizar
        );
        Test.stopTest();
        
        
    }*/

    @isTest
    static void testObtenerSegmentoPorConfig() {
        Test.startTest();
        Map<String, ConfiguracionActinver__c> resultado = PSTA_PriorizacionMensual_cls.obtenerSegmentoPorConfig();
        Test.stopTest();
        
    }

    @isTest
    static void testUpdateRecords_Exitoso() {
        List<Account> cuentas = PSTA_TestDataFactory.createAccounts(2, null, false);
        for(Account acc : cuentas) {
            acc.PriorizacionContacto__c = true;
        }
        
        Test.startTest();
        PSTA_PriorizacionMensual_cls.updateRecords(cuentas);
        Test.stopTest();
      
    }

    @isTest
    static void testUpdateRecords_ConError() {
        // Forzar error (cuenta sin nombre requerido)
        List<Account> cuentas = new List<Account>{
            new Account(PriorizacionContacto__c = true) // Falta Name que es requerido
        };
        
        Test.startTest();
        PSTA_PriorizacionMensual_cls.updateRecords(cuentas);
        Test.stopTest();
        
    
    }
}