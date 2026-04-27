/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Gallegos Alan
* Project           :   Post venta
* Clase test    :   
* Description       :   Batch para la creación y actualización del objeto Resumen
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         24-Jun-2025       Gallegos Alan              Creación
*--------------------------------------------------------------------------
*******************************************************************************/

global class PSTA_RegistroResumenGlobal_bch implements Database.Batchable<sObject>{

    public List<BranchUnitBusinessMember> start(Database.BatchableContext BC) {
        String query;
        if (Test.isRunningTest()) {
            query = 'SELECT Id, Name, BusinessUnitMemberId, TYPEOF BusinessUnitMember WHEN Banker THEN Division__c, Cargo__c, ExternalId__c, Id, Name END FROM BranchUnitBusinessMember WHERE ExternalId__c != null';
        }else {
            query = PSTA_SegmentacionClientesSelector_cls.getQueryAllBBM();
        }
        return Database.query(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        
        List<BranchUnitBusinessMember> lstAllBBM    = (List<BranchUnitBusinessMember>) scope;
        List<String> lstBanqueros                   = new List<String>();
        
        System.debug('Lista de todos los BBM : '  + lstAllBBM);
        
        for (BranchUnitBusinessMember branchUnitBusinessMember : lstAllBBM) {
            Banker banquero = (Banker) branchUnitBusinessMember.BusinessUnitMember;
            lstBanqueros.add(banquero.ExternalId__c);
        }
        
        List<ResumenGlobalPostventa__c> lstResumenesUpsert = new List<ResumenGlobalPostventa__c>();
        
        Map<String, Integer> mapAsesorByMeta    = PSTA_RegistroResumenGlobal_cls.getMetaByAccount(lstBanqueros);
        Map<String, SObject> mapResExistentes   = PSTA_RegistroResumenGlobal_cls.getResumenesActuales();
        Map<String,String> mapaUserIds          = PSTA_RegistroResumenGlobal_cls.getUserIds();
        

        for(BranchUnitBusinessMember registroAsesor : lstAllBBM) {
            Banker banquero = (Banker) registroAsesor.BusinessUnitMember;

            Integer intMetaAsesor = mapAsesorByMeta.get(banquero.ExternalId__c);
            
            ResumenGlobalPostventa__c resumen = new ResumenGlobalPostventa__c();
            resumen.Name         = banquero.Name;
            resumen.Fecha__c     = System.today();
            resumen.Banker__c    = registroAsesor.Id;
            resumen.OwnerId      = mapaUserIds.containsKey(banquero.ExternalId__c) ? mapaUserIds.get(banquero.ExternalId__c) : null;
            resumen.ExternalId_Nomina__c = banquero.ExternalId__c;
            resumen.Contactados__c = 0;
            resumen.Meta__c = intMetaAsesor;
            
            lstResumenesUpsert.add(resumen);
            
        }

        PSTA_RegistroResumenGlobal_cls.upsertRecords(lstResumenesUpsert);

    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Batch objeto resumen finalizado');
    }
}