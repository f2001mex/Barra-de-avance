String jobName = 'PSTA PostCarga Postventa Nocturno';
String cronExp = '0 0 1 ? * 1,3,4,5,6,7';

List<CronTrigger> existingJobs = [
    SELECT Id, CronJobDetail.Name
    FROM CronTrigger
    WHERE CronJobDetail.Name = :jobName
];

for (CronTrigger jobRecord : existingJobs) {
    System.abortJob(jobRecord.Id);
}

System.schedule(jobName, cronExp, new PSTA_PostCargaPostventa_sch());
System.debug('Scheduler creado: ' + jobName + ' -> ' + cronExp);
