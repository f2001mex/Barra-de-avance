@IsTest
private class PSTA_FACCadenceCompletion_cls_tst {
    private static final String TEST_SESSION = 'TEST_SESSION';
    private static final String TASK_SUBJECT_LIKE = 'Ficha de afinidad con el cliente';

    @IsTest(SeeAllData=true)
    static void testCompletesExistingRunningTaskWhenCalloutSucceeds() {
        TestData data = createCadenceTestData(true, 'Running', 'Other: Ficha de afinidad con el cliente, Demo', 'Abierto');
        configureCadenceOverridesWithRealCadence();
        Test.setMock(HttpCalloutMock.class, new RemoveCadenceMock(200, true));

        Test.startTest();
        PSTA_FACCadenceCompletion_cls.onAfterUpdate(
            new List<Account>{ buildAccountProgress(data.accountId, 14, 13) },
            new Map<Id, Account>{ data.accountId => buildAccountProgress(data.accountId, 14, 12) }
        );
        Test.stopTest();

        Task updatedTask = [
            SELECT Subject, Status, DeveloperName__c, El_cliente_fue_contactado__c, Description, PV_ExternalID__c
            FROM Task
            WHERE Id = :data.taskId
        ];

        System.assertEquals(TASK_SUBJECT_LIKE, updatedTask.Subject);
        System.assertEquals('Completado', updatedTask.Status);
        System.assertEquals('FAC', updatedTask.DeveloperName__c);
        System.assertEquals('Si', updatedTask.El_cliente_fue_contactado__c);
        System.assert(updatedTask.Description.contains(TASK_SUBJECT_LIKE));
        System.assert(updatedTask.PV_ExternalID__c.startsWith('FAC-'));
    }

    @IsTest(SeeAllData=true)
    static void testLeavesExistingTaskUntouchedWhenCalloutReturnsNoSuccess() {
        TestData data = createCadenceTestData(true, 'Running', 'Other: Ficha de afinidad con el cliente, Demo', 'Abierto');
        configureCadenceOverridesWithRealCadence();
        Test.setMock(HttpCalloutMock.class, new RemoveCadenceMock(200, false));

        Test.startTest();
        PSTA_FACCadenceCompletion_cls.onAfterUpdate(
            new List<Account>{ buildAccountProgress(data.accountId, 14, 13) },
            new Map<Id, Account>{ data.accountId => buildAccountProgress(data.accountId, 14, 12) }
        );
        Test.stopTest();

        Task untouchedTask = [
            SELECT Subject, Status, DeveloperName__c, El_cliente_fue_contactado__c
            FROM Task
            WHERE Id = :data.taskId
        ];

        System.assertEquals('Other: Ficha de afinidad con el cliente, Demo', untouchedTask.Subject);
        System.assertEquals('Abierto', untouchedTask.Status);
        System.assertEquals(null, untouchedTask.DeveloperName__c);
        System.assertEquals(null, untouchedTask.El_cliente_fue_contactado__c);
    }

    @IsTest(SeeAllData=true)
    static void testCreatesCompletedTaskWhenNoCadenceTaskExists() {
        TestData data = createCadenceTestData(false, 'Running', null, null);
        configureCadenceOverridesWithRealCadence();
        Test.setMock(HttpCalloutMock.class, new RemoveCadenceMock(200, true));

        Test.startTest();
        PSTA_FACCadenceCompletion_cls.onAfterUpdate(
            new List<Account>{ buildAccountProgress(data.accountId, 14, 13) },
            new Map<Id, Account>{ data.accountId => buildAccountProgress(data.accountId, 14, 12) }
        );
        Test.stopTest();

        Task createdTask = [
            SELECT Subject, Status, DeveloperName__c, El_cliente_fue_contactado__c, RecordType.DeveloperName, WhoId, PV_ExternalID__c
            FROM Task
            WHERE WhatId = :data.accountId
            AND Subject = :TASK_SUBJECT_LIKE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(TASK_SUBJECT_LIKE, createdTask.Subject);
        System.assertEquals('Completado', createdTask.Status);
        System.assertEquals('FAC', createdTask.DeveloperName__c);
        System.assertEquals('Postventa', createdTask.RecordType.DeveloperName);
        System.assertEquals(data.contactId, createdTask.WhoId);
        System.assertEquals(null, createdTask.El_cliente_fue_contactado__c);
        System.assert(createdTask.PV_ExternalID__c.startsWith('FAC-'));
    }

    @IsTest(SeeAllData=true)
    static void testUpdatesTaskUsingCompletedTrackerWhenNoRunningTrackerExists() {
        TestData data = createCadenceTestData(true, 'Complete', 'Pendiente Ficha de afinidad con el cliente', 'Abierto');
        configureCadenceOverridesWithRealCadence();

        Test.startTest();
        PSTA_FACCadenceCompletion_cls.onAfterUpdate(
            new List<Account>{ buildAccountProgress(data.accountId, 14, 13) },
            new Map<Id, Account>{ data.accountId => buildAccountProgress(data.accountId, 14, 12) }
        );
        Test.stopTest();

        Task updatedTask = [
            SELECT Subject, Status, DeveloperName__c, El_cliente_fue_contactado__c
            FROM Task
            WHERE Id = :data.taskId
        ];

        System.assertEquals(TASK_SUBJECT_LIKE, updatedTask.Subject);
        System.assertEquals('Completado', updatedTask.Status);
        System.assertEquals('FAC', updatedTask.DeveloperName__c);
        System.assertEquals('Si', updatedTask.El_cliente_fue_contactado__c);
    }

    @IsTest
    static void testOnAfterUpdateSkipsRecordsThatDidNotNewlyReachThreshold() {
        resetOverrides();
        Id fakeAccountId = buildFakeId(Account.SObjectType, 1);

        Test.startTest();
        PSTA_FACCadenceCompletion_cls.onAfterUpdate(
            new List<Account>{
                null,
                new Account(),
                buildAccountProgress(fakeAccountId, 14, 12),
                buildAccountProgress(fakeAccountId, 14, 13)
            },
            new Map<Id, Account>{ fakeAccountId => buildAccountProgress(fakeAccountId, 14, 13) }
        );
        System.assertEquals(0, Limits.getFutureCalls());
        Test.stopTest();
    }

    @IsTest
    static void testOnAfterUpdateEnqueuesFutureWhenOldMapIsMissing() {
        resetOverrides();
        PSTA_FACCadenceCompletion_cls.cadenceIdOverride = String.valueOf(buildFakeId(ActionCadence.SObjectType, 1));
        PSTA_FACCadenceCompletion_cls.sessionIdOverride = TEST_SESSION;
        Id fakeAccountId = buildFakeId(Account.SObjectType, 2);

        Test.startTest();
        PSTA_FACCadenceCompletion_cls.onAfterUpdate(
            new List<Account>{ buildAccountProgress(fakeAccountId, 14, 13) },
            null
        );
        System.assertEquals(1, Limits.getFutureCalls());
        Test.stopTest();
    }

    @IsTest
    static void testCompleteCadenceAsyncReturnsForGuardClausesWithoutSupportingData() {
        resetOverrides();
        PSTA_FACCadenceCompletion_cls.cadenceIdOverride = String.valueOf(buildFakeId(ActionCadence.SObjectType, 2));

        Account accountWithoutContact = createAccountOnly('sin-contacto');
        Account accountWithContact = createAccountOnly('sin-tracker');
        insert new Contact(
            FirstName = 'Sin',
            LastName = 'Tracker',
            AccountId = accountWithContact.Id
        );

        Test.startTest();
        PSTA_FACCadenceCompletion_cls.completeCadenceAsync(new List<Id>(), TEST_SESSION);
        PSTA_FACCadenceCompletion_cls.completeCadenceAsync(
            new List<Id>{ buildFakeId(Account.SObjectType, 99) },
            TEST_SESSION
        );
        PSTA_FACCadenceCompletion_cls.completeCadenceAsync(
            new List<Id>{ accountWithoutContact.Id },
            TEST_SESSION
        );
        PSTA_FACCadenceCompletion_cls.completeCadenceAsync(
            new List<Id>{ accountWithContact.Id },
            TEST_SESSION
        );
        Test.stopTest();

        Set<Id> accountIds = new Set<Id>{ accountWithoutContact.Id, accountWithContact.Id };
        Integer facTaskCount = [
            SELECT Count()
            FROM Task
            WHERE WhatId IN :accountIds
            AND Subject = :TASK_SUBJECT_LIKE
        ];
        System.assertEquals(0, facTaskCount);
    }

    @IsTest(SeeAllData=true)
    static void testGetFacCadenceIdQueriesCadenceWhenNoOverrideExists() {
        resetOverrides();
        System.assertNotEquals(null, PSTA_FACCadenceCompletion_cls.getFacCadenceId());
    }

    @IsTest
    static void testHelperMethodsCoverEdgeCases() {
        resetOverrides();
        Id fakeCadenceId = buildFakeId(ActionCadence.SObjectType, 5);
        Id fakeAccountId = buildFakeId(Account.SObjectType, 5);

        PSTA_FACCadenceCompletion_cls.cadenceIdOverride = String.valueOf(fakeCadenceId);
        System.assertEquals(String.valueOf(fakeCadenceId), PSTA_FACCadenceCompletion_cls.getFacCadenceId());

        System.assertEquals(false, PSTA_FACCadenceCompletion_cls.hasReachedFac100(null));
        System.assertEquals(false, PSTA_FACCadenceCompletion_cls.hasReachedFac100(new Account(Id = fakeAccountId)));
        System.assertEquals(false, PSTA_FACCadenceCompletion_cls.hasReachedFac100(buildAccountProgress(fakeAccountId, 0, 1)));
        System.assertEquals(false, PSTA_FACCadenceCompletion_cls.hasReachedFac100(buildAccountProgress(fakeAccountId, 14, 12)));
        System.assertEquals(true, PSTA_FACCadenceCompletion_cls.hasReachedFac100(buildAccountProgress(fakeAccountId, 14, 13)));
        System.assertEquals(true, PSTA_FACCadenceCompletion_cls.hasReachedFac100(buildAccountProgress(fakeAccountId, 14, 14)));

        System.assertEquals(0, PSTA_FACCadenceCompletion_cls.removeTrackers(new List<ActionCadenceTracker>(), TEST_SESSION).size());

        Test.setMock(HttpCalloutMock.class, new RemoveCadenceMock(500, false));
        Set<Id> removedTrackers = PSTA_FACCadenceCompletion_cls.removeTrackers(
            new List<ActionCadenceTracker>{
                new ActionCadenceTracker(Id = buildFakeId(ActionCadenceTracker.SObjectType, 1))
            },
            TEST_SESSION
        );
        System.assertEquals(0, removedTrackers.size());
    }

    private static void configureCadenceOverridesWithRealCadence() {
        resetOverrides();
        PSTA_FACCadenceCompletion_cls.cadenceIdOverride = String.valueOf(getCadenceId());
        PSTA_FACCadenceCompletion_cls.sessionIdOverride = TEST_SESSION;
    }

    private static void resetOverrides() {
        PSTA_FACCadenceCompletion_cls.cadenceIdOverride = null;
        PSTA_FACCadenceCompletion_cls.sessionIdOverride = null;
    }

    private static TestData createCadenceTestData(Boolean createCadenceTask, String trackerState, String taskSubject, String taskStatus) {
        Account acc = createAccountOnly('cadence');
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'FAC',
            AccountId = acc.Id
        );
        insert con;

        ActionCadenceTracker tracker = new ActionCadenceTracker(
            TargetId = con.Id,
            ActionCadenceId = getCadenceId(),
            State = trackerState
        );
        insert tracker;

        TestData data = new TestData();
        data.accountId = acc.Id;
        data.contactId = con.Id;
        data.trackerId = tracker.Id;

        if (createCadenceTask) {
            Task taskRecord = new Task(
                Subject = taskSubject,
                Status = taskStatus,
                WhatId = acc.Id,
                WhoId = con.Id,
                OwnerId = UserInfo.getUserId()
            );
            insert taskRecord;
            data.taskId = taskRecord.Id;
        }

        return data;
    }

