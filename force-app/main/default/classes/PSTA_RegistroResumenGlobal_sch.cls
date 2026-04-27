/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test        :   PSTA_RegistroResumenGlobal_sch_tst
* Description       :   Clase exclusiva para el registro de resumen global
*-------------------------------------------------------------------------- 
* No.            Date              Author                    Description
* 1.0         16-Jul-2025       Canche Isaac                 Creación
* 1.1         20-Jan-2026       Francisco Ortega             Ejecución de BusinessHours vía ACT_PSTA_BusinessHoursHelper_cls
*-------------------------------------------------------------------------- 
*******************************************************************************/
global class PSTA_RegistroResumenGlobal_sch implements Schedulable {

    global void execute(SchedulableContext sc) {

        ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
            'PSTA_RegistroResumenGlobal',
            new PSTA_RegistroResumenGlobal_bch(),
            Integer.valueOf(System.Label.PSTA_Resumen_Global_Registros)
        );
    }
}