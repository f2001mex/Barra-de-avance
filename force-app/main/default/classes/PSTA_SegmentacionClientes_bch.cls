/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_SegmentacionClientes_bch_tst
* Description       :   Batch para la segmentacion de clientes.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         09-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
global class PSTA_SegmentacionClientes_bch implements Database.Batchable<sObject>{
    global static ConfiguracionActinver__c config = PSTA_SegmentacionClientesSelector_cls.getConfiguracionContratosPostventa();
    public Database.QueryLocator start(Database.BatchableContext BC) {


        return Database.getQueryLocator(PSTA_SegmentacionClientesSelector_cls.getQueryCuentas());
    }

    public void execute(Database.BatchableContext BC, List<Account> scope) {
        System.debug('#### PSTA_SegmentacionClientes_bch[execute]: '+scope.size());
        String[] setStatusValidos  = config.EstatusContrato__c.split(';');
        String[] setTipoContratoValidos   = config.TipoContratos__c.split(';');
        List<Account> lstClientes  = [SELECT Id, 
                                        FechaUltimoContacto__c,
                                        FechaUltimaVisita__c,
                                        BanqueroAsignado__c, 
                                        SaldoIntegral__c, 
                                        Segmento__c, 
                                        (SELECT Id, Status__c, AccountOpeningDate__c, TypeOfContract__c, Saldo__c 
                                        FROM Contracts 
                                        WHERE Status__c IN :setStatusValidos AND TypeOfContract__c IN :setTipoContratoValidos AND Saldo__c != null AND AccountOpeningDate__c != null ORDER BY AccountOpeningDate__c ASC), 
                                        TYPEOF BanqueroAsignado__r.BusinessUnitMember 
                                        WHEN Banker THEN Division__c, ExternalId__c, Id, Cargo__c 
                                        END
                                    FROM Account 
                                    WHERE Id IN :scope];

        List<Account> lstClientesToUpdate = PSTA_SegmentacionClientes_cls.segmentacionClientes(lstClientes);

        if (!lstClientesToUpdate.isEmpty()) {
            PSTA_SegmentacionClientes_cls.updateRecords(lstClientesToUpdate);
        } 
    }

    public void finish(Database.BatchableContext BC) {
        PSTA_AgrupacionPriorizacionMensual_bch batch = new PSTA_AgrupacionPriorizacionMensual_bch();
        if(!Test.isRunningTest()) Database.executeBatch(batch);
    }
}