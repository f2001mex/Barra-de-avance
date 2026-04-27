public class Task_Helper {
    public static Boolean bypassExecutionTriggerTask = false;

    public static void publishEventToComponent(List<Task> newListTask, Map<Id, Task> mapOldTask){
        // SI EL BYPASS ESTÁ ACTIVADO, NO SE EJECUTA EL TRIGGER
        if (bypassExecutionTriggerTask) return;

        for(Task objTask :newListTask){
            Task objOldTask = mapOldTask.get(objTask.Id);
            if(objOldTask.ClienteNoQuiereSerContactado__c != objTask.ClienteNoQuiereSerContactado__c && objTask.DeveloperName__c != null){
                PSTA_PlatformEvent_ctr.publishEvent_ShowFileUploadLWC(objTask.Id,objTask.ClienteNoQuiereSerContactado__c);
            }
        }
        bypassExecutionTriggerTask = true;
    }

}