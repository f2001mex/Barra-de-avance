/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para MedalliaSurvey_payload
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     16-07-2025        Jessica Salazar                         Creación
*******************************************************************************************/
@IsTest
public class MedalliaSurvey_payload_tst {

    @isTest
    static void testGetRequest_WithAllParams() {
        Map<String, Object> params = new Map<String, Object>{
            'fullName' => 'Ana López',
            'userType' => 'Cliente',
            'uniqueClientId' => '123456',
            'contractNumber' => 'CON-7890',
            'email' => 'ana.lopez@example.com',
            'phone' => '5556781234',
            'financialCenter' => 'Centro Financiero',
            'visitReason' => 'Consulta',
            'visitDate' => '2025-07-15',
            'entryTime' => '10:00',
            'exitTime' => '10:30',
            'advisorName' => 'Carlos Ruiz',
            'contractStatus' => 'Activo',
            'enrollmentStatus' => 'Completado',
            'contractOrigin' => 'Web',
            'otherFunctions' => 'Cambio de dirección'
        };

        MedalliaSurvey_Request result = MedalliaSurvey_payload.getRequest(params);
    }

    @isTest
    static void testGetRequest_WithPartialParams() {
        Map<String, Object> params = new Map<String, Object>{
            'fullName' => 'Pedro Hernández',
            'email' => 'pedro@example.com'
        };
        MedalliaSurvey_Request result = MedalliaSurvey_payload.getRequest(params);
    }
}