/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Gallegos Alan
* Project           :   Post venta
* Clase test    :   
* Description       :   Batch para el reseteo de estatus de contacto
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         16-Jun-2025       Gallegos Alan          Creación
* 2.0         15-Jul-2025       Gallegos Alan          Se agrega el reset de las banderas de contacto diario
*--------------------------------------------------------------------------
*******************************************************************************/

global class PSTA_ResetearEstatusContacto_bch implements Database.Batchable<sObject>{

    //Se obtiene la lista de cuentas por banker
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(PSTA_SegmentacionClientesSelector_cls.getQueryStatusCuentas());
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        
        List<Account> lstClientes = (List<Account>) scope;

        //Se manda la lista de cuentas por resetear.
        Map<Id,Account> lstClientesToUpdate = PSTA_ResetearEstatusContacto_cls.resetEstatus(lstClientes);

        //Si se tienen cuentas para actualizar, se ejecuta el update.
        if (!lstClientesToUpdate.values().isEmpty()) {
            PSTA_ResetearEstatusContacto_cls.updateRecords(lstClientesToUpdate.values(), lstClientesToUpdate);
        } 
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Batch reinicio estatus finalizado');
        PSTA_AgrupacionPriorizacionDiaria_bch newBchAPD = new PSTA_AgrupacionPriorizacionDiaria_bch();
        Database.executeBatch(newBchAPD);
    }
}