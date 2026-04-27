/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_AgrupacionPriorizacionMensual_bch_tst
* Description       :   Batch para la priorizacion mensual de clientes.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         08-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
global class PSTA_AgrupacionPriorizacionMensual_bch implements Database.Batchable<sObject>{
    public Map<String, ConfiguracionActinver__c> mapConfigPorSegmento;
    public String strConditions;
    global PSTA_AgrupacionPriorizacionMensual_bch() {
        this.mapConfigPorSegmento = PSTA_PriorizacionMensual_cls.obtenerSegmentoPorConfig();
        this.strConditions = PSTA_PriorizacionMensual_cls.getClausuleQueryBySegmento(this.mapConfigPorSegmento);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionMensual(this.strConditions));
    }

    global void execute(Database.BatchableContext BC, List<Account> lstClientes) {
        System.debug('scope: ' + lstClientes);
        List<Account> lstClientesActualizar = PSTA_PriorizacionMensual_cls.agrupacionBanqueroPorCuentas(lstClientes, this.mapConfigPorSegmento);
        System.debug('Clientes a actualizar: ' + lstClientesActualizar);
        if(lstClientesActualizar.size() > 0) PSTA_PriorizacionMensual_cls.updateRecords(lstClientesActualizar);
    }

    global void finish(Database.BatchableContext BC) {

        /*PSTA_ProcesarPriorizacionMensual_bch batch = new PSTA_ProcesarPriorizacionMensual_bch(this.mapAsesorPorCuentas, this.mapConfigPorSegmento);
        Database.executeBatch(batch);*/
        System.debug('Finaliza batch PSTA_AgrupacionPriorizacionMensual_bch');
    }
}
/*global class PSTA_AgrupacionPriorizacionMensual_bch implements Database.Batchable<sObject>, Database.Stateful{
    
    public Map<Id, List<Account>> mapAsesorPorCuentas;
    public Map<String, ConfiguracionActinver__c> mapConfigPorSegmento; 

    global PSTA_AgrupacionPriorizacionMensual_bch() {
        this.mapAsesorPorCuentas = new Map<Id, List<Account>>();
        this.mapConfigPorSegmento = PSTA_PriorizacionMensual_cls.obtenerSegmentoPorConfig();
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return null;//Database.getQueryLocator(PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionMensual());
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Account> lstClientes = (List<Account>) scope;

        //PSTA_PriorizacionMensual_cls.agrupacionBanqueroPorCuentas(lstClientes, this.mapAsesorPorCuentas);
            
    }

    global void finish(Database.BatchableContext BC) {

        PSTA_ProcesarPriorizacionMensual_bch batch = new PSTA_ProcesarPriorizacionMensual_bch(this.mapAsesorPorCuentas, this.mapConfigPorSegmento);
        Database.executeBatch(batch);
    }
}*/