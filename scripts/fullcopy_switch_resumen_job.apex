List<CronTrigger> existingJobs = [
    SELECT Id, CronJobDetail.Name
    FROM CronTrigger
    WHERE CronJobDetail.Name IN ('PSTA_RegistroResumenGlobal', 'PSTA_RegistroResumenGlobalMensual')
];

for (CronTrigger jobRecord : existingJobs) {
    System.abortJob(jobRecord.Id);
}

String cronExp = '0 0 4 ? * 2,3,4,5,6';
String jobName = 'PSTA_RegistroResumenGlobalMensual';
System.schedule(jobName, cronExp, new PSTA_RegistroResumenGlobalMensual_sch());

System.debug('Resumen global mensual calendarizado con cron: ' + cronExp);
