/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase wrapper para el response de encuesta medallia

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-08-19      Salvador Ramírez	    Creación de la Clase.
*/
public class BIT_Medallia_Response implements ResponseBody_cls {
    public String statusCode;
    public String statusCodeValue;
    public ResponseBody_CLS deserializeResponseBody(String jsonBody) {
        return (BIT_Medallia_Response) JSON.deserialize(jsonBody, BIT_Medallia_Response.class);
    }
}