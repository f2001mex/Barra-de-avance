/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Postventa
    Descripción     : Clase encargada de preparar el envío de la encuesta medallia.

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2025-06-06      Salvador Ramírez        Creación de la Clase.
*/
public class PSTA_EnvioEncuestaMedallia_ctr {
    @future(callout = true)
    public static void calloutMedallia(Id idTask){
        List<Task> lstTask = PSTA_EnvioEncuestaMedallia_soql.getInfoTask(idTask);
        BIT_Medallia_Response response = new BIT_Medallia_Response();
        if(lstTask.size() > 0){
            MedalliaSurvey_Request request = new MedalliaSurvey_Request();
            Task objTask = lstTask[0];
            Map<String, Object> mapParams = new Map<String, Object>{
                'visitReason' => objTask.Type,
                'visitDate' => ACTINVER_UtilityFactory_utils.formatDate(System.today(), true),
                'userType' => 'ModeloPostventa',
                'uniqueClientId' => objTask.Account.Client_ID__c,
                'phone' => objTask.Account.Phone,
                'otherFunctions' => objTask.Subject,
                'fullName' => objTask.Account.Name,
                'financialCenter' => objTask.Account.BanqueroAsignado__r.BranchUnit.Name,
                'exitTime' => '00:00',//ACTINVER_UtilityFactory_utils.calcularEdad(objTask.Account.PersonBirthdate),
                'entryTime' => '00:00',//objTask.Account.FechaAntiguedad__c,
                'enrollmentStatus' => objTask.Account.SaldoIntegral__c,
                'email' => objTask.Account.PersonEmail,
                'contractStatus' => objTask.Account.Owner.ID_ASESOR__c,
                'contractOrigin' => 'PV' + objTask.Account.Client_ID__c + ACTINVER_UtilityFactory_utils.formatDate(System.today(), false),
                'advisorName' => objTask.Account.BanqueroAsignado__r.BusinessUnitMember.name
            };
            request = MedalliaSurvey_payload.getRequest(mapParams);
            System.debug('Request: ' + JSON.serialize(request));
            response = (BIT_Medallia_Response) Callout_cls.callService(new PostVenta_Callouts_cls.PV_EnvioEncuestaMedallia(), request);
            System.debug('Respuesta: ' + response);
        }
        //Pendiente que se termine de definir el envío de las encuestas.
    }
}