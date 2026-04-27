/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Modelo de Gestión Empresarial
* Clase test		:   GE_FinalizarVisitas_sch_tst
* Description       :   Clase exclusiva para pocesar por lotes la actualizacion del estado de las visitas y finalizarlas
*--------------------------------------------------------------------------
* No.            Date              Author             Description
* 1.0         31-Jul-2024       Canche Isaac           Creación
* 2.0         10-Ene-2025       Ramirez Salvador       Optmización por métodos y restricción de llamado a envío de encuestas a visitas de clientes.
*--------------------------------------------------------------------------
*******************************************************************************/
global class BIT_FinalizarVisitas_bch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = System.Label.BIT_QueryFinalizacionVisitas;
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        Visita__c[] lstVisitas     = (List<Visita__c>) scope;
        Servicio__c[] lstServicios = new List<Servicio__c>();
        Set<Id> visitasIds = new Set<Id>();
        Set<Id> setIds     = new Set<Id>();
        Map<Id, String> mapVisitas = new Map<Id, String>();
        Map<Id, String> mapServicios = new Map<Id, String>();
        for (Visita__c objVisita : lstVisitas) {
            visitasIds.add(objVisita.Id);
            objVisita.Etapa__c               = 'Finalizado';
            objVisita.FinalizadaScheduler__c = true;
            objVisita.HoraSalida__c          = System.now();
            if(objVisita.RecordType.Name == 'Cliente') setIds.add(objVisita.Id);
            if(!mapVisitas.containsKey(objVisita.Id)) mapVisitas.put(objVisita.Id, objVisita.Name);
        }
        if(!visitasIds.isEmpty()) lstServicios = BIT_FinalizarVisitas_Helper.getServicios(visitasIds);
        for (Servicio__c servicio : lstServicios) {
            servicio.Etapa__c = 'Finalizado';
            servicio.FinalizadoScheduler__c = true;
            if(!mapServicios.containsKey(servicio.Id)) mapServicios.put(servicio.Id, servicio.Name);
        }

        if(!lstServicios.isEmpty()) BIT_FinalizarVisitas_Helper.updateRecords(lstServicios, mapServicios);
        BIT_FinalizarVisitas_Helper.updateRecords(lstVisitas, mapVisitas);
        if(!Test.isRunningTest()){
            System.Queueable job = new BIT_SendMedalliaSurvey_qbl(new map<String, Set<Id>>{'idVisita' => setIds});
            System.enqueueJob(job);
        }
    }

    public void finish(Database.BatchableContext BC) {
    }

}