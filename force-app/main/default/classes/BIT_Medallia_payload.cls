/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase encargada de llenar el payload del request para envío de encuesta medallia

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-08-22      Salvador Ramírez        Creación de la Clase.
*/
public with sharing class BIT_Medallia_payload {
    public static BIT_Medallia_Request getRequest(Map<String, Object> mapParameters){
        Visita__c objVisita = (Visita__c)mapParameters.get('Visita');
        Telefono_de_Contrato__c objTel = (Telefono_de_Contrato__c)mapParameters.get('TelContrato');
        Correo_de_Contrato__c objEmail = (Correo_de_Contrato__c)mapParameters.get('EmailContrato');
        Servicio__c objServicio = (Servicio__c)mapParameters.get('Servicio');
        BIT_Medallia_Request clsRequest = new BIT_Medallia_Request();
        BIT_Medallia_Request.payload wrpPayload = new BIT_Medallia_Request.payload();
        List<BIT_Medallia_Request.payload> lstPayload = new List<BIT_Medallia_Request.payload>();
            wrpPayload.fullName           = objVisita.Cuenta__r.Name;
            wrpPayload.userType           = objVisita.RecordType.Name;
            wrpPayload.uniqueClientId     = objVisita.Cuenta__r.Client_ID__c;
            wrpPayload.contractNumber     = objVisita.Contrato__r.ContractNumber__c;
            wrpPayload.email              = objEmail.Contract_email__c;
            wrpPayload.phone              = objTel.Phone__c;
            wrpPayload.financialCenter    = objVisita.CentroFinanciero__r.Name;
            wrpPayload.visitReason        = objServicio.Submotivo__c.toUpperCase();
            wrpPayload.visitDate          = formatDate(objVisita.HoraEntradaVisita__c);
            wrpPayload.entryTime          = formatTime(objVisita.HoraEntradaVisita__c);
            wrpPayload.exitTime           = formatTime(objVisita.HoraSalida__c);
            wrpPayload.advisorName        = objVisita.Owner.Name;
            wrpPayload.contractStatus     = objVisita.Contrato__r.Status__c;
            wrpPayload.enrollmentStatus   = objVisita.Cuenta__r.Enrollment_Status__c ? 'Activo' : 'Inactivo';
            wrpPayload.contractOrigin     = objVisita.Contrato__r.Source__c;
            wrpPayload.otherFunctions     = '';
        lstPayload.add(wrpPayload);
        clsRequest.payload = lstPayload;
        return clsRequest;
    }
    public static String formatDate(DateTime dt){
        String strDay = dt.day() < 10 ? '0' + dt.day() : String.valueOf(dt.day());
        String strMonth = dt.month() < 10 ? '0' + dt.month() : String.valueOf(dt.month());
        return dt.year() + '-' + strMonth + '-' + strDay;
    }
    public static string formatTime(Datetime dt){
        String strHour = dt.hour() < 10 ? '0' + dt.hour() : String.valueOf(dt.hour());
        String strMinute = dt.minute() < 10 ? '0' + dt.minute() : String.valueOf(dt.minute());
        return strHour + ':' + strMinute;
    }
}