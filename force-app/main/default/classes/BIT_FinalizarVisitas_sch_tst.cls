/**
 * @Developed by  : VASS México
 * @Autor         : Canche Isaac
 * @Project       : 
 * @Descripcion   : 
**/
@isTest
public class BIT_FinalizarVisitas_sch_tst {
    @isTest
    static void testExecuteSchedule() {
        Test.startTest();
        // Llamar al método para programar el Job
        String jobId = BIT_FinalizarVisitas_sch.executeSchedule();
        
        // Verificar que el job fue programado
        CronTrigger ct = [SELECT Id, CronExpression, State FROM CronTrigger WHERE Id = :jobId];
        System.assertNotEquals(null, ct, 'El trabajo debería haber sido programado.');
        System.assertEquals(BIT_FinalizarVisitas_sch.CRON_EXPR, ct.CronExpression, 'La expresión cron debería coincidir.');
    	Test.stopTest();
    }
    
}