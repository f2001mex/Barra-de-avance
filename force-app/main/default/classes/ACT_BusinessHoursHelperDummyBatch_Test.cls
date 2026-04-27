@IsTest
public class ACT_BusinessHoursHelperDummyBatch_Test implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM Account WHERE Id = null');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // No-op
    }

    public void finish(Database.BatchableContext bc) {
        // No-op
    }
}