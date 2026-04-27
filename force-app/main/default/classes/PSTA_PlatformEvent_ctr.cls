public with sharing class PSTA_PlatformEvent_ctr {
    public static void publishEvent_ShowFileUploadLWC(String strRecordId, Boolean blnShowComponent){
        UpdateTask__e eventUpdateTask = new UpdateTask__e();
        eventUpdateTask.RecordId__c = strRecordId;
        eventUpdateTask.ShowComponent__c = blnShowComponent;
        EventBus.publish(eventUpdateTask);
    }
}