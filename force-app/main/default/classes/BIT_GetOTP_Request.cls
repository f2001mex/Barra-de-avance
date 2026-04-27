/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase wrapper para el request de solicitud de OTP

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-08-22      Salvador Ramírez	    Creación de la Clase.
*/
public class BIT_GetOTP_Request implements RequestBody_cls {
    public Integer clientNumber;
    public String lastDigitsPhoneNumber;
    public String mailNotificationFlag;
    public String serializeRequestBody(RequestBody_CLS requestBody) {
        return JSON.serialize( ( BIT_GetOTP_Request ) requestBody, true);
    }
}