/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Yesica Navarro
* Project           :   Org. de Datos
* Clase test		:   
* Description       :   Clase exclusiva para la periodicidad de eliminación de Cuentas sin Contratos.
*--------------------------------------------------------------------------
* No.            Date              Author             Description
* 1.0         09-Dic-2024       Yesica Navarro          Creación
*--------------------------------------------------------------------------
*******************************************************************************/

global class OD_EliminarCuentasSinContrato_sch implements Schedulable{
    global void execute(SchedulableContext sc){
        executeBatch();
	}
    
 public static void executeBatch() {
    // Obtén el valor de la etiqueta personalizada
    Integer batchSize = Integer.valueOf(Label.Batch_Size_Limit);
    
    // Ejecuta el batch con el tamaño definido por la etiqueta
    Database.executeBatch(new OD_EliminarCuentasSinContrato_bch(), batchSize);
 }
}