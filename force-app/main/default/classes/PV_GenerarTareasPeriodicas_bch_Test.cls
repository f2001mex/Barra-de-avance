@isTest
public class PV_GenerarTareasPeriodicas_bch_Test {

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
            OwnerId = [SELECT Id FROM User WHERE Name = 'IntegrationUser' LIMIT 1].Id,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
        );
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

    @isTest static void testBatchExecution() {
        PSTA_TestDataFactory.createConfiguracionContratosActinver();
        User user = createTestUser();
        BranchUnit branchUnit = createTestBranchUnit();
        Id bankerMemberId = createBankerMembership(user, branchUnit);
        createContactWithoutLicense();
        Account account = createTestAccount(user, bankerMemberId);
        insert new Contract(
            AccountId = account.Id,
            Source__c = 'Contrato de Banco',
            ContractNumber__c = '142535',
            Status__c = 'Nuevo',
            TypeOfContract__c = '01',
            ID_ASESOR__c = '0001',
            IDSap__c = '142535',
            OwnerId = [SELECT Id FROM User WHERE Name = 'IntegrationUser' LIMIT 1].Id
        );

        Test.startTest();
        Database.executeBatch(new PV_GenerarTareasPeriodicas_bch(), 2);
        Test.stopTest();

        System.assert(true, 'Batch ejecutado sin errores.');
    }

    @isTest static void testBatchExecutionWithContract() {
        PSTA_TestDataFactory.createConfiguracionContratosActinver();
        User user = createTestUser();
        BranchUnit branchUnit = createTestBranchUnit();
        Id bankerMemberId = createBankerMembership(user, branchUnit);
        createContactWithoutLicense();
        Account acc = createTestAccount(user, bankerMemberId);

        Contract contract = new Contract(
            AccountId = acc.Id,
            Source__c = 'Contrato de Banco',
            ContractNumber__c = '142536',
            Status__c = 'Nuevo',
            TypeOfContract__c = '01',
            FLAG_MARKETING__c = 'X',
            FLAG_MARKETING_ACTINVER__c = 'X',
            FLAG_EVENTS_INVITATIONS__c = 'X',
            ID_ASESOR__c = '0001',
            IDSap__c = '142536',
            OwnerId = [SELECT Id FROM User WHERE Name = 'IntegrationUser' LIMIT 1].Id
        );
        insert contract;

        Test.startTest();
        Database.executeBatch(new PV_GenerarTareasPeriodicas_bch(), 2);
        Test.stopTest();

        System.assert(true, 'Batch con contrato ejecutado sin errores.');
    }
}
