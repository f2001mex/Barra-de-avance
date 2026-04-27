public class ACT_UpdateLeadPhonesBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        // Incluye todos los Leads
        return Database.getQueryLocator([
            SELECT Id, LastName
            FROM Lead
        ]);
    }

    public void execute(Database.BatchableContext context, List<Lead> scope) {
        // Falso update: fuerza la ejecución del trigger sin cambiar datos
        for (Lead l : scope) {
            l.LastName = l.LastName;
        }
        update scope;
    }

    public void finish(Database.BatchableContext context) {
        System.debug('Batch ACT_UpdateLeadPhonesBatch finalizado.');
    }
}