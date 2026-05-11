String advisorExternalId = '65035';
Date targetDate = Date.today();

Map<String, Integer> dailyGoalBySegment = PSTA_RegistroResumenGlobalMensual_cls.getDailyGoalBySegment();
Map<String, Integer> eligiblePortfolio = PSTA_RegistroResumenGlobalMensual_cls.getEligiblePortfolioCountByAdvisor(
    new List<String>{advisorExternalId}
);
Integer businessDaysInMonth = PSTA_RegistroResumenGlobalMensual_cls.getBusinessDaysInMonth(targetDate);

Banker banker = [
    SELECT Id, Name, ExternalId__c, Division__c, Cargo__c
    FROM Banker
    WHERE ExternalId__c = :advisorExternalId
    LIMIT 1
];
String segment = PSTA_Segmentacion_cls.determinarSegmento(banker);
Integer dailyGoalConfig = dailyGoalBySegment.containsKey(segment) ? dailyGoalBySegment.get(segment) : 0;
Integer portfolioCount = eligiblePortfolio.containsKey(advisorExternalId) ? eligiblePortfolio.get(advisorExternalId) : 0;
Integer monthlyMeta = PSTA_RegistroResumenGlobalMensual_cls.resolveMonthlyMeta(
    advisorExternalId, banker, dailyGoalBySegment, eligiblePortfolio, businessDaysInMonth
);
Integer dailyMeta = PSTA_RegistroResumenGlobalMensual_cls.resolveDailyGoal(monthlyMeta, businessDaysInMonth);

Integer totalAccounts = [
    SELECT COUNT()
    FROM Account
    WHERE ID_Asesor__c = :advisorExternalId
];
Integer monthlyPrioritized = [
    SELECT COUNT()
    FROM Account
    WHERE ID_Asesor__c = :advisorExternalId
      AND ContactoPriorizadoEsteMes__c = true
];
Integer listTodayCount = [
    SELECT COUNT()
    FROM Account
    WHERE ID_Asesor__c = :advisorExternalId
      AND ContactoPriorizadoEsteMes__c = true
      AND PriorizacionContacto__c = true
      AND EstatusContacto__c = 'Pendiente'
];

ConfiguracionActinver__c contractConfig = PSTA_SegmentacionClientesSelector_cls.getConfiguracionContratosPostventa();
Set<String> validContractTypes = PSTA_UtilityClass.splitValuesMultiPickList(contractConfig.TipoContratos__c);
Set<String> validContractStatuses = PSTA_UtilityClass.splitValuesMultiPickList(contractConfig.EstatusContrato__c);
AggregateResult contractAgg = [
    SELECT COUNT_DISTINCT(AccountId) total
    FROM Contract
    WHERE AccountId != null
      AND Account.ID_Asesor__c = :advisorExternalId
      AND TypeOfContract__c IN :validContractTypes
      AND Status__c IN :validContractStatuses
];
Integer contractEligibleByConfig = (Integer) contractAgg.get('total');

System.debug('=== DIAG Jessica ===');
System.debug('Asesor: ' + banker.Name + ' extId=' + advisorExternalId);
System.debug('Segmento calculado: ' + segment);
System.debug('Dias habiles mes: ' + businessDaysInMonth);
System.debug('Meta diaria config segmento: ' + dailyGoalConfig);
System.debug('Cartera elegible por config contratos: ' + portfolioCount);
System.debug('Meta mensual resultante: ' + monthlyMeta);
System.debug('Meta diaria resultante: ' + dailyMeta);
System.debug('Total cuentas asesor: ' + totalAccounts);
System.debug('Cuentas priorizadas este mes: ' + monthlyPrioritized);
System.debug('Cuentas en lista hoy (priorizada diaria + pendiente): ' + listTodayCount);
System.debug('Contratos elegibles (query directa config): ' + contractEligibleByConfig);
System.debug('Config tipos contrato: ' + contractConfig.TipoContratos__c);
System.debug('Config estatus contrato: ' + contractConfig.EstatusContrato__c);
System.debug('=== FIN DIAG Jessica ===');
