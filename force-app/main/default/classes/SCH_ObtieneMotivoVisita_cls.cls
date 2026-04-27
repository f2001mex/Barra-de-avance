/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Reingeniería scheduler
    Descripción     : Clase que contendrá la acción para obtener el motivo del submotivo seleccionado en el scheduler

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-11-29      Salvador Ramírez	    Creación de la Clase.
*/
public with sharing class SCH_ObtieneMotivoVisita_cls {
    public class data{
        @invocableVariable
        public String submotivo;
    }
    public class Response{
        @InvocableVariable
        public String strMotivo;
    }
    @InvocableMethod(label='Obtiene motivo del submotivo')
    public static List<Response> obtieneMotivoDeSubmotivo(List<data> lstData){
        List<Response> resList = new List<Response>();
        for(data objdata : lstData){
            response res = new response();
            Map<Object, List<String>> mapValuesPicklist = SCH_SchedulerFunctions_cls.getDependentPicklistValues(Servicio__c.SubMotivo__c);
            for(Object key : mapValuesPicklist.keySet()){
                List<String> values = mapValuesPicklist.get(key);
                System.debug('Lista de valores:' + values);
                System.debug('Submotivo: ' + objdata.submotivo);
                System.debug('Llave: ' + key);
                if(values.contains(objdata.submotivo)){
                    res.strMotivo = String.valueOf(key);
                    resList.add(res);
                    break;
                } else {
                    continue;
                }
            }
        }
        return resList;
    }
}