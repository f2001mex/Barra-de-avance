List<CronTrigger> jobs = [
    SELECT Id, CronJobDetail.Name, State, CronExpression, NextFireTime, PreviousFireTime
    FROM CronTrigger
    WHERE CronJobDetail.Name IN (
        'PSTA_SegmentacionClientes',
        'PSTA PostCarga Postventa Nocturno',
        'PSTA_ResetearEstatusContacto',
        'PV_GenerarTareasPeriodicas',
        'PSTA_RegistroResumenGlobal',
        'PSTA_RegistroResumenGlobalMensual'
    )
    ORDER BY CronJobDetail.Name
];

System.debug(JSON.serializePretty(jobs));
