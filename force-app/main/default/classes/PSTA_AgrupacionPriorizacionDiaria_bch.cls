/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_SegmentacionClientes_bch_tst
* Description       :   Clase para agrupar los clientes con asesores para la priorizacion diaria.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         09-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
global class PSTA_AgrupacionPriorizacionDiaria_bch implements Database.Batchable<sObject>, Database.Stateful{
    global Map<Id, Integer> mapAsesorPorNumCuentas;
    global Map<String, ConfiguracionActinver__c> mapConfigPorSegmento; 

    global PSTA_AgrupacionPriorizacionDiaria_bch() {
        this.mapAsesorPorNumCuentas = new Map<Id, Integer>();
        this.mapConfigPorSegmento   = PSTA_PriorizacionDiaria_cls.obtenerSegmentoPorConfig();
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionDiaria());
    }

    global void execute(Database.BatchableContext BC, List<Account> lstClientes) {
        System.debug('mapAsesorPorNumCuentas en BATCH: ' + mapAsesorPorNumCuentas);
        Account[] lstClientesActualizar = new List<Account>();
        Map<String,Object> response  = PSTA_PriorizacionDiaria_cls.agrupacionBanqueroPorCuentas(lstClientes,this.mapConfigPorSegmento,this.mapAsesorPorNumCuentas);
        lstClientesActualizar = (List<Account>)response.get('lstCuentasParaActualizar');
        this.mapAsesorPorNumCuentas = ( Map<Id, Integer> )response.get('mapAsesorPorNumCuentas');

        System.debug('lstClientesActualizar: ' + lstClientesActualizar.size());
        if(!lstClientesActualizar.isEmpty()) PSTA_PriorizacionDiaria_cls.updateRecords(lstClientesActualizar);
    }

    global void finish(Database.BatchableContext BC) {
       System.debug('finalizó ejecución batch PSTA_AgrupacionPriorizacionDiaria_bch');
       System.debug('mapAsesorPorNumCuentas: ' + mapAsesorPorNumCuentas);
    }
}