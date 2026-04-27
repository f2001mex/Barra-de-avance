/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase encargada del envio de encuesta a Medallia

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-08-20      Salvador Ramírez	    Creación de la Clase.
*/
public with sharing class BIT_SendMedalliaSurvey_cls {
    public class parameters {
        @InvocableVariable
        public Id idVisita;
    }
    @InvocableMethod(label='CalloutMedallia')
    public static void calloutMedallia(List<parameters> lstParameter){
        callSendMedallia(lstParameter);
    }
    public static void callSendMedallia(List<parameters> lstParameter){
        for(parameters objLoop : lstParameter){
            if(!Test.isRunningTest()){BIT_SendMedalliaSurvey_ctr.callout(objLoop.idVisita);}
        }
    }
}