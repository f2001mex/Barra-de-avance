public class ACT_UpdateContractPhonesBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        // SIN filtros: se incluyen todos los registros
        return Database.getQueryLocator([
            SELECT Id, Name
            FROM Telefono_de_Contrato__c
        ]);
    }

    public void execute(Database.BatchableContext context, List<Telefono_de_Contrato__c> scope) {
        // Falso update: mantiene el valor pero dispara el trigger
        for (Telefono_de_Contrato__c record : scope) {
            record.Name = record.Name;
        }

        update scope;
    }

    public void finish(Database.BatchableContext context) {
        System.debug('Batch ACT_UpdateContractPhonesBatch finalizado.');
    }
}