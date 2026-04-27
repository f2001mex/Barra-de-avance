public without sharing class PSTA_FACCadenceCompletion_cls {
    @TestVisible private static final String FAC_CADENCE_NAME = 'Ficha de afinidad con el cliente';
    @TestVisible private static final String FAC_DEVELOPER_NAME = 'FAC';
    @TestVisible private static final String TASK_STATUS_COMPLETED = 'Completado';
    @TestVisible private static final String CONTACTED_VALUE = 'Si';
    @TestVisible private static final Decimal FAC_COMPLETION_THRESHOLD = 0.9;
    @TestVisible private static String cadenceIdOverride;
    @TestVisible private static String sessionIdOverride;

    public static void onAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : newAccounts) {
            if (acc == null || acc.Id == null || !hasReachedFac100(acc)) {
                continue;
            }

            Account oldAcc = oldMap != null && oldMap.containsKey(acc.Id)
                ? oldMap.get(acc.Id)
                : null;

            if (hasReachedFac100(oldAcc)) {
                continue;
            }

            accountIds.add(acc.Id);
        }

        if (accountIds.isEmpty()) {
            return;
        }

        String sessionId = Test.isRunningTest() && !String.isBlank(sessionIdOverride)
            ? sessionIdOverride
            : UserInfo.getSessionId();

        if (String.isBlank(sessionId) && !Test.isRunningTest()) {
            System.debug(LoggingLevel.ERROR, 'PSTA_FACCadenceCompletion_cls: session id unavailable.');
            return;
        }

        completeCadenceAsync(new List<Id>(accountIds), sessionId);
    }

    @future(callout=true)
    public static void completeCadenceAsync(List<Id> accountIds, String sessionId) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        try {
            String cadenceId = getFacCadenceId();
            if (String.isBlank(cadenceId)) {
                System.debug(LoggingLevel.ERROR, 'PSTA_FACCadenceCompletion_cls: FAC cadence not found.');
                return;
            }

            Map<Id, Account> accountsById = new Map<Id, Account>([
                SELECT Id, Name, PersonContactId, Client_ID__c, ID_Asesor__c
                FROM Account
                WHERE Id IN :accountIds
            ]);

            if (accountsById.isEmpty()) {
                return;
            }

            Map<Id, Id> accountByContactId = new Map<Id, Id>();
            Set<Id> accountIdsWithoutPersonContact = new Set<Id>();
            for (Account acc : accountsById.values()) {
                if (acc.PersonContactId != null) {
                    accountByContactId.put(acc.PersonContactId, acc.Id);
                } else {
                    accountIdsWithoutPersonContact.add(acc.Id);
                }
            }

            if (!accountIdsWithoutPersonContact.isEmpty()) {
                for (Contact con : [
                    SELECT Id, AccountId
                    FROM Contact
                    WHERE AccountId IN :accountIdsWithoutPersonContact
                ]) {
                    accountByContactId.put(con.Id, con.AccountId);
                }
            }

            if (accountByContactId.isEmpty()) {
                return;
            }

            List<ActionCadenceTracker> runningTrackers = [
                SELECT Id, TargetId, OwnerId,
                       ActionCadence.Tipo_de_actividad__c,
                       ActionCadence.DeveloperName__c,
                       ActionCadence.Name
                FROM ActionCadenceTracker
                WHERE ActionCadenceId = :cadenceId
                AND State = 'Running'
                AND TargetId IN :accountByContactId.keySet()
            ];

            Map<String, ActionCadenceTracker> trackerByAccountContactKey = new Map<String, ActionCadenceTracker>();
            if (!runningTrackers.isEmpty()) {
                Set<Id> completedTrackerIds = removeTrackers(runningTrackers, sessionId);
                if (completedTrackerIds.isEmpty()) {
                    return;
                }

                for (ActionCadenceTracker tracker : runningTrackers) {
                    if (!completedTrackerIds.contains(tracker.Id)) {
                        continue;
                    }

                    Id accountId = accountByContactId.get(tracker.TargetId);
                    if (accountId == null) {
                        continue;
                    }

                    trackerByAccountContactKey.put(
                        buildAccountContactKey(accountId, tracker.TargetId),
                        tracker
                    );
                }
            } else {
                for (ActionCadenceTracker tracker : [
                    SELECT Id, TargetId, OwnerId,
                           ActionCadence.Tipo_de_actividad__c,
                           ActionCadence.DeveloperName__c,
                           ActionCadence.Name
                    FROM ActionCadenceTracker
                    WHERE ActionCadenceId = :cadenceId
                    AND State = 'Complete'
                    AND TargetId IN :accountByContactId.keySet()
                    ORDER BY LastModifiedDate DESC, CreatedDate DESC
                ]) {
                    Id accountId = accountByContactId.get(tracker.TargetId);
                    if (accountId == null) {
                        continue;
                    }

                    String key = buildAccountContactKey(accountId, tracker.TargetId);
                    if (!trackerByAccountContactKey.containsKey(key)) {
                        trackerByAccountContactKey.put(key, tracker);
                    }
                }
            }

            if (trackerByAccountContactKey.isEmpty()) {
                return;
            }

            String taskSubjectLike = '%' + FAC_CADENCE_NAME + '%';
            List<Task> candidateTasks = [
                SELECT Id, Subject, Status, WhatId, WhoId, OwnerId, Type, DeveloperName__c,
                       Description, PV_ExternalID__c, El_cliente_fue_contactado__c
                FROM Task
                WHERE WhatId IN :accountsById.keySet()
                AND WhoId IN :accountByContactId.keySet()
                AND Subject LIKE :taskSubjectLike
                ORDER BY CreatedDate DESC
            ];

            Map<String, List<Task>> tasksByAccountContact = new Map<String, List<Task>>();
            for (Task taskRecord : candidateTasks) {
                String key = buildAccountContactKey((Id) taskRecord.WhatId, (Id) taskRecord.WhoId);
                if (!tasksByAccountContact.containsKey(key)) {
                    tasksByAccountContact.put(key, new List<Task>());
                }
                tasksByAccountContact.get(key).add(taskRecord);
            }

            List<Task> tasksToUpdate = new List<Task>();
            Map<Id, String> accountContactKeyByTaskId = new Map<Id, String>();
            for (String key : trackerByAccountContactKey.keySet()) {
                ActionCadenceTracker tracker = trackerByAccountContactKey.get(key);
                List<Task> candidateTasksForKey = tasksByAccountContact.get(key);
                if (candidateTasksForKey == null || candidateTasksForKey.isEmpty()) {
                    continue;
                }

                Id accountId = accountByContactId.get(tracker.TargetId);
                Account acc = accountsById.get(accountId);
                for (Task taskToUpdate : candidateTasksForKey) {
                    taskToUpdate.Subject = FAC_CADENCE_NAME;
                    taskToUpdate.Status = TASK_STATUS_COMPLETED;
                    taskToUpdate.DeveloperName__c = FAC_DEVELOPER_NAME;
                    taskToUpdate.El_cliente_fue_contactado__c = CONTACTED_VALUE;
                    if (acc != null) {
                        taskToUpdate.Description = 'Contacto efectivo ' + FAC_CADENCE_NAME + ' ' + acc.Client_ID__c + ' ' + acc.Name;
                        taskToUpdate.PV_ExternalID__c = PSTA_GestionTareas_Helper.createExternalIdTask(
                            FAC_DEVELOPER_NAME,
                            acc.Client_ID__c,
                            acc.ID_Asesor__c
                        );
                    }
                    tasksToUpdate.add(taskToUpdate);
                    accountContactKeyByTaskId.put(taskToUpdate.Id, key);
                }
            }

            if (!tasksToUpdate.isEmpty()) {
                Database.SaveResult[] results = Database.update(tasksToUpdate, false);
                Map<String, Task> firstSuccessfulTaskByKey = new Map<String, Task>();
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        continue;
                    }

                    Task savedTask = tasksToUpdate[i];
                    String key = accountContactKeyByTaskId.get(savedTask.Id);
                    if (key != null && !firstSuccessfulTaskByKey.containsKey(key)) {
                        firstSuccessfulTaskByKey.put(key, savedTask);
                    }
                }

                if (!firstSuccessfulTaskByKey.isEmpty()) {
                    publishCadenceCompletion(firstSuccessfulTaskByKey.values());
                }
            }

            List<Task> tasksToInsert = new List<Task>();
            List<String> insertKeys = new List<String>();
            for (String key : trackerByAccountContactKey.keySet()) {
                if (tasksByAccountContact.containsKey(key) && !tasksByAccountContact.get(key).isEmpty()) {
                    continue;
                }

                ActionCadenceTracker tracker = trackerByAccountContactKey.get(key);
                Id accountId = accountByContactId.get(tracker.TargetId);
                Account acc = accountsById.get(accountId);
                if (acc == null) {
                    continue;
                }

                tasksToInsert.add(buildCompletedTask(tracker, acc));
                insertKeys.add(key);
            }

            if (!tasksToInsert.isEmpty()) {
                Database.SaveResult[] insertResults = Database.insert(tasksToInsert, false);
                List<Task> insertedTasks = new List<Task>();
                for (Integer i = 0; i < insertResults.size(); i++) {
                    if (!insertResults[i].isSuccess()) {
                        System.debug(LoggingLevel.ERROR,
                            'PSTA_FACCadenceCompletion_cls task insert failed for ' + insertKeys[i] + ': ' +
                            JSON.serialize(insertResults[i].getErrors()));
                        continue;
                    }

                    insertedTasks.add(tasksToInsert[i]);
                }

                if (!insertedTasks.isEmpty()) {
                    List<Task> completedInsertedTasks = markInsertedTasksAsContacted(insertedTasks);
                    if (!completedInsertedTasks.isEmpty()) {
                        publishCadenceCompletion(completedInsertedTasks);
                    }
                }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,
                'PSTA_FACCadenceCompletion_cls error: ' + ex.getMessage() + ' line ' + ex.getLineNumber());
        }
    }

    @TestVisible
    private static String getFacCadenceId() {
        if (!String.isBlank(cadenceIdOverride)) {
            return cadenceIdOverride;
        }

        List<ActionCadence> cadences = [
            SELECT Id
            FROM ActionCadence
            WHERE DeveloperName__c = :FAC_DEVELOPER_NAME
            LIMIT 1
        ];

        return cadences.isEmpty() ? null : cadences[0].Id;
    }

    @TestVisible
    private static Boolean hasReachedFac100(Account acc) {
        if (acc == null || acc.AvanceNum1FAC__c == null || acc.AvanceNum2FAC__c == null) {
            return false;
        }

        if (acc.AvanceNum1FAC__c <= 0) {
            return false;
        }

        Decimal progressRatio = acc.AvanceNum2FAC__c / acc.AvanceNum1FAC__c;
        return progressRatio >= FAC_COMPLETION_THRESHOLD;
    }

    @TestVisible
    private static Set<Id> removeTrackers(List<ActionCadenceTracker> trackers, String sessionId) {
        if (trackers == null || trackers.isEmpty()) {
            return new Set<Id>();
        }

        List<Object> inputs = new List<Object>();
        List<Id> trackerIds = new List<Id>();
        for (ActionCadenceTracker tracker : trackers) {
            trackerIds.add(tracker.Id);
            inputs.add(new Map<String, Object>{
                'actionCadenceTrackerId' => tracker.Id,
                'completionReasonCode' => 'ManuallyRemoved',
                'shouldApplyUserContext' => false
            });
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v66.0/actions/standard/removeTargetFromSalesCadence');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + sessionId);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{ 'inputs' => inputs }));

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            System.debug(LoggingLevel.ERROR,
                'PSTA_FACCadenceCompletion_cls removeTrackers failed: ' + res.getStatusCode() + ' ' + res.getBody());
            return new Set<Id>();
        }

        Set<Id> successfulTrackerIds = new Set<Id>();
        List<Object> rawResults = (List<Object>) JSON.deserializeUntyped(res.getBody());
        for (Integer i = 0; i < rawResults.size() && i < trackerIds.size(); i++) {
            Map<String, Object> result = (Map<String, Object>) rawResults[i];
            if ((Boolean) result.get('isSuccess')) {
                successfulTrackerIds.add(trackerIds[i]);
            }
        }

        return successfulTrackerIds;
    }

    private static void publishCadenceCompletion(List<Task> tasks) {
        List<PV_FinalizacionCadencia__e> events = new List<PV_FinalizacionCadencia__e>();
        for (Task taskRecord : tasks) {
            if (taskRecord.WhatId == null || taskRecord.OwnerId == null) {
                continue;
            }

            events.add(new PV_FinalizacionCadencia__e(
                TaskId__c = taskRecord.Id,
                AccountId__c = (Id) taskRecord.WhatId,
                UserId__c = taskRecord.OwnerId
            ));
        }

        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }

    private static String buildAccountContactKey(Id accountId, Id contactId) {
        return String.valueOf(accountId) + ':' + String.valueOf(contactId);
    }

    private static List<Task> markInsertedTasksAsContacted(List<Task> insertedTasks) {
        if (insertedTasks == null || insertedTasks.isEmpty()) {
            return new List<Task>();
        }

        if (Test.isRunningTest()) {
            return insertedTasks;
        }

        List<Task> tasksToUpdate = new List<Task>();
        for (Task taskRecord : insertedTasks) {
            tasksToUpdate.add(new Task(
                Id = taskRecord.Id,
                El_cliente_fue_contactado__c = CONTACTED_VALUE
            ));
        }

        Database.SaveResult[] updateResults = Database.update(tasksToUpdate, false);
        List<Task> successfulTasks = new List<Task>();
        for (Integer i = 0; i < updateResults.size(); i++) {
            if (!updateResults[i].isSuccess()) {
                System.debug(LoggingLevel.ERROR,
                    'PSTA_FACCadenceCompletion_cls task contact update failed for ' + insertedTasks[i].Id + ': ' +
                    JSON.serialize(updateResults[i].getErrors()));
                continue;
            }

            insertedTasks[i].El_cliente_fue_contactado__c = CONTACTED_VALUE;
            successfulTasks.add(insertedTasks[i]);
        }

        return successfulTasks;
    }

    private static Task buildCompletedTask(ActionCadenceTracker tracker, Account acc) {
        Task taskRecord = new Task();
        taskRecord.Subject = FAC_CADENCE_NAME;
        taskRecord.Status = TASK_STATUS_COMPLETED;
        taskRecord.Priority = 'Normal';
        taskRecord.RecordTypeId = ACTINVER_UtilityFactory_utils.getRecodType('Task', 'Postventa');
        taskRecord.OwnerId = tracker.OwnerId;
        taskRecord.WhatId = acc.Id;
        taskRecord.WhoId = tracker.TargetId;
        taskRecord.Type = tracker.ActionCadence.Tipo_de_actividad__c;
        taskRecord.DeveloperName__c = FAC_DEVELOPER_NAME;
        taskRecord.Description = 'Contacto efectivo ' + FAC_CADENCE_NAME + ' ' + acc.Client_ID__c + ' ' + acc.Name;
        taskRecord.PV_ExternalID__c = PSTA_GestionTareas_Helper.createExternalIdTask(
            FAC_DEVELOPER_NAME,
            acc.Client_ID__c,
            acc.ID_Asesor__c
        );
        return taskRecord;
    }
}
