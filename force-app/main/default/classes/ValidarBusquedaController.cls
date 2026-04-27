public with sharing class ValidarBusquedaController {
    
    @AuraEnabled
    public static WrapperResult validarBusqueda(String interactionId, String phoneNumber){
        try {
            WrapperResult result = new WrapperResult();
            List<List<SObject>> lstResults = [FIND :phoneNumber IN PHONE FIELDS RETURNING ACT_Genesys_Phone__c(Id, Name), Telefono_de_Contrato__c(Id, Name), Lead(Id, Name)];
            
            System.debug('lstResults: ' + lstResults);

            List<SObject> lstTelefonosGenesys = lstResults[0];
            List<SObject> lstTelefonosContrato = lstResults[1];
            List<SObject> lstLeads = lstResults[2];

            result.multipleCoincidencia = false;
            result.unicaCoincidencia = false;
            result.noCoincidencia = false;

            if ((!lstTelefonosGenesys.isEmpty() && !lstLeads.isEmpty()) || (!lstTelefonosContrato.isEmpty() && !lstLeads.isEmpty()) || (!lstLeads.isEmpty() && lstLeads.size()>1)) {
                result.multipleCoincidencia = true;
            } else if (!lstLeads.isEmpty() && lstLeads.size()==1) {
                result.unicaCoincidencia = true;
                result.idProspecto = lstLeads[0].Id;

                //Actualizar tarea generada por Genesys
                actualizarTarea(result.idProspecto, interactionId);
            } else if (lstLeads.isEmpty()) {
                result.noCoincidencia = true;
            }

            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static void actualizarTarea(String leadId, String interactionId) {
        Task tarea = [SELECT Id, ACT_ConversationId__c, ACT_Authenticated_Customer__c, ACT_Client_Identifier__c  FROM Task WHERE ACT_ConversationId__c = :interactionId];
        tarea.WhoId = leadId;
        tarea.ACT_Is_Genesys_Task__c = true;
        update tarea;
    }
    
    public class WrapperResult {
        @AuraEnabled
        public Boolean multipleCoincidencia {get; set;}
        @AuraEnabled
        public Boolean unicaCoincidencia {get; set;}
        @AuraEnabled
        public Boolean noCoincidencia {get; set;}
        @AuraEnabled
        public String idProspecto {get; set;}
    }
}