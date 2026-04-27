/*******************************************************************************
* Developed by      :   Actinver Mexico
* Author            :   Francisco Ortega
* Project           :   Post venta
* Clase test        :   PSTA_RegistroResumenGlobalMensual_sch_tst
* Description       :   Scheduler para el resumen global mensual diario.
*-------------------------------------------------------------------------- 
* No.            Date              Author                    Description
* 1.0         15-Apr-2026       Francisco Ortega            Creacion
*-------------------------------------------------------------------------- 
*******************************************************************************/
global class PSTA_RegistroResumenGlobalMensual_sch implements Schedulable {

    global void execute(SchedulableContext sc) {
        ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
            'PSTA_RegistroResumenGlobal',
            new PSTA_RegistroResumenGlobalMensual_bch(),
            Integer.valueOf(System.Label.PSTA_Resumen_Global_Registros)
        );
    }
}
