/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Clase test		:   
* Description       :   Clase que ejecuta
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         12-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class PSTA_ListadoClientes_cls {

    public static Boolean bypassTriggerExecution = false;


    public static final String ESTATUS_PENDIENTE                    = 'Pendiente';
    public static final String ESTATUS_CONTACTO_NO_EXITOSO          = 'Contacto no exitoso';
    public static final String ESTATUS_NO_QUIERE_SER_CONTACTADO     = 'Cliente no quiere ser contactado';
    public static final String ESTATUS_CONTACTO_EFECTIVO_EXITOSO    = 'Contacto efectivo exitoso';


    private static Id businessHoursId = PSTA_ListaClientesSelector_cls.getDiasLaborales();

    public static void actualizarFechaSiguienteContacto(List<Account> lstClientes, Map<Id, Account> oldMap) {

        if(bypassTriggerExecution == true) {
            return;
        }
        
        Map<String, Integer> mapSegmentoByFrecuenciaContacto = getMapSegmentoByFrecuenciaContacto();
        
        for(Account cuentaNueva : lstClientes) {
            Account cuentaVieja = oldMap.get(cuentaNueva.Id);

            if(cuentaNueva.FechaUltimoContacto__c != null  && cuentaVieja.FechaUltimoContacto__c != cuentaNueva.FechaUltimoContacto__c)  {
                
                Integer frecuencia = mapSegmentoByFrecuenciaContacto.get(cuentaNueva.Segmento__c);
                cuentaNueva.FechaSiguienteContacto__c = PSTA_UtilityClass.agregarDiasLaborales(
                    cuentaNueva.FechaUltimoContacto__c,
                    frecuencia,
                    businessHoursId
                 );
                
                
            }
        }
        
    }

    public static void actualizarFechaSiguienteVisita(List<Account> lstClientes, Map<Id, Account> oldMap) {

        if(bypassTriggerExecution == true) {
            return;
        }

        Map<String, Integer> mapSegmentoByFrecuenciaVisita = getMapSegmentoByFrecuenciaVisita();
        
        for(Account cuentaNueva : lstClientes) {
            Account cuentaVieja = oldMap.get(cuentaNueva.Id);

            if(cuentaVieja.FechaUltimaVisita__c != cuentaNueva.FechaUltimaVisita__c) {
                
                Integer frecuencia = mapSegmentoByFrecuenciaVisita.get(cuentaNueva.Segmento__c);
                cuentaNueva.FechaSiguienteVisita__c = PSTA_UtilityClass.agregarDiasLaborales(
                    cuentaNueva.FechaUltimaVisita__c,
                    frecuencia,
                    businessHoursId
                 );
                
            }
        }
    }

    public static void actualizarFechaNoQuiereSerContactado(List<Account> lstClientes, Map<Id, Account> oldMap) {

        if(bypassTriggerExecution == true) {
            return;
        }
        
        Map<String, Integer> mapSegmentoByFrecuenciaNoContacto = getMapSegmentoByFrecuenciaNoContacto();
        
        for(Account cuentaNueva : lstClientes) {
            Account cuentaVieja = oldMap.get(cuentaNueva.Id);
            
            
            if(cuentaVieja.EstatusContacto__c != cuentaNueva.EstatusContacto__c && cuentaNueva.EstatusContacto__c == ESTATUS_NO_QUIERE_SER_CONTACTADO && cuentaVieja.FechaNoRequiereSerContacto__c != cuentaNueva.FechaNoRequiereSerContacto__c) {
                
                Integer frecuencia = mapSegmentoByFrecuenciaNoContacto.get(cuentaNueva.Segmento__c);
                cuentaNueva.FechaSiguienteContacto__c = PSTA_UtilityClass.agregarDiasLaborales(
                    System.today(),
                    frecuencia,
                    businessHoursId
                );
                
                cuentaNueva.FechaUltimoContacto__c = System.today();
                
            }
        }
    }

    public static Map<String,Integer> getMapSegmentoByFrecuenciaContacto() {
        List<ConfiguracionActinver__c> lstConfigPostventa = PSTA_ListaClientesSelector_cls.getConfiguracionPostVenta();
        Map<String, Integer> mapMapSegmentoByFrecuencia = new Map<String, Integer>();
        for(ConfiguracionActinver__c config : lstConfigPostventa) {
            mapMapSegmentoByFrecuencia.put(
                config.Segmento__c, 
                Integer.valueOf(config.FrecuenciaContacto__c)
            );
        }

        return mapMapSegmentoByFrecuencia;
    }

    public static Map<String,Integer> getMapSegmentoByFrecuenciaVisita() {
        List<ConfiguracionActinver__c> lstConfigPostventa = PSTA_ListaClientesSelector_cls.getConfiguracionPostVenta();
        Map<String, Integer> mapMapSegmentoByFrecuencia = new Map<String, Integer>();
        for(ConfiguracionActinver__c config : lstConfigPostventa) {
            mapMapSegmentoByFrecuencia.put(
                config.Segmento__c, 
                Integer.valueOf(config.FrecuenciaVisita__c)
            );
        }

        return mapMapSegmentoByFrecuencia;
    }

    public static Map<String,Integer> getMapSegmentoByFrecuenciaNoContacto() {
        List<ConfiguracionActinver__c> lstConfigPostventa = PSTA_ListaClientesSelector_cls.getConfiguracionPostVenta();
        Map<String, Integer> mapMapSegmentoByFrecuencia = new Map<String, Integer>();
        for(ConfiguracionActinver__c config : lstConfigPostventa) {
            mapMapSegmentoByFrecuencia.put(
                config.Segmento__c, 
                Integer.valueOf(config.FrecReinicioNoReqContacto__c)
            );
        }

        return mapMapSegmentoByFrecuencia;
    }
}