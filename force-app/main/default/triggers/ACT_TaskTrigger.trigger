trigger ACT_TaskTrigger on Task (before insert, before update, after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        ACT_TaskTriggerHandler.handleInboundCallTasks(Trigger.new);
    }
    
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        ACT_TaskTriggerHandler.handleGenesysTask(Trigger.new);
    }
}