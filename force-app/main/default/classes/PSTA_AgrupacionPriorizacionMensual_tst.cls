/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Description       :   Clase test para la clase PSTA_AgrupacionPriorizacionMensual_bch
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         28-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@isTest
public class PSTA_AgrupacionPriorizacionMensual_tst {
    @testSetup
    public static void testSetup() {
        // Configuración base (similar a tus otros tests)
        ConfiguracionActinver__c configContratos = PSTA_TestDataFactory.createConfiguracionContratosActinver();
        ConfiguracionActinver__c configContacto = PSTA_TestDataFactory.createConfiguracionContactoActinver();
        //ConfiguracionActinver__c configReactivo = PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();
        
        User user = PSTA_TestDataFactory.createUser();
        BranchUnit branchunit = PSTA_TestDataFactory.createBranchUnit();
        Banker bankero = PSTA_TestDataFactory.createBanker(branchunit.Id, user.Id);
        BranchUnitBusinessMember banqueroAsignado = PSTA_TestDataFactory.getBranchUnitBusinessMember(bankero.Id, branchunit.Id);
        
        List<Account> cuentas = new List<Account>();
        for(Integer i = 0; i < 5; i++) {
            Account acc = new Account(
                Name = 'Cuenta Test ' + i,
                Segmento__c = 'Privada',
                Person_Type__c = 'FISICA',
                BanqueroAsignado__c = banqueroAsignado.Id,
                ContactoPriorizadoEsteMes__c = false,
                FechaSiguienteContacto__c = System.today().addDays(-i * 50), // Fechas diferentes para probar priorización
                SaldoIntegral__c = (10000 * (i + 1)), // Saldos diferentes para probar ordenamiento
                FechaSiguienteVisita__c = System.today().addDays(-i * 50)
            );
            System.debug('Cliente. Saldo: ' + acc);
            cuentas.add(acc);
        }
        
        OD_Account_cls.bypassTriggerExecution = true;

        insert cuentas;
        
        // Crear contratos asociados
        List<Id> accountIds = new List<Id>();
        for(Account acc : cuentas) {
            accountIds.add(acc.Id);
        }
        PSTA_TestDataFactory.createContracts(accountIds, banqueroAsignado.ExternalId__c, true, banqueroAsignado.Id);
    }
    @isTest
    static void testBatch_FlujoCompleto() {
        // Obtener datos de prueba
        
        List<Account> cuentas = [SELECT Id,  
                  FechaUltimoContacto__c,  
                  BanqueroAsignado__c,  
                  SaldoIntegral__c,  
                  Name,  
                  Segmento__c,  
                  TYPEOF BanqueroAsignado__r.BusinessUnitMember  
                  WHEN Banker THEN Division__c, ExternalId__c, Id, Cargo__c  
                  END  
                  FROM Account  
                  WHERE Segmento__c != null AND SaldoIntegral__c != null AND FechaSiguienteContacto__c != null];
        Map<Id, List<Account>> mapClientesPorAsesor = new Map<Id, List<Account>>();
        for(Account acc : cuentas) {
            if(!mapClientesPorAsesor.containsKey(acc.BanqueroAsignado__c)) {
                mapClientesPorAsesor.put(acc.BanqueroAsignado__c, new List<Account>());
            }
            mapClientesPorAsesor.get(acc.BanqueroAsignado__c).add(acc);
        }
        
        Map<String, ConfiguracionActinver__c> mapConfigPorSegmento = new Map<String, ConfiguracionActinver__c>();
        ConfiguracionActinver__c config = [SELECT Segmento__c, RangoMontoMaximo__c, RangoMontoMinimo__c, FrecReinicioNoReqContacto__c, Rol__c, FrecuenciaContacto__c, FrecuenciaVisita__c, ClientesContactarPorDia__c FROM ConfiguracionActinver__c LIMIT 1];
        mapConfigPorSegmento.put(config.Segmento__c, config);
        
        Test.startTest();
        PSTA_AgrupacionPriorizacionMensual_bch batch = new PSTA_AgrupacionPriorizacionMensual_bch();
        ID batchprocessid = Database.executeBatch(batch);
        Test.stopTest();
        
    }
}