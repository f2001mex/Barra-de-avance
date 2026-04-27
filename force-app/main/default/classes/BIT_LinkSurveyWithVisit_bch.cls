/**
**/
global class BIT_LinkSurveyWithVisit_bch implements Database.Batchable<sObject>,Database.Stateful {
    String strQuery = '';
    Set<String> setExternalIDs = new Set<String>();
    List<Visita__c> lstRecordsToUpdate = new List<Visita__c>();
    Map<String, CR_ME_Encuestas_Medallia__c> mapIdSurvey = new Map<String, CR_ME_Encuestas_Medallia__c>();
    public BIT_LinkSurveyWithVisit_bch() {
        strQuery = label.QueryBatchLigaEncuestaVisita;
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(strQuery);
    }
    global void execute(Database.BatchableContext BC, List<Visita__c> records){
        for(Visita__c objVisita : records) setExternalIDs.add(objVisita.ExternalID__c);
        
        List<CR_ME_Encuestas_Medallia__c> lstSurveys = [SELECT ID, ExternalID__c, act_rel_ltr_scale11__c FROM CR_ME_Encuestas_Medallia__c WHERE EXTERNALID__C IN :setExternalIDs];
        
        System.debug('lstSurveys: ' + lstSurveys);
        System.debug('encuestas encontradas: ' + lstSurveys.size());
        for(CR_ME_Encuestas_Medallia__c objSurvey : lstSurveys){
            System.debug('Id encuesta: ' + objSurvey.ExternalID__c);
            if(!mapIdSurvey.containsKey(objSurvey.ExternalID__c)) mapIdSurvey.put(objSurvey.ExternalID__c, objSurvey);
        }
        for(Visita__c objVisita : records){
            if(mapIdSurvey.containsKey(objVisita.ExternalID__c)){
                objVisita.EncuestaMedallia__c = mapIdSurvey.get(objVisita.ExternalID__c).Id;
                lstRecordsToUpdate.add(objVisita);
            }
        }
        for(Database.SaveResult result : Database.update(lstRecordsToUpdate, false)){
            if(!result.isSuccess()) {
                for (Database.Error error : result.getErrors()){
                    System.debug('Error actualizando visita: ' + error.getMessage());
                }
            }
        }
    }
    global void finish(Database.BatchableContext BC){
        System.debug('Tarea finalizada con éxito');
    }
}