@IsTest
public class PSTA_RResumenMensual_sch_tst {

    @IsTest
    static void testExecute() {
        ACT_BusinessHoursHelper_cls.testOverrideIsConfiguredBusinessDay = true;
        Test.startTest();
        new PSTA_RegistroResumenGlobalMensual_sch().execute(null);
        Test.stopTest();
        ACT_BusinessHoursHelper_cls.testOverrideIsConfiguredBusinessDay = null;
    }
}
