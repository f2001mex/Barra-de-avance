public without sharing class PSTA_RResumenMes_thr {

    @TestVisible private static Boolean bypassExecution = false;
    private static Boolean isExecuting = false;

    public static void afterUpsert(List<ResumenGlobalPostventa__c> newList) {
        if (bypassExecution || isExecuting || newList == null || newList.isEmpty()) {
            return;
        }

        List<ResumenGlobalPostventa__c> triggerCandidates = new List<ResumenGlobalPostventa__c>();
        Set<String> advisorIds = new Set<String>();
        Set<Date> recordDates = new Set<Date>();

        for (ResumenGlobalPostventa__c summaryRecord : newList) {
            if (summaryRecord.Id == null ||
                String.isBlank(summaryRecord.ExternalId_Nomina__c) ||
                summaryRecord.Fecha__c == null ||
                summaryRecord.MetaMensual__c == null) {
                continue;
            }

            triggerCandidates.add(summaryRecord);
            advisorIds.add(summaryRecord.ExternalId_Nomina__c);
            recordDates.add(summaryRecord.Fecha__c);
        }

        if (triggerCandidates.isEmpty()) {
            return;
        }

        Date minDate = null;
        Date maxDate = null;
        for (Date currentDate : recordDates) {
            minDate = minDate == null || currentDate < minDate ? currentDate : minDate;
            maxDate = maxDate == null || currentDate > maxDate ? currentDate : maxDate;
        }

        Map<String, Decimal> monthlyContactCountByAdvisorMonth = new Map<String, Decimal>();
        for (AggregateResult result : [
            SELECT ExternalId_Nomina__c advisorId,
                   CALENDAR_YEAR(Fecha__c) yearValue,
                   CALENDAR_MONTH(Fecha__c) monthValue,
                   SUM(Contactados__c) totalContacts
            FROM ResumenGlobalPostventa__c
            WHERE ExternalId_Nomina__c IN :advisorIds
                AND Fecha__c >= :Date.newInstance(minDate.year(), minDate.month(), 1)
                AND Fecha__c < :Date.newInstance(maxDate.year(), maxDate.month(), 1).addMonths(1)
            GROUP BY ExternalId_Nomina__c, CALENDAR_YEAR(Fecha__c), CALENDAR_MONTH(Fecha__c)
        ]) {
            String key = buildAdvisorMonthKey(
                (String) result.get('advisorId'),
                Integer.valueOf(String.valueOf(result.get('yearValue'))),
                Integer.valueOf(String.valueOf(result.get('monthValue')))
            );
            monthlyContactCountByAdvisorMonth.put(key, (Decimal) result.get('totalContacts'));
        }

        List<ResumenGlobalPostventa__c> summariesToUpdate = new List<ResumenGlobalPostventa__c>();
        for (ResumenGlobalPostventa__c summaryRecord : triggerCandidates) {
            String key = buildAdvisorMonthKey(
                summaryRecord.ExternalId_Nomina__c,
                summaryRecord.Fecha__c.year(),
                summaryRecord.Fecha__c.month()
            );
            Decimal monthlyContacts = monthlyContactCountByAdvisorMonth.containsKey(key)
                ? monthlyContactCountByAdvisorMonth.get(key)
                : 0;
            Decimal monthlyGoal = summaryRecord.MetaMensual__c != null ? summaryRecord.MetaMensual__c : 0;
            Decimal percentage = 0;

            if (monthlyGoal > 0) {
                percentage = monthlyContacts / monthlyGoal;
                if (percentage > 1) {
                    percentage = 1;
                }
            }

            summariesToUpdate.add(new ResumenGlobalPostventa__c(
                Id = summaryRecord.Id,
                ContactadosMensual__c = monthlyContacts,
                PorcentajeAvanceMensual__c = percentage
            ));
        }

        if (summariesToUpdate.isEmpty()) {
            return;
        }

        isExecuting = true;
        try {
            update summariesToUpdate;
        } finally {
            isExecuting = false;
        }
    }

    private static String buildAdvisorMonthKey(String advisorId, Integer yearValue, Integer monthValue) {
        return advisorId + '-' + String.valueOf(yearValue) + '-' + String.valueOf(monthValue);
    }
}
