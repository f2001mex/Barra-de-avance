/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test        :   PSTA_ResetearEstatusContacto_sch_tst
* Description       :   Clase exclusiva para el reinicio de estatus de contacto de clientes
*-------------------------------------------------------------------------- 
* No.            Date              Author                Description
* 1.0         16-Jul-2025       Canche Isaac             Creación
* 1.1         20-Jan-2026       Francisco Ortega         Ejecución de BusinessHours vía ACT_PSTA_BusinessHoursHelper_cls
*-------------------------------------------------------------------------- 
*******************************************************************************/
global class PSTA_ResetearEstatusContacto_sch implements Schedulable {

    global void execute(SchedulableContext sc) {

        ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
            'PSTA_ResetearEstatusContacto',                        // DeveloperName en ACT_BatchConfig__mdt
            new PSTA_ResetearEstatusContacto_bch(),                // Batch original
            Integer.valueOf(System.Label.PSTA_Reinicio_Estatus_Registros)
        );
    }
}