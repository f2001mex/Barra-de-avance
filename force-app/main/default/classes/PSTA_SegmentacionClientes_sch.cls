/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_SegmentacionClientes_sch_tst
* Description       :   Clase exclusiva para la periodicidad de la segmentacion de clientes
*--------------------------------------------------------------------------
* No.            Date              Author             Description
* 1.0         06-Jun-2025       Canche Isaac           Creación
*--------------------------------------------------------------------------
*******************************************************************************/
global class PSTA_SegmentacionClientes_sch implements Schedulable {
    
    global void execute(SchedulableContext sc) {

        Id batchJobId = Database.executeBatch(new PSTA_SegmentacionClientes_bch(),Integer.valueOf(System.Label.PSTA_Segmentacion_Registros_Batch));
    }
    
}