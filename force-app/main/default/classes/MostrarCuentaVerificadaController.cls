public with sharing class MostrarCuentaVerificadaController {
    
    @AuraEnabled
    public static WrapperResult verificarCuenta(String interactionId, String phoneNumber, Boolean authenticated, String idCliente){
        WrapperResult wrapper = new WrapperResult();

        List<Account> lstAccounts = (List<Account>) Database.query('SELECT Id, PersonContactId FROM Account WHERE Client_ID__c = \'' + idCliente + '\' LIMIT 1');
       
        if (!lstAccounts.isEmpty()) {
            Account cuenta = lstAccounts[0];
            wrapper.cuentaEncontrada = true;
            wrapper.idCuenta = cuenta.Id;

            //Actualizar tarea generada por Genesys
            actualizarTarea(cuenta.PersonContactId, authenticated, idCliente, interactionId);
        } else {
            wrapper.cuentaEncontrada = false;
        }

        return wrapper;
    }

    public static void actualizarTarea(String personContactId, Boolean authenticated, String idCliente, String interactionId) {
        Task tarea = [SELECT Id, ACT_ConversationId__c, ACT_Is_Genesys_Task__c, ACT_Authenticated_Customer__c, ACT_Client_Identifier__c  FROM Task WHERE ACT_ConversationId__c = :interactionId];
        tarea.ACT_Authenticated_Customer__c = authenticated;
        tarea.ACT_Client_Identifier__c = idCliente;
        tarea.WhoId = personContactId;
        tarea.ACT_Is_Genesys_Task__c = true;
        update tarea;
    }

    public class WrapperResult {
        @AuraEnabled
        public String idCuenta {get;set;}
        @AuraEnabled
        public Boolean cuentaEncontrada {get;set;}
    }
    
}