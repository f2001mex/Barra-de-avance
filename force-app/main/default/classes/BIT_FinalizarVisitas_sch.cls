/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Modelo de Gestión Empresarial
* Clase test		:   GE_FinalizarVisitas_sch_tst
* Description       :   Clase exclusiva para la periodicidad del revisado y finalizacion de visitas
*--------------------------------------------------------------------------
* No.            Date              Author             Description
* 1.0         31-Jul-2024       Canche Isaac           Creación
*--------------------------------------------------------------------------
*******************************************************************************/
global class BIT_FinalizarVisitas_sch implements Schedulable{

    @TestVisible 
    public static final String CRON_EXPR = Label.BIT_CronExpresion_sch; //Todos los dias a las 20 Hrs (0 0 20 * * ?) por defecto.

    global static String executeSchedule() {
        unSchedule('BIT_FinalizarVisitas');
        BIT_FinalizarVisitas_sch job = new BIT_FinalizarVisitas_sch();
        return System.schedule((Test.isRunningTest() ? ('BIT_FinalizarVisitas' + System.now()) : 'BIT_FinalizarVisitas'), CRON_EXPR, job);
    }


    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BIT_finalizarVisitas_bch(),50);
    }

    public static void unSchedule(String name) {
        for (CronTrigger ct : [select Id,CronExpression from CronTrigger where CronJobDetail.Name like :(name+'%')] )  System.abortJob(ct.Id);
    }
}