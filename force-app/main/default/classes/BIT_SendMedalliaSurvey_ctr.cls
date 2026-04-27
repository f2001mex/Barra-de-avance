/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase encargada de preparar el envío de la encuesta medallia.

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-08-22      Salvador Ramírez        Creación de la Clase.
*/
public with sharing class BIT_SendMedalliaSurvey_ctr {
    @future(callout=true)
    public static void callout(Id idVisita){
        BIT_Medallia_Request request   = new BIT_Medallia_Request();
        BIT_Medallia_Response response = new BIT_Medallia_Response();
        Visita__c objVisita            = new Visita__c();
        try{
            objVisita = BIT_SendMedalliaSurvey_soql.getVisitaInfo(idVisita);
            List<Telefono_de_Contrato__c> lstTel = BIT_SendMedalliaSurvey_soql.getPhonesFromContract(objVisita.Contrato__c);
            List<Correo_de_Contrato__c> lstEmail = BIT_SendMedalliaSurvey_soql.getEmailsFromContract(objVisita.Contrato__c);
            Servicio__c objServicio              = BIT_SendMedalliaSurvey_soql.getFirstService(idVisita);
            Telefono_de_Contrato__c objPhone     = getPrincipalPhone(lstTel);
            Correo_de_Contrato__c objEmail       = getPrincipalEmail(lstEmail);
            Map<String, Object> mapParameters    = new map<String, Object>{'Visita' => objVisita,
                                                                        'TelContrato' => objPhone,
                                                                        'EmailContrato' => objEmail,
                                                                        'Servicio' => objServicio};
            request   = BIT_Medallia_payload.getRequest(mapParameters);
            response = (BIT_Medallia_Response) Callout_cls.callService(new Bitacora_Callouts_cls.MEDALLIA_SendSurvey_WebService(), Request);
            updateVisita(getExternalID(objVisita.Cuenta__r.Client_ID__c, objVisita.Contrato__r.ContractNumber__c, objVisita.HoraSalida__c, objVisita.HoraEntradaVisita__c), objVisita.Id);
        }
        catch(ServiceException serviceException){
            System.debug('#### ERROR BIT_SendMedalliaSurvey_ctr[callout]: ' + serviceException.getMessage());
            EventLogger.error(new Map<String, String>{'contextId' => objVisita.Id,'type' => 'Medallia','errorCode' => String.valueOf(serviceException.statusCode), 'message'   => serviceException.getMessage(), 'request'   => JSON.serializePretty(request)});
        }
        catch(Exception executionException){
            System.debug('#### ERROR BIT_SendMedalliaSurvey_ctr[callout]: ' + executionException.getMessage());        
            EventLogger.error(new Map<String, String>{'contextId' => objVisita.Id,'type' => 'Medallia','errorCode' => 'ERROR_MED_001', 'message'   => executionException.getMessage(), 'request'   => JSON.serializePretty(request)});
        }
    }
    public static void updateVisita(String strExternalID, Id idVisita){
        Visita__c objVisita = new Visita__c(Id = idVisita, ExternalId__c = strExternalID, EncuestaEnviada__c = true);
        update objVisita;
    }
    public static String getExternalID(String strClientId, String strContractNumber, Datetime dtHoraSalida, Datetime dtFechaEntrada){
        String strExternalId = '';
        String strFormatDate = BIT_Medallia_payload.formatDate(dtFechaEntrada).replace('-','');
        String strFormatTimeIn = BIT_Medallia_payload.formatTime(dtFechaEntrada).replace(':','');
        String strFormatTime = BIT_Medallia_payload.formatTime(dtHoraSalida).replace(':','');
        strExternalId = strClientId + strContractNumber + strFormatDate + strFormatTimeIn + strFormatTime;
        System.debug('External ID generado: ' + strExternalId);
        return strExternalId;
    }
    public static Telefono_de_Contrato__c getPrincipalPhone(List<Telefono_de_Contrato__c> lstTel){
        Datetime dtLastDay = null;
        Telefono_de_Contrato__c objPhone = new Telefono_de_Contrato__c();
        for(Telefono_de_Contrato__c objTel : lstTel){
            if(!objTel.principal__c){
                if(dtLastDay != null && objTel.CreatedDate > dtLastDay || dtLastDay == null){
                    objPhone = objTel;
                }
                dtLastDay = objTel.CreatedDate;
            } else {
                objPhone = objTel;
                break;
            }
        }
        return objPhone;
    }
    public static Correo_de_Contrato__c getPrincipalEmail(List<Correo_de_Contrato__c> lstEmail){
        Datetime dtLastDay = null;
        Correo_de_Contrato__c objEmailReturn = new Correo_de_Contrato__c();
        for(Correo_de_Contrato__c objEmail : lstEmail){
            if(!objEmail.principal__c){
                if(dtLastDay != null && objEmail.CreatedDate > dtLastDay || dtLastDay == null){
                    objEmailReturn = objEmail;
                }
                dtLastDay = objEmail.CreatedDate;
            } else {
                objEmailReturn = objEmail;
                break;
            }
        }
        return objEmailReturn;
    }
    
}