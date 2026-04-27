public with sharing class PSTA_MetaMensualDashboard_ctr {

    public class DashboardRow {
        @AuraEnabled public Id summaryId;
        @AuraEnabled public Id ownerId;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String centroFinanciero;
        @AuraEnabled public Decimal metaDiaria;
        @AuraEnabled public Decimal metaMensual;
        @AuraEnabled public Decimal contactadosHoy;
        @AuraEnabled public Decimal contactadosMensual;
        @AuraEnabled public Decimal porcentajeDiario;
        @AuraEnabled public Decimal porcentajeMensual;
    }

    public class DashboardResponse {
        @AuraEnabled public Date targetDate;
        @AuraEnabled public Decimal metaDiariaTotal;
        @AuraEnabled public Decimal metaMensualTotal;
        @AuraEnabled public Decimal contactadosHoyTotal;
        @AuraEnabled public Decimal contactadosMensualTotal;
        @AuraEnabled public Decimal porcentajeDiarioTotal;
        @AuraEnabled public Decimal porcentajeMensualTotal;
        @AuraEnabled public Integer totalAsesores;
        @AuraEnabled public Id monthlyReportId;
        @AuraEnabled public Id detailReportId;
        @AuraEnabled public List<DashboardRow> rows;
    }

    @AuraEnabled(cacheable=true)
    public static DashboardResponse getDashboardData() {
        Date targetDate = System.today();
        List<ResumenGlobalPostventa__c> summaries = [
            SELECT Id, OwnerId, Owner.Name, CentroFinanciero__c,
                   Meta__c, MetaMensual__c, Contactados__c, ContactadosMensual__c
            FROM ResumenGlobalPostventa__c
            WHERE Fecha__c = :targetDate
            ORDER BY Owner.Name ASC, CentroFinanciero__c ASC
        ];

        DashboardResponse response = new DashboardResponse();
        response.targetDate = targetDate;
        response.rows = new List<DashboardRow>();

        Decimal metaDiariaTotal = 0;
        Decimal metaMensualTotal = 0;
        Decimal contactadosHoyTotal = 0;
        Decimal contactadosMensualTotal = 0;

        for (ResumenGlobalPostventa__c summary : summaries) {
            DashboardRow row = new DashboardRow();
            row.summaryId = summary.Id;
            row.ownerId = summary.OwnerId;
            row.ownerName = summary.Owner != null ? summary.Owner.Name : null;
            row.centroFinanciero = summary.CentroFinanciero__c;
            row.metaDiaria = summary.Meta__c != null ? summary.Meta__c : 0;
            row.metaMensual = summary.MetaMensual__c != null ? summary.MetaMensual__c : 0;
            row.contactadosHoy = summary.Contactados__c != null ? summary.Contactados__c : 0;
            row.contactadosMensual = summary.ContactadosMensual__c != null ? summary.ContactadosMensual__c : 0;
            row.porcentajeDiario = calculateProgress(row.contactadosHoy, row.metaDiaria);
            row.porcentajeMensual = calculateProgress(row.contactadosMensual, row.metaMensual);

            metaDiariaTotal += row.metaDiaria;
            metaMensualTotal += row.metaMensual;
            contactadosHoyTotal += row.contactadosHoy;
            contactadosMensualTotal += row.contactadosMensual;

            response.rows.add(row);
        }

        response.metaDiariaTotal = metaDiariaTotal;
        response.metaMensualTotal = metaMensualTotal;
        response.contactadosHoyTotal = contactadosHoyTotal;
        response.contactadosMensualTotal = contactadosMensualTotal;
        response.porcentajeDiarioTotal = calculateProgress(contactadosHoyTotal, metaDiariaTotal);
        response.porcentajeMensualTotal = calculateProgress(contactadosMensualTotal, metaMensualTotal);
        response.totalAsesores = response.rows.size();
        Map<String, Id> reportIdsByDeveloperName = getReportIdsByDeveloperName(new Set<String>{
            'Meta_mensual_resumen_global',
            'Resumen_Global_Diario_Mensual'
        });
        response.monthlyReportId = reportIdsByDeveloperName.get('Meta_mensual_resumen_global');
        response.detailReportId = reportIdsByDeveloperName.get('Resumen_Global_Diario_Mensual');
        return response;
    }

    private static Map<String, Id> getReportIdsByDeveloperName(Set<String> developerNames) {
        Map<String, Id> results = new Map<String, Id>();
        for (Report reportRecord : [
            SELECT Id, DeveloperName
            FROM Report
            WHERE FolderName = 'Postventa'
                AND DeveloperName IN :developerNames
        ]) {
            results.put(reportRecord.DeveloperName, reportRecord.Id);
        }

        return results;
    }

    private static Decimal calculateProgress(Decimal contactados, Decimal meta) {
        if (meta == null || meta <= 0) {
            return 0;
        }

        Decimal avance = (contactados == null ? 0 : contactados) / meta;
        if (avance > 1) {
            return 1;
        }

        return avance.setScale(4);
    }
}
