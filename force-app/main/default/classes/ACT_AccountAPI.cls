/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-09-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/Accountconsult/*')
global with sharing class ACT_AccountAPI {

    @HttpPost
    
    global static list<ResultTask> getTaskList(objtask records) {
        List<ResultTask> ltsInsert = new List<ResultTask>();
        List<ClienteInfoWrapper> Enc = new List<ClienteInfoWrapper>();
        ResultTask resultado=new ResultTask ();
        Try
        {
            List<CR_ME_Encuestas_Medallia__c> results = [SELECT act_rel_sat_asesoria_scale11na__c, act_rel_sat_agente_scale11na__c, act_rel_especializados_inv_scale11na__c,CR_ME_Encuesta_en_Medallia__c,act_cdmx_date__c,act_filtro_segmento_auto__c
                           FROM CR_ME_Encuestas_Medallia__c
                           WHERE CR_ME_Cliente_unico__r.Client_ID__c  = :records.BP ORDER BY CreatedDate DESC
                           LIMIT 1];

                           If(!results.isEmpty()){
                            for (CR_ME_Encuestas_Medallia__c perRec : results) {
                                ClienteInfoWrapper encu = new ClienteInfoWrapper();
                                encu.CalificacionAsesoria = perRec.act_rel_sat_asesoria_scale11na__c;
                                encu.CalificacionServicio = perRec.act_rel_sat_agente_scale11na__c;
                                encu.CalificacionEspecialistaInversiones = perRec.act_rel_especializados_inv_scale11na__c;
                                encu.LigaUltimaEncuestaPresionandoCalificacion = perRec.CR_ME_Encuesta_en_Medallia__c;
                                encu.UltimoContacto = perRec.act_cdmx_date__c;
                                encu.SegmentoBanca = perRec.act_filtro_segmento_auto__c;
                                Enc.add(encu);
                            }
                        resultado.result = true;
                        resultado.message = 'Encuesta encontrada';
                        resultado.Cliente_InfoWrapper = Enc;
                        ltsInsert.add(resultado);                    
                        }else{
                            resultado.result = False;
                            resultado.message = 'No se encontraron Encuestas asociadas al cliente';
                            ltsInsert.add(resultado);
                             return ltsInsert;
                    }
        }catch(Exception ex){
            System.debug('Error en procesamiento de registro: '+ ex.getMessage()+ ' : ' + ex.getStackTraceString());
            resultado.message='Error en procesamiento de registro: '+ ex.getMessage() + ': ' + ex.getStackTraceString();
            resultado.result=false;
            ltsInsert.add(resultado);
            return ltsInsert;
            
        }
        return ltsInsert;

    }    

    global class objtask {
        global String BP;
    }

    global class ResultTask {
        Public Boolean result;
        Public String message;
        Public List<ClienteInfoWrapper> Cliente_InfoWrapper {get; set;}
    }
    
    global class ClienteInfoWrapper {
        global String CalificacionAsesoria;
        global String CalificacionServicio;
        global String CalificacionEspecialistaInversiones;
        global String LigaUltimaEncuestaPresionandoCalificacion;
        global Date UltimoContacto;
        global String SegmentoBanca;
        
       /* public ClienteInfoWrapper(String CalificacionAsesoria, String CalificacionServicio,
                                  String  CalificacionEspecialistaInversiones, String LigaUltimaEncuestaPresionandoCalificacion,
                                  Date UltimoContacto, String SegmentoBanca) {
            this.CalificacionAsesoria = CalificacionAsesoria;
            this.CalificacionServicio = CalificacionServicio;
            this.CalificacionEspecialistaInversiones = CalificacionEspecialistaInversiones;
            this.LigaUltimaEncuestaPresionandoCalificacion = LigaUltimaEncuestaPresionandoCalificacion;
            this.UltimoContacto = UltimoContacto;
            this.SegmentoBanca = SegmentoBanca;
        }*/
    }
}