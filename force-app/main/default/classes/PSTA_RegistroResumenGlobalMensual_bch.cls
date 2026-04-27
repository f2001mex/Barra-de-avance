/*******************************************************************************
* Developed by      :   Actinver Mexico
* Author            :   Francisco Ortega
* Project           :   Post venta
* Clase test        :   PSTA_RegistroResumenGlobalMensual_bch_Test
* Description       :   Batch para crear/actualizar el resumen global diario
*                       con meta mensual proyectada.
*-------------------------------------------------------------------------- 
* No.            Date              Author                    Description
* 1.0         15-Apr-2026       Francisco Ortega            Creacion
*-------------------------------------------------------------------------- 
*******************************************************************************/
global class PSTA_RegistroResumenGlobalMensual_bch implements Database.Batchable<SObject> {

    public List<BranchUnitBusinessMember> start(Database.BatchableContext bc) {
        String query;
        if (Test.isRunningTest()) {
            query = 'SELECT Id, Name, BusinessUnitMemberId, TYPEOF BusinessUnitMember WHEN Banker THEN Division__c, Cargo__c, ExternalId__c, Id, Name END FROM BranchUnitBusinessMember WHERE ExternalId__c != null';
        } else {
            query = PSTA_SegmentacionClientesSelector_cls.getQueryAllBBM();
        }
        return Database.query(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<BranchUnitBusinessMember> branchMembers = (List<BranchUnitBusinessMember>) scope;
        List<ResumenGlobalPostventa__c> summariesToUpsert =
            PSTA_RegistroResumenGlobalMensual_cls.buildDailySummaries(branchMembers);
        PSTA_RegistroResumenGlobalMensual_cls.saveDailySummaries(summariesToUpsert);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch objeto resumen global mensual diario finalizado');
    }
}
