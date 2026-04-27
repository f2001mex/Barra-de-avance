global without sharing class ACT_CadenceReassignQueueScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ACT_CadenceReassignQueueBatch(), 50);
    }
}