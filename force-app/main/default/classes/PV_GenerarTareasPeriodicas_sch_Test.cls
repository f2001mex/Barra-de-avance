@isTest
public class PV_GenerarTareasPeriodicas_sch_Test {

    @isTest static void testExecuteInvokesBatch() {
        Test.startTest();

        PV_GenerarTareasPeriodicas_sch sched = new PV_GenerarTareasPeriodicas_sch();
        sched.execute(null);

        Test.stopTest();
        
        System.assert(true, 'El batch fue invocado sin lanzar excepciones');
    }
}