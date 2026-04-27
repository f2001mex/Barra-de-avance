/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase encargada de llenar el payload del request para envío de encuesta medallia

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-08-22      Salvador Ramírez	    Creación de la Clase.
*/
public with sharing class BIT_GetOTP_Payload {
    public static BIT_GetOTP_Request getRequest(Map<String, Object> mapParameters) {
        BIT_GetOTP_Request clsRequest = new BIT_GetOTP_Request();
        clsRequest.clientNumber = (Integer)mapParameters.get( 'clientNumber' );
        clsRequest.lastDigitsPhoneNumber = (String)mapParameters.get( 'lastDigitsPhoneNumber' );
        clsRequest.mailNotificationFlag = (String)mapParameters.get( 'mailNotificationFlag' );
        return clsRequest;
    }
}