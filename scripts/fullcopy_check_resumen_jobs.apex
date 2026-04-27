List<CronTrigger> jobs = [
    SELECT Id, CronJobDetail.Name, State, CronExpression, NextFireTime, PreviousFireTime
    FROM CronTrigger
    WHERE CronJobDetail.Name IN ('PSTA_RegistroResumenGlobal', 'PSTA_RegistroResumenGlobalMensual')
    ORDER BY CronJobDetail.Name
];

System.debug(JSON.serializePretty(jobs));
