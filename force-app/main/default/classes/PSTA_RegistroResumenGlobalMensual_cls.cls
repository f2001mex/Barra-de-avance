/*******************************************************************************
* Developed by      :   Actinver Mexico
* Author            :   Francisco Ortega
* Project           :   Post venta
* Clase test        :   PSTA_RegistroResumenGlobalMensual_cls_Test
* Description       :   Helper para generar resumen global diario por asesor
*                       preservando Contactados__c del dia y calculando Meta__c
*                       diaria, MetaMensual__c y PorcentajeAvanceMensual__c.
*-------------------------------------------------------------------------- 
* No.            Date              Author                    Description
* 1.0         15-Apr-2026       Francisco Ortega            Creacion
*-------------------------------------------------------------------------- 
*******************************************************************************/
public without sharing class PSTA_RegistroResumenGlobalMensual_cls {

    public static final Id idConfigContactoPostVentaRecordType =
        Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ContactoPostventa').getRecordTypeId();
    @TestVisible private static Integer testOverrideBusinessDaysInMonth;
    @TestVisible private static Date testOverrideTargetDate;

    public static Date getTargetDate() {
        return testOverrideTargetDate != null ? testOverrideTargetDate : System.today();
    }

    public static String buildDailyExternalId(String advisorId, Date targetDate) {
        if (String.isBlank(advisorId) || targetDate == null) {
            return null;
        }

        String monthValue = targetDate.month() < 10 ? '0' + String.valueOf(targetDate.month()) : String.valueOf(targetDate.month());
        String dayValue = targetDate.day() < 10 ? '0' + String.valueOf(targetDate.day()) : String.valueOf(targetDate.day());
        return advisorId + '_' + String.valueOf(targetDate.year()) + monthValue + dayValue;
    }

    public static Integer getBusinessDaysInMonth(Date targetDate) {
        if (testOverrideBusinessDaysInMonth != null) {
            return testOverrideBusinessDaysInMonth;
        }

        Id businessHoursId = PSTA_PriorizacionSelector_cls.getDiasLaborales();
        if (businessHoursId == null) {
            return 0;
        }

        Date monthStart = Date.newInstance(targetDate.year(), targetDate.month(), 1);
        Date nextMonthStart = monthStart.addMonths(1);
        Integer totalBusinessDays = 0;

        for (Date currentDate = monthStart; currentDate < nextMonthStart; currentDate = currentDate.addDays(1)) {
            Datetime currentDatetime = Datetime.newInstance(currentDate, Time.newInstance(12, 0, 0, 0));
            if (BusinessHours.isWithin(businessHoursId, currentDatetime)) {
                totalBusinessDays++;
            }
        }

        return totalBusinessDays;
    }

    public static Map<String, Integer> getDailyGoalBySegment() {
        Map<String, Integer> dailyGoalBySegment = new Map<String, Integer>();

        for (ConfiguracionActinver__c config : [
            SELECT Segmento__c, ClientesContactarPorDia__c
            FROM ConfiguracionActinver__c
            WHERE RecordTypeId = :idConfigContactoPostVentaRecordType
                AND ClientesContactarPorDia__c != null
        ]) {
            if (String.isNotBlank(config.Segmento__c)) {
                dailyGoalBySegment.put(config.Segmento__c.trim(), Integer.valueOf(config.ClientesContactarPorDia__c));
            }
        }

        return dailyGoalBySegment;
    }

    public static Map<String, Integer> getEligiblePortfolioCountByAdvisor(List<String> advisorIds) {
        Map<String, Integer> eligiblePortfolioByAdvisor = new Map<String, Integer>();
        if (advisorIds == null || advisorIds.isEmpty()) {
            return eligiblePortfolioByAdvisor;
        }

        ConfiguracionActinver__c contractConfig = PSTA_SegmentacionClientesSelector_cls.getConfiguracionContratosPostventa();
        Set<String> validContractTypes = PSTA_UtilityClass.splitValuesMultiPickList(contractConfig.TipoContratos__c);
        Set<String> validContractStatuses = PSTA_UtilityClass.splitValuesMultiPickList(contractConfig.EstatusContrato__c);

        if (validContractTypes.isEmpty() || validContractStatuses.isEmpty()) {
            return eligiblePortfolioByAdvisor;
        }

        for (AggregateResult result : [
            SELECT Account.ID_Asesor__c advisorId, COUNT_DISTINCT(AccountId) totalAccounts
            FROM Contract
            WHERE AccountId != null
                AND Account.ID_Asesor__c IN :advisorIds
                AND Account.ID_Asesor__c != null
                AND TypeOfContract__c IN :validContractTypes
                AND Status__c IN :validContractStatuses
            GROUP BY Account.ID_Asesor__c
        ]) {
            eligiblePortfolioByAdvisor.put(
                (String) result.get('advisorId'),
                (Integer) result.get('totalAccounts')
            );
        }

        return eligiblePortfolioByAdvisor;
    }

    public static Map<String, String> getUserIds() {
        return PSTA_RegistroResumenGlobal_cls.getUserIds();
    }

    public static Map<String, ResumenGlobalPostventa__c> getDailySummariesByExternalId(Set<String> dailyExternalIds) {
        Map<String, ResumenGlobalPostventa__c> summariesByExternalId = new Map<String, ResumenGlobalPostventa__c>();
        if (dailyExternalIds == null || dailyExternalIds.isEmpty()) {
            return summariesByExternalId;
        }

        for (ResumenGlobalPostventa__c summary : [
            SELECT Id, Name, Banker__c, OwnerId, ExternalId_Nomina__c, ExternalId_NominaFecha__c, Fecha__c,
                   Contactados__c, ContactadosMensual__c, Meta__c, MetaMensual__c, PorcentajeAvanceMensual__c
            FROM ResumenGlobalPostventa__c
            WHERE ExternalId_NominaFecha__c IN :dailyExternalIds
            ORDER BY CreatedDate DESC
        ]) {
            if (!summariesByExternalId.containsKey(summary.ExternalId_NominaFecha__c)) {
                summariesByExternalId.put(summary.ExternalId_NominaFecha__c, summary);
            }
        }

        return summariesByExternalId;
    }

    public static Integer resolveMonthlyMeta(
        String advisorId,
        Banker banker,
        Map<String, Integer> dailyGoalBySegment,
        Map<String, Integer> eligiblePortfolioByAdvisor,
        Integer businessDaysInMonth
    ) {
        if (String.isBlank(advisorId) || banker == null) {
            return 0;
        }

        String bankerSegment = PSTA_Segmentacion_cls.determinarSegmento(banker);
        Integer dailyGoal = dailyGoalBySegment.containsKey(bankerSegment)
            ? dailyGoalBySegment.get(bankerSegment)
            : 0;
        Integer monthlyGoal = dailyGoal * businessDaysInMonth;
        Integer eligiblePortfolio = eligiblePortfolioByAdvisor.containsKey(advisorId)
            ? eligiblePortfolioByAdvisor.get(advisorId)
            : 0;

        return monthlyGoal < eligiblePortfolio ? monthlyGoal : eligiblePortfolio;
    }

    public static Integer resolveDailyGoal(Integer monthlyMeta, Integer businessDaysInMonth) {
        if (businessDaysInMonth == null || businessDaysInMonth <= 0 || monthlyMeta == null || monthlyMeta <= 0) {
            return 0;
        }

        Decimal result = Decimal.valueOf(monthlyMeta) / Decimal.valueOf(businessDaysInMonth);
        return Integer.valueOf(result.setScale(0, System.RoundingMode.CEILING));
    }

    public static Map<String, Decimal> getMonthlyContactCountByAdvisor(List<String> advisorIds, Date targetDate) {
        Map<String, Decimal> monthlyContactsByAdvisor = new Map<String, Decimal>();
        if (advisorIds == null || advisorIds.isEmpty()) {
            return monthlyContactsByAdvisor;
        }

        Date monthStart = Date.newInstance(targetDate.year(), targetDate.month(), 1);
        Date nextMonthStart = monthStart.addMonths(1);

        for (AggregateResult result : [
            SELECT ExternalId_Nomina__c advisorId, SUM(Contactados__c) totalContacts
            FROM ResumenGlobalPostventa__c
            WHERE ExternalId_Nomina__c IN :advisorIds
                AND Fecha__c >= :monthStart
                AND Fecha__c < :nextMonthStart
            GROUP BY ExternalId_Nomina__c
        ]) {
            monthlyContactsByAdvisor.put(
                (String) result.get('advisorId'),
                (Decimal) result.get('totalContacts')
            );
        }

        return monthlyContactsByAdvisor;
    }

    public static Decimal resolveMonthlyProgress(Integer monthlyMeta, Decimal monthlyContacts) {
        if (monthlyMeta == null || monthlyMeta <= 0) {
            return 0;
        }

        Decimal percentage = (monthlyContacts == null ? 0 : monthlyContacts) / monthlyMeta;
        return percentage > 1 ? 1 : percentage;
    }

    public static List<ResumenGlobalPostventa__c> buildDailySummaries(List<BranchUnitBusinessMember> scope) {
        List<ResumenGlobalPostventa__c> summariesToUpsert = new List<ResumenGlobalPostventa__c>();
        if (scope == null || scope.isEmpty()) {
            return summariesToUpsert;
        }

        List<String> advisorIds = new List<String>();
        for (BranchUnitBusinessMember member : scope) {
            Banker banker = (Banker) member.BusinessUnitMember;
            if (banker != null && String.isNotBlank(banker.ExternalId__c)) {
                advisorIds.add(banker.ExternalId__c);
            }
        }

        Date targetDate = getTargetDate();
        Integer businessDaysInMonth = getBusinessDaysInMonth(targetDate);
        Map<String, Integer> dailyGoalBySegment = getDailyGoalBySegment();
        Map<String, Integer> eligiblePortfolioByAdvisor = getEligiblePortfolioCountByAdvisor(advisorIds);
        Map<String, String> userIdsByAdvisor = getUserIds();
        Map<String, Decimal> monthlyContactsByAdvisor = getMonthlyContactCountByAdvisor(advisorIds, targetDate);
        Set<String> dailyExternalIds = new Set<String>();

        for (String advisorId : advisorIds) {
            dailyExternalIds.add(buildDailyExternalId(advisorId, targetDate));
        }

        Map<String, ResumenGlobalPostventa__c> existingSummariesByExternalId = getDailySummariesByExternalId(dailyExternalIds);

        for (BranchUnitBusinessMember member : scope) {
            Banker banker = (Banker) member.BusinessUnitMember;
            if (banker == null || String.isBlank(banker.ExternalId__c)) {
                continue;
            }

            String advisorId = banker.ExternalId__c;
            Integer monthlyMeta = resolveMonthlyMeta(
                advisorId,
                banker,
                dailyGoalBySegment,
                eligiblePortfolioByAdvisor,
                businessDaysInMonth
            );
            Integer dailyMeta = resolveDailyGoal(monthlyMeta, businessDaysInMonth);
            Decimal monthlyProgress = resolveMonthlyProgress(
                monthlyMeta,
                monthlyContactsByAdvisor.get(advisorId)
            );
            String dailyExternalId = buildDailyExternalId(advisorId, targetDate);

            ResumenGlobalPostventa__c existingSummary = existingSummariesByExternalId.get(dailyExternalId);
            ResumenGlobalPostventa__c summaryRecord = existingSummary != null
                ? new ResumenGlobalPostventa__c(Id = existingSummary.Id)
                : new ResumenGlobalPostventa__c();

            summaryRecord.Name = banker.Name + ' - ' + String.valueOf(targetDate);
            summaryRecord.Fecha__c = targetDate;
            summaryRecord.Banker__c = member.Id;
            summaryRecord.ExternalId_Nomina__c = advisorId;
            summaryRecord.ExternalId_NominaFecha__c = dailyExternalId;
            summaryRecord.Meta__c = dailyMeta;
            summaryRecord.MetaMensual__c = monthlyMeta;
            summaryRecord.ContactadosMensual__c = monthlyContactsByAdvisor.containsKey(advisorId)
                ? monthlyContactsByAdvisor.get(advisorId)
                : 0;
            summaryRecord.PorcentajeAvanceMensual__c = monthlyProgress;
            summaryRecord.Contactados__c = existingSummary != null && existingSummary.Contactados__c != null
                ? existingSummary.Contactados__c
                : 0;

            if (userIdsByAdvisor.containsKey(advisorId)) {
                summaryRecord.OwnerId = userIdsByAdvisor.get(advisorId);
            }

            summariesToUpsert.add(summaryRecord);
        }

        return summariesToUpsert;
    }

    public static void saveDailySummaries(List<ResumenGlobalPostventa__c> records) {
        if (records == null || records.isEmpty()) {
            return;
        }

        Map<String, String> errorsByRecord = new Map<String, String>();
        Database.UpsertResult[] upsertResults = Database.upsert(records, ResumenGlobalPostventa__c.ExternalId_NominaFecha__c, false);

        for (Integer index = 0; index < upsertResults.size(); index++) {
            Database.UpsertResult result = upsertResults[index];
            if (result.isSuccess()) {
                continue;
            }

            errorsByRecord.clear();
            Integer errorIndex = 0;
            for (Database.Error error : result.getErrors()) {
                errorsByRecord.put('Error' + errorIndex, error.getMessage());
                errorIndex++;
            }
            errorsByRecord.put('Registro', JSON.serialize(records[index]));

            PSTA_RegistroResumenGlobal_cls.saveLogError(
                new Map<String, String>(errorsByRecord),
                'Error durante la creacion del resumen global mensual diario',
                'ERROR_BATCH_RESUMENES_MENSUAL_001',
                ''
            );
        }
    }
}
