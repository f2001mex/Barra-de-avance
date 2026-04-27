/****************************************************************************************************
Desarrollado por: Unknown
Proyecto        : Actinver
Descripción     : Interfaz a implementar por los callouts para centralizar su gestión

Cambios (Versiones)
-----------------------------------------------------------------------------------------------------
No.     Fecha           Autor                   Descripción
-----   ----------      --------------------    -----------------------------------------------------
1.0     2024-08-14      Unknown			Creación de la Clase.                                       
*/
public interface Service_cls {
    void setRequestBody( RequestBody_CLS requestBody );
	void setUrlParams( Map<String, String> urlParams);
    ResponseBody_CLS run();
	ResponseBody_CLS setMockResponse();
	String getMdtName();
}