public with sharing class ACT_TaskTriggerHandler {
    
    public static void handleGenesysTask(List<Task> taskList) {
        for (Task t : taskList) {
            if (t.ACT_ConversationId__c != null) {
                t.ACT_Is_Genesys_Task__c = true;
                t.ACT_Interaction_Type__c = t.Type;
            }
        }
    }

    public static void handleInboundCallTasks(List<Task> taskList) {
        Set<String> uniquePhonesToCheck = new Set<String>();
        Map<String, Task> phoneToTask = new Map<String, Task>();
        Set<Id> whoIds = new Set<Id>();

        for (Task t : taskList) {
            String phone = t.ACT_Caller_Phone_Number__c;

            if (
                t.CallType == 'Inbound' &&
                t.ACT_Authenticated_Customer__c == true &&
                String.isNotBlank(phone) &&
                t.WhoId != null &&
                String.valueOf(t.WhoId).startsWith('003') && // Contact
                !ACT_TaskTriggerHelper.insertedPhoneNumbers.contains(phone)
            ) {
                uniquePhonesToCheck.add(phone);
                phoneToTask.put(phone, t);
                whoIds.add(t.WhoId);
            } else {
                return;
            }
        }

        // Mapear ContactId (WhoId) -> AccountId
        Map<Id, Id> contactToAccountMap = new Map<Id, Id>();
        if (!whoIds.isEmpty()) {
            for (Account acc : [
                SELECT Id, PersonContactId
                FROM Account
                WHERE PersonContactId IN :whoIds
            ]) {
                contactToAccountMap.put(acc.PersonContactId, acc.Id);
            }
        }

        // Buscar si ya existen esos números
        Set<String> existingPhones = new Set<String>();
        if (!uniquePhonesToCheck.isEmpty()) {
            for (ACT_Genesys_Phone__c record : [
                SELECT ACT_Genesys_Phone_Number__c
                FROM ACT_Genesys_Phone__c
                WHERE ACT_Genesys_Phone_Number__c IN :uniquePhonesToCheck
            ]) {
                existingPhones.add(record.ACT_Genesys_Phone_Number__c);
            }
        }

        // Insertar los nuevos
        List<ACT_Genesys_Phone__c> toInsert = new List<ACT_Genesys_Phone__c>();
        for (String phone : uniquePhonesToCheck) {
            if (!existingPhones.contains(phone)) {
                Task t = phoneToTask.get(phone);
                Id accountId = contactToAccountMap.get(t.WhoId);
                if (accountId != null) {
                    toInsert.add(new ACT_Genesys_Phone__c(
                        ACT_Genesys_Phone_Number__c = phone,
                        ACT_Customer__c = accountId
                    ));
                    ACT_TaskTriggerHelper.insertedPhoneNumbers.add(phone);
                }
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }
}