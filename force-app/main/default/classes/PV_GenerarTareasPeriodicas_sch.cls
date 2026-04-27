/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Martín Martínez
* Project           :   Post venta
* Clase test        :   PV_GenerarTareasPeriodicas_sch_tst
* Description       :   Clase exclusiva para la periodicidad de creación de tareas
*-------------------------------------------------------------------------- 
* No.            Date              Author                    Description
* 1.0         19-Jun-2025       Martín Martínez              Creación
* 1.1         20-Jan-2026       Francisco Ortega             Ejecución de BusinessHours vía ACT_PSTA_BusinessHoursHelper_cls
*-------------------------------------------------------------------------- 
*******************************************************************************/
global class PV_GenerarTareasPeriodicas_sch implements Schedulable {

    global void execute(SchedulableContext sc) {

        ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
            'PV_GenerarTareasPeriodicas',
            new PV_GenerarTareasPeriodicas_bch(),
            Integer.valueOf(Label.BatchCadencias_Size_Limit)
        );
    }
}