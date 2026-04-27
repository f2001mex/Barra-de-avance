/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase wrapper para el response de envío OTP

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-08-23      Salvador Ramírez	    Creación de la Clase.
*/
public  class BIT_GetOTP_Response implements ResponseBody_cls {
    public Integer status;
    public payload payload;
    List<String> messages;
    public class payload {
        public Integer id;
        public String message;
    }
    public ResponseBody_CLS deserializeResponseBody(String jsonBody) {
        return (BIT_GetOTP_Response) JSON.deserialize(jsonBody, BIT_GetOTP_Response.class);
    }
}