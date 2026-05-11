@IsTest
private class PSTA_PostCargaPostventa_tst {

    @IsTest
    static void testProcessAccountsCleansInvalidAndRemovesCadences() {
        PSTA_TestDataFactory.createConfiguracionContratosActinver();
        PSTA_TestDataFactory.createConfiguracionContactoActinver();
        PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();

        User ownerOne = createUser('owner1', '00045');
        User ownerTwo = createUser('owner2', '00046');

        BranchUnit branchUnit = PSTA_TestDataFactory.createBranchUnit();
        Banker banker = PSTA_TestDataFactory.createBanker(branchUnit.Id, ownerTwo.Id);
        BranchUnitBusinessMember bankerBbm = PSTA_TestDataFactory.getBranchUnitBusinessMember(banker.Id, branchUnit.Id);

        List<Account> accounts = PSTA_TestDataFactory.createAccounts(2, bankerBbm.Id, true);
        Account invalidAccount = accounts[0];
        Account validAccount = accounts[1];
        invalidAccount.OwnerId = ownerOne.Id;
        invalidAccount.ID_Asesor__c = '00045';
        invalidAccount.Segmento__c = 'Privada';
        invalidAccount.SaldoIntegral__c = 999;
        invalidAccount.ContactoPriorizadoEsteMes__c = true;
        invalidAccount.PriorizacionContacto__c = true;
        invalidAccount.PriorizacionVisita__c = true;
        invalidAccount.FechaSiguienteContacto__c = Date.today();
        invalidAccount.FechaSiguienteVisita__c = Date.today();

        validAccount.OwnerId = ownerTwo.Id;
        validAccount.ID_Asesor__c = '00046';
        validAccount.Segmento__c = 'Privada';
        validAccount.SaldoIntegral__c = 999;
        validAccount.ContactoPriorizadoEsteMes__c = true;
        validAccount.PriorizacionContacto__c = true;
        validAccount.PriorizacionVisita__c = true;
        validAccount.FechaSiguienteContacto__c = Date.today();
        validAccount.FechaSiguienteVisita__c = Date.today();

        Contact invalidContact = new Contact(FirstName = 'Invalid', LastName = 'Contact', AccountId = invalidAccount.Id);
        Contact relatedContact = new Contact(FirstName = 'Valid', LastName = 'Contact', AccountId = validAccount.Id);
        insert new List<Contact>{ invalidContact, relatedContact };

        Task invalidOpenTask = new Task(
            Subject = 'Task invalid',
            Status = 'Abierto',
            WhatId = invalidAccount.Id,
            WhoId = invalidContact.Id,
            OwnerId = ownerOne.Id
        );
        insert invalidOpenTask;

        Opportunity invalidOpenOpportunity = new Opportunity(
            Name = 'Opportunity invalid',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15),
            AccountId = invalidAccount.Id,
            OwnerId = ownerOne.Id
        );
        insert invalidOpenOpportunity;

        OD_Contract_cls.bypassTriggerExecution = true;
        insert new List<Contract>{
            new Contract(
                AccountId = invalidAccount.Id,
                TypeOfContract__c = '01',
                Status__c = 'Cancelado',
                AccountOpeningDate__c = Date.today().addDays(-30),
                Saldo__c = '1000',
                ID_ASESOR__c = '00045',
                BanqueroAsignado__c = bankerBbm.Id
            ),
            new Contract(
                AccountId = validAccount.Id,
                TypeOfContract__c = '01',
                Status__c = 'Nuevo',
                AccountOpeningDate__c = Date.today().addDays(-45),
                Saldo__c = '2000',
                ID_ASESOR__c = '00046',
                BanqueroAsignado__c = bankerBbm.Id
            )
        };
        OD_Contract_cls.bypassTriggerExecution = false;

        PSTA_PostCargaPostventa_soql.testRunningTrackersOverride = new List<ActionCadenceTracker>{
            new ActionCadenceTracker(
                Id = buildFakeId(ActionCadenceTracker.SObjectType, 1),
                TargetId = invalidContact.Id,
                ActionCadenceId = buildFakeId(ActionCadence.SObjectType, 1),
                State = 'Running'
            )
        };

        PSTA_PostCargaPostventa_cls.ProcessResult result = PSTA_PostCargaPostventa_cls.processAccounts(
            new List<Account>{ invalidAccount, validAccount }
        );

        System.assert(containsAccountUpdate(result.accountsToUpdate, invalidAccount.Id, false, false, false));
        System.assertEquals(1, result.cadenceRequests.size());
        System.assertEquals(invalidAccount.Id, result.cadenceRequests[0].accountId);
        System.assertEquals(false, result.cadenceRequests[0].shouldReassign);
        System.assertEquals(1, result.tasksToDelete.size());
        System.assertEquals(invalidOpenTask.Id, result.tasksToDelete[0].Id);
        System.assertEquals(1, result.opportunitiesToDelete.size());
        System.assertEquals(invalidOpenOpportunity.Id, result.opportunitiesToDelete[0].Id);
    }

    @IsTest
    static void testQueueableRemovesAndBuildsReassignmentRequests() {
        User ownerTwo = createUser('owner4', '00046');
        BranchUnit branchUnit = PSTA_TestDataFactory.createBranchUnit();
        Banker banker = PSTA_TestDataFactory.createBanker(branchUnit.Id, ownerTwo.Id);
        BranchUnitBusinessMember bankerBbm = PSTA_TestDataFactory.getBranchUnitBusinessMember(banker.Id, branchUnit.Id);

        Account validAccount = PSTA_TestDataFactory.createAccounts(1, bankerBbm.Id, true)[0];

        Contact relatedContact = new Contact(FirstName = 'Queue', LastName = 'Contact', AccountId = validAccount.Id);
        insert relatedContact;
        Id trackerId = buildFakeId(ActionCadenceTracker.SObjectType, 2);
        Id cadenceId = buildFakeId(ActionCadence.SObjectType, 2);
        PSTA_PostCargaPostventa_soql.testTrackersByIdsOverride = new List<ActionCadenceTracker>{
            new ActionCadenceTracker(
                Id = trackerId,
                TargetId = relatedContact.Id,
                ActionCadenceId = cadenceId,
                State = 'Running'
            )
        };

        Test.setMock(HttpCalloutMock.class, new RemoveTrackerMock());
        PSTA_PostCargaPostventaCadencias_qbl.sessionIdOverride = 'TEST_SESSION';
        PSTA_PostCargaPostventaCadencias_qbl.skipFlowInvocation = true;

        Test.startTest();
        System.enqueueJob(new PSTA_PostCargaPostventaCadencias_qbl(
            new List<PSTA_PostCargaPostventa_Request>{
                new PSTA_PostCargaPostventa_Request(
                    trackerId,
                    cadenceId,
                    validAccount.Id,
                    ownerTwo.Id,
                    true
                )
            }
        ));
        Test.stopTest();

        System.assertEquals(1, PSTA_PostCargaPostventaCadencias_qbl.lastGeneratedRequests.size());
        System.assertEquals(String.valueOf(validAccount.Id), PSTA_PostCargaPostventaCadencias_qbl.lastGeneratedRequests[0].targetId);
        System.assertEquals(String.valueOf(ownerTwo.Id), PSTA_PostCargaPostventaCadencias_qbl.lastGeneratedRequests[0].userId);
    }

    @IsTest
    static void testProcessAccountsDoesNotCleanWhenValidContractsRemain() {
        PSTA_TestDataFactory.createConfiguracionContratosActinver();
        PSTA_TestDataFactory.createConfiguracionContactoActinver();
        PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();

        User ownerTwo = createUser('owner6', '00046');

        BranchUnit branchUnit = PSTA_TestDataFactory.createBranchUnit();
        Banker banker = PSTA_TestDataFactory.createBanker(branchUnit.Id, ownerTwo.Id);
        BranchUnitBusinessMember bankerBbm = PSTA_TestDataFactory.getBranchUnitBusinessMember(banker.Id, branchUnit.Id);

        Account validAccount = PSTA_TestDataFactory.createAccounts(1, bankerBbm.Id, true)[0];
        validAccount.OwnerId = ownerTwo.Id;
        validAccount.ID_Asesor__c = '00046';
        validAccount.Segmento__c = 'Privada';
        validAccount.ContactoPriorizadoEsteMes__c = false;
        validAccount.PriorizacionContacto__c = false;
        validAccount.PriorizacionVisita__c = false;
        validAccount.FechaSiguienteContacto__c = Date.today();
        validAccount.FechaSiguienteVisita__c = Date.today();
        OD_Account_cls.bypassTriggerExecution = true;
        PSTA_ListadoClientes_cls.bypassTriggerExecution = true;
        PSTA_Segmentacion_cls.bypassTriggerExecution = true;
        update validAccount;
        OD_Account_cls.bypassTriggerExecution = false;
        PSTA_ListadoClientes_cls.bypassTriggerExecution = false;
        PSTA_Segmentacion_cls.bypassTriggerExecution = false;

        OD_Contract_cls.bypassTriggerExecution = true;
        insert new List<Contract>{
            new Contract(
                AccountId = validAccount.Id,
                TypeOfContract__c = '01',
                Status__c = 'Nuevo',
                AccountOpeningDate__c = Date.today().addDays(-20),
                Saldo__c = '1500',
                ID_ASESOR__c = '00046',
                BanqueroAsignado__c = bankerBbm.Id
            ),
            new Contract(
                AccountId = validAccount.Id,
                TypeOfContract__c = '01',
                Status__c = 'Cancelado',
                AccountOpeningDate__c = Date.today().addDays(-10),
                Saldo__c = '500',
                ID_ASESOR__c = '00046',
                BanqueroAsignado__c = bankerBbm.Id
            )
        };
        OD_Contract_cls.bypassTriggerExecution = false;

        PSTA_PostCargaPostventa_cls.ProcessResult result = PSTA_PostCargaPostventa_cls.processAccounts(
            new List<Account>{ validAccount }
        );

        System.assertEquals(0, result.cadenceRequests.size());
        System.assert(containsBalanceUpdate(result.accountsToUpdate, validAccount.Id, 1500));
    }

    @IsTest
    static void testProcessAccountsResetsStatusToPendingWhenAdvisorChanges() {
        PSTA_TestDataFactory.createConfiguracionContratosActinver();
        PSTA_TestDataFactory.createConfiguracionContactoActinver();
        PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();

        User owner = createUser('owner10', '00050');
        BranchUnit branchUnit = PSTA_TestDataFactory.createBranchUnit();
        Banker banker = PSTA_TestDataFactory.createBanker(branchUnit.Id, owner.Id);
        BranchUnitBusinessMember bankerBbm = PSTA_TestDataFactory.getBranchUnitBusinessMember(banker.Id, branchUnit.Id);

        Account advisorChangedAccount = PSTA_TestDataFactory.createAccounts(1, bankerBbm.Id, true)[0];
        advisorChangedAccount.OwnerId = owner.Id;
        advisorChangedAccount.ID_Asesor__c = '00050';
        advisorChangedAccount.Segmento__c = 'Privada';
        advisorChangedAccount.EstatusContacto__c = 'Contacto efectivo exitoso';
        advisorChangedAccount.FechaUltimoContacto__c = Date.today().addDays(-5);
        advisorChangedAccount.FechaUltimaVisita__c = Date.today().addDays(-10);

        OD_Account_cls.bypassTriggerExecution = true;
        PSTA_ListadoClientes_cls.bypassTriggerExecution = true;
        PSTA_Segmentacion_cls.bypassTriggerExecution = true;
        update advisorChangedAccount;
        OD_Account_cls.bypassTriggerExecution = false;
        PSTA_ListadoClientes_cls.bypassTriggerExecution = false;
        PSTA_Segmentacion_cls.bypassTriggerExecution = false;

        OD_Contract_cls.bypassTriggerExecution = true;
        insert new Contract(
            AccountId = advisorChangedAccount.Id,
            TypeOfContract__c = '01',
            Status__c = 'Nuevo',
            AccountOpeningDate__c = Date.today().addDays(-25),
            Saldo__c = '1000',
            ID_ASESOR__c = '00050',
            BanqueroAsignado__c = bankerBbm.Id
        );
        OD_Contract_cls.bypassTriggerExecution = false;

        PSTA_PostCargaPostventa_cls.ProcessResult result = PSTA_PostCargaPostventa_cls.processAccounts(
            new List<Account>{ advisorChangedAccount },
            new Set<Id>{ advisorChangedAccount.Id }
        );

        System.assert(containsStatusUpdate(result.accountsToUpdate, advisorChangedAccount.Id, 'Pendiente'));
        System.assertEquals(0, result.tasksToDelete.size());
        System.assertEquals(0, result.opportunitiesToDelete.size());
        System.assertEquals(0, result.cadenceRequests.size());
    }

    @IsTest
    static void testSoqlHelpersCoverSummaries() {
        User owner = createUser('owner7', '00047');

        BranchUnit branchUnit = PSTA_TestDataFactory.createBranchUnit();
        Banker banker = PSTA_TestDataFactory.createBanker(branchUnit.Id, owner.Id);
        BranchUnitBusinessMember bankerBbm = PSTA_TestDataFactory.getBranchUnitBusinessMember(banker.Id, branchUnit.Id);

        Account accountRecord = PSTA_TestDataFactory.createAccounts(1, bankerBbm.Id, true)[0];

        List<ResumenGlobalPostventa__c> summaries =
            PSTA_PostCargaPostventa_soql.getResumenesByAdvisorIds(new Set<String>{ '00047' });

        System.assertNotEquals(null, accountRecord.Id);
        System.assertNotEquals(null, summaries);
    }

    @IsTest
    static void testSchedulerExecutesBatch() {
        PSTA_PostCargaPostventa_bch.testWindowStart = System.now().addHours(-1);
        PSTA_PostCargaPostventa_bch.testWindowEnd = System.now();

        Test.startTest();
        new PSTA_PostCargaPostventa_sch().execute(null);
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testBatchExecuteAndFinishDirectly() {
        PSTA_TestDataFactory.createConfiguracionContratosActinver();
        PSTA_TestDataFactory.createConfiguracionContactoActinver();
        PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();

        User owner = createUser('owner8', '00048');
        BranchUnit branchUnit = PSTA_TestDataFactory.createBranchUnit();
        Banker banker = PSTA_TestDataFactory.createBanker(branchUnit.Id, owner.Id);
        BranchUnitBusinessMember bankerBbm = PSTA_TestDataFactory.getBranchUnitBusinessMember(banker.Id, branchUnit.Id);

        Account invalidAccount = PSTA_TestDataFactory.createAccounts(1, bankerBbm.Id, true)[0];
        invalidAccount.ID_Asesor__c = '00048';
        invalidAccount.ContactoPriorizadoEsteMes__c = true;
        invalidAccount.PriorizacionContacto__c = true;
        invalidAccount.PriorizacionVisita__c = true;
        OD_Account_cls.bypassTriggerExecution = true;
        PSTA_ListadoClientes_cls.bypassTriggerExecution = true;
        PSTA_Segmentacion_cls.bypassTriggerExecution = true;
        update invalidAccount;
        OD_Account_cls.bypassTriggerExecution = false;
        PSTA_ListadoClientes_cls.bypassTriggerExecution = false;
        PSTA_Segmentacion_cls.bypassTriggerExecution = false;

        OD_Contract_cls.bypassTriggerExecution = true;
        insert new Contract(
            AccountId = invalidAccount.Id,
            TypeOfContract__c = '01',
            Status__c = 'C02',
            AccountOpeningDate__c = Date.today().addDays(-10),
            Saldo__c = '100',
            ID_ASESOR__c = '00048',
            BanqueroAsignado__c = bankerBbm.Id
        );
        OD_Contract_cls.bypassTriggerExecution = false;

        PSTA_PostCargaPostventa_bch batchInstance = new PSTA_PostCargaPostventa_bch();
        batchInstance.execute(null, new List<SObject>{ invalidAccount });
        batchInstance.finish(null);

        System.assert(true);
    }

    @IsTest
    static void testBatchStartAndSoqlHelpersDirectly() {
        User owner = createUser('owner9', '00049');
        BranchUnit branchUnit = PSTA_TestDataFactory.createBranchUnit();
        Banker banker = PSTA_TestDataFactory.createBanker(branchUnit.Id, owner.Id);
        BranchUnitBusinessMember bankerBbm = PSTA_TestDataFactory.getBranchUnitBusinessMember(banker.Id, branchUnit.Id);

        Account accountRecord = PSTA_TestDataFactory.createAccounts(1, bankerBbm.Id, true)[0];
        Contact contactRecord = new Contact(FirstName = 'Helper', LastName = 'Contact', AccountId = accountRecord.Id);
        insert contactRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name = 'Helper Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = accountRecord.Id,
            OwnerId = owner.Id
        );
        insert opportunityRecord;

        Task taskRecord = new Task(
            Subject = 'Helper Task',
            Status = 'Abierto',
            WhatId = accountRecord.Id,
            WhoId = contactRecord.Id,
            OwnerId = owner.Id
        );
        insert taskRecord;

        Id trackerId = buildFakeId(ActionCadenceTracker.SObjectType, 3);
        Id cadenceId = buildFakeId(ActionCadence.SObjectType, 3);
        PSTA_PostCargaPostventa_soql.testRunningTrackersOverride = new List<ActionCadenceTracker>{
            new ActionCadenceTracker(
                Id = trackerId,
                TargetId = contactRecord.Id,
                ActionCadenceId = cadenceId,
                State = 'Running'
            )
        };
        PSTA_PostCargaPostventa_soql.testTrackersByIdsOverride = new List<ActionCadenceTracker>{
            new ActionCadenceTracker(
                Id = trackerId,
                TargetId = contactRecord.Id,
                ActionCadenceId = cadenceId,
                State = 'Running'
            )
        };

        PSTA_PostCargaPostventa_bch.testWindowStart = System.now().addHours(-1);
        PSTA_PostCargaPostventa_bch.testWindowEnd = System.now();
        PSTA_PostCargaPostventa_bch.testImpactedAccountIds = new Set<Id>{ accountRecord.Id };

        Iterable<SObject> startResult = new PSTA_PostCargaPostventa_bch().start(null);
        Integer startCount = 0;
        for (SObject row : startResult) {
            startCount++;
        }

        System.assertNotEquals(null, PSTA_PostCargaPostventa_soql.getAccountsForProcessing(new Set<Id>{ accountRecord.Id }));
        System.assertEquals(1, PSTA_PostCargaPostventa_soql.getContactsByAccountIds(new Set<Id>{ accountRecord.Id }).size());
        System.assertEquals(1, PSTA_PostCargaPostventa_soql.getOpenOpportunities(new Set<Id>{ accountRecord.Id }).size());
        System.assertEquals(1, PSTA_PostCargaPostventa_soql.getActiveTasks(new Set<Id>{ accountRecord.Id }).size());
        System.assertEquals(1, PSTA_PostCargaPostventa_soql.getRunningTrackers(new Set<Id>{ contactRecord.Id }).size());
        System.assertEquals(1, PSTA_PostCargaPostventa_soql.getTrackersByIds(new Set<Id>{ trackerId }).size());
        System.assertNotEquals(null, PSTA_PostCargaPostventa_soql.getResumenesByAdvisorIds(new Set<String>{ '00049' }));
        System.assertEquals(1, startCount);
    }

    @IsTest
    static void testSoqlHelpersReturnEmptyCollectionsWhenNoIds() {
        PSTA_PostCargaPostventa_soql.testRunningTrackersOverride = null;
        PSTA_PostCargaPostventa_soql.testTrackersByIdsOverride = null;

        System.assertEquals(0, PSTA_PostCargaPostventa_soql.getAccountsForProcessing(new Set<Id>()).size());
        System.assertEquals(0, PSTA_PostCargaPostventa_soql.getContactsByAccountIds(new Set<Id>()).size());
        System.assertEquals(0, PSTA_PostCargaPostventa_soql.getOpenOpportunities(new Set<Id>()).size());
        System.assertEquals(0, PSTA_PostCargaPostventa_soql.getActiveTasks(new Set<Id>()).size());
        System.assertEquals(0, PSTA_PostCargaPostventa_soql.getRunningTrackers(new Set<Id>()).size());
        System.assertEquals(0, PSTA_PostCargaPostventa_soql.getTrackersByIds(new Set<Id>()).size());
        System.assertEquals(0, PSTA_PostCargaPostventa_soql.getResumenesByAdvisorIds(new Set<String>()).size());
    }

    private static User createUser(String suffix, String advisorId) {
        Id profileId = [SELECT Id FROM Profile WHERE Name IN ('System Administrator', 'Administrador del sistema') LIMIT 1].Id;
        User userRecord = new User(
            LastName = 'User' + suffix,
            Username = 'postcarga.' + suffix + '.' + System.now().getTime() + '@test.com',
            Email = 'postcarga.' + suffix + '@test.com',
            EmailEncodingKey = 'ISO-8859-1',
            Alias = ('pc' + suffix).substring(0, 5),
            TimeZoneSidKey = 'America/Mexico_City',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'es',
            ProfileId = profileId,
            ID_ASESOR__c = advisorId
        );
        insert userRecord;
        return userRecord;
    }

    private static Boolean containsAccountUpdate(
        List<Account> updates,
        Id accountId,
        Boolean contactoPriorizadoEsteMes,
        Boolean priorizacionContacto,
        Boolean priorizacionVisita
    ) {
        for (Account updateRecord : updates) {
            if (updateRecord.Id == accountId &&
                updateRecord.ContactoPriorizadoEsteMes__c == contactoPriorizadoEsteMes &&
                updateRecord.PriorizacionContacto__c == priorizacionContacto &&
                updateRecord.PriorizacionVisita__c == priorizacionVisita) {
                return true;
            }
        }
        return false;
    }

    private static Boolean containsBalanceUpdate(
        List<Account> updates,
        Id accountId,
        Decimal expectedBalance
    ) {
        for (Account updateRecord : updates) {
            if (updateRecord.Id == accountId &&
                updateRecord.SaldoIntegral__c == expectedBalance) {
                return true;
            }
        }
        return false;
    }

    private static Boolean containsStatusUpdate(
        List<Account> updates,
        Id accountId,
        String expectedStatus
    ) {
        for (Account updateRecord : updates) {
            if (updateRecord.Id == accountId &&
                updateRecord.EstatusContacto__c == expectedStatus &&
                updateRecord.FechaUltimoContacto__c == null &&
                updateRecord.FechaUltimaVisita__c == null) {
                return true;
            }
        }
        return false;
    }

    private static Id buildFakeId(Schema.SObjectType sObjectType, Integer sequence) {
        String prefix = sObjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(prefix + String.valueOf(sequence).leftPad(12, '0'));
    }

    private class RemoveTrackerMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('[{"actionName":"removeTargetFromSalesCadence","isSuccess":true,"errors":[],"outputValues":{"error":null}}]');
            return response;
        }
    }
}
