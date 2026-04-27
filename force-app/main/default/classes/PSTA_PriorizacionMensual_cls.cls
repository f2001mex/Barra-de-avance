/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_PriorizacionMensual_cls_tst
* Description       :   Clase controlador para la priorizacion mensual.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         09-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class PSTA_PriorizacionMensual_cls {

    public static Id defaultBusinessHoursId = PSTA_PriorizacionSelector_cls.getDiasLaborales();

    public static List<Account> agrupacionBanqueroPorCuentas(List<Account> lstCuentas, Map<String, ConfiguracionActinver__c> mapConfiguraciones) {
        List<Account> lstToUpdate = new List<Account>();
        for(Account cuenta : lstCuentas) {
            if( cuenta.BanqueroAsignado__r != null && 
                cuenta.BanqueroAsignado__r.BusinessUnitMember != null &&
                cuenta.BanqueroAsignado__r.BusinessUnitMember instanceof Banker) {
                if (!mapConfiguraciones.containsKey(cuenta.Segmento__c)) continue;
                ConfiguracionActinver__c config = mapConfiguraciones.get(cuenta.Segmento__c);
                cuenta.ContactoPriorizadoEsteMes__c = debePriorizarContacto(cuenta.FechaSiguienteContacto__c, Date.today());
                cuenta.PriorizacionVisita__c = debePriorizarContacto(cuenta.FechaSiguienteVisita__c, Date.today());
                if(cuenta.PriorizacionVisita__c || cuenta.ContactoPriorizadoEsteMes__c) lstToUpdate.add(cuenta);
                
            }
        }
        return lstToUpdate;
    }

    

    public static List<Account> priorizarCuentas(List<Id> lstAsesores,Map<Id, List<Account>> mapCuentasPorAsesor, Map<String, ConfiguracionActinver__c> mapConfiguraciones){
        List<Account> lstCuentasParaActualizar = new List<Account>();
        Date hoy = Date.today();
        for (Id asesor : lstAsesores) {
            List<Account> clientes = mapCuentasPorAsesor.get(asesor);
            if (clientes == null || clientes.isEmpty()) continue;
            
            // Obtenemos el segmento del primer cliente (todos tienen mismo asesor y segmento)
            String segmentoAsesor = clientes[0].Segmento__c;
            if (!mapConfiguraciones.containsKey(segmentoAsesor)) continue;
            
            ConfiguracionActinver__c config = mapConfiguraciones.get(segmentoAsesor);
            
            for (Account cliente : clientes) {
                cliente.ContactoPriorizadoEsteMes__c = debePriorizarContacto(cliente, config, hoy);
                lstCuentasParaActualizar.add(cliente);
            }
        }

        return lstCuentasParaActualizar;
    }
	public static Boolean debePriorizarContacto( Date dtFechaSiguiente, Date dtFechaEjecucion) {
        Long lngDiasEntreFechas = PSTA_UtilityClass.obtenerDiasLaboralesEntreFechas(dtFechaSiguiente, dtFechaEjecucion, defaultBusinessHoursId);
        Boolean cumpleFrecuencia = lngDiasEntreFechas >= 0;
        return cumpleFrecuencia;
    }
    public static Boolean debePriorizarContacto(Account cliente, ConfiguracionActinver__c config, Date hoy) {
        

        Long lngDiasEntreFechas = PSTA_UtilityClass.obtenerDiasLaboralesEntreFechas(cliente.FechaSiguienteContacto__c, hoy, defaultBusinessHoursId);
        Boolean cumpleFrecuencia = lngDiasEntreFechas >= config.FrecuenciaContacto__c;
        
        return /*contactoEnMesActual || */cumpleFrecuencia;
    }

    public static Map<String,ConfiguracionActinver__c> obtenerSegmentoPorConfig() {
        Map<String, ConfiguracionActinver__c> mapConfiguraciones = new Map<String, ConfiguracionActinver__c>();
        List<ConfiguracionActinver__c> lstConfiguraciones = PSTA_PriorizacionSelector_cls.getConfiguracionContacto();

        for (ConfiguracionActinver__c configuracion : lstConfiguraciones) {
            if (String.isNotBlank(configuracion.Segmento__c)) {
                mapConfiguraciones.put(configuracion.Segmento__c.trim(), configuracion);
            }
        }

        return mapConfiguraciones;
    }
	public static String getClausuleQueryBySegmento(Map<String, ConfiguracionActinver__c> mapConfiguraciones){
        Map<String, ConfiguracionActinver__c> mapConfigPorSegmento = PSTA_PriorizacionMensual_cls.obtenerSegmentoPorConfig();
        String cadena = 'AND (';
        String strOr = '';
        Integer intTamanio = 0;
        for(String segmento : mapConfigPorSegmento.keySet()){
            strOr += '(Segmento__c = \'' + segmento + '\' AND SaldoIntegral__c >= ' + mapConfigPorSegmento.get(segmento).RangoMontoMinimo__c;
            strOr += ' AND SaldoIntegral__c <= ' + + mapConfigPorSegmento.get(segmento).RangoMontoMaximo__c + ')';
            system.debug('contador: ' + intTamanio);
            if(intTamanio < (mapConfigPorSegmento.keySet().size() - 1)){
                strOr += ' OR ';
                intTamanio++;
            }
        }
        cadena += strOr + ')';
        System.debug('cadena: ' + cadena);
        return cadena;
    }
    public static void updateRecords(List<SObject> lstRecords){
        Map<String, String> mapErrors = new Map<String, String>();
        Database.SaveResult[] updateList = Database.update(lstRecords, false);
        for(Database.SaveResult saveResult : updateList){
            if(!saveResult.isSuccess()){
                mapErrors = new Map<String, String>();
                Integer intCount = 0;
                for(Database.Error error : saveResult.getErrors()){
                    mapErrors.put('Numero de errores:' + intCount, error.getMessage());
                    intCount++;
                }
            }
        }
        if(!mapErrors.isEmpty()){
            saveLogError(mapErrors, 'Error durante Actualizacion de priorizacion mensual de cuenta', 'ERROR_BATCH_PRIORIZACION_MENSUAL_001', '');
        }
    }

    public static void saveLogError(Map<String, String> mapErrors, String message, String errorCode, String type){
        EventLogger.error(new Map<String, String>{'contextId' => null,
                                                    'type' => '',
                                                    'errorCode' => errorCode,
                                                    'message'   => message,
                                                    'request'   => JSON.serializePretty(mapErrors)});
    }

}