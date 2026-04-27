/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para MedalliaSurvey_Request
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     16-07-2025        Jessica Salazar                         Creación
*******************************************************************************************/
@IsTest
public class MedalliaSurvey_Request_tst {

    @isTest
    static void testSerializeRequestBody() {
        MedalliaSurvey_Request request = new MedalliaSurvey_Request();
        
        MedalliaSurvey_Request.payload p = new MedalliaSurvey_Request.payload();
        p.fullName = 'Juan Perez';
        p.email = 'juan.perez@example.com';
        p.phone = '5551234567';
        request.payload.add(p);

        String jsonResult = request.serializeRequestBody(request);
    }
}