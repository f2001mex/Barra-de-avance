/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_PriorizacionSelecto_cls_tst
* Description       :   Clase de consultas para la priorizacion mensual y diaria.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         14-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public without sharing class PSTA_PriorizacionSelector_cls {
    
    public static final Id idConfigContactoPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ContactoPostventa').getRecordTypeId();

    public static String getQueryCuentasPriorizacionMensual(String strConditionsBySegment) {
        
        String baseQuery = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Priorizacion_Mensual'].Consulta__c ;
        
        // Reemplazar el placeholder {0} con las condiciones dinámicas
        return String.format(baseQuery, new List<String>{strConditionsBySegment});
            
        
    }

    /* public static String getQueryCuentasPriorizacionMensual(String strConditionsBySegment) {
        return 'SELECT Id, ' +
                  'FechaUltimoContacto__c, ' +
                  'FechaSiguienteContacto__c, ' +
                  'FechaSiguienteVisita__c, ' +
                  'BanqueroAsignado__c, ' +
                  'SaldoIntegral__c, ' +
                  'ContactoPriorizadoEsteMes__c, ' +
                  'PriorizacionVisita__c, ' +
                  'Segmento__c, ' +
                  'TYPEOF BanqueroAsignado__r.BusinessUnitMember ' +
                  'WHEN Banker THEN Id, Division__c, ExternalId__c, Cargo__c ' +
                  'END ' +
                  'FROM Account ' +
                  'WHERE Segmento__c != null AND SaldoIntegral__c != null AND FechaSiguienteContacto__c != null AND ContactoPriorizadoEsteMes__c = false AND FechaSiguienteVisita__c != null AND Person_Type__c = \'FISICA\' ' + 
            	  strConditionsBySegment + ' AND ((FechaSiguienteContacto__c <= THIS_MONTH ) OR (FechaSiguienteVisita__c  <= THIS_MONTH ))';
    } */

    public static String getQueryCuentasPriorizacionDiaria() {
        // Obtener la consulta base de la Custom Label
        String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Priorizacion_Diaria'].Consulta__c ;
        return consulta;
    }

    /* public static String getQueryCuentasPriorizacionDiaria() {
        return 'SELECT Id, ' +
                  'FechaUltimoContacto__c, ' +
                  'BanqueroAsignado__c, ' +
                  'SaldoIntegral__c, ' +
                  'FechaSiguienteContacto__c, ' +
                  'FechaSiguienteVisita__c, ' +
                  'ContactoPriorizadoEsteMes__c, ' +
                  'PriorizacionContacto__c, ' +
                  'PriorizacionVisita__c, ' +
                  'Segmento__c, ' +
                  'TYPEOF BanqueroAsignado__r.BusinessUnitMember ' +
                  'WHEN Banker THEN Id, Division__c, ExternalId__c, Cargo__c ' +
                  'END ' +
                  'FROM Account ' +
                  'WHERE ContactoPriorizadoEsteMes__c = true AND PriorizacionContacto__c = false AND EstatusContacto__c = \'Pendiente\' AND FechaSiguienteContacto__c != null AND Segmento__c != null AND SaldoIntegral__c != null AND Person_Type__c = \'FISICA\' ORDER BY SaldoIntegral__c DESC';
    } */

    public static List<ConfiguracionActinver__c> getConfiguracionContacto() {
        return [
            SELECT Segmento__c, RangoMontoMaximo__c, RangoMontoMinimo__c, FrecReinicioNoReqContacto__c, Rol__c, FrecuenciaContacto__c, FrecuenciaVisita__c, ClientesContactarPorDia__c 
            FROM ConfiguracionActinver__c
            WHERE RecordTypeId =: idConfigContactoPostVentaRecordType
        ];
    }

    public static Id getDiasLaborales(){
        return [SELECT Id FROM BusinessHours WHERE Name = 'Postventa'].Id;
    }

}