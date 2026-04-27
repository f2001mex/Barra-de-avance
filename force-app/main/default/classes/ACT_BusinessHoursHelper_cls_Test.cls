@IsTest
public class ACT_BusinessHoursHelper_cls_Test {

    @IsTest
    static void test_isWithinConfiguredBH_returnsBoolean() {
        ACT_BusinessHoursHelper_cls.testOverrideIsWithinConfiguredBH = null;

        Boolean result = ACT_BusinessHoursHelper_cls.isWithinConfiguredBH('PSTA_ResetearEstatusContacto');
        System.assertNotEquals(null, result, 'Debe devolver un booleano.');
    }

    @IsTest
    static void test_isConfiguredBusinessDay_returnsBoolean() {
        ACT_BusinessHoursHelper_cls.testOverrideIsConfiguredBusinessDay = null;

        Boolean result = ACT_BusinessHoursHelper_cls.isConfiguredBusinessDay('PSTA_ResetearEstatusContacto');
        System.assertNotEquals(null, result, 'Debe devolver un booleano.');
    }

    @IsTest
    static void test_executeBatchIfWithinConfiguredBH_executesWhenOverrideIsTrue() {
        Test.startTest();
        ACT_BusinessHoursHelper_cls.testOverrideIsWithinConfiguredBH = true;

        Id jobId = ACT_BusinessHoursHelper_cls.executeBatchIfWithinConfiguredBH(
            'PSTA_ResetearEstatusContacto',
            new ACT_BusinessHoursHelperDummyBatch_Test(),
            1
        );

        Test.stopTest();
        ACT_BusinessHoursHelper_cls.testOverrideIsWithinConfiguredBH = null;

        System.assertNotEquals(null, jobId, 'Debe ejecutar batch cuando esta permitido por horario.');
    }

    @IsTest
    static void test_executeBatchIfConfiguredBusinessDay_executesWhenOverrideIsTrue() {
        Test.startTest();
        ACT_BusinessHoursHelper_cls.testOverrideIsConfiguredBusinessDay = true;

        Id jobId = ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
            'PSTA_ResetearEstatusContacto',
            new ACT_BusinessHoursHelperDummyBatch_Test(),
            1
        );

        Test.stopTest();
        ACT_BusinessHoursHelper_cls.testOverrideIsConfiguredBusinessDay = null;

        System.assertNotEquals(null, jobId, 'Debe ejecutar batch cuando el dia es habil.');
    }

    @IsTest
    static void test_executeBatchIfConfiguredBusinessDay_skipsWhenOverrideIsFalse() {
        Test.startTest();
        ACT_BusinessHoursHelper_cls.testOverrideIsConfiguredBusinessDay = false;

        Id jobId = ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
            'PSTA_ResetearEstatusContacto',
            new ACT_BusinessHoursHelperDummyBatch_Test(),
            1
        );

        Test.stopTest();
        ACT_BusinessHoursHelper_cls.testOverrideIsConfiguredBusinessDay = null;

        System.assertEquals(null, jobId, 'No debe ejecutar batch cuando el dia no es habil.');
    }

    @IsTest
    static void test_executeBatchIfWithinConfiguredBH_skipsWhenOverrideIsFalse() {
        Test.startTest();
        ACT_BusinessHoursHelper_cls.testOverrideIsWithinConfiguredBH = false;

        Id jobId = ACT_BusinessHoursHelper_cls.executeBatchIfWithinConfiguredBH(
            'PSTA_ResetearEstatusContacto',
            new ACT_BusinessHoursHelperDummyBatch_Test(),
            1
        );

        Test.stopTest();
        ACT_BusinessHoursHelper_cls.testOverrideIsWithinConfiguredBH = null;

        System.assertEquals(null, jobId, 'No debe ejecutar batch cuando esta fuera de horario.');
    }

    @IsTest
    static void test_executeBatchIfConfiguredBusinessDay_withoutScope_executes() {
        Test.startTest();
        ACT_BusinessHoursHelper_cls.testOverrideIsConfiguredBusinessDay = true;

        Id jobId = ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
            'PSTA_ResetearEstatusContacto',
            new ACT_BusinessHoursHelperDummyBatch_Test()
        );

        Test.stopTest();
        ACT_BusinessHoursHelper_cls.testOverrideIsConfiguredBusinessDay = null;

        System.assertNotEquals(null, jobId, 'Debe ejecutar batch sin scope explicito.');
    }

    @IsTest
    static void test_executeBatchIfWithinConfiguredBH_withoutScope_executes() {
        Test.startTest();
        ACT_BusinessHoursHelper_cls.testOverrideIsWithinConfiguredBH = true;

        Id jobId = ACT_BusinessHoursHelper_cls.executeBatchIfWithinConfiguredBH(
            'PSTA_ResetearEstatusContacto',
            new ACT_BusinessHoursHelperDummyBatch_Test()
        );

        Test.stopTest();
        ACT_BusinessHoursHelper_cls.testOverrideIsWithinConfiguredBH = null;

        System.assertNotEquals(null, jobId, 'Debe ejecutar batch sin scope explicito.');
    }
}