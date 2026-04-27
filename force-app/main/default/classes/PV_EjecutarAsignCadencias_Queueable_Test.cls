@isTest
public class PV_EjecutarAsignCadencias_Queueable_Test {
    @isTest
    static void test1(){
     //PV_GenerarTareasPeriodicas_Request req = new PV_GenerarTareasPeriodicas_Request('Pruebas', 'Pruebas', 'Test');
        List<PV_GenerarTareasPeriodicas_Request> lstReq = new List<PV_GenerarTareasPeriodicas_Request>();
        lstReq.add(new PV_GenerarTareasPeriodicas_Request('Pruebas', 'Pruebas', 'Test'));
        System.Queueable job = new PV_EjecutarAsignacionCadencias_Queueable(lstReq, 1);
        test.startTest();
        System.enqueueJob(job);
        test.stopTest();
    }
}