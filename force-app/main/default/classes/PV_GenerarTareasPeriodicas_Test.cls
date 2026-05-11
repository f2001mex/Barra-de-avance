@isTest
public class PV_GenerarTareasPeriodicas_Test {

    @testSetup
    static void setupData() {
        String adminProfileId = [SELECT Id FROM Profile WHERE name IN ('System Administrator', 'Administrador del sistema')].Id;
        String uniqueSuffix = String.valueOf(System.now().getTime());
        User user = new User();
        user.LastName = 'User1';
        user.Username = 'User1.' + uniqueSuffix + '@user.com.u';
        user.Email = 'user.' + uniqueSuffix + '@u.com.u';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.Alias = 'uAas2';
        user.IsActive = true;
        user.TimeZoneSidKey = 'America/Mexico_City';
        user.LocaleSidKey = 'en_US';
        user.LanguageLocaleKey = 'es';
        user.ID_ASESOR__c = '0001';
        user.ProfileId = adminProfileId;
        insert user;

        System.runAs(user) {
            Contact contactWithOutLicense = new Contact();
            contactWithOutLicense.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('BanqueroLlicencia').getRecordTypeId();
            contactWithOutLicense.FirstName = 'TestName';
            contactWithOutLicense.LastName = 'TestApp';
            contactWithOutLicense.EmpleadoSinLicenciaSFDC__c = true;
            contactWithOutLicense.NumeroNomina__c = '0001';
            insert contactWithOutLicense;
            
            BranchUnit branchUnit = new BranchUnit();
            branchUnit.Name = 'TestBranchUnit';
            branchUnit.IsActive = true;
            branchUnit.BranchCode = '10000012345';
            branchUnit.ExternalIdBI__c = '37';
            branchUnit.ExternalId__c = '10000012345';
            insert branchUnit;
            
            Banker bankerContact = new Banker();
            bankerContact.Name = 'TestBankerContact';
            bankerContact.JobCode = '0001';
            bankerContact.CurrentBranchId = branchUnit.Id;
            bankerContact.UserOrContactId = contactWithOutLicense.Id;
            insert bankerContact;
            
            Account acc = new Account();
            acc.FirstName = 'TestName';
            acc.MiddleName = 'TestMiddle';
            acc.LastName = 'TestApp';
            acc.F3_CURP__c = 'TESTING1';
            acc.Client_ID__c = '02030';
            acc.ID_Asesor__c = '0001';
            acc.EnrolamientoBiometricos__c = '0';
            acc.EnrolamientoActivo__c = '0';        
            acc.OwnerId = [SELECT Id FROM User WHERE Name = 'IntegrationUser'].Id;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
            insert acc;
            
            Account acc2 = new Account();
            acc2.FirstName = 'TestName2';
            acc2.MiddleName = 'TestMiddle2';
            acc2.LastName = 'TestApp2';
            acc2.F3_CURP__c = 'TESTING2';
            acc2.Client_ID__c = '02031';
            acc2.ID_Asesor__c = '0001';
            acc2.OwnerId = [SELECT Id FROM User WHERE Name = 'IntegrationUser'].Id;
            acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
            insert acc2;
            
            Contract contract = new Contract();
            contract.AccountId = acc.Id;
            contract.Source__c = 'Contrato de Banco';
            contract.ContractNumber__c = '142536';
            contract.Status__c = 'Nuevo';
            contract.TypeOfContract__c = '01';
            contract.ID_ASESOR__c = '0001';
            contract.OwnerId = [SELECT Id FROM User WHERE Name = 'IntegrationUser'].Id;
            contract.IDSap__c = '142536';
            insert contract;
            
            Contract contract2 = new Contract();
            contract2.AccountId = acc2.Id;
            contract2.Source__c = 'Contrato de Banco';
            contract2.ContractNumber__c = '142536';
            contract2.Status__c = 'Nuevo';
            contract2.TypeOfContract__c = '01';
            contract2.FLAG_MARKETING__c = 'X';
            contract2.FLAG_MARKETING_ACTINVER__c = 'X';
            contract2.FLAG_EVENTS_INVITATIONS__c = 'X';
            contract2.ID_ASESOR__c = '0001';
            contract2.OwnerId = [SELECT Id FROM User WHERE Name = 'IntegrationUser'].Id;
            contract2.IDSap__c = '142536';
            insert contract2;

            // Crea una tarea
            Task t = new Task(
                Subject = 'Tarea de prueba',
                WhoId = acc.PersonContactId,
                Status = 'Completado',
                Priority = 'Normal',
                WhatId = acc.Id,
                DeveloperName__c = PSTA_UtilityClass.DEVELOPERNAME_PLANEACION_FINANCIERA
            );
            insert t;
            System.debug('>>>>>>> Tarea: ' + t);
        }
    }

    @isTest
    static void test_obtenerCuentasValidas() {
        List<Account> cuentas = [SELECT Id, PersonContactId FROM Account WHERE Client_ID__c = '02030'];
        List<SObject> cuentasSObject = new List<SObject>();
        
        for (Account acc : cuentas) {
            cuentasSObject.add(acc);
        }

        Test.startTest();
        List<Account> result = PV_GenerarTareasPeriodicas.obtenerCuentasValidas(cuentasSObject);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Debe devolver una lista de cuentas');
    }
    
    @isTest
    static void test_obtenerCuentasValidas2() {
        List<Account> cuentas = [SELECT Id, PersonContactId FROM Account WHERE Client_ID__c = '02031'];
        List<SObject> cuentasSObject = new List<SObject>();
        
        for (Account acc : cuentas) {
            cuentasSObject.add(acc);
        }

        Test.startTest();
        List<Account> result = PV_GenerarTareasPeriodicas.obtenerCuentasValidas(cuentasSObject);
        Test.stopTest();

        //System.assertEquals(0, result.size());
    }

    @IsTest
    static void testSaveErrorFlow_conErrores() {
        // Datos de prueba
        List<String> errores = new List<String>{
            'Error de conexión',
            'No se encontró la cuenta'
        };
        
        Test.startTest();
        // Llamada al método con lista de errores
        PV_GenerarTareasPeriodicas.saveErrorFlow(errores);
        Test.stopTest();
        
        // Aquí podrías validar efectos secundarios si saveLogError guarda algo
        // Ejemplo si guarda en un objeto Log__c:
        // System.assertEquals(2, [SELECT COUNT() FROM Log__c WHERE Tipo__c = 'ERROR_BATCH_CADENCIAS']);
    }
    
    @IsTest
    static void testSaveErrorFlow_listaVacia() {
        Test.startTest();
        // Lista vacía: no debería llamar saveLogError
        PV_GenerarTareasPeriodicas.saveErrorFlow(new List<String>());
        Test.stopTest();
    }
    
    @IsTest
    static void testSaveErrorFlow_listaNull() {
        Test.startTest();
        // Lista nula: no debería llamar saveLogError
        PV_GenerarTareasPeriodicas.saveErrorFlow(null);
        Test.stopTest();
    }

    @isTest
    static void test_createMapsToReference() {
        List<Account> cuentas = [SELECT Id, BanqueroAsignado__c, BanqueroAsignado__r.BusinessUnitMemberId FROM Account LIMIT 1];

        Map<String, Object> result = PV_GenerarTareasPeriodicas.createMapsToReference(cuentas);
        System.assert(result.containsKey('mapAccount'));
        System.assert(result.containsKey('setBMemberId'));
    }

    @isTest
    static void test_getMapBankerAccount() {
        List<Banker> banquero = [SELECT Id FROM Banker LIMIT 1];
        Set<Id> fakeSet = new Set<Id>{banquero[0].Id};
        Map<Id, List<Id>> fakeMap = new Map<Id, List<Id>>{
            banquero[0].Id => new List<Id>{[SELECT Id FROM Account LIMIT 1].Id}
        };
        Test.startTest();
        Map<Id, Id> result = PV_GenerarTareasPeriodicas.getMapBankerAccount(fakeSet, fakeMap);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void test_validarTareaPorCuenta() {
        List<Account> cuentas = [SELECT Id, EnrolamientoBiometricos__c, EnrolamientoActivo__c FROM Account LIMIT 1];
        List<Account> result = PV_GenerarTareasPeriodicas.validarTareaPorCuenta(cuentas, PV_GenerarTareasPeriodicas.biometricos);
        System.assert(result.size() > 0);
    }
    
    @isTest
    static void test_validarTareaPorCuenta2() {
        List<Account> cuentas = [SELECT Id, EnrolamientoBiometricos__c, EnrolamientoActivo__c FROM Account LIMIT 1];
        List<Account> result = PV_GenerarTareasPeriodicas.validarTareaPorCuenta(cuentas, PV_GenerarTareasPeriodicas.bancaElectronica);
        System.assert(result.size() > 0);
    }

    @isTest
    static void test_validarTareaPorContrato() {
        List<Account> cuentas = [SELECT Id FROM Account LIMIT 1];
        List<Contract> contratos = [SELECT Id, AccountId, PlaneacionFinancieraCompletada__c, PropuestaInversionCompletada__c FROM Contract WHERE AccountId = :cuentas[0].Id LIMIT 1];
        List<Account> result = PV_GenerarTareasPeriodicas.validarTareaPorContrato(cuentas, PV_GenerarTareasPeriodicas.planeacionFinanciera, contratos);
        System.assert(result.size() > 0);
    }
    
    @isTest
    static void test_validarTareaPorContrato2() {
        List<Account> cuentas = [SELECT Id FROM Account LIMIT 1];
        List<Contract> contratos = [SELECT Id, AccountId, PlaneacionFinancieraCompletada__c, PropuestaInversionCompletada__c FROM Contract WHERE AccountId = :cuentas[0].Id LIMIT 1];
        List<Account> result = PV_GenerarTareasPeriodicas.validarTareaPorContrato(cuentas, PV_GenerarTareasPeriodicas.propuestaInversion, contratos);
        System.assert(result.size() > 0);
    }

    @isTest
    static void test_obtenerCuentasValidasParaAsignarCadencia() {
        List<Account> cuentas = [SELECT Id FROM Account LIMIT 1]; 
        Task t = [SELECT Id,DeveloperName__c,AccountId,WhoId FROM Task LIMIT 1];
        List<Account> result = PV_GenerarTareasPeriodicas.obtenerCuentasValidasParaAsignarCadencia(cuentas, PSTA_UtilityClass.DEVELOPERNAME_PLANEACION_FINANCIERA, 10);
        System.assertNotEquals(null, result);
    }

    @isTest
    static void test_generarCadenceItems() {
        List<Account> cuentas = [SELECT Id FROM Account LIMIT 1];
        Map<Id, Id> mapBanker = new Map<Id, Id>{cuentas[0].Id => UserInfo.getUserId()};
        List<PV_GenerarTareasPeriodicas_Request> result = PV_GenerarTareasPeriodicas.generarCadenceItems(Id.valueOf(UserInfo.getUserId()), cuentas, mapBanker, 'TEST_CADENCE');
        System.assert(result.size() > 0);
    }

    @isTest
    static void test_filtrarAccountsConCadencias() {
        List<Account> cuentas = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        ActionCadence cadence = (ActionCadence)JSON.deserialize('{}', ActionCadence.class);
    	cadence.DeveloperName__c = 'TEST_CADENCE';
        cadence.TareaUnicaPorCuenta__c = false;
        List<Account> result = PV_GenerarTareasPeriodicas.filtrarAccountsConCadencias(cuentas, cadence);
        System.assertNotEquals(null, result);
    }

    @isTest
    static void test_generarRequestCadence() {
        List<Account> cuentas = [SELECT Id FROM Account LIMIT 1];
        Map<Id, Id> mapBanker = new Map<Id, Id>{cuentas[0].Id => UserInfo.getUserId()};
        ActionCadence cadence = (ActionCadence)JSON.deserialize('{}', ActionCadence.class);
    	cadence.DeveloperName__c = PSTA_UtilityClass.DEVELOPERNAME_BIOMETRICOS;
        cadence.TareaUnicaPorCuenta__c = true;
        List<ActionCadence> lstCadence = new List<ActionCadence>();
        lstCadence.add(cadence);

        Test.startTest();
        PV_GenerarTareasPeriodicas.generarRequestCadence(lstCadence, cuentas, mapBanker);
        Test.stopTest();
    }

    @isTest
    static void test_getContactsId() {
        List<Account> cuentas = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Set<Id> ids = PV_GenerarTareasPeriodicas.getContactsId(cuentas);
        System.assert(ids.size() > 0);
    }

    @isTest
    static void test_filtrarCuentas() {
        List<Account> cuentas = [SELECT Id FROM Account LIMIT 1];
        Set<Id> ids = new Set<Id>();
        List<Account> result = PV_GenerarTareasPeriodicas.filtrarCuentas(cuentas, ids, false);
        System.assert(result.size() > 0);
    }

    @isTest
    static void test_saveLogError() {
        Map<String, String> errores = new Map<String, String>{ 'Error' => 'Error', 'Linea' => '1' };
        Test.startTest();
        PV_GenerarTareasPeriodicas.saveLogError(errores, 'Mensaje de prueba', 'CODIGO_ERROR', '');
        Test.stopTest();
    }

    @isTest
    static void test_obtenerCuentasValidas_conOverrides() {
        List<Account> cuentas = [SELECT Id, PersonContactId FROM Account WHERE PersonContactId != null LIMIT 1];
        System.assert(!cuentas.isEmpty(), 'Se requiere al menos una Person Account para esta prueba');

        PV_GenerarTareasPeriodicas.testAvailableCadenceContactIdsOverride = new Set<Id>{ UserInfo.getUserId() };
        PV_GenerarTareasPeriodicas.testUseValidContractFilter = true;
        PV_GenerarTareasPeriodicas.testValidContractAccountIdsOverride = new Set<Id>{ UserInfo.getUserId() };
        try {
            List<SObject> scope = new List<SObject>();
            scope.addAll(cuentas);
            List<Account> result = PV_GenerarTareasPeriodicas.obtenerCuentasValidas(scope);
            System.assertNotEquals(null, result, 'Debe devolver una lista aun cuando use overrides');
        } finally {
            PV_GenerarTareasPeriodicas.testAvailableCadenceContactIdsOverride = null;
            PV_GenerarTareasPeriodicas.testValidContractAccountIdsOverride = null;
            PV_GenerarTareasPeriodicas.testUseValidContractFilter = false;
        }
    }

    @isTest
    static void test_getAccountsWithValidContracts_guardClauses() {
        System.assertEquals(0, PV_GenerarTareasPeriodicas.getAccountsWithValidContracts(new Set<Id>()).size());
        System.assertEquals(0, PV_GenerarTareasPeriodicas.getAccountsWithAvailableCadenceSlot(new Set<Id>()).size());
    }
}
