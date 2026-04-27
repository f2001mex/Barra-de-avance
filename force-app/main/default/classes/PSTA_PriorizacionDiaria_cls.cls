/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_PriorizacionDiaria_bch_tst
* Description       :   Clase controlador para la priorizacion diaria.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         14-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class PSTA_PriorizacionDiaria_cls {
    
    public static Id defaultBusinessHoursId = PSTA_PriorizacionSelector_cls.getDiasLaborales();
    public static Date hoy = Date.today();

    public static Map<String,Object> agrupacionBanqueroPorCuentas(List<Account> lstCuentas, Map<String, ConfiguracionActinver__c> mapConfiguraciones, Map<Id, Integer> mapAsesorPorNumCuentas) {
        Map<Id,List<Account>> mapCuentasPorAsesor = new Map<Id,List<Account>>();
        List<Account> lstCuentasParaActualizar = new List<Account>();
        System.debug('mapAsesorPorNumCuentas en FUNCION: ' + mapAsesorPorNumCuentas);
        Map<String,Object> response = new Map<String,Object>();
        for(Account cuenta : lstCuentas) {
            if(!mapConfiguraciones.containsKey(cuenta.Segmento__c)) continue;
            ConfiguracionActinver__c config = mapConfiguraciones.get(cuenta.Segmento__c);
            Integer limiteClientes          = (Integer) config.ClientesContactarPorDia__c;
            if( cuenta.BanqueroAsignado__r != null && 
                cuenta.BanqueroAsignado__r.BusinessUnitMember != null &&
                cuenta.BanqueroAsignado__r.BusinessUnitMember instanceof Banker) {

                Banker asesor               = (Banker)cuenta.BanqueroAsignado__r.BusinessUnitMember;
                System.debug('asesor: ' + asesor);
                Integer intNumCuentasAsesor = mapAsesorPorNumCuentas.containsKey(asesor.Id) ? mapAsesorPorNumCuentas.get(asesor.Id) : 0;
				System.debug('Cuenta: ' + cuenta);
                if(intNumCuentasAsesor < limiteClientes){
                    cuenta.PriorizacionContacto__c = debePriorizarContacto(cuenta.FechaSiguienteContacto__c, Integer.valueOf(config.FrecuenciaContacto__c), hoy);
                    System.debug('PriorizacionContacto__c ' + cuenta.PriorizacionContacto__c);

                    if(cuenta.PriorizacionContacto__c){
                        lstCuentasParaActualizar.add(cuenta);
                        mapAsesorPorNumCuentas.put(asesor.Id, intNumCuentasAsesor + 1);
                    } 
                }  
            }
        }
        response.put('lstCuentasParaActualizar',lstCuentasParaActualizar);
        response.put('mapAsesorPorNumCuentas',mapAsesorPorNumCuentas);
        return response;
    }

    public static Boolean debePriorizarContacto(Date FechaInicio, Integer intFrecuencia, Date hoy) {
        
        Long lngDiasEntreFechas = PSTA_UtilityClass.obtenerDiasLaboralesEntreFechas(FechaInicio, hoy, defaultBusinessHoursId);
        System.debug('lngDiasEntreFechas: ' + lngDiasEntreFechas);
        Boolean cumpleFrecuencia = lngDiasEntreFechas >= 0;        
        return cumpleFrecuencia;
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

    public static void updateRecords(List<SObject> lstRecords){
        Map<String, String> mapErrors = new Map<String, String>();
        Database.SaveResult[] updateList = Database.update(lstRecords, false);
        for(Database.SaveResult saveResult : updateList){
            if(!saveResult.isSuccess()){
                mapErrors = new Map<String, String>();
                Integer intCount = 0;
                for(Database.Error error : saveResult.getErrors()){
                    mapErrors.put('Error' + intCount, error.getMessage());
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