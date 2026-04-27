/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Description       :   Clase test de la clase PSTA_FechaPrimerContacto_cls
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         23-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@isTest
public class PSTA_FechaPrimerContacto_cls_tst {
    public static final Id idConfigContratosPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('PSTA_ConfiguracionContratosPostventa').getRecordTypeId();
    @testSetup
    public static void testSetup() {
        ConfiguracionActinver__c config = PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();
        ConfiguracionActinver__c configContracts = PSTA_TestDataFactory.createConfiguracionContratosActinver();
        ConfiguracionActinver__c configContact = PSTA_TestDataFactory.createConfiguracionContactoActinver();
        User user = PSTA_TestDataFactory.createUser();
        BranchUnit branchunit = PSTA_TestDataFactory.createBranchUnit();
        Banker bankero = PSTA_TestDataFactory.createBanker(branchunit.Id, user.Id);
        BranchUnitBusinessMember banqueroAsignado = PSTA_TestDataFactory.getBranchUnitBusinessMember(bankero.Id,branchunit.Id);
        List<Account> cuentas = PSTA_TestDataFactory.createAccounts(2,banqueroAsignado.Id,true);
        List<Id> accountIds = new List<Id>();
        for(Account acc : cuentas) {
            accountIds.add(acc.Id);
        }
        List<Contract> contratos = PSTA_TestDataFactory.createContracts(accountIds,banqueroAsignado.ExternalId__c,true,banqueroAsignado.Id);
    }
@isTest
    static void testProcesarFechasConContratosValidos() {
        ConfiguracionActinver__c config = [SELECT TipoContratos__c, EstatusContrato__c 
                             FROM ConfiguracionActinver__c 
                             WHERE RecordTypeId =: idConfigContratosPostVentaRecordType 
                             LIMIT 1];
        
        //List<Account> cuentas = [SELECT Id, Name, FechaAntiguedad__c, FechaUltimoContacto__c, BanqueroAsignado__r.BusinessUnitMember FROM Account];
        List<Account> cuentas  = [SELECT Id, 
                                        FechaUltimoContacto__c,
                                        FechaUltimaVisita__c,
                                        BanqueroAsignado__c, 
                                        SaldoIntegral__c, 
                                        Segmento__c, (SELECT Id, Status__c, AccountOpeningDate__c, TypeOfContract__c, Saldo__c 
                                        FROM Contracts 
                                        WHERE Saldo__c != null AND AccountOpeningDate__c != null ORDER BY AccountOpeningDate__c ASC),
                                        TYPEOF BanqueroAsignado__r.BusinessUnitMember 
                                        WHEN Banker THEN Division__c, ExternalId__c, Id, Cargo__c 
                                        END
                                    FROM Account];
        List<Contract> contratos = [SELECT Id, AccountId, TypeOfContract__c, Status, 
                                   AccountOpeningDate__c FROM Contract 
                                   ORDER BY AccountOpeningDate__c ASC];
        
        Map<Id, List<Contract>> mapContratosPorCuenta = new Map<Id, List<Contract>>();
        for(Account acc : cuentas) {
            mapContratosPorCuenta.put(acc.Id, new List<Contract>());
        }
        for(Contract con : contratos) {
            mapContratosPorCuenta.get(con.AccountId).add(con);
        }
        
        Test.startTest();
        Map<Id, Account> cuentasParaActualizar = new Map<Id, Account>();
        //PSTA_FechaPrimerContacto_cls.procesarFechas(cuentas, mapContratosPorCuenta, cuentasParaActualizar);
        PSTA_FechaPrimerContacto_cls.procesarFechas(cuentas);
        Test.stopTest();
        
    }
    
    /*@isTest
    static void testObtenerFechaContratoMasAntiguo() {
        ConfiguracionActinver__c config = [SELECT TipoContratos__c, EstatusContrato__c 
                             FROM ConfiguracionActinver__c 
                             WHERE RecordTypeId =: idConfigContratosPostVentaRecordType 
                             LIMIT 1];
        
        List<Contract> contratos = [SELECT Id, 
                Status,
                TypeOfContract__c, 
                Saldo__c,
                AccountOpeningDate__c,
                AccountId
                FROM Contract];
        
        
        Test.startTest();
        Set<String> tiposValidos = PSTA_UtilityClass.splitValuesMultiPickList(config.TipoContratos__c);
        Set<String> estatusValidos = PSTA_UtilityClass.splitValuesMultiPickList(config.EstatusContrato__c);
        
        Date fechaResultado = PSTA_FechaPrimerContacto_cls.obtenerFechaContratoMasAntiguo(
            contratos, 
            tiposValidos, 
            estatusValidos
        );
        Test.stopTest();
        
        
    }*/
    
    
}