/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Mockup para PSTA_EnvioEncuestaMedallia_cls
------------------------------------------------------------------------------------------
No.        Fecha               Autor                            Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     14-07-2025        Jessica Salazar                        Creación
*******************************************************************************************/
@isTest
global class PSTA_EnvioEncuestaMedallia_Mockup implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status": "ok"}');
        res.setStatusCode(200);
        return res;
    }
}