/****************************************************************************************************
Desarrollado por : Unknown
Proyecto         : -
Descripción      : Clase de excepción para los callouts

Cambios (Versiones)
-----------------------------------------------------------------------------------------------------
No.     Fecha           Autor                   Descripción
-----   ----------      --------------------    -----------------------------------------------------
1.0     2024-08-14      Unknown			Creación de la Clase.                                       
*/
public class ServiceException extends Exception {
    public String aplicacionOrigen;
    public String webServiceName;
    public String requestBody;
    public String responseBody;
    public Integer statusCode;
    public String status;
  
}