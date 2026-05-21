@IsTest(SeeAllData=true)
private class PSTA_AntiChurnDashboard_ctr_tst {

    private class TestBundle {
        Id recordTypeId;
        Id branchUnitId;
        User dashboardUser;
        String advisorIdOne;
        String advisorIdTwo;
    }

    @IsTest
    static void testGetDashboardDataBuildsKpisForBranchScope() {
        TestBundle bundle = createDashboardDataBundle();
        setScope('BRANCH', null, null, bundle.branchUnitId);

        Test.startTest();
        PSTA_AntiChurnDashboard_ctr.DashboardResponse response =
            PSTA_AntiChurnDashboard_ctr.getDashboardData();
        Test.stopTest();

        System.assertNotEquals(null, response);
        System.assertEquals(System.today(), response.generatedDate);
        System.assertEquals(countDistinctAccountsByBranch(bundle.recordTypeId, bundle.branchUnitId), response.totalPilotClients);
        System.assertEquals(countActivitiesByBranch(bundle.recordTypeId, bundle.branchUnitId), response.totalActivities);
        System.assertEquals(countDistinctHighRiskAccountsByBranch(bundle.recordTypeId, bundle.branchUnitId), response.highRiskClientsWithActivity);
        System.assertEquals(1, response.positiveActivities);
        System.assertEquals(0, response.negativeActivities);
        System.assertEquals(1, response.noContactActivities);
        System.assertEquals(1, response.pendingActivities);
        System.assertNotEquals(null, response.highRiskReportId);
        System.assertNotEquals(null, response.activitiesReportId);
        System.assert(response.pilotPopulationDefinition.contains('Anti-Churn abierta o completada'));

        PSTA_AntiChurnDashboard_ctr.clearTestScope();
    }

    @IsTest
    static void testGetDashboardDataBuildsKpisForAdvisorScope() {
        TestBundle bundle = createDashboardDataBundle();
        setScope('ADVISOR', bundle.advisorIdOne, null, null);

        Test.startTest();
        PSTA_AntiChurnDashboard_ctr.DashboardResponse response =
            PSTA_AntiChurnDashboard_ctr.getDashboardData();
        Test.stopTest();

        System.assertEquals(countDistinctAccountsByAdvisor(bundle.recordTypeId, bundle.advisorIdOne), response.totalPilotClients);
        System.assertEquals(countActivitiesByAdvisor(bundle.recordTypeId, bundle.advisorIdOne), response.totalActivities);
        System.assertEquals(countDistinctHighRiskAccountsByAdvisor(bundle.recordTypeId, bundle.advisorIdOne), response.highRiskClientsWithActivity);
        System.assertEquals(1, response.positiveActivities);
        System.assertEquals(0, response.negativeActivities);
        System.assertEquals(0, response.noContactActivities);
        System.assertEquals(1, response.pendingActivities);
        System.assertEquals(1, response.motivoFuga.size());

        PSTA_AntiChurnDashboard_ctr.clearTestScope();
    }

    @IsTest
    static void testGetDashboardDataBuildsKpisForTeamScope() {
        TestBundle bundle = createDashboardDataBundle();
        setScope('TEAM', null, new Set<String>{ bundle.advisorIdOne, bundle.advisorIdTwo }, null);

        Test.startTest();
        PSTA_AntiChurnDashboard_ctr.DashboardResponse response =
            PSTA_AntiChurnDashboard_ctr.getDashboardData();
        Test.stopTest();

        System.assertEquals(countDistinctAccountsByAdvisorSet(bundle.recordTypeId, new Set<String>{ bundle.advisorIdOne, bundle.advisorIdTwo }), response.totalPilotClients);
        System.assertEquals(countActivitiesByAdvisorSet(bundle.recordTypeId, new Set<String>{ bundle.advisorIdOne, bundle.advisorIdTwo }), response.totalActivities);
        System.assertEquals(countDistinctHighRiskAccountsByAdvisorSet(bundle.recordTypeId, new Set<String>{ bundle.advisorIdOne, bundle.advisorIdTwo }), response.highRiskClientsWithActivity);
        System.assertEquals(1, response.positiveActivities);
        System.assertEquals(0, response.negativeActivities);
        System.assertEquals(1, response.noContactActivities);
        System.assertEquals(1, response.pendingActivities);
        System.assertEquals(1, response.motivoFuga.size());

        PSTA_AntiChurnDashboard_ctr.clearTestScope();
    }

    @IsTest
    static void testGetDashboardDataForAllScope() {
        createDashboardDataBundle();
        setScope('ALL', null, null, null);

        Test.startTest();
        PSTA_AntiChurnDashboard_ctr.DashboardResponse response =
            PSTA_AntiChurnDashboard_ctr.getDashboardData();
        Test.stopTest();

        System.assertEquals(true, response.hasDashboardAccess);
        System.assertNotEquals(null, response.generatedDate);
        System.assertNotEquals(null, response.motivoFuga);
        System.assertNotEquals(null, response.highRiskReportId);
        System.assertNotEquals(null, response.activitiesReportId);

        PSTA_AntiChurnDashboard_ctr.clearTestScope();
    }

    @IsTest
    static void testGetDashboardDataForNoneScope() {
        createDashboardDataBundle();
        setScope('NONE', null, null, null);

        Test.startTest();
        PSTA_AntiChurnDashboard_ctr.DashboardResponse response =
            PSTA_AntiChurnDashboard_ctr.getDashboardData();
        Test.stopTest();

        System.assertEquals(0, response.totalPilotClients);
        System.assertEquals(0, response.totalActivities);
        System.assertEquals(0, response.highRiskClientsWithActivity);
        System.assertEquals(0, response.positiveActivities);
        System.assertEquals(0, response.negativeActivities);
        System.assertEquals(0, response.noContactActivities);
        System.assertEquals(0, response.pendingActivities);
        System.assertEquals(0, response.avgContactDays);
        System.assertEquals(0, response.motivoFuga.size());

        PSTA_AntiChurnDashboard_ctr.clearTestScope();
    }

    @IsTest
    static void testGetDashboardDataUsesRuntimeBranchScope() {
        TestBundle bundle = createDashboardDataBundle();
        PSTA_AntiChurnDashboard_ctr.clearTestScope();

        System.runAs(bundle.dashboardUser) {
            Test.startTest();
            PSTA_AntiChurnDashboard_ctr.DashboardResponse response =
                PSTA_AntiChurnDashboard_ctr.getDashboardData();
            Test.stopTest();

            System.assertEquals(countDistinctAccountsByBranch(bundle.recordTypeId, bundle.branchUnitId), response.totalPilotClients);
            System.assertEquals(countActivitiesByBranch(bundle.recordTypeId, bundle.branchUnitId), response.totalActivities);
            System.assertEquals(countDistinctHighRiskAccountsByBranch(bundle.recordTypeId, bundle.branchUnitId), response.highRiskClientsWithActivity);
        }
    }

    @IsTest
    static void testScopeHelperMethods() {
        String uniqueKey = String.valueOf(DateTime.now().getTime()).right(8);
        BranchUnit branchUnit = createBranchUnit(uniqueKey);

        Test.startTest();
        Boolean advisorByProfile = PSTA_AntiChurnDashboard_ctr.isAdvisorUser('Asesor Patrimonial', null);
        Boolean advisorByRole = PSTA_AntiChurnDashboard_ctr.isAdvisorUser(null, 'Consultor Privada');
        Boolean branchByProfile = PSTA_AntiChurnDashboard_ctr.isBranchScopedUser('Director', null);
        Boolean branchByRole = PSTA_AntiChurnDashboard_ctr.isBranchScopedUser(null, 'Subdirector Regional');
        Set<String> emptyAdvisorIds = PSTA_AntiChurnDashboard_ctr.getAdvisorIdsFromRoleTree(null);
        Id byBranchCode = PSTA_AntiChurnDashboard_ctr.resolveBranchUnitIdFromUserFields(branchUnit.BranchCode, null);
        Id byCenterName = PSTA_AntiChurnDashboard_ctr.resolveBranchUnitIdFromUserFields(null, branchUnit.Name);
        Id noBranch = PSTA_AntiChurnDashboard_ctr.resolveBranchUnitIdFromUserFields(null, null);
        Integer zeroInteger = PSTA_AntiChurnDashboard_ctr.toInteger(null);
        Decimal zeroDecimal = PSTA_AntiChurnDashboard_ctr.toDecimal(null);
        Decimal zeroPercentage = PSTA_AntiChurnDashboard_ctr.calculatePercentage(10, 0);
        Decimal validPercentage = PSTA_AntiChurnDashboard_ctr.calculatePercentage(1, 4);
        Test.stopTest();

        System.assertEquals(true, advisorByProfile);
        System.assertEquals(true, advisorByRole);
        System.assertEquals(true, branchByProfile);
        System.assertEquals(true, branchByRole);
        System.assertEquals(true, emptyAdvisorIds.isEmpty());
        System.assertNotEquals(null, byBranchCode);
        System.assertNotEquals(null, byCenterName);
        System.assertEquals(null, noBranch);
        System.assertEquals(0, zeroInteger);
        System.assertEquals(0, zeroDecimal);
        System.assertEquals(0, zeroPercentage);
        System.assertEquals(25.00, validPercentage);
    }

    private static void setScope(String scopeType, String advisorId, Set<String> advisorIds, Id branchUnitId) {
        PSTA_AntiChurnDashboard_ctr.testScopeType = scopeType;
        PSTA_AntiChurnDashboard_ctr.testAdvisorId = advisorId;
        PSTA_AntiChurnDashboard_ctr.testAdvisorIds = advisorIds;
        PSTA_AntiChurnDashboard_ctr.testBranchUnitId = branchUnitId;
    }

    private static TestBundle createDashboardDataBundle() {
        TestBundle bundle = new TestBundle();
        bundle.recordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Task'
                AND DeveloperName = 'Anti_Churn'
            LIMIT 1
        ].Id;

        bundle.advisorIdOne = 'AC' + String.valueOf(DateTime.now().getTime()).right(6);
        bundle.advisorIdTwo = 'BD' + String.valueOf(DateTime.now().getTime() + 1).right(6);

        User dashboardUser = createDashboardUser(bundle.advisorIdOne);
        bundle.dashboardUser = dashboardUser;
        String uniqueKey = String.valueOf(DateTime.now().getTime()).right(8);
        BranchUnit branchUnit = createBranchUnit(uniqueKey);
        bundle.branchUnitId = branchUnit.Id;
        Banker banker = createBanker(branchUnit.Id, dashboardUser.Id, bundle.advisorIdOne, uniqueKey);
        Id bankerMemberId = [
            SELECT Id
            FROM BranchUnitBusinessMember
            WHERE BranchUnitId = :branchUnit.Id
                AND BusinessUnitMemberId = :banker.Id
            LIMIT 1
        ].Id;

        List<Account> accounts = new List<Account>{
            createAccount('Anti Churn High Risk One', bankerMemberId, bundle.advisorIdOne, 'Alto'),
            createAccount('Anti Churn Medium Risk One', bankerMemberId, bundle.advisorIdOne, 'Medio'),
            createAccount('Anti Churn High Risk Two', bankerMemberId, bundle.advisorIdTwo, 'Alto')
        };

        OD_Account_cls.bypassTriggerExecution = true;
        insert accounts;

        List<Task> tasks = new List<Task>();

        Task retainedTask = new Task(
            Subject = 'Retenido',
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = System.today(),
            RecordTypeId = bundle.recordTypeId,
            WhatId = accounts[0].Id
        );
        retainedTask.put('Resultado_de_Gestion__c', 'Contactado Retenido');
        retainedTask.put('Motivo_de_fuga__c', 'Otro');
        retainedTask.put('Fecha_de_contactacion__c', System.today());
        tasks.add(retainedTask);

        Task pendingTask = new Task(
            Subject = 'Pendiente',
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = System.today(),
            RecordTypeId = bundle.recordTypeId,
            WhatId = accounts[1].Id
        );
        pendingTask.put('Resultado_de_Gestion__c', 'Pendiente');
        tasks.add(pendingTask);

        Task noContactTask = new Task(
            Subject = 'No responde',
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = System.today(),
            RecordTypeId = bundle.recordTypeId,
            WhatId = accounts[2].Id
        );
        noContactTask.put('Resultado_de_Gestion__c', 'Cliente no responde');
        tasks.add(noContactTask);

        insert tasks;
        return bundle;
    }

    private static User createDashboardUser(String advisorId) {
        Id adminProfileId = [
            SELECT Id
            FROM Profile
            WHERE Name IN ('System Administrator', 'Administrador del sistema')
            LIMIT 1
        ].Id;

        String uniqueValue = String.valueOf(DateTime.now().getTime());
        User userRecord = new User(
            LastName = 'AntiChurn',
            Username = 'anti.churn.' + uniqueValue + '@test.com',
            Email = 'anti.churn.' + uniqueValue + '@test.com',
            EmailEncodingKey = 'ISO-8859-1',
            Alias = 'achrn',
            IsActive = true,
            TimeZoneSidKey = 'America/Mexico_City',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'es',
            ID_ASESOR__c = advisorId,
            ProfileId = adminProfileId
        );
        insert userRecord;
        return userRecord;
    }

    private static BranchUnit createBranchUnit(String uniqueKey) {
        BranchUnit branchUnit = new BranchUnit(
            Name = 'Test ' + uniqueKey,
            IsActive = true,
            BranchCode = '1' + uniqueKey,
            ExternalIdBI__c = 'BI' + uniqueKey,
            ExternalId__c = 'BR' + uniqueKey
        );
        insert branchUnit;
        return branchUnit;
    }

    private static Banker createBanker(Id branchUnitId, Id userId, String advisorId, String uniqueKey) {
        Banker banker = new Banker(
            Name = 'Banker ' + uniqueKey,
            JobCode = advisorId,
            ExternalId__c = advisorId,
            Division__c = 'Privada',
            CurrentBranchId = branchUnitId,
            UserOrContactId = userId
        );
        insert banker;
        return banker;
    }

    private static Account createAccount(
        String accountName,
        Id bankerMemberId,
        String advisorId,
        String riskLevel
    ) {
        Account accountRecord = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount')
                .getRecordTypeId(),
            FirstName = 'Anti',
            LastName = accountName,
            InstitucionFinancieraPrincipal__c = 'Banorte',
            PorqueIndentInteres__c = 'Prueba',
            Conquetipodeseguroscuentas__c = 'Seguro de Auto',
            CuandoVence__c = System.today(),
            Conqueempresaestasasegurado__c = 'Mapfre',
            MesPreferenteInversion_o_ahorrar__c = 'Febrero',
            Cuantos_hijos_tienes__c = '1',
            Viajas_recurrentemente__c = 'No',
            FamiliarqueseaclienteenActinver__c = 'No',
            Frecuencia_para_ser_contactado__c = 'El cliente prefiere contactarse con nosotros',
            MedioPreferidoContacto__c = 'Mail',
            BanqueroAsignado__c = bankerMemberId,
            Person_Type__c = 'FISICA',
            ID_Asesor__c = advisorId
        );
        accountRecord.put('Indicador_de_Riesgo_Churn__c', riskLevel);
        return accountRecord;
    }

    private static Integer countDistinctAccountsByBranch(Id recordTypeId, Id branchUnitId) {
        return Integer.valueOf(String.valueOf([
            SELECT COUNT_DISTINCT(AccountId) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND AccountId != null
                AND Account.BanqueroAsignado__r.BranchUnitId = :branchUnitId
        ][0].get('total')));
    }

    private static Integer countActivitiesByBranch(Id recordTypeId, Id branchUnitId) {
        return Integer.valueOf(String.valueOf([
            SELECT COUNT(Id) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND AccountId != null
                AND Account.BanqueroAsignado__r.BranchUnitId = :branchUnitId
        ][0].get('total')));
    }

    private static Integer countDistinctHighRiskAccountsByBranch(Id recordTypeId, Id branchUnitId) {
        return Integer.valueOf(String.valueOf([
            SELECT COUNT_DISTINCT(AccountId) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND AccountId != null
                AND Account.BanqueroAsignado__r.BranchUnitId = :branchUnitId
                AND Account.Indicador_de_Riesgo_Churn__c = 'Alto'
        ][0].get('total')));
    }

    private static Integer countDistinctAccountsByAdvisor(Id recordTypeId, String advisorId) {
        return Integer.valueOf(String.valueOf([
            SELECT COUNT_DISTINCT(AccountId) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND AccountId != null
                AND Account.ID_Asesor__c = :advisorId
        ][0].get('total')));
    }

    private static Integer countActivitiesByAdvisor(Id recordTypeId, String advisorId) {
        return Integer.valueOf(String.valueOf([
            SELECT COUNT(Id) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND AccountId != null
                AND Account.ID_Asesor__c = :advisorId
        ][0].get('total')));
    }

    private static Integer countDistinctHighRiskAccountsByAdvisor(Id recordTypeId, String advisorId) {
        return Integer.valueOf(String.valueOf([
            SELECT COUNT_DISTINCT(AccountId) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND AccountId != null
                AND Account.ID_Asesor__c = :advisorId
                AND Account.Indicador_de_Riesgo_Churn__c = 'Alto'
        ][0].get('total')));
    }

    private static Integer countDistinctAccountsByAdvisorSet(Id recordTypeId, Set<String> advisorIds) {
        return Integer.valueOf(String.valueOf([
            SELECT COUNT_DISTINCT(AccountId) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND AccountId != null
                AND Account.ID_Asesor__c IN :advisorIds
        ][0].get('total')));
    }

    private static Integer countActivitiesByAdvisorSet(Id recordTypeId, Set<String> advisorIds) {
        return Integer.valueOf(String.valueOf([
            SELECT COUNT(Id) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND AccountId != null
                AND Account.ID_Asesor__c IN :advisorIds
        ][0].get('total')));
    }

    private static Integer countDistinctHighRiskAccountsByAdvisorSet(Id recordTypeId, Set<String> advisorIds) {
        return Integer.valueOf(String.valueOf([
            SELECT COUNT_DISTINCT(AccountId) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND AccountId != null
                AND Account.ID_Asesor__c IN :advisorIds
                AND Account.Indicador_de_Riesgo_Churn__c = 'Alto'
        ][0].get('total')));
    }
}
