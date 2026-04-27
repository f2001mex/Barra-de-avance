String advisorId = '67979';
Date targetDate = Date.today();

List<Banker> bankers = [
    SELECT Id, Name, Division__c, Cargo__c, ExternalId__c
    FROM Banker
    WHERE ExternalId__c = :advisorId
    LIMIT 1
];

System.debug('BANKERS_SIZE=' + bankers.size());

if (!bankers.isEmpty()) {
    Banker banker = bankers[0];
    String segment = PSTA_Segmentacion_cls.determinarSegmento(banker);
    Map<String, Integer> dailyGoalBySegment = PSTA_RegistroResumenGlobalMensual_cls.getDailyGoalBySegment();
    Integer businessDays = PSTA_RegistroResumenGlobalMensual_cls.getBusinessDaysInMonth(targetDate);
    Map<String, Integer> eligiblePortfolio = PSTA_RegistroResumenGlobalMensual_cls.getEligiblePortfolioCountByAdvisor(new List<String>{advisorId});
    Integer monthlyMeta = PSTA_RegistroResumenGlobalMensual_cls.resolveMonthlyMeta(
        advisorId,
        banker,
        dailyGoalBySegment,
        eligiblePortfolio,
        businessDays
    );
    Integer dailyMeta = PSTA_RegistroResumenGlobalMensual_cls.resolveDailyGoal(monthlyMeta, businessDays);

    System.debug('ADVISOR_ID=' + advisorId);
    System.debug('BANKER_NAME=' + banker.Name);
    System.debug('BANKER_DIVISION=' + banker.Division__c);
    System.debug('BANKER_ROLE=' + banker.Cargo__c);
    System.debug('SEGMENT=' + segment);
    System.debug('DAILY_GOAL_SEGMENT=' + dailyGoalBySegment.get(segment));
    System.debug('BUSINESS_DAYS=' + businessDays);
    System.debug('ELIGIBLE_PORTFOLIO=' + eligiblePortfolio.get(advisorId));
    System.debug('MONTHLY_META=' + monthlyMeta);
    System.debug('DAILY_META=' + dailyMeta);
}
