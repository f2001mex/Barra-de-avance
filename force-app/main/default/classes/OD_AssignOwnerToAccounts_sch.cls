/**
* @File Name : OD_AssignOwnerToAccounts_sch.cls
* @Description : Clase programada para la ejecución de la asignación de cuentas
* @Author : Andrés Hernandez Rios
* @Last Modified By :
* @Last Modified On : December 9, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 9, 2024 | Andrés Hernández Ríos | Initial Version
**/
global class OD_AssignOwnerToAccounts_sch implements Schedulable {
    
    // ESTE ES EL MÉTODO QUE SE EJECUTARÁ CUANDO SE ACTIVE EL JOB PROGRAMADO
    global void execute(SchedulableContext SC) {
        // CREAR UNA INSTANCIA DEL BATCH
        OD_BatchAssignAccounts_bch batchAccounts = new OD_BatchAssignAccounts_bch();
        
        // EJECUTAR EL BATCH. 200 ES EL TAMAÑO DEL LOTE, PUEDE SER AJUSTADO SEGÚN LAS NECESIDADES.
        Database.executeBatch(batchAccounts, 200);
    }

}