Date startDate = Date.newInstance(2026, 4, 25);
Date endDate = Date.newInstance(2026, 4, 29);

Map<String, Schema.SObjectField> resumenFieldMap = Schema.SObjectType.ResumenGlobalPostventa__c.fields.getMap();
Boolean hasMetaMensual = resumenFieldMap.containsKey('metamensual__c');
Boolean hasContactadosMensual = resumenFieldMap.containsKey('contactadosmensual__c');
Boolean hasPorcentajeAvanceMensual = resumenFieldMap.containsKey('porcentajeavancemensual__c');

List<BranchUnitBusinessMember> branchMembers =
    (List<BranchUnitBusinessMember>) Database.query(PSTA_SegmentacionClientesSelector_cls.getQueryAllBBM());

Set<String> advisorIdSet = new Set<String>();
for (BranchUnitBusinessMember member : branchMembers) {
    Banker banker = (Banker) member.BusinessUnitMember;
    if (banker != null && String.isNotBlank(banker.ExternalId__c)) {
        advisorIdSet.add(banker.ExternalId__c);
    }
}

List<String> advisorIds = new List<String>(advisorIdSet);
Map<String, Integer> dailyGoalBySegment = PSTA_RegistroResumenGlobalMensual_cls.getDailyGoalBySegment();
Map<String, Integer> eligiblePortfolioByAdvisor = PSTA_RegistroResumenGlobalMensual_cls.getEligiblePortfolioCountByAdvisor(advisorIds);
Map<String, String> userIdsByAdvisor = PSTA_RegistroResumenGlobalMensual_cls.getUserIds();

System.debug('=== Recalculo retroactivo metas ===');
System.debug('Asesores considerados: ' + advisorIds.size());
System.debug('Rango: ' + String.valueOf(startDate) + ' a ' + String.valueOf(endDate));
System.debug('Campos mensuales detectados -> MetaMensual: ' + hasMetaMensual + ', ContactadosMensual: ' + hasContactadosMensual + ', PorcentajeAvanceMensual: ' + hasPorcentajeAvanceMensual);

for (Date targetDate = startDate; targetDate <= endDate; targetDate = targetDate.addDays(1)) {
    Integer businessDaysInMonth = PSTA_RegistroResumenGlobalMensual_cls.getBusinessDaysInMonth(targetDate);
    Map<String, Decimal> monthlyContactsByAdvisor =
        PSTA_RegistroResumenGlobalMensual_cls.getMonthlyContactCountByAdvisor(advisorIds, targetDate);

    Map<String, ResumenGlobalPostventa__c> existingByAdvisor = new Map<String, ResumenGlobalPostventa__c>();
    for (ResumenGlobalPostventa__c existing : [
        SELECT Id, ExternalId_Nomina__c, Contactados__c
        FROM ResumenGlobalPostventa__c
        WHERE ExternalId_Nomina__c IN :advisorIds
          AND Fecha__c = :targetDate
    ]) {
        existingByAdvisor.put(existing.ExternalId_Nomina__c, existing);
    }

    List<ResumenGlobalPostventa__c> toInsert = new List<ResumenGlobalPostventa__c>();
    List<ResumenGlobalPostventa__c> toUpdate = new List<ResumenGlobalPostventa__c>();

    for (BranchUnitBusinessMember member : branchMembers) {
        Banker banker = (Banker) member.BusinessUnitMember;
        if (banker == null || String.isBlank(banker.ExternalId__c)) {
            continue;
        }

        String advisorId = banker.ExternalId__c;
        Integer monthlyMeta = PSTA_RegistroResumenGlobalMensual_cls.resolveMonthlyMeta(
            advisorId,
            banker,
            dailyGoalBySegment,
            eligiblePortfolioByAdvisor,
            businessDaysInMonth
        );
        Integer dailyMeta = PSTA_RegistroResumenGlobalMensual_cls.resolveDailyGoal(monthlyMeta, businessDaysInMonth);
        Decimal monthlyProgress = PSTA_RegistroResumenGlobalMensual_cls.resolveMonthlyProgress(
            monthlyMeta,
            monthlyContactsByAdvisor.get(advisorId)
        );

        ResumenGlobalPostventa__c existingSummary = existingByAdvisor.get(advisorId);
        ResumenGlobalPostventa__c summaryRecord = existingSummary != null
            ? new ResumenGlobalPostventa__c(Id = existingSummary.Id)
            : new ResumenGlobalPostventa__c();

        summaryRecord.Name = banker.Name + ' - ' + String.valueOf(targetDate);
        summaryRecord.Fecha__c = targetDate;
        summaryRecord.Banker__c = member.Id;
        summaryRecord.ExternalId_Nomina__c = advisorId;
        summaryRecord.Meta__c = dailyMeta;
        summaryRecord.Contactados__c = existingSummary != null && existingSummary.Contactados__c != null
            ? existingSummary.Contactados__c
            : 0;

        if (hasMetaMensual) {
            summaryRecord.put('metamensual__c', monthlyMeta);
        }
        if (hasContactadosMensual) {
            summaryRecord.put(
                'contactadosmensual__c',
                monthlyContactsByAdvisor.containsKey(advisorId) ? monthlyContactsByAdvisor.get(advisorId) : 0
            );
        }
        if (hasPorcentajeAvanceMensual) {
            summaryRecord.put('porcentajeavancemensual__c', monthlyProgress);
        }

        if (userIdsByAdvisor.containsKey(advisorId)) {
            summaryRecord.OwnerId = userIdsByAdvisor.get(advisorId);
        }

        if (existingSummary != null) {
            toUpdate.add(summaryRecord);
        } else {
            toInsert.add(summaryRecord);
        }
    }

    Integer insertOk = 0;
    Integer updateOk = 0;
    Integer err = 0;

    if (!toInsert.isEmpty()) {
        Database.SaveResult[] insRes = Database.insert(toInsert, false);
        for (Database.SaveResult r : insRes) {
            if (r.isSuccess()) {
                insertOk++;
            } else {
                err++;
            }
        }
    }
    if (!toUpdate.isEmpty()) {
        Database.SaveResult[] updRes = Database.update(toUpdate, false);
        for (Database.SaveResult r : updRes) {
            if (r.isSuccess()) {
                updateOk++;
            } else {
                err++;
            }
        }
    }

    System.debug(
        'Fecha ' + String.valueOf(targetDate) +
        ' | Inserts OK: ' + insertOk +
        ' | Updates OK: ' + updateOk +
        ' | Errores: ' + err
    );
}

System.debug('=== Fin recalculo retroactivo metas ===');
