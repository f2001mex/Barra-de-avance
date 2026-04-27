# Evidencia de calendarizacion en QA

## Proceso
Cancelacion de contrato en PostVenta.

## Ambiente
- `actiqa`

## Job calendarizado
- Nombre: `PSTA PostCarga Postventa Nocturno`
- Clase schedulable: `PSTA_PostCargaPostventa_sch`
- Batch ejecutado por scheduler: `PSTA_PostCargaPostventa_bch`

## Cron configurado
- `0 0 1 ? * TUE,WED,THU,FRI,SAT`

Interpretacion:
- ejecucion a la `1:00 AM`
- dias de ejecucion: `martes, miercoles, jueves, viernes y sabado`
- no ejecuta: `domingo` ni `lunes`

## Evidencia de org
- `CronTrigger Id`: `08eWF00000s0I9LYAU`
- `State`: `WAITING`
- `NextFireTime`: `2026-04-14T07:00:00.000+0000`
- `PreviousFireTime`: `null`

## Script utilizado
```apex
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
```

## Consulta de validacion
```sql
SELECT Id, CronJobDetail.Name, State, CronExpression, NextFireTime, PreviousFireTime
FROM CronTrigger
WHERE CronJobDetail.Name = 'PSTA PostCarga Postventa Nocturno'
```
