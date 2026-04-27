/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Description       :   Clase test para la clase PSTA_SegmentacionClientes_bch
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         28-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@isTest
public class PSTA_SegmentacionClientes_bch_tst {
     @testSetup
    public static void testSetup() {
        // Configuración base (similar a tus otros tests)
        ConfiguracionActinver__c configContratos = PSTA_TestDataFactory.createConfiguracionContratosActinver();
        ConfiguracionActinver__c configContacto = PSTA_TestDataFactory.createConfiguracionContactoActinver();
        ConfiguracionActinver__c configReactivo = PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();
        
        User user = PSTA_TestDataFactory.createUser();
        BranchUnit branchunit = PSTA_TestDataFactory.createBranchUnit();
        Banker bankero = PSTA_TestDataFactory.createBanker(branchunit.Id, user.Id);
        BranchUnitBusinessMember banqueroAsignado = PSTA_TestDataFactory.getBranchUnitBusinessMember(bankero.Id, branchunit.Id);
        
        // Crear cuentas para el batch
        List<Account> cuentas = PSTA_TestDataFactory.createAccounts(5, banqueroAsignado.Id, true);
        
        // Crear contratos asociados
        List<Id> accountIds = new List<Id>();
        for(Account acc : cuentas) {
            accountIds.add(acc.Id);
        }
        PSTA_TestDataFactory.createContracts(accountIds, banqueroAsignado.ExternalId__c, true, banqueroAsignado.Id);
    }

    @isTest
    static void testBatch_FlujoCompleto() {
        
        Test.startTest();
        PSTA_SegmentacionClientes_bch batch = new PSTA_SegmentacionClientes_bch();
        ID batchprocessid = Database.executeBatch(batch);
        Test.stopTest();
        
    }
}