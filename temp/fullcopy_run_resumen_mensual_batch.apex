Id jobId = Database.executeBatch(new PSTA_RegistroResumenGlobalMensual_bch(), 200);
System.debug('JobId=' + jobId);