    private static Account createAccountOnly(String suffix) {
        OD_Account_cls.bypassTriggerExecution = true;
        String uniqueToken = String.valueOf(System.now().getTime());
        Account acc = new Account(
            Name = 'Cuenta FAC ' + suffix + ' ' + uniqueToken,
            Client_ID__c = 'C' + uniqueToken,
            ID_Asesor__c = 'A' + uniqueToken,
            SaldoIntegral__c = 1000,
            FechaNoRequiereSerContacto__c = Date.today(),
            FechaSiguienteContacto__c = Date.today(),
            FechaSiguienteVisita__c = Date.today(),
            FechaUltimaVisita__c = Date.today().addDays(-10),
            EstatusContacto__c = 'Contacto efectivo exitoso'
        );
        insert acc;
        return acc;
    }

    private static Account buildAccountProgress(Id accountId, Decimal applicable, Decimal completed) {
        return (Account) JSON.deserialize(
            '{"Id":"' + accountId + '","AvanceNum1FAC__c":' + String.valueOf(applicable) +
            ',"AvanceNum2FAC__c":' + String.valueOf(completed) + '}',
            Account.class
        );
    }

    private static Id buildFakeId(Schema.SObjectType sObjectType, Integer sequence) {
        return (Id) (sObjectType.getDescribe().getKeyPrefix() + String.valueOf(sequence).leftPad(12, '0'));
    }

    private class RemoveCadenceMock implements HttpCalloutMock {
        private final Integer statusCode;
        private final Boolean shouldSucceed;

        private RemoveCadenceMock(Integer statusCode, Boolean shouldSucceed) {
            this.statusCode = statusCode;
            this.shouldSucceed = shouldSucceed;
        }

        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('POST', req.getMethod());
            System.assert(req.getEndpoint().contains('/actions/standard/removeTargetFromSalesCadence'));

            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
            List<Object> inputs = (List<Object>) body.get('inputs');
            System.assertEquals(1, inputs.size());

            Map<String, Object> firstInput = (Map<String, Object>) inputs[0];
            System.assertEquals('ManuallyRemoved', firstInput.get('completionReasonCode'));
            System.assertEquals(false, firstInput.get('shouldApplyUserContext'));

            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            if (shouldSucceed) {
                response.setBody('[{"actionName":"removeTargetFromSalesCadence","isSuccess":true,"errors":[],"outputValues":{"error":null}}]');
            } else {
                response.setBody('[{"actionName":"removeTargetFromSalesCadence","isSuccess":false,"errors":[{"statusCode":"INVALID","message":"failure"}],"outputValues":{"error":"failure"}}]');
            }
            return response;
        }
    }

    private static Id getCadenceId() {
        return [SELECT Id FROM ActionCadence WHERE DeveloperName__c = 'FAC' LIMIT 1].Id;
    }

    private class TestData {
        Id accountId;
        Id contactId;
        Id taskId;
        Id trackerId;
    }
}
