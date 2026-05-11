@IsTest
public class PSTA_RResumenMensual_cls_tst {

    private static User createTestUser(String advisorId) {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name IN ('System Administrator', 'Administrador del sistema') LIMIT 1];
        User user = new User(
            LastName = 'User' + advisorId,
            Username = 'user_' + advisorId + '_' + System.currentTimeMillis() + '@test.com',
            Email = 'user_' + advisorId + '@test.com',
            EmailEncodingKey = 'ISO-8859-1',
            Alias = 'u' + advisorId.right(3),
            IsActive = true,
            TimeZoneSidKey = 'America/Mexico_City',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'es',
            ID_ASESOR__c = advisorId,
            ProfileId = adminProfile.Id
        );
        insert user;
        return user;
    }

    private static BranchUnit createBranchUnit(String externalId) {
        BranchUnit branchUnit = new BranchUnit(
            Name = 'TestBranchUnit ' + externalId,
            IsActive = true,
            BranchCode = '100000' + externalId.right(5),
            ExternalIdBI__c = externalId.right(2),
            ExternalId__c = '100000' + externalId.right(5)
        );
        insert branchUnit;
        return branchUnit;
    }

    private static Id createBankerMembership(User user, BranchUnit branchUnit, String advisorId, String division) {
        Banker banker = new Banker(
            Name = 'TestBanker ' + advisorId,
            JobCode = advisorId,
            CurrentBranchId = branchUnit.Id,
            UserOrContactId = user.Id,
            ExternalId__c = advisorId,
            Division__c = division
        );
        insert banker;

        return [
            SELECT Id
            FROM BranchUnitBusinessMember
            WHERE BranchUnitId = :branchUnit.Id
                AND BusinessUnitMemberId = :banker.Id
            LIMIT 1
        ].Id;
    }

    private static void createContactWithoutLicense(String advisorId) {
        Contact contactRecord = new Contact(
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('BanqueroLlicencia').getRecordTypeId(),
            FirstName = 'TestName',
            LastName = 'TestApp',
            EmpleadoSinLicenciaSFDC__c = true,
            NumeroNomina__c = advisorId
        );
        insert contactRecord;
    }

    private static void createPrioritizedAccounts(Id bankerMemberId, String advisorId, Integer countAccounts) {
        List<Account> accounts = new List<Account>();
        for (Integer index = 0; index < countAccounts; index++) {
            accounts.add(new Account(
                FirstName = 'Cliente',
                LastName = 'Resumen ' + index,
                F3_CURP__c = 'CURP' + advisorId + index,
                Client_ID__c = advisorId + index,
                ID_Asesor__c = advisorId,
                SaldoIntegral__c = 100 + index,
                BanqueroAsignado__c = bankerMemberId,
                Person_Type__c = 'Persona Fisica',
                Segmento__c = 'Privada',
                ContactoPriorizadoEsteMes__c = true,
                FechaSiguienteContacto__c = Date.today(),
                OwnerId = [SELECT Id FROM User WHERE Name = 'IntegrationUser' LIMIT 1].Id,
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
            ));
        }

        OD_Account_cls.bypassTriggerExecution = true;
        PSTA_ListadoClientes_cls.bypassTriggerExecution = true;
        PSTA_Segmentacion_cls.bypassTriggerExecution = true;
        insert accounts;
    }

    private static void createValidContractsForAdvisor(String advisorId, Integer countContracts, Id bankerMemberId) {
        List<Account> advisorAccounts = [
            SELECT Id
            FROM Account
            WHERE ID_Asesor__c = :advisorId
            ORDER BY CreatedDate ASC
            LIMIT :countContracts
        ];

        List<Contract> contracts = new List<Contract>();
        Integer index = 0;
        for (Account accountRecord : advisorAccounts) {
            contracts.add(new Contract(
                AccountId = accountRecord.Id,
                TypeOfContract__c = '01',
                Status__c = 'Nuevo',
                AccountOpeningDate__c = Date.today().addDays(-30 - index),
                Saldo__c = String.valueOf(1000 + index),
                ID_ASESOR__c = advisorId,
                BanqueroAsignado__c = bankerMemberId
            ));
            index++;
        }

        OD_Contract_cls.bypassTriggerExecution = true;
        insert contracts;
    }

    private static void createExistingDailySummary(Id bankerMemberId, String advisorId, Integer meta, Integer contactados, Date summaryDate) {
        insert new ResumenGlobalPostventa__c(
            Name = 'Resumen existente ' + advisorId,
            Fecha__c = summaryDate,
            OwnerId = [SELECT Id FROM User WHERE Name = 'IntegrationUser' LIMIT 1].Id,
            Banker__c = bankerMemberId,
            ExternalId_Nomina__c = advisorId,
            ExternalId_NominaFecha__c = PSTA_RegistroResumenGlobalMensual_cls.buildDailyExternalId(advisorId, summaryDate),
            Contactados__c = contactados,
            ContactadosMensual__c = contactados,
            Meta__c = meta,
            MetaMensual__c = meta
        );
    }

    @IsTest
    static void testBatchCreatesDailySummaryWithProjectedMonthlyMeta() {
        PSTA_TestDataFactory.createConfiguracionContactoActinver();
        PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();
        PSTA_TestDataFactory.createConfiguracionContratosActinver();

        String advisorId = '70001';
        User user = createTestUser(advisorId);
        BranchUnit branchUnit = createBranchUnit(advisorId);
        Id bankerMemberId = createBankerMembership(user, branchUnit, advisorId, 'Privada');
        createContactWithoutLicense(advisorId);
        createPrioritizedAccounts(bankerMemberId, advisorId, 3);
        createValidContractsForAdvisor(advisorId, 3, bankerMemberId);

        PSTA_RegistroResumenGlobalMensual_cls.testOverrideBusinessDaysInMonth = 20;
        PSTA_RegistroResumenGlobalMensual_cls.testOverrideTargetDate = Date.newInstance(2026, 4, 15);

        Test.startTest();
        Database.executeBatch(new PSTA_RegistroResumenGlobalMensual_bch(), 1);
        Test.stopTest();

        ResumenGlobalPostventa__c summaryRecord = [
            SELECT ExternalId_Nomina__c, Fecha__c, Meta__c, MetaMensual__c, Contactados__c, ContactadosMensual__c, OwnerId
            FROM ResumenGlobalPostventa__c
            WHERE ExternalId_Nomina__c = :advisorId
                AND Fecha__c = :Date.newInstance(2026, 4, 15)
            LIMIT 1
        ];

        System.assertEquals(1, Integer.valueOf(summaryRecord.Meta__c));
        System.assertEquals(3, Integer.valueOf(summaryRecord.MetaMensual__c));
        System.assertEquals(0, Integer.valueOf(summaryRecord.Contactados__c));
        System.assertEquals(0, Integer.valueOf(summaryRecord.ContactadosMensual__c));
        System.assertEquals(user.Id, summaryRecord.OwnerId);
    }

    @IsTest
    static void testBatchPreservesContactadosWhenDailySummaryAlreadyExists() {
        PSTA_TestDataFactory.createConfiguracionContactoActinver();
        PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();
        PSTA_TestDataFactory.createConfiguracionContratosActinver();

        String advisorId = '70002';
        User user = createTestUser(advisorId);
        BranchUnit branchUnit = createBranchUnit(advisorId);
        Id bankerMemberId = createBankerMembership(user, branchUnit, advisorId, 'Privada');
        createContactWithoutLicense(advisorId);
        createPrioritizedAccounts(bankerMemberId, advisorId, 8);
        createValidContractsForAdvisor(advisorId, 8, bankerMemberId);
        createExistingDailySummary(bankerMemberId, advisorId, 1, 7, Date.newInstance(2026, 4, 15));

        PSTA_RegistroResumenGlobalMensual_cls.testOverrideBusinessDaysInMonth = 1;
        PSTA_RegistroResumenGlobalMensual_cls.testOverrideTargetDate = Date.newInstance(2026, 4, 15);

        Test.startTest();
        Database.executeBatch(new PSTA_RegistroResumenGlobalMensual_bch(), 1);
        Test.stopTest();

        List<ResumenGlobalPostventa__c> summaries = [
            SELECT ExternalId_Nomina__c, Fecha__c, Meta__c, MetaMensual__c, Contactados__c, ContactadosMensual__c
            FROM ResumenGlobalPostventa__c
            WHERE ExternalId_Nomina__c = :advisorId
                AND Fecha__c = :Date.newInstance(2026, 4, 15)
        ];

        System.assertEquals(1, summaries.size());
        System.assertEquals(7, Integer.valueOf(summaries[0].Contactados__c));
        System.assertEquals(7, Integer.valueOf(summaries[0].ContactadosMensual__c));
        System.assertEquals(5, Integer.valueOf(summaries[0].Meta__c));
        System.assertEquals(5, Integer.valueOf(summaries[0].MetaMensual__c));
    }

    @IsTest
    static void testMonthlyGoalUsesProjectionWhenPortfolioIsGreaterThanProjectedGoal() {
        PSTA_TestDataFactory.createConfiguracionContactoActinver();
        PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();
        PSTA_TestDataFactory.createConfiguracionContratosActinver();

        String advisorId = '70003';
        User user = createTestUser(advisorId);
        BranchUnit branchUnit = createBranchUnit(advisorId);
        Id bankerMemberId = createBankerMembership(user, branchUnit, advisorId, 'Privada');
        createContactWithoutLicense(advisorId);
        createPrioritizedAccounts(bankerMemberId, advisorId, 12);
        createValidContractsForAdvisor(advisorId, 12, bankerMemberId);

        PSTA_RegistroResumenGlobalMensual_cls.testOverrideBusinessDaysInMonth = 2;
        PSTA_RegistroResumenGlobalMensual_cls.testOverrideTargetDate = Date.newInstance(2026, 4, 16);

        Test.startTest();
        Database.executeBatch(new PSTA_RegistroResumenGlobalMensual_bch(), 1);
        Test.stopTest();

        ResumenGlobalPostventa__c summaryRecord = [
            SELECT Meta__c, MetaMensual__c, ContactadosMensual__c
            FROM ResumenGlobalPostventa__c
            WHERE ExternalId_Nomina__c = :advisorId
                AND Fecha__c = :Date.newInstance(2026, 4, 16)
            LIMIT 1
        ];

        System.assertEquals(5, Integer.valueOf(summaryRecord.Meta__c));
        System.assertEquals(10, Integer.valueOf(summaryRecord.MetaMensual__c));
        System.assertEquals(0, Integer.valueOf(summaryRecord.ContactadosMensual__c));
        System.assertEquals(user.Id, [
            SELECT OwnerId
            FROM ResumenGlobalPostventa__c
            WHERE ExternalId_Nomina__c = :advisorId
                AND Fecha__c = :Date.newInstance(2026, 4, 16)
            LIMIT 1
        ].OwnerId);
    }

    @IsTest
    static void testMonthlyProgressIsCalculatedOnSummaryTrigger() {
        String advisorId = '9' + String.valueOf(System.now().getTime()).right(4);
        User user = createTestUser(advisorId);
        BranchUnit branchUnit = createBranchUnit(advisorId);
        Id bankerMemberId = createBankerMembership(user, branchUnit, advisorId, 'Privada');
        createContactWithoutLicense(advisorId);

        PSTA_RResumenMes_thr.bypassExecution = true;

        ResumenGlobalPostventa__c firstDay = new ResumenGlobalPostventa__c(
            Name = 'Resumen mes 1',
            Fecha__c = Date.newInstance(2026, 4, 1),
            ExternalId_Nomina__c = advisorId,
            ExternalId_NominaFecha__c = PSTA_RegistroResumenGlobalMensual_cls.buildDailyExternalId(advisorId, Date.newInstance(2026, 4, 1)),
            Banker__c = bankerMemberId,
            Contactados__c = 3,
            Meta__c = 1,
            MetaMensual__c = 10
        );
        ResumenGlobalPostventa__c secondDay = new ResumenGlobalPostventa__c(
            Name = 'Resumen mes 2',
            Fecha__c = Date.newInstance(2026, 4, 2),
            ExternalId_Nomina__c = advisorId,
            ExternalId_NominaFecha__c = PSTA_RegistroResumenGlobalMensual_cls.buildDailyExternalId(advisorId, Date.newInstance(2026, 4, 2)),
            Banker__c = bankerMemberId,
            Contactados__c = 2,
            Meta__c = 1,
            MetaMensual__c = 10
        );
        insert new List<ResumenGlobalPostventa__c>{ firstDay, secondDay };
        PSTA_RResumenMes_thr.bypassExecution = false;

        secondDay.Contactados__c = 4;
        Test.startTest();
        update secondDay;
        Test.stopTest();

        ResumenGlobalPostventa__c refreshedSecondDay = [
            SELECT ContactadosMensual__c, PorcentajeAvanceMensual__c
            FROM ResumenGlobalPostventa__c
            WHERE Id = :secondDay.Id
        ];

        System.assertEquals(7, Integer.valueOf(refreshedSecondDay.ContactadosMensual__c));
        System.assertEquals(0.70, refreshedSecondDay.PorcentajeAvanceMensual__c);
    }
}
