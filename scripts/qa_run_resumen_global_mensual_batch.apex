Id jobId = Database.executeBatch(new PSTA_RegistroResumenGlobalMensual_bch(), 200);
System.debug('JOB_ID_RESUMEN_GLOBAL_MENSUAL=' + jobId);
