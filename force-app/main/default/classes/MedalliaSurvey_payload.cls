/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - postventa
    Descripción     : Clase encargada de llenar el payload del request para envío de encuesta medallia

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2025-06-10      Salvador Ramírez        Creación de la Clase.
*/
public class MedalliaSurvey_payload {
    public static MedalliaSurvey_Request getRequest(Map<String, Object> mapParameters) {
        MedalliaSurvey_Request request = new MedalliaSurvey_Request();
        MedalliaSurvey_Request.payload payload = new MedalliaSurvey_Request.payload();
        List<MedalliaSurvey_Request.payload> lstpayload = new List<MedalliaSurvey_Request.payload>();
        payload.fullName = mapParameters.containsKey('fullName') ? (String)mapParameters.get('fullName') : null;
        payload.userType = mapParameters.containsKey('userType') ? (String)mapParameters.get('userType') : null;
        payload.uniqueClientId = mapParameters.containsKey('uniqueClientId') ? (String)mapParameters.get('uniqueClientId') : null;
        payload.contractNumber = mapParameters.containsKey('contractNumber') ? (String)mapParameters.get('contractNumber') : null;
        payload.email = mapParameters.containsKey('email') ? (String)mapParameters.get('email') : null;
        payload.phone = mapParameters.containsKey('phone') ? (String)mapParameters.get('phone') : null;
        payload.financialCenter = mapParameters.containsKey('financialCenter') ? (String)mapParameters.get('financialCenter') : null;
        payload.visitReason = mapParameters.containsKey('visitReason') ? (String)mapParameters.get('visitReason') : null;
        payload.visitDate = mapParameters.containsKey('visitDate') ? (String)mapParameters.get('visitDate') : null;
        payload.entryTime = mapParameters.containsKey('entryTime') ? (String)mapParameters.get('entryTime') : null;
        payload.exitTime = mapParameters.containsKey('exitTime') ? (String)mapParameters.get('exitTime') : null;
        payload.advisorName = mapParameters.containsKey('advisorName') ? (String)mapParameters.get('advisorName') : null;
        payload.otherFunctions =  mapParameters.containsKey('otherFunctions') ? (String)mapParameters.get('otherFunctions') : null;
        payload.contractStatus =  mapParameters.containsKey('contractStatus') ? (String)mapParameters.get('contractStatus') : null;
        payload.contractOrigin =  mapParameters.containsKey('contractOrigin') ? (String)mapParameters.get('contractOrigin') : null;
        lstpayload.add(payload);
        request.payload = lstpayload;
        return request;
    }
}