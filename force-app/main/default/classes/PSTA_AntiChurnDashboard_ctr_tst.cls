@IsTest(SeeAllData=true)
private class PSTA_AntiChurnDashboard_ctr_tst {

    @IsTest
    static void testGetDashboardDataBuildsKpis() {
        String advisorId = 'AC' + String.valueOf(DateTime.now().getTime()).right(6);
        User dashboardUser = createDashboardUser(advisorId);

        System.runAs(dashboardUser) {
            Id recordTypeId = [
                SELECT Id
                FROM RecordType
                WHERE SObjectType = 'Task'
                    AND DeveloperName = 'Anti_Churn'
                LIMIT 1
            ].Id;

            String uniqueKey = String.valueOf(DateTime.now().getTime()).right(8);
            BranchUnit branchUnit = createBranchUnit(uniqueKey);
            Banker banker = createBanker(branchUnit.Id, UserInfo.getUserId(), advisorId, uniqueKey);
            BranchUnitBusinessMember bankerMember = [
                SELECT Id
                FROM BranchUnitBusinessMember
                WHERE BranchUnitId = :branchUnit.Id
                    AND BusinessUnitMemberId = :banker.Id
                LIMIT 1
            ];

            List<Account> accounts = new List<Account>{
                createAccount('Anti Churn High Risk', bankerMember.Id, advisorId, 'Alto'),
                createAccount('Anti Churn Medium Risk', bankerMember.Id, advisorId, 'Medio')
            };
            Account highRiskAccount = accounts[0];
            Account mediumRiskAccount = accounts[1];

            OD_Account_cls.bypassTriggerExecution = true;
            insert accounts;

            List<Task> tasks = new List<Task>();

            Task retainedTask = new Task(
                Subject = 'Retenido',
                Status = 'Not Started',
                Priority = 'Normal',
                ActivityDate = System.today(),
                RecordTypeId = recordTypeId,
                WhatId = highRiskAccount.Id
            );
            retainedTask.put('Resultado_de_Gestion__c', 'Contactado Retenido');
            retainedTask.put('Fecha_de_contactacion__c', System.today());
            tasks.add(retainedTask);

            Task negativeTask = new Task(
                Subject = 'No retenido',
                Status = 'Not Started',
                Priority = 'Normal',
                ActivityDate = System.today(),
                RecordTypeId = recordTypeId,
                WhatId = mediumRiskAccount.Id
            );
            negativeTask.put('Resultado_de_Gestion__c', 'Contactado No Retenido');
            negativeTask.put('Motivo_de_fuga__c', 'Otro');
            negativeTask.put('Fecha_de_contactacion__c', System.today());
            tasks.add(negativeTask);

            Task pendingTask = new Task(
                Subject = 'Pendiente',
                Status = 'Not Started',
                Priority = 'Normal',
                ActivityDate = System.today(),
                RecordTypeId = recordTypeId,
                WhatId = highRiskAccount.Id
            );
            pendingTask.put('Resultado_de_Gestion__c', 'Pendiente');
            tasks.add(pendingTask);

            insert tasks;

            Integer expectedPilotClients = countDistinctAccounts(recordTypeId);
            Integer expectedActivities = countActivities(recordTypeId);
            Integer expectedHighRiskClients = countDistinctHighRiskAccounts(recordTypeId);
            Map<String, Integer> expectedCountsByResult = getCountsByResult(recordTypeId);
            Decimal expectedAverageDays = getAverageContactDays(recordTypeId);
            Integer expectedMotivoCount = getMotivoSliceCount(recordTypeId);

            Test.startTest();
            PSTA_AntiChurnDashboard_ctr.DashboardResponse response =
                PSTA_AntiChurnDashboard_ctr.getDashboardData();
            Test.stopTest();

            System.assertNotEquals(null, response);
            System.assertEquals(System.today(), response.generatedDate);
            System.assertEquals(expectedPilotClients, response.totalPilotClients);
            System.assertEquals(expectedActivities, response.totalActivities);
            System.assertEquals(expectedHighRiskClients, response.highRiskClientsWithActivity);
            System.assertEquals(
                calculatePercentage(expectedHighRiskClients, expectedPilotClients),
                response.highRiskAssignedPct
            );
            System.assertEquals(expectedCountsByResult.get('Contactado Retenido'), response.positiveActivities);
            System.assertEquals(expectedCountsByResult.get('Contactado No Retenido'), response.negativeActivities);
            System.assertEquals(expectedCountsByResult.get('Cliente no responde'), response.noContactActivities);
            System.assertEquals(expectedCountsByResult.get('Pendiente'), response.pendingActivities);
            System.assertEquals(expectedAverageDays, response.avgContactDays);
            System.assertEquals(
                calculatePercentage(
                    response.positiveActivities + response.negativeActivities,
                    response.totalPilotClients
                ),
                response.effectiveContactRate
            );
            System.assertEquals(
                calculatePercentage(response.totalActivities, response.positiveActivities),
                response.churnVariationPct
            );
            System.assertEquals(expectedMotivoCount, response.motivoFuga.size());
            System.assertNotEquals(null, response.highRiskReportId);
            System.assertNotEquals(null, response.activitiesReportId);
            System.assert(response.pilotPopulationDefinition.contains('Anti-Churn abierta'));
        }
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
            Name = accountName,
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

    private static Integer countDistinctAccounts(Id recordTypeId) {
        return Integer.valueOf(String.valueOf([
            SELECT COUNT_DISTINCT(AccountId) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND IsClosed = false
                AND AccountId != null
        ][0].get('total')));
    }

    private static Integer countActivities(Id recordTypeId) {
        return Integer.valueOf(String.valueOf([
            SELECT COUNT(Id) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND IsClosed = false
                AND AccountId != null
        ][0].get('total')));
    }

    private static Integer countDistinctHighRiskAccounts(Id recordTypeId) {
        return Integer.valueOf(String.valueOf([
            SELECT COUNT_DISTINCT(AccountId) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND IsClosed = false
                AND AccountId != null
                AND Account.Indicador_de_Riesgo_Churn__c = 'Alto'
        ][0].get('total')));
    }

    private static Map<String, Integer> getCountsByResult(Id recordTypeId) {
        Map<String, Integer> counts = new Map<String, Integer>{
            'Contactado Retenido' => 0,
            'Contactado No Retenido' => 0,
            'Cliente no responde' => 0,
            'Pendiente' => 0
        };

        for (AggregateResult groupedResult : [
            SELECT Resultado_de_Gestion__c resultValue, COUNT(Id) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND IsClosed = false
                AND AccountId != null
            GROUP BY Resultado_de_Gestion__c
        ]) {
            String resultValue = (String) groupedResult.get('resultValue');
            if (counts.containsKey(resultValue)) {
                counts.put(
                    resultValue,
                    Integer.valueOf(String.valueOf(groupedResult.get('total')))
                );
            }
        }

        return counts;
    }

    private static Decimal getAverageContactDays(Id recordTypeId) {
        Object value = [
            SELECT AVG(Tiempo_promedio_de_contacto_CHURN__c) averageDays
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND IsClosed = false
                AND AccountId != null
                AND Tiempo_promedio_de_contacto_CHURN__c != null
        ][0].get('averageDays');

        return value == null ? 0 : Decimal.valueOf(String.valueOf(value)).setScale(2);
    }

    private static Integer getMotivoSliceCount(Id recordTypeId) {
        Integer total = 0;
        for (AggregateResult groupedResult : [
            SELECT Motivo_de_fuga__c reason
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND IsClosed = false
                AND AccountId != null
                AND Motivo_de_fuga__c != null
            GROUP BY Motivo_de_fuga__c
        ]) {
            total++;
        }

        return total;
    }

    private static Decimal calculatePercentage(Decimal numerator, Decimal denominator) {
        if (denominator == null || denominator <= 0) {
            return 0;
        }

        return ((numerator == null ? 0 : numerator) / denominator * 100).setScale(2);
    }
}
