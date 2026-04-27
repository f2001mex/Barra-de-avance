@IsTest
private class PSTA_FACCadenceCompletion_cls_tst {
    @IsTest(SeeAllData=true)
    static void testCompletesFacTaskWhenCalloutSucceeds() {
        TestData data = createTestData();
        PSTA_FACCadenceCompletion_cls.cadenceIdOverride = String.valueOf(getCadenceId());
        PSTA_FACCadenceCompletion_cls.sessionIdOverride = 'TEST_SESSION';
        Test.setMock(HttpCalloutMock.class, new RemoveCadenceMock(true));

        Account acc = [SELECT Id, AvanceNum1FAC__c, AvanceNum2FAC__c FROM Account WHERE Id = :data.accountId];
        Account oldAcc = buildAccountProgress(acc.Id, 14, 12);
        Account updatedAcc = buildAccountProgress(acc.Id, 14, 13);

        Test.startTest();
        PSTA_FACCadenceCompletion_cls.onAfterUpdate(
            new List<Account>{ updatedAcc },
            new Map<Id, Account>{ acc.Id => oldAcc }
        );
        Test.stopTest();

        Task updatedTask = [
            SELECT Subject, Status, DeveloperName__c, El_cliente_fue_contactado__c, Description, PV_ExternalID__c
            FROM Task
            WHERE WhatId = :acc.Id
            LIMIT 1
        ];

        System.assertEquals('Ficha de afinidad con el cliente', updatedTask.Subject);
        System.assertEquals('Completado', updatedTask.Status);
        System.assertEquals('FAC', updatedTask.DeveloperName__c);
        System.assertEquals('Si', updatedTask.El_cliente_fue_contactado__c);
        System.assert(updatedTask.Description.contains('Ficha de afinidad con el cliente'));
        System.assertNotEquals(null, updatedTask.PV_ExternalID__c);
    }

    @IsTest(SeeAllData=true)
    static void testLeavesTaskUnchangedWhenCalloutFails() {
        TestData data = createTestData();
        PSTA_FACCadenceCompletion_cls.cadenceIdOverride = String.valueOf(getCadenceId());
        PSTA_FACCadenceCompletion_cls.sessionIdOverride = 'TEST_SESSION';
        Test.setMock(HttpCalloutMock.class, new RemoveCadenceMock(false));

        Account acc = [SELECT Id, AvanceNum1FAC__c, AvanceNum2FAC__c FROM Account WHERE Id = :data.accountId];
        Account oldAcc = buildAccountProgress(acc.Id, 14, 12);
        Account updatedAcc = buildAccountProgress(acc.Id, 14, 13);

        Test.startTest();
        PSTA_FACCadenceCompletion_cls.onAfterUpdate(
            new List<Account>{ updatedAcc },
            new Map<Id, Account>{ acc.Id => oldAcc }
        );
        Test.stopTest();

        Task untouchedTask = [
            SELECT Subject, Status, DeveloperName__c, El_cliente_fue_contactado__c
            FROM Task
            WHERE WhatId = :acc.Id
            LIMIT 1
        ];

        System.assertEquals('Other: Ficha de afinidad con el cliente, Demo', untouchedTask.Subject);
        System.assertEquals('Abierto', untouchedTask.Status);
        System.assertEquals(null, untouchedTask.DeveloperName__c);
        System.assertEquals(null, untouchedTask.El_cliente_fue_contactado__c);
    }

    @IsTest(SeeAllData=true)
    static void testCreatesCompletedTaskWhenCadenceTaskWasRemoved() {
        TestData data = createTestData(false);
        PSTA_FACCadenceCompletion_cls.cadenceIdOverride = String.valueOf(getCadenceId());
        PSTA_FACCadenceCompletion_cls.sessionIdOverride = 'TEST_SESSION';
        Test.setMock(HttpCalloutMock.class, new RemoveCadenceMock(true));

        Account currentAcc = [SELECT Id FROM Account WHERE Id = :data.accountId];
        Account oldAcc = buildAccountProgress(currentAcc.Id, 14, 12);
        Account updatedAcc = buildAccountProgress(currentAcc.Id, 14, 13);

        Test.startTest();
        PSTA_FACCadenceCompletion_cls.onAfterUpdate(
            new List<Account>{ updatedAcc },
            new Map<Id, Account>{ currentAcc.Id => oldAcc }
        );
        Test.stopTest();

        Task createdTask = [
            SELECT Subject, Status, DeveloperName__c, El_cliente_fue_contactado__c, RecordType.DeveloperName, WhatId, WhoId
            FROM Task
            WHERE WhatId = :currentAcc.Id
            LIMIT 1
        ];

        System.assertEquals('Ficha de afinidad con el cliente', createdTask.Subject);
        System.assertEquals('Completado', createdTask.Status);
        System.assertEquals('FAC', createdTask.DeveloperName__c);
        System.assertEquals(null, createdTask.El_cliente_fue_contactado__c);
        System.assertEquals('Postventa', createdTask.RecordType.DeveloperName);
        System.assertEquals(data.contactId, createdTask.WhoId);
    }

    @IsTest(SeeAllData=true)
    static void testUpdatesExistingCompletedTaskWhenCadenceWasAlreadyCompleted() {
        TestData data = createTestData(true, 'Complete', 'Ficha de afinidad con el cliente', 'Completado');
        PSTA_FACCadenceCompletion_cls.cadenceIdOverride = String.valueOf(getCadenceId());
        PSTA_FACCadenceCompletion_cls.sessionIdOverride = 'TEST_SESSION';

        Account currentAcc = [
            SELECT Id, FechaUltimoContacto__c, EstatusContacto__c
            FROM Account
            WHERE Id = :data.accountId
        ];
        Account oldAcc = buildAccountProgress(currentAcc.Id, 14, 12);
        Account updatedAcc = buildAccountProgress(currentAcc.Id, 14, 13);

        Test.startTest();
        PSTA_FACCadenceCompletion_cls.onAfterUpdate(
            new List<Account>{ updatedAcc },
            new Map<Id, Account>{ currentAcc.Id => oldAcc }
        );
        Test.stopTest();

        Task updatedTask = [
            SELECT Subject, Status, DeveloperName__c, El_cliente_fue_contactado__c
            FROM Task
            WHERE Id = :data.taskId
        ];

        Account refreshedAcc = [
            SELECT FechaUltimoContacto__c, EstatusContacto__c
            FROM Account
            WHERE Id = :data.accountId
        ];

        System.assertEquals('Ficha de afinidad con el cliente', updatedTask.Subject);
        System.assertEquals('Completado', updatedTask.Status);
        System.assertEquals('FAC', updatedTask.DeveloperName__c);
        System.assertEquals('Si', updatedTask.El_cliente_fue_contactado__c);
        System.assertEquals(Date.today(), refreshedAcc.FechaUltimoContacto__c);
        System.assertEquals('Contacto efectivo exitoso', refreshedAcc.EstatusContacto__c);
    }

    @IsTest(SeeAllData=true)
    static void testAccountTriggerAfterUpdateCoverage() {
        TestData data = createTestData();
        OD_Account_cls.bypassTriggerExecution = true;
        PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();

        OD_Account_cls.bypassTriggerExecution = true;
        Account acc = [
            SELECT Id, SaldoIntegral__c, FechaNoRequiereSerContacto__c,
                   FechaSiguienteContacto__c, FechaSiguienteVisita__c,
                   FechaUltimaVisita__c, EstatusContacto__c
            FROM Account
            WHERE Id = :data.accountId
        ];
        acc.SaldoIntegral__c = 2000;

        Test.startTest();
        update acc;
        Test.stopTest();

        System.assertEquals(2000, [SELECT SaldoIntegral__c FROM Account WHERE Id = :acc.Id].SaldoIntegral__c);
    }

    @IsTest
    static void testHasReachedFac100UsesUnderlyingCounters() {
        System.assertEquals(false, PSTA_FACCadenceCompletion_cls.hasReachedFac100(null));
        System.assertEquals(false, PSTA_FACCadenceCompletion_cls.hasReachedFac100(buildAccountProgress('001000000000001AAA', 14, 12)));
        System.assertEquals(true, PSTA_FACCadenceCompletion_cls.hasReachedFac100(buildAccountProgress('001000000000001AAA', 14, 13)));
        System.assertEquals(true, PSTA_FACCadenceCompletion_cls.hasReachedFac100(buildAccountProgress('001000000000001AAA', 14, 14)));
    }

    private static TestData createTestData() {
        return createTestData(true);
    }

    private static TestData createTestData(Boolean createCadenceTask) {
        return createTestData(createCadenceTask, 'Running', 'Other: Ficha de afinidad con el cliente, Demo', 'Abierto');
    }

    private static TestData createTestData(Boolean createCadenceTask, String trackerState, String taskSubject, String taskStatus) {
        OD_Account_cls.bypassTriggerExecution = true;
        TestData data = new TestData();

        Account acc = new Account(
            Name = 'Cuenta FAC ' + System.now().getTime(),
            Client_ID__c = 'C123',
            ID_Asesor__c = 'A456',
            SaldoIntegral__c = 1000,
            FechaNoRequiereSerContacto__c = Date.today(),
            FechaSiguienteContacto__c = Date.today(),
            FechaSiguienteVisita__c = Date.today(),
            FechaUltimaVisita__c = Date.today().addDays(-10),
            EstatusContacto__c = 'Contacto efectivo exitoso'
        );
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'FAC',
            AccountId = acc.Id
        );
        insert con;

        insert new ActionCadenceTracker(
            TargetId = con.Id,
            ActionCadenceId = getCadenceId(),
            State = trackerState
        );

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

        data.accountId = acc.Id;
        data.contactId = con.Id;
        return data;
    }

    private static Account buildAccountProgress(Id accountId, Decimal applicable, Decimal completed) {
        return (Account) JSON.deserialize(
            '{"Id":"' + accountId + '","AvanceNum1FAC__c":' + String.valueOf(applicable) +
            ',"AvanceNum2FAC__c":' + String.valueOf(completed) + '}',
            Account.class
        );
    }

    private class RemoveCadenceMock implements HttpCalloutMock {
        private final Boolean shouldSucceed;

        private RemoveCadenceMock(Boolean shouldSucceed) {
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
            response.setStatusCode(200);
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
    }
}
