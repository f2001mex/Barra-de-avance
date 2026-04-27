public with sharing class ACT_CadenceReassignQueueBatch
implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    @TestVisible
    private static String sessionIdOverride;

    @TestVisible
    private static Map<String, User> usersByAdvisorIdOverride;

    @TestVisible
    private static Map<Id, List<ActionCadenceTracker>> trackersByAccountIdOverride;

    @TestVisible
    private static Map<Id, Integer> taskCountByAccountIdOverride;

    @TestVisible
    private static Map<Id, List<Opportunity>> opportunitiesByAccountIdOverride;

    @TestVisible
    private static Id notificationTypeIdOverride;

    @TestVisible
    private static List<Id> notifiedUserIdsTest = new List<Id>();

    @TestVisible
    private static List<Id> notifiedAccountIdsTest = new List<Id>();

    private static final Integer MAX_RETRIES = 3;
    private static final String STATUS_PENDING = 'Pending';
    private static final String STATUS_PROCESSING = 'Processing';
    private static final String STATUS_RETRY = 'Retry';
    private static final String STATUS_COMPLETED = 'Completed';
    private static final String STATUS_FAILED = 'Failed';
    private static final List<String> NOTIFICATION_TYPE_CANDIDATES = new List<String>{
        'Reasignacion_de_Cliente',
        'Asignacion_de_Lead'
    };

    private String sessionId;

    public Integer processed = 0;
    public Integer completed = 0;
    public Integer retried = 0;
    public Integer failed = 0;

    public ACT_CadenceReassignQueueBatch() {
        this(null);
    }

    public ACT_CadenceReassignQueueBatch(String sessionId) {
        this.sessionId = sessionId;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Account__c, OldAdvisorId__c, NewAdvisorId__c, OldOwner__c, NewOwner__c,
                   Status__c, RetryCount__c, LastError__c, NextAttemptAt__c
            FROM Act_Cadence_Reassign_Queue__c
            WHERE Status__c IN :new List<String>{ STATUS_PENDING, STATUS_RETRY }
            AND (NextAttemptAt__c = null OR NextAttemptAt__c <= :System.now())
            ORDER BY CreatedDate ASC
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Act_Cadence_Reassign_Queue__c> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        Datetime executionTime = System.now();
        String runtimeSessionId = resolveSessionId();

        Set<String> advisorIds = new Set<String>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Act_Cadence_Reassign_Queue__c> queueById = new Map<Id, Act_Cadence_Reassign_Queue__c>();

        for (Act_Cadence_Reassign_Queue__c queueRecord : scope) {
            queueById.put(queueRecord.Id, queueRecord);
            accountIds.add(queueRecord.Account__c);
            if (String.isNotBlank(queueRecord.NewAdvisorId__c) && queueRecord.NewOwner__c == null) {
                advisorIds.add(queueRecord.NewAdvisorId__c);
            }
        }

        Map<String, User> usersByAdvisorId = advisorIds.isEmpty()
            ? new Map<String, User>()
            : Service_Utility_Trigger.getUsersByNomina(advisorIds);

        if (Test.isRunningTest() && usersByAdvisorIdOverride != null) {
            usersByAdvisorId = usersByAdvisorIdOverride;
        }

        Map<Id, List<Id>> contactIdsByAccountId = new Map<Id, List<Id>>();
        Set<Id> allContactIds = new Set<Id>();
        Map<Id, Account> accountsById = new Map<Id, Account>([
            SELECT Id, Name
            FROM Account
            WHERE Id IN :accountIds
        ]);
        for (Contact con : [
            SELECT Id, AccountId
            FROM Contact
            WHERE AccountId IN :accountIds
        ]) {
            if (!contactIdsByAccountId.containsKey(con.AccountId)) {
                contactIdsByAccountId.put(con.AccountId, new List<Id>());
            }
            contactIdsByAccountId.get(con.AccountId).add(con.Id);
            allContactIds.add(con.Id);
        }

        Map<Id, List<ActionCadenceTracker>> trackersByAccountId = new Map<Id, List<ActionCadenceTracker>>();
        if (!allContactIds.isEmpty()) {
            Map<Id, Id> accountIdByContactId = new Map<Id, Id>();
            for (Id accountId : contactIdsByAccountId.keySet()) {
                for (Id contactId : contactIdsByAccountId.get(accountId)) {
                    accountIdByContactId.put(contactId, accountId);
                }
            }

            for (ActionCadenceTracker tracker : [
                SELECT Id, TargetId, OwnerId, ActionCadenceId
                FROM ActionCadenceTracker
                WHERE State = 'Running'
                AND TargetId IN :allContactIds
            ]) {
                Id accountId = accountIdByContactId.get(tracker.TargetId);
                if (accountId == null) {
                    continue;
                }

                if (!trackersByAccountId.containsKey(accountId)) {
                    trackersByAccountId.put(accountId, new List<ActionCadenceTracker>());
                }
                trackersByAccountId.get(accountId).add(tracker);
            }
        }

        Map<Id, Integer> taskCountByAccountId = new Map<Id, Integer>();
        if (!allContactIds.isEmpty()) {
            for (AggregateResult ar : [
                SELECT WhatId accountId, COUNT(Id) totalTasks
                FROM Task
                WHERE WhatId IN :accountIds
                AND WhoId IN :allContactIds
                AND IsClosed = false
                GROUP BY WhatId
            ]) {
                taskCountByAccountId.put((Id) ar.get('accountId'), (Integer) ar.get('totalTasks'));
            }
        }

        if (Test.isRunningTest() && trackersByAccountIdOverride != null) {
            trackersByAccountId = trackersByAccountIdOverride;
        }

        if (Test.isRunningTest() && taskCountByAccountIdOverride != null) {
            taskCountByAccountId = taskCountByAccountIdOverride;
        }

        Map<Id, List<Opportunity>> opportunitiesByAccountId = new Map<Id, List<Opportunity>>();
        for (Opportunity opp : [
            SELECT Id, AccountId, OwnerId
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND IsClosed = false
        ]) {
            if (!opportunitiesByAccountId.containsKey(opp.AccountId)) {
                opportunitiesByAccountId.put(opp.AccountId, new List<Opportunity>());
            }
            opportunitiesByAccountId.get(opp.AccountId).add(opp);
        }

        if (Test.isRunningTest() && opportunitiesByAccountIdOverride != null) {
            opportunitiesByAccountId = opportunitiesByAccountIdOverride;
        }

        List<Act_Cadence_Reassign_Queue__c> resultUpdates = new List<Act_Cadence_Reassign_Queue__c>();
        Map<Id, QueueWork> queueWorkById = new Map<Id, QueueWork>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        List<OpportunityUpdateRef> opportunityUpdateRefs = new List<OpportunityUpdateRef>();

        for (Act_Cadence_Reassign_Queue__c queueRecord : scope) {
            processed++;

            Id resolvedNewOwnerId = queueRecord.NewOwner__c;
            if (resolvedNewOwnerId == null && usersByAdvisorId.containsKey(queueRecord.NewAdvisorId__c)) {
                resolvedNewOwnerId = usersByAdvisorId.get(queueRecord.NewAdvisorId__c).Id;
            }

            QueueWork work = new QueueWork(queueRecord, resolvedNewOwnerId);
            queueWorkById.put(queueRecord.Id, work);

            if (resolvedNewOwnerId == null) {
                work.finalizedEarly = true;
                resultUpdates.add(buildRetryOrFailedUpdate(
                    queueRecord,
                    'No se encontró usuario activo para el ID_ASESOR__c ' + queueRecord.NewAdvisorId__c,
                    executionTime,
                    bc.getJobId()
                ));
                continue;
            }

            List<ActionCadenceTracker> accountTrackers = trackersByAccountId.containsKey(queueRecord.Account__c)
                ? trackersByAccountId.get(queueRecord.Account__c)
                : new List<ActionCadenceTracker>();

            work.trackerCount = accountTrackers.size();
            work.taskCount = taskCountByAccountId.containsKey(queueRecord.Account__c)
                ? taskCountByAccountId.get(queueRecord.Account__c)
                : 0;

            for (Opportunity opp : opportunitiesByAccountId.containsKey(queueRecord.Account__c)
                ? opportunitiesByAccountId.get(queueRecord.Account__c)
                : new List<Opportunity>()) {
                work.opportunityCount++;
                if (opp.OwnerId != resolvedNewOwnerId) {
                    opportunitiesToUpdate.add(new Opportunity(
                        Id = opp.Id,
                        OwnerId = resolvedNewOwnerId
                    ));
                    opportunityUpdateRefs.add(new OpportunityUpdateRef(queueRecord.Id, opp.Id));
                }
            }

            if (accountTrackers.isEmpty()) {
                continue;
            }

            Boolean alreadyAssignedToTargetOwner = true;
            Set<Id> uniqueTargetIds = new Set<Id>();
            for (ActionCadenceTracker tracker : accountTrackers) {
                uniqueTargetIds.add(tracker.TargetId);
                if (tracker.OwnerId != resolvedNewOwnerId) {
                    alreadyAssignedToTargetOwner = false;
                }
            }

            if (alreadyAssignedToTargetOwner) {
                continue;
            }

            if (String.isBlank(runtimeSessionId)) {
                work.finalizedEarly = true;
                resultUpdates.add(buildRetryOrFailedUpdate(
                    queueRecord,
                    'Session id unavailable. Para ejecución nocturna se requiere una sesión válida o Named Credential para el callout interno.',
                    executionTime,
                    bc.getJobId()
                ));
                continue;
            }

            for (Id targetId : uniqueTargetIds) {
                work.inputs.add(new Map<String, Object>{
                    'targetId' => (String) targetId,
                    'userId' => (String) resolvedNewOwnerId
                });
                work.inputRefs.add(new InputRef(queueRecord.Id, targetId));
                work.totalInputs++;
            }
        }

        if (!opportunitiesToUpdate.isEmpty()) {
            Database.SaveResult[] opportunityResults = Database.update(opportunitiesToUpdate, false);
            for (Integer i = 0; i < opportunityResults.size() && i < opportunityUpdateRefs.size(); i++) {
                if (opportunityResults[i].isSuccess()) {
                    continue;
                }

                OpportunityUpdateRef ref = opportunityUpdateRefs[i];
                QueueWork work = queueWorkById.get(ref.queueId);
                if (work == null) {
                    continue;
                }

                for (Database.Error err : opportunityResults[i].getErrors()) {
                    work.errorMessages.add('Opportunity ' + ref.opportunityId + ' | ' + truncate(err.getMessage(), 400));
                }
            }
        }

        for (QueueWork work : queueWorkById.values()) {
            if (work.totalInputs == 0) {
                continue;
            }

            processCadenceReassignment(work, runtimeSessionId);
        }

        for (QueueWork work : queueWorkById.values()) {
            if (work.finalizedEarly) {
                continue;
            }

            if (work.totalInputs == 0) {
                resultUpdates.add(
                    work.errorMessages.isEmpty()
                        ? buildCompletedUpdate(
                            work.queueRecord,
                            work.newOwnerId,
                            work.trackerCount > 0,
                            work.trackerCount,
                            work.taskCount,
                            executionTime,
                            bc.getJobId()
                        )
                        : buildRetryOrFailedUpdate(
                            work.queueRecord,
                            truncate(String.join(work.errorMessages, ' || '), 32000),
                            executionTime,
                            bc.getJobId()
                        )
                );
                continue;
            }

            if (work.errorMessages.isEmpty() && work.successInputs == work.totalInputs) {
                resultUpdates.add(buildCompletedUpdate(
                    work.queueRecord,
                    work.newOwnerId,
                    true,
                    work.trackerCount,
                    work.taskCount,
                    executionTime,
                    bc.getJobId()
                ));
            } else {
                resultUpdates.add(buildRetryOrFailedUpdate(
                    work.queueRecord,
                    truncate(String.join(work.errorMessages, ' || '), 32000),
                    executionTime,
                    bc.getJobId()
                ));
            }
        }

        if (!resultUpdates.isEmpty()) {
            Map<Id, Act_Cadence_Reassign_Queue__c> resultUpdatesById = new Map<Id, Act_Cadence_Reassign_Queue__c>();
            for (Act_Cadence_Reassign_Queue__c updateRecord : resultUpdates) {
                resultUpdatesById.put(updateRecord.Id, updateRecord);
            }

            List<Act_Cadence_Reassign_Queue__c> finalUpdates = resultUpdatesById.values();
            update finalUpdates;
            updateCounters(finalUpdates);
            sendNotificationsForCompleted(finalUpdates, queueWorkById, accountsById);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('ACT_CadenceReassignQueueBatch FINISH');
        System.debug('Processed: ' + processed);
        System.debug('Completed: ' + completed);
        System.debug('Retried: ' + retried);
        System.debug('Failed: ' + failed);
    }

    private String resolveSessionId() {
        if (Test.isRunningTest() && !String.isBlank(sessionIdOverride)) {
            return sessionIdOverride;
        }

        if (!String.isBlank(sessionId)) {
            return sessionId;
        }

        return UserInfo.getSessionId();
    }

    private void updateCounters(List<Act_Cadence_Reassign_Queue__c> updates) {
        for (Act_Cadence_Reassign_Queue__c updateRecord : updates) {
            if (updateRecord.Status__c == STATUS_COMPLETED) {
                completed++;
            } else if (updateRecord.Status__c == STATUS_RETRY) {
                retried++;
            } else if (updateRecord.Status__c == STATUS_FAILED) {
                failed++;
            }
        }
    }

    private void processCadenceReassignment(QueueWork work, String runtimeSessionId) {
        try {
            HttpResponse res = ACT_CadenceReassignCallout_cls.changeSalesCadenceTargetAssignee(work.inputs, runtimeSessionId);
            List<Object> rawResults = deserializeActionResults(res);

            if (!rawResults.isEmpty()) {
                for (Integer i = 0; i < work.inputRefs.size(); i++) {
                    InputRef ref = work.inputRefs[i];
                    Map<String, Object> rawResult = i < rawResults.size()
                        ? (Map<String, Object>) rawResults[i]
                        : null;

                    if (isSuccessfulOrAlreadyAssigned(rawResult)) {
                        work.successInputs++;
                    } else {
                        work.errorMessages.add(
                            'Target ' + ref.targetId + ' | ' + summarizeActionError(rawResult)
                        );
                    }
                }
                return;
            }

            work.errorMessages.add('HTTP ' + res.getStatusCode() + ' | ' + truncate(res.getBody(), 1200));
        } catch (Exception ex) {
            work.errorMessages.add('EX ' + ex.getMessage());
        }
    }

    private static List<Object> deserializeActionResults(HttpResponse res) {
        if (res == null || String.isBlank(res.getBody())) {
            return new List<Object>();
        }

        try {
            Object rawPayload = JSON.deserializeUntyped(res.getBody());
            if (rawPayload instanceof List<Object>) {
                return (List<Object>) rawPayload;
            }
        } catch (Exception ex) {
            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                throw ex;
            }
        }

        return new List<Object>();
    }

    private static Boolean isSuccessfulOrAlreadyAssigned(Map<String, Object> rawResult) {
        if (rawResult == null) {
            return false;
        }

        Boolean isSuccess = rawResult.containsKey('isSuccess')
            ? (Boolean) rawResult.get('isSuccess')
            : false;
        if (isSuccess) {
            return true;
        }

        String summarizedError = summarizeActionError(rawResult);
        return !String.isBlank(summarizedError)
            && summarizedError.toLowerCase().contains('same as the current assignee');
    }

    private static Act_Cadence_Reassign_Queue__c buildCompletedUpdate(
        Act_Cadence_Reassign_Queue__c source,
        Id newOwnerId,
        Boolean hasActiveCadences,
        Integer trackerCount,
        Integer taskCount,
        Datetime executionTime,
        String batchJobId
    ) {
        return new Act_Cadence_Reassign_Queue__c(
            Id = source.Id,
            NewOwner__c = newOwnerId,
            Status__c = STATUS_COMPLETED,
            RetryCount__c = source.RetryCount__c,
            LastError__c = null,
            NextAttemptAt__c = null,
            ProcessedAt__c = executionTime,
            BatchJobId__c = batchJobId,
            HasActiveCadences__c = hasActiveCadences,
            TrackerCount__c = trackerCount,
            TaskCount__c = taskCount
        );
    }

    private static Act_Cadence_Reassign_Queue__c buildRetryOrFailedUpdate(
        Act_Cadence_Reassign_Queue__c source,
        String errorMessage,
        Datetime executionTime,
        String batchJobId
    ) {
        Integer nextRetryCount = source.RetryCount__c == null ? 1 : Integer.valueOf(source.RetryCount__c) + 1;
        Boolean shouldFail = nextRetryCount >= MAX_RETRIES;

        return new Act_Cadence_Reassign_Queue__c(
            Id = source.Id,
            Status__c = shouldFail ? STATUS_FAILED : STATUS_RETRY,
            RetryCount__c = nextRetryCount,
            LastError__c = truncate(errorMessage, 32000),
            NextAttemptAt__c = shouldFail ? null : calculateNextAttempt(nextRetryCount, executionTime),
            ProcessedAt__c = shouldFail ? executionTime : null,
            BatchJobId__c = batchJobId
        );
    }

    private static Datetime calculateNextAttempt(Integer retryCount, Datetime baseTime) {
        if (retryCount <= 1) {
            return baseTime.addMinutes(30);
        }
        if (retryCount == 2) {
            return baseTime.addHours(2);
        }
        return baseTime.addDays(1);
    }

    private static String summarizeActionError(Map<String, Object> rawResult) {
        if (rawResult == null) {
            return 'Sin respuesta del action.';
        }

        if (rawResult.containsKey('outputValues')) {
            Map<String, Object> outputValues = (Map<String, Object>) rawResult.get('outputValues');
            if (outputValues != null && outputValues.containsKey('error') && outputValues.get('error') != null) {
                return truncate(String.valueOf(outputValues.get('error')), 400);
            }
        }

        if (rawResult.containsKey('errors')) {
            return truncate(JSON.serialize(rawResult.get('errors')), 400);
        }

        return truncate(JSON.serialize(rawResult), 400);
    }

    private static String truncate(String value, Integer maxLength) {
        if (String.isBlank(value) || value.length() <= maxLength) {
            return value;
        }

        return value.substring(0, maxLength - 3) + '...';
    }

    private static void sendNotificationsForCompleted(
        List<Act_Cadence_Reassign_Queue__c> updates,
        Map<Id, QueueWork> queueWorkById,
        Map<Id, Account> accountsById
    ) {
        Id notificationTypeId = resolveNotificationTypeId();
        if (notificationTypeId == null) {
            return;
        }

        for (Act_Cadence_Reassign_Queue__c updateRecord : updates) {
            if (updateRecord.Status__c != STATUS_COMPLETED) {
                continue;
            }

            QueueWork work = queueWorkById.get(updateRecord.Id);
            if (work == null || work.newOwnerId == null) {
                continue;
            }

            Account accountRecord = accountsById.get(work.queueRecord.Account__c);
            String accountName = accountRecord == null ? 'cliente' : accountRecord.Name;
            sendNotification(work.newOwnerId, notificationTypeId, work.queueRecord.Account__c, accountName);
        }
    }

    private static Id resolveNotificationTypeId() {
        if (Test.isRunningTest() && notificationTypeIdOverride != null) {
            return notificationTypeIdOverride;
        }

        List<CustomNotificationType> notificationTypes = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName IN :NOTIFICATION_TYPE_CANDIDATES
            LIMIT 10
        ];

        if (notificationTypes.isEmpty()) {
            return null;
        }

        Map<String, Id> notificationTypeIdByDeveloperName = new Map<String, Id>();
        for (CustomNotificationType notificationType : notificationTypes) {
            notificationTypeIdByDeveloperName.put(notificationType.DeveloperName, notificationType.Id);
        }

        for (String developerName : NOTIFICATION_TYPE_CANDIDATES) {
            if (notificationTypeIdByDeveloperName.containsKey(developerName)) {
                return notificationTypeIdByDeveloperName.get(developerName);
            }
        }

        return null;
    }

    private static void sendNotification(Id recipientId, Id notificationTypeId, Id targetId, String accountName) {
        if (recipientId == null || notificationTypeId == null || targetId == null) {
            return;
        }

        if (Test.isRunningTest()) {
            notifiedUserIdsTest.add(recipientId);
            notifiedAccountIdsTest.add(targetId);
            return;
        }

        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle('Cliente reasignado');
        notification.setBody('Se te reasigno el cliente ' + accountName + ' y se actualizaron sus registros activos de seguimiento.');
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetId(targetId);

        try {
            notification.send(new Set<String>{ String.valueOf(recipientId) });
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'No se pudo enviar notificacion de reasignacion: ' + ex.getMessage());
        }
    }

    private class QueueWork {
        Act_Cadence_Reassign_Queue__c queueRecord;
        Id newOwnerId;
        Integer trackerCount = 0;
        Integer taskCount = 0;
        Integer opportunityCount = 0;
        Integer totalInputs = 0;
        Integer successInputs = 0;
        Boolean finalizedEarly = false;
        List<String> errorMessages = new List<String>();
        List<Object> inputs = new List<Object>();
        List<InputRef> inputRefs = new List<InputRef>();

        QueueWork(Act_Cadence_Reassign_Queue__c queueRecord, Id newOwnerId) {
            this.queueRecord = queueRecord;
            this.newOwnerId = newOwnerId;
        }
    }

    private class InputRef {
        Id queueId;
        Id targetId;

        InputRef(Id queueId, Id targetId) {
            this.queueId = queueId;
            this.targetId = targetId;
        }
    }

    private class OpportunityUpdateRef {
        Id queueId;
        Id opportunityId;

        OpportunityUpdateRef(Id queueId, Id opportunityId) {
            this.queueId = queueId;
            this.opportunityId = opportunityId;
        }
    }

    @TestVisible
    private static void clearTestOverrides() {
        sessionIdOverride = null;
        usersByAdvisorIdOverride = null;
        trackersByAccountIdOverride = null;
        taskCountByAccountIdOverride = null;
        opportunitiesByAccountIdOverride = null;
        notificationTypeIdOverride = null;
        notifiedUserIdsTest.clear();
        notifiedAccountIdsTest.clear();
    }
}