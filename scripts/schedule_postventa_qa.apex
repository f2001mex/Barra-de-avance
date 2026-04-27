String jobName = 'PSTA PostCarga Postventa Nocturno';
for (CronTrigger ct : [
    SELECT Id, CronJobDetail.Name
    FROM CronTrigger
    WHERE CronJobDetail.Name = :jobName
]) {
    System.abortJob(ct.Id);
}
String cronExp = '0 0 1 ? * TUE,WED,THU,FRI,SAT';
System.schedule(jobName, cronExp, new PSTA_PostCargaPostventa_sch());
System.debug('POSTVENTA_CRON_PROGRAMADO=' + cronExp);
