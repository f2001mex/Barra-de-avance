/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Description       :   Clase test de la clase PSTA_Segmentacion_cls
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         23-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@isTest
public class PSTA_Segmentacion_cls_tst {
    public static final Id idConfigContratosPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('PSTA_ConfiguracionContratosPostventa').getRecordTypeId();
    @testSetup
    public static void testSetup() {

        ConfiguracionActinver__c configContracts = PSTA_TestDataFactory.createConfiguracionContratosActinver();
        ConfiguracionActinver__c configContactPat = PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver(); 
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

    /*@isTest
    static void testProcesarSegmentos() {
        
        List<Account> cuentas = [SELECT Id,  
                  FechaUltimoContacto__c,  
                  BanqueroAsignado__c,  
                  SaldoIntegral__c,  
                  Name,  
                  Segmento__c,  
                  TYPEOF BanqueroAsignado__r.BusinessUnitMember  
                  WHEN Banker THEN Division__c, ExternalId__c, Id, Cargo__c  
                  END 
                  FROM Account];
        Map<Id, Account> cuentasParaActualizar = new Map<Id, Account>();
        
        Test.startTest();
        PSTA_Segmentacion_cls.procesarSegmentos(cuentas, cuentasParaActualizar);
        Test.stopTest();
        
    }*/

    @isTest
    static void testProcesarSegmentoPorCambioAsesor() {
        // Crear segundo banquero para simular cambio
        String adminProfileId = [SELECT Id FROM Profile WHERE name IN ('System Administrator', 'Administrador del sistema')].Id;
        User user = new User();
        user.LastName = 'UserNew';
        user.Username = 'User1@user.com.mx';
        user.Email = 'Useruser@u.com.mx';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.Alias = 'uAas3';
        user.IsActive = true;
        user.TimeZoneSidKey = 'America/Mexico_City';
        user.LocaleSidKey = 'en_US';
        user.LanguageLocaleKey = 'es';
        user.ID_ASESOR__c = '00046';
        user.ProfileId = adminProfileId;
        insert user;

        BranchUnit branchUnit = new BranchUnit();
        branchUnit.Name = 'TestNew';
        branchUnit.IsActive = true;
        branchUnit.BranchCode = '10000012346';
        branchUnit.ExternalIdBI__c = '38';
        branchUnit.ExternalId__c = '10000012346';
        insert branchUnit;

        Banker bankerContact = new Banker();
        bankerContact.Name = 'TestNewBankerContact1';
        bankerContact.JobCode = '00046';
        bankerContact.ExternalId__c = '00046';
        bankerContact.Division__c = 'Patrimonial';
        bankerContact.CurrentBranchId = branchUnit.Id;
        bankerContact.UserOrContactId = user.Id;
        insert bankerContact;

        BranchUnitBusinessMember banqueroAsignado = [SELECT Id, ExternalId__c FROM BranchUnitBusinessMember WHERE BranchUnitId =: branchUnit.Id AND BusinessUnitMemberId =: bankerContact.Id AND IsActive = true LIMIT 1];
        
        // Obtener cuenta existente
        Account cuentaOld = [SELECT Id,  
                  FechaUltimoContacto__c,  
                  BanqueroAsignado__c,  
                  SaldoIntegral__c,  
                  Name,  
                  Segmento__c, Owner.Id,
                  TYPEOF BanqueroAsignado__r.BusinessUnitMember  
                  WHEN Banker THEN Division__c, ExternalId__c, Id, Cargo__c  
                  END  FROM Account WHERE BanqueroAsignado__c !=: bankerContact.Id LIMIT 1];
        Account cuentaNew = cuentaOld.clone(true, true);
        
        // Cambiar el banquero asignado
        cuentaNew.BanqueroAsignado__c = banqueroAsignado.Id;
        
        List<Account> cuentasNuevas = new List<Account>{cuentaNew};
        Map<Id, Account> oldCuentas = new Map<Id, Account>{cuentaOld.Id => cuentaOld};
        
        Test.startTest();
        PSTA_Segmentacion_cls.procesarSegmentoPorCambioAsesor(cuentasNuevas, oldCuentas);
        Test.stopTest();
        
    }


    @isTest
    static void testBypassTriggerExecution() {
        
        List<Account> cuentasNuevas = new List<Account>();
        Map<Id, Account> oldCuentas = new Map<Id, Account>();
        
        Test.startTest();
        PSTA_Segmentacion_cls.bypassTriggerExecution = true;
        PSTA_Segmentacion_cls.procesarSegmentoPorCambioAsesor(cuentasNuevas, oldCuentas);
        Test.stopTest();
        
      
    }
}