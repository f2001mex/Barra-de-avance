List<CronTrigger> oldJobs = [
    SELECT Id, CronJobDetail.Name
    FROM CronTrigger
    WHERE CronJobDetail.Name = 'PSTA_RegistroResumenGlobal'
];

for (CronTrigger oldJob : oldJobs) {
    System.abortJob(oldJob.Id);
}

List<CronTrigger> newJobs = [
    SELECT Id, CronJobDetail.Name
    FROM CronTrigger
    WHERE CronJobDetail.Name = 'PSTA_RegistroResumenGlobalMensual'
];

for (CronTrigger newJob : newJobs) {
    System.abortJob(newJob.Id);
}

String cronExpression = '0 0 4 ? * 2,3,4,5,6';
System.schedule(
    'PSTA_RegistroResumenGlobalMensual',
    cronExpression,
    new PSTA_RegistroResumenGlobalMensual_sch()
);
