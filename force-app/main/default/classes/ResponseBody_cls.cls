/****************************************************************************************************
Desarrollado por: Unknown
Proyecto        : Actinver
Descripción     : Interfaz para las estructuras del body del response de los distintos callouts

Cambios (Versiones)
-----------------------------------------------------------------------------------------------------
No.     Fecha           Autor                   Descripción
-----   ----------      --------------------    -----------------------------------------------------
1.0     2024-08-14      Unknown			        Creación de la Clase.                                   
*/
public interface ResponseBody_cls {
    ResponseBody_cls deserializeResponseBody( String jsonBody );
}