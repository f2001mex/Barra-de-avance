public with sharing class PSTA_AntiChurnDashboard_ctr {

    private static final String RESULT_POSITIVE = 'Contactado Retenido';
    private static final String RESULT_NEGATIVE = 'Contactado No Retenido';
    private static final String RESULT_NO_CONTACT = 'Cliente no responde';
    private static final String RESULT_PENDING = 'Pendiente';
    private static final String REPORT_FOLDER_NAME = 'Anti Churn';

    public class MotivoSlice {
        @AuraEnabled public String label;
        @AuraEnabled public Integer count;
        @AuraEnabled public Decimal percentage;
    }

    public class DashboardResponse {
        @AuraEnabled public Date generatedDate;
        @AuraEnabled public Integer totalPilotClients;
        @AuraEnabled public Integer totalActivities;
        @AuraEnabled public Integer highRiskClientsWithActivity;
        @AuraEnabled public Decimal highRiskAssignedPct;
        @AuraEnabled public Integer positiveActivities;
        @AuraEnabled public Integer negativeActivities;
        @AuraEnabled public Integer noContactActivities;
        @AuraEnabled public Integer pendingActivities;
        @AuraEnabled public Decimal avgContactDays;
        @AuraEnabled public Decimal effectiveContactRate;
        @AuraEnabled public Decimal churnVariationPct;
        @AuraEnabled public String pilotPopulationDefinition;
        @AuraEnabled public Id highRiskReportId;
        @AuraEnabled public Id activitiesReportId;
        @AuraEnabled public List<MotivoSlice> motivoFuga;
    }

    @AuraEnabled(cacheable=true)
    public static DashboardResponse getDashboardData() {
        Id antiChurnRecordTypeId = getAntiChurnTaskRecordTypeId();

        DashboardResponse response = new DashboardResponse();
        response.generatedDate = System.today();
        response.pilotPopulationDefinition =
            'Clientes del piloto = cuentas distintas con actividad Anti-Churn abierta y AccountId informado.';
        response.totalPilotClients = getDistinctAccountCount(antiChurnRecordTypeId, null);
        response.totalActivities = getTaskCount(antiChurnRecordTypeId);
        response.highRiskClientsWithActivity = getDistinctAccountCount(antiChurnRecordTypeId, 'Alto');
        response.highRiskAssignedPct = calculatePercentage(
            response.highRiskClientsWithActivity,
            response.totalPilotClients
        );

        Map<String, Integer> countsByResult = getCountsByResult(antiChurnRecordTypeId);
        response.positiveActivities = countsByResult.get(RESULT_POSITIVE);
        response.negativeActivities = countsByResult.get(RESULT_NEGATIVE);
        response.noContactActivities = countsByResult.get(RESULT_NO_CONTACT);
        response.pendingActivities = countsByResult.get(RESULT_PENDING);
        response.avgContactDays = getAverageContactDays(antiChurnRecordTypeId);
        response.effectiveContactRate = calculatePercentage(
            response.positiveActivities + response.negativeActivities,
            response.totalPilotClients
        );

        // Requirement provided as generated / retained * 100.
        response.churnVariationPct = calculatePercentage(
            response.totalActivities,
            response.positiveActivities
        );
        response.motivoFuga = getMotivoSlices(antiChurnRecordTypeId);

        Map<String, Id> reportIdsByDeveloperName = getReportIdsByDeveloperName(new Set<String>{
            'Clientes_con_alto_riesgo_de_fuga_hh1',
            'Clientes_con_alto_riesgo_de_fuga_ANM'
        });
        response.highRiskReportId = reportIdsByDeveloperName.get('Clientes_con_alto_riesgo_de_fuga_hh1');
        response.activitiesReportId = reportIdsByDeveloperName.get('Clientes_con_alto_riesgo_de_fuga_ANM');
        return response;
    }

    private static Id getAntiChurnTaskRecordTypeId() {
        return [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Task'
                AND DeveloperName = 'Anti_Churn'
            LIMIT 1
        ].Id;
    }

    private static Integer getDistinctAccountCount(Id recordTypeId, String riskLevel) {
        AggregateResult[] results;
        if (String.isBlank(riskLevel)) {
            results = [
                SELECT COUNT_DISTINCT(AccountId) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND IsClosed = false
                    AND AccountId != null
            ];
        } else {
            results = [
                SELECT COUNT_DISTINCT(AccountId) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND IsClosed = false
                    AND AccountId != null
                    AND Account.Indicador_de_Riesgo_Churn__c = :riskLevel
            ];
        }

        return toInteger(results[0].get('total'));
    }

    private static Integer getTaskCount(Id recordTypeId) {
        AggregateResult[] results = [
            SELECT COUNT(Id) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND IsClosed = false
                AND AccountId != null
        ];

        return toInteger(results[0].get('total'));
    }

    private static Map<String, Integer> getCountsByResult(Id recordTypeId) {
        Map<String, Integer> counts = new Map<String, Integer>{
            RESULT_POSITIVE => 0,
            RESULT_NEGATIVE => 0,
            RESULT_NO_CONTACT => 0,
            RESULT_PENDING => 0
        };

        for (AggregateResult groupedResult : [
            SELECT Resultado_de_Gestion__c resultValue, COUNT(Id) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND IsClosed = false
                AND AccountId != null
            GROUP BY Resultado_de_Gestion__c
        ]) {
            String resultValue = (String) groupedResult.get('resultValue');
            if (counts.containsKey(resultValue)) {
                counts.put(resultValue, toInteger(groupedResult.get('total')));
            }
        }

        return counts;
    }

    private static Decimal getAverageContactDays(Id recordTypeId) {
        AggregateResult[] results = [
            SELECT AVG(Tiempo_promedio_de_contacto_CHURN__c) averageDays
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND IsClosed = false
                AND AccountId != null
                AND Tiempo_promedio_de_contacto_CHURN__c != null
        ];

        return toDecimal(results[0].get('averageDays'));
    }

    private static List<MotivoSlice> getMotivoSlices(Id recordTypeId) {
        List<AggregateResult> groupedResults = [
            SELECT Motivo_de_fuga__c reason, COUNT(Id) total
            FROM Task
            WHERE RecordTypeId = :recordTypeId
                AND IsClosed = false
                AND AccountId != null
                AND Motivo_de_fuga__c != null
            GROUP BY Motivo_de_fuga__c
            ORDER BY COUNT(Id) DESC, Motivo_de_fuga__c ASC
        ];

        Integer totalMotivos = 0;
        for (AggregateResult groupedResult : groupedResults) {
            totalMotivos += toInteger(groupedResult.get('total'));
        }

        List<MotivoSlice> slices = new List<MotivoSlice>();
        for (AggregateResult groupedResult : groupedResults) {
            MotivoSlice slice = new MotivoSlice();
            slice.label = (String) groupedResult.get('reason');
            slice.count = toInteger(groupedResult.get('total'));
            slice.percentage = calculatePercentage(slice.count, totalMotivos);
            slices.add(slice);
        }

        return slices;
    }

    private static Map<String, Id> getReportIdsByDeveloperName(Set<String> developerNames) {
        Map<String, Id> results = new Map<String, Id>();
        for (Report reportRecord : [
            SELECT Id, DeveloperName
            FROM Report
            WHERE FolderName = :REPORT_FOLDER_NAME
                AND DeveloperName IN :developerNames
        ]) {
            results.put(reportRecord.DeveloperName, reportRecord.Id);
        }

        return results;
    }

    private static Integer toInteger(Object value) {
        if (value == null) {
            return 0;
        }

        return Integer.valueOf(String.valueOf(value));
    }

    private static Decimal toDecimal(Object value) {
        if (value == null) {
            return 0;
        }

        return Decimal.valueOf(String.valueOf(value)).setScale(2);
    }

    private static Decimal calculatePercentage(Decimal numerator, Decimal denominator) {
        if (denominator == null || denominator <= 0) {
            return 0;
        }

        Decimal safeNumerator = numerator == null ? 0 : numerator;
        return ((safeNumerator / denominator) * 100).setScale(2);
    }
}
