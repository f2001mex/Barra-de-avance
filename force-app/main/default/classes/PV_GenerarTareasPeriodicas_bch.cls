/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test    :   PV_GenerarTareasPeriodicas_bch_tst
* Description       :   Batch para crear nuevas tareas por periodicidad.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         19-Jun-2025       Martín Martínez              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
global class PV_GenerarTareasPeriodicas_bch implements Database.Batchable<sObject>, Database.Stateful{
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(PV_GenerarTareasPeriodicasSelector_cls.getQueryAccounts());
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        // Convertir el scope a lista tipada
        List<Account> lstAccount = PV_GenerarTareasPeriodicas.obtenerCuentasValidas(scope);
        
        if (lstAccount.isEmpty()) {
            System.debug('No se encontraron clientes a procesar para procesar.');
            return;
        }

        // Obtener cadencia
        List<ActionCadence> lstCadence = PV_GenerarTareasPeriodicasSelector_cls.getCadence();

        if (lstCadence.isEmpty() && !Test.isRunningTest()) {
            System.debug('No se encontraron cadencias para procesar.');
            return;
        }

        // Crear mapas de referencia
        Map<String, Object> mapReferences = PV_GenerarTareasPeriodicas.createMapsToReference(lstAccount);

        // Obtener mapa de banqueros por cuenta
        Map<Id, Id> mapBankerAccount = PV_GenerarTareasPeriodicas.getMapBankerAccount(
            (Set<Id>) mapReferences.get('setBMemberId'),
            (Map<Id, List<Id>>) mapReferences.get('mapAccount')
        );        

        // Generar request a partir de las cadencias y cuentas
        PV_GenerarTareasPeriodicas.generarRequestCadence(
            lstCadence,
            lstAccount,
            mapBankerAccount
        );
    }


    public void finish(Database.BatchableContext BC) {
        System.debug('Finaliza el batch de tareas.');
        
    }

}