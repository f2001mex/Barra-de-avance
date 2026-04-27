/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Reingeniería scheduler
    Descripción     : Clase que obtiene la función para obtener la hora de la cita con la zona horaria del usuario

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     29/01/2025     Salvador Ramírez	    Creación de la Clase.
*/
public with sharing class SCH_ObtieneHoraCita_Cls {
    public class wpParameters {
        @invocableVariable
        public DateTime dtTimeToConvert;
        @invocableVariable
        public String strTimeZoneSidKey;
    }
    public class Response {
        @invocableVariable
        public DateTime dtTimeConvert;
    }
    @invocableMethod(label='Convertir fecha y hora a zona horaria de usuario')
    public static List<Response> convertDateTimeToTimeZone(List<wpParameters> lstData){
        List<Response> lstResponse = new List<Response>();
        for(wpParameters wp : lstData){
            Response objRes = new Response();
            Datetime format = SCH_SchedulerFunctions_cls.getDateTimeWithOffset(wp.strTimeZoneSidKey, wp.dtTimeToConvert);
            objRes.dtTimeConvert = format;
            lstResponse.add(objRes);
        }
        return lstResponse;
    }
}