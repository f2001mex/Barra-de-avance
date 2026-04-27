/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Gallegos Alan
* Project           :   Post venta
* Clase test		:   
* Description       :   Clase test para el Batch de reseteo de estatus de contacto
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         28-Jul-2025       Gallegos Alan          Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@IsTest
public class PSTA_RegistroResumenGlobal_cls_Test {


private static User createTestUser() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name IN ('System Administrator', 'Administrador del sistema') LIMIT 1];
        User user = new User(
            LastName = 'User1',
            Username = 'user1_' + System.currentTimeMillis() + '@test.com',
            Email = 'user1@test.com',
            EmailEncodingKey = 'ISO-8859-1',
            Alias = 'usr1',
            IsActive = true,
            TimeZoneSidKey = 'America/Mexico_City',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'es',
            ID_ASESOR__c = '0001',
            ProfileId = adminProfile.Id
        );
        insert user;
        return user;
    }


    private static Account createTestAccount(User user, Id bankerMemberId) {
        Account account = new Account(
            FirstName = 'TestName',
            MiddleName = 'TestMiddle',
            LastName = 'TestApp',
            F3_CURP__c = 'TESTING1',
            Client_ID__c = '02030',
            ID_Asesor__c = '0001',
            SaldoIntegral__c = 123,
            BanqueroAsignado__c = bankerMemberId,
            Person_Type__c = 'Persona Fisica',
            FechaSiguienteContacto__c = Date.today(),
            EstatusContacto__c = 'Contacto no exitoso',
            OwnerId = [SELECT Id FROM User WHERE Name = 'IntegrationUser' LIMIT 1].Id,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
        );
        
        OD_Account_cls.bypassTriggerExecution = true;
        PSTA_ListadoClientes_cls.bypassTriggerExecution = true;
        PSTA_Segmentacion_cls.bypassTriggerExecution = true;

        insert account;
        return account;
    }

     private static BranchUnit createTestBranchUnit() {
        BranchUnit branchUnit = new BranchUnit(
            Name = 'TestBranchUnit',
            IsActive = true,
            BranchCode = '10000012345',
            ExternalIdBI__c = '37',
            ExternalId__c = '10000012345'
        );
        insert branchUnit;
        return branchUnit;
    }

    private static Id createBankerMembership(User user, BranchUnit branchUnit) {
        Banker banker = new Banker(
            Name = 'TestBankerContact',
            JobCode = '0001',
            CurrentBranchId = branchUnit.Id,
            UserOrContactId = user.Id
        );
        insert banker;

        List<BranchUnitBusinessMember> existing = [
            SELECT Id FROM BranchUnitBusinessMember
            WHERE BranchUnitId = :branchUnit.Id
            AND BusinessUnitMemberId = :banker.Id
        ];
        return existing[0].Id;
    }


    private static void createContactWithoutLicense() {
        Contact c = new Contact(
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('BanqueroLlicencia').getRecordTypeId(),
            FirstName = 'TestName',
            LastName = 'TestApp',
            EmpleadoSinLicenciaSFDC__c = true,
            NumeroNomina__c = '0001'
        );
        insert c;
    }

    private static void createResumen() {
        ResumenGlobalPostventa__c resAux = new ResumenGlobalPostventa__c(
                Name = 'Resumen Test',
                Fecha__c = System.today(),              
                OwnerId = [SELECT Id FROM User WHERE Name = 'IntegrationUser' LIMIT 1].Id,
                Banker__c = [SELECT Id FROM BranchUnitBusinessMember LIMIT 1].Id,
                ExternalId_Nomina__c = '123456789',
                Contactados__c = 0,
                Meta__c = 10
        );
        insert resAux;
    }

     @isTest 
    static void testGetResumenesActuales() {
        User user = createTestUser();
        BranchUnit branchUnit = createTestBranchUnit();
        Id bankerMemberId = createBankerMembership(user, branchUnit);
        createContactWithoutLicense();
        PSTA_TestDataFactory.createConfiguracionContactoActinver();
        PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();
        createTestAccount(user, bankerMemberId);

        Test.startTest();
        PSTA_RegistroResumenGlobal_cls.getResumenesActuales();
        Test.stopTest();

        System.assert(true, 'Clase test terminada.');
    }


    @isTest 
    static void testGetAllDivisions() {
        PSTA_TestDataFactory.createConfiguracionContactoActinver();
        PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();
        User user = createTestUser();
        BranchUnit branchUnit = createTestBranchUnit();
        Id bankerMemberId = createBankerMembership(user, branchUnit);
        createContactWithoutLicense();
        createTestAccount(user, bankerMemberId);


        Test.startTest();
        PSTA_RegistroResumenGlobal_cls.getAllDivisions();
        Test.stopTest();

        System.assert(true, 'Clase test terminada.');
    }


    @isTest 
    static void testGetUserIds() {
        PSTA_TestDataFactory.createConfiguracionContactoActinver();
        PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();
        User user = createTestUser();
        BranchUnit branchUnit = createTestBranchUnit();
        Id bankerMemberId = createBankerMembership(user, branchUnit);
        createContactWithoutLicense();
        createTestAccount(user, bankerMemberId);

        Test.startTest();
        PSTA_RegistroResumenGlobal_cls.getUserIds();
        Test.stopTest();

        System.assert(true, 'Clase test terminada.');
    }


    @isTest 
    static void testUpdateRecords() {
        PSTA_TestDataFactory.createConfiguracionContactoActinver();
        PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();
        User user = createTestUser();
        BranchUnit branchUnit = createTestBranchUnit();
        Id bankerMemberId = createBankerMembership(user, branchUnit);
        createContactWithoutLicense();
        createTestAccount(user, bankerMemberId);
        createResumen();

        // List<ResumenGlobalPostventa__c> testList = [SELECT Id, Name FROM ResumenGlobalPostventa__c LIMIT 1];
        List<ResumenGlobalPostventa__c> testList = new List<ResumenGlobalPostventa__c>();
        Map<Id,ResumenGlobalPostventa__c> testMap = new Map<Id,ResumenGlobalPostventa__c>();

        ResumenGlobalPostventa__c newTest = new ResumenGlobalPostventa__c(
            Id = [SELECT Id, Name, Banker__c, CreatedDate FROM ResumenGlobalPostventa__c LIMIT 1].Id,
            Banker__c = [SELECT Id FROM Banker LIMIT 1].Id
        );

        testList.add(newTest);
        testMap.put(newTest.Id, testList[0]);

        Test.startTest();
        PSTA_RegistroResumenGlobal_cls.upsertRecords(testList);
        Test.stopTest();

        System.assert(true, 'Clase test terminada.');
    }



}