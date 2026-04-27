/**
 * @description       : 
 * @author            : francisco.ortega@optimissa.com
 * @group             : 
 * @last modified on  : 11-27-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ActualizarContratosBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    // Método `start`: Cambiado `global` a `public`
    public Database.QueryLocator start(Database.BatchableContext batchContext) {
        return Database.getQueryLocator(
            'SELECT Id, Source__c FROM Contract WHERE BusinessUnitNumber__c = \'1\''
        );
    }
    
    // Método `execute`: Cambiado `global` a `public`
    public void execute(Database.BatchableContext batchContext, List<Contract> scope) {
        for (Contract c : scope) {
            c.Source__c = 'Contrato de Banco';
        }
        update scope;
    }
    
    // Método `finish`: Cambiado `global` a `public`
    public void finish(Database.BatchableContext batchContext) {
        System.debug('Batch job completado exitosamente.');
    }
}