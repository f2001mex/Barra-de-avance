@RestResource(urlMapping='/opentext/razonabilidad')
global with sharing class OpenTextRazonabilidadRest {
    private static final String CADENCE_NAME = 'Planeacion Financiera';
    private static final String TASK_OPENTEXT_FIELD = 'RefenciaOpenText__c';
    private static final String TASK_CONTACTED_FIELD = 'El_cliente_fue_contactado__c';
    private static final String TASK_CONTRACT_FIELD = 'ContratoVinculado__c';
    private static final String ADVISOR_ID_FIELD = 'ID_ASESOR__c';
    private static final Integer TASK_OWNER_REASSIGN_MAX_ATTEMPTS = 3;
    private static final Integer TASK_OWNER_REASSIGN_DELAY_MINUTES = 1;
    @TestVisible private static Account testAccount;
    @TestVisible private static Id testContactId;
    @TestVisible private static CadenceStepInfo testCadenceStep;
    @TestVisible private static Id testAdvisorUserId;
    @TestVisible private static Boolean skipCadenceActionsForTest = false;

    global class Request {
        public String bpCliente;
        public String contrato;
        public String areaBancaria;
        public String idAsesor;
        public Date fechaGeneracion;
        public String idOpenText;
    }

    global class Response {
        public Boolean success;
        public String codigo;
        public String mensaje;
        public String accountId;
        public String contactId;
        public String cadenciaId;
        public String pasoCadenciaId;
        public String taskId;
        public List<String> errores;
    }

    @TestVisible
    private class CadenceStepInfo {
        private String id;
        private String trackerId;
        private String state;
        private String ownerId;

        @TestVisible
        private CadenceStepInfo(String id, String trackerId, String state) {
            this.id = id;
            this.trackerId = trackerId;
            this.state = state;
        }

        @TestVisible
        private CadenceStepInfo(String id, String trackerId, String state, String ownerId) {
            this.id = id;
            this.trackerId = trackerId;
            this.state = state;
            this.ownerId = ownerId;
        }
    }

    @HttpPost
    global static Response procesar() {
        RestContext.response.addHeader('Content-Type', 'application/json');
        Response res = new Response();
        res.errores = new List<String>();

        try {
            Request req = parseRequest();
            res.errores.addAll(validate(req));

            if (!res.errores.isEmpty()) {
                return buildError(res, 400, 'DATOS_INVALIDOS', 'La solicitud no contiene la informacion minima requerida.');
            }

            User advisor = findAdvisor(req.idAsesor);
            if (advisor == null) {
                res.errores.add('No se encontro un asesor activo con el idAsesor recibido.');
                return buildError(res, 404, 'ASESOR_NO_ENCONTRADO', 'Asesor no encontrado');
            }

            Account account = findAccount(req.bpCliente);
            if (account == null) {
                res.errores.add('No se encontro cliente con el bpCliente recibido.');
                return buildError(res, 404, 'BP_NO_ENCONTRADO', 'BP no encontrado');
            }

            Id contactId = Test.isRunningTest() && testContactId != null ? testContactId : account.PersonContactId;
            if (contactId == null) {
                res.accountId = account.Id;
                res.errores.add('El cliente encontrado no tiene contacto asociado para buscar la cadencia.');
                return buildError(res, 404, 'CADENCIA_NO_ENCONTRADA', 'Cadencia no encontrada');
            }

            res.accountId = account.Id;
            res.contactId = contactId;

            CadenceStepInfo step = findCadenceStep(contactId, req.fechaGeneracion);
            if (step == null) {
                return buildError(res, 404, 'CADENCIA_NO_ENCONTRADA', 'Cadencia no encontrada');
            }

            res.pasoCadenciaId = step.id;
            res.cadenciaId = step.trackerId;

            String stepState = step.state;
            if (!equalsIgnoreCase(stepState, 'Completed') && !equalsIgnoreCase(stepState, 'Complete')) {
                completeCadenceStep(res.cadenciaId, res.pasoCadenciaId, step.ownerId);
            }

            Task task = findRelatedTask(res.pasoCadenciaId, contactId, req.fechaGeneracion);
            if (task == null) {
                return buildError(res, 500, 'ERROR_ACTUALIZAR_TAREA', 'Error al actualizar la tarea');
            }

            res.taskId = task.Id;
            updateTask(task.Id, req);
            validateSuccessfulTaskUpdate(task.Id, req);
            System.enqueueJob(new TaskOwnerReassignmentJob(task.Id, account.OwnerId, 1, true));

            res.success = true;
            res.codigo = 'OK';
            res.mensaje = 'Registro procesado exitosamente';
            RestContext.response.statusCode = 200;
            return res;
        } catch (QueryException ex) {
            res.errores.add(ex.getMessage());
            return buildError(res, 404, 'CADENCIA_NO_ENCONTRADA', 'Cadencia no encontrada');
        } catch (DmlException ex) {
            res.errores.add(ex.getDmlMessage(0));
            return buildError(res, 500, 'ERROR_ACTUALIZAR_TAREA', 'Error al actualizar la tarea');
        } catch (Exception ex) {
            res.errores.add(ex.getMessage());
            return buildError(res, 500, 'ERROR_ACTUALIZAR_TAREA', 'Error al actualizar la tarea');
        }
    }

    private static Request parseRequest() {
        if (RestContext.request == null || RestContext.request.requestBody == null) {
            return null;
        }

        String body = RestContext.request.requestBody.toString();
        if (String.isBlank(body)) {
            return null;
        }

        return (Request) JSON.deserialize(body, Request.class);
    }

    private static List<String> validate(Request req) {
        List<String> errors = new List<String>();
        if (req == null) {
            errors.add('El body de la solicitud es obligatorio.');
            return errors;
        }

        if (String.isBlank(req.bpCliente)) {
            errors.add('bpCliente es obligatorio.');
        }
        if (String.isBlank(req.contrato)) {
            errors.add('contrato es obligatorio.');
        }
        if (String.isBlank(req.areaBancaria)) {
            errors.add('areaBancaria es obligatorio.');
        }
        if (String.isBlank(req.idAsesor)) {
            errors.add('idAsesor es obligatorio.');
        }
        if (req.fechaGeneracion == null) {
            errors.add('fechaGeneracion es obligatorio.');
        }
        if (String.isBlank(req.idOpenText)) {
            errors.add('idOpenText es obligatorio.');
        }

        return errors;
    }

    private static Account findAccount(String bpCliente) {
        if (Test.isRunningTest() && testAccount != null) {
            return testAccount;
        }

        List<Account> accounts = [
            SELECT Id, OwnerId, PersonContactId, Client_ID__c, AccountNumber
            FROM Account
            WHERE Client_ID__c = :bpCliente OR AccountNumber = :bpCliente
            LIMIT 1
        ];
        return accounts.isEmpty() ? null : accounts[0];
    }

    private static User findAdvisor(String advisorCode) {
        if (Test.isRunningTest() && testAdvisorUserId != null) {
            return new User(Id = testAdvisorUserId);
        }

        if (!Schema.SObjectType.User.fields.getMap().containsKey(ADVISOR_ID_FIELD)) {
            throw new OpenTextRazonabilidadException('No existe el campo User.' + ADVISOR_ID_FIELD + ' para localizar al asesor.');
        }

        String query =
            'SELECT Id, Name, IsActive, ' + ADVISOR_ID_FIELD + ' ' +
            'FROM User ' +
            'WHERE IsActive = true ' +
            'AND ' + ADVISOR_ID_FIELD + ' = :advisorCode ' +
            'LIMIT 1';

        List<User> advisors = Database.query(query);
        return advisors.isEmpty() ? null : advisors[0];
    }

    private static CadenceStepInfo findCadenceStep(Id contactId, Date fechaGeneracion) {
        if (Test.isRunningTest() && testCadenceStep != null) {
            return testCadenceStep;
        }

        if (!Schema.getGlobalDescribe().containsKey('ActionCadenceStepTracker')) {
            return null;
        }

        Date startDate = Date.newInstance(fechaGeneracion.year(), fechaGeneracion.month(), 1);
        Date endDate = startDate.addMonths(1);
        String query =
            'SELECT Id, State, ActionCadenceName, TargetId, ActionCadenceTrackerId, ' +
            'ActionCadenceTracker.OwnerId, CreatedDate ' +
            'FROM ActionCadenceStepTracker ' +
            'WHERE TargetId = :contactId ' +
            'AND (ActionCadenceName = :CADENCE_NAME OR ActionCadenceName LIKE \'Planeaci%n Financiera\') ' +
            'AND CreatedDate >= :startDate AND CreatedDate < :endDate ' +
            'ORDER BY CreatedDate DESC ' +
            'LIMIT 1';

        List<SObject> steps = Database.query(query);
        if (steps.isEmpty()) {
            return null;
        }

        SObject step = steps[0];
        return new CadenceStepInfo(
            (String) step.get('Id'),
            (String) step.get('ActionCadenceTrackerId'),
            (String) step.get('State'),
            (String) step.getSObject('ActionCadenceTracker').get('OwnerId')
        );
    }

    private static Task findRelatedTask(String stepId, Id contactId, Date fechaGeneracion) {
        Date startDate = Date.newInstance(fechaGeneracion.year(), fechaGeneracion.month(), 1);
        Date endDate = startDate.addMonths(1);

        if (Schema.SObjectType.Task.fields.getMap().containsKey('ActionCadenceStepTrackerId')) {
            String taskByCadenceQuery =
                'SELECT Id, Status, Subject, WhoId, CreatedDate ' +
                'FROM Task ' +
                'WHERE ActionCadenceStepTrackerId = :stepId ' +
                'ORDER BY CreatedDate DESC ' +
                'LIMIT 1';

            List<SObject> taskResults = Database.query(taskByCadenceQuery);
            if (!taskResults.isEmpty()) {
                return (Task) taskResults[0];
            }
        }

        List<Task> tasks = [
            SELECT Id, Status, Subject, WhoId, CreatedDate
            FROM Task
            WHERE WhoId = :contactId
            AND Subject LIKE 'Propuesta de inversi%n'
            AND CreatedDate >= :startDate
            AND CreatedDate < :endDate
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return tasks.isEmpty() ? null : tasks[0];
    }

    private static void reassignCadenceIfNeeded(String trackerId, String userId) {
        if (Test.isRunningTest() && skipCadenceActionsForTest) {
            return;
        }

        if (String.isBlank(trackerId) || String.isBlank(userId)) {
            return;
        }

        callStandardAction('changeSalesCadenceTargetAssignee', new Map<String, Object>{
            'actionCadenceTrackerId' => trackerId,
            'userId' => userId,
            'shouldApplyUserContext' => false
        });
    }

    private static void completeCadenceStep(String trackerId, String stepId, String originalOwnerId) {
        String runningUserId = UserInfo.getUserId();

        if (!equalsIgnoreCase(originalOwnerId, runningUserId)) {
            reassignCadenceIfNeeded(trackerId, runningUserId);
        }

        sendCadenceEvent(stepId, 'ManualComplete');
    }

    private static void sendCadenceEvent(String stepId, String eventType) {
        if (Test.isRunningTest() && skipCadenceActionsForTest) {
            return;
        }

        callStandardAction('sendSalesCadenceEvent', new Map<String, Object>{
            'recordId' => stepId,
            'eventType' => eventType
        });
    }

    private static void callStandardAction(String actionName, Map<String, Object> input) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v67.0/actions/standard/' + actionName);
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);
        request.setBody(JSON.serialize(new Map<String, Object>{
            'inputs' => new List<Object>{ input }
        }));

        HttpResponse response = new Http().send(request);
        if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
            throw new OpenTextRazonabilidadException(actionName + ' fallo: ' + response.getBody());
        }
    }

    private static void updateTask(Id taskId, Request req) {
        Map<String, Schema.SObjectField> taskFields = Schema.SObjectType.Task.fields.getMap();
        List<String> missingFields = new List<String>();
        for (String fieldName : new List<String>{ TASK_OPENTEXT_FIELD, TASK_CONTACTED_FIELD, TASK_CONTRACT_FIELD }) {
            if (!taskFields.containsKey(fieldName)) {
                missingFields.add(fieldName);
            }
        }

        if (!missingFields.isEmpty()) {
            throw new OpenTextRazonabilidadException('Faltan campos en Task: ' + String.join(missingFields, ', '));
        }

        Task taskToUpdate = new Task(Id = taskId);
        taskToUpdate.Status = 'Completado';
        taskToUpdate.put(TASK_OPENTEXT_FIELD, req.idOpenText);
        taskToUpdate.put(TASK_CONTACTED_FIELD, 'Si');
        taskToUpdate.put(TASK_CONTRACT_FIELD, req.contrato);
        update taskToUpdate;
    }

    private static void validateSuccessfulTaskUpdate(Id taskId, Request req) {
        String query =
            'SELECT Id, Status, ' + TASK_OPENTEXT_FIELD + ', ' + TASK_CONTACTED_FIELD + ', ' + TASK_CONTRACT_FIELD + ' ' +
            'FROM Task ' +
            'WHERE Id = :taskId ' +
            'LIMIT 1';
        Task updatedTask = (Task) Database.query(query);

        List<String> validationErrors = new List<String>();
        if (!equalsIgnoreCase(updatedTask.Status, 'Completado')) {
            validationErrors.add('La tarea no quedo en estado Completado.');
        }
        if ((String) updatedTask.get(TASK_OPENTEXT_FIELD) != req.idOpenText) {
            validationErrors.add('No se registro correctamente la Referencia OpenText.');
        }
        if ((String) updatedTask.get(TASK_CONTACTED_FIELD) != 'Si') {
            validationErrors.add('No se marco correctamente el campo El cliente fue contactado.');
        }
        if ((String) updatedTask.get(TASK_CONTRACT_FIELD) != req.contrato) {
            validationErrors.add('No se registro correctamente el Contrato Vinculado.');
        }

        if (!validationErrors.isEmpty()) {
            throw new OpenTextRazonabilidadException(String.join(validationErrors, ' | '));
        }
    }

    private static Response buildError(Response res, Integer statusCode, String codigo, String mensaje) {
        res.success = false;
        res.codigo = codigo;
        res.mensaje = mensaje;
        RestContext.response.statusCode = statusCode;
        return res;
    }

    private static Boolean equalsIgnoreCase(String leftValue, String rightValue) {
        return leftValue != null && rightValue != null && leftValue.toLowerCase() == rightValue.toLowerCase();
    }

    private class OpenTextRazonabilidadException extends Exception {
    }

    private class TaskOwnerReassignmentJob implements Queueable {
        private Id taskId;
        private Id ownerId;
        private Integer attemptNumber;
        private Boolean scheduleFollowUp;

        private TaskOwnerReassignmentJob(Id taskId, Id ownerId, Integer attemptNumber, Boolean scheduleFollowUp) {
            this.taskId = taskId;
            this.ownerId = ownerId;
            this.attemptNumber = attemptNumber;
            this.scheduleFollowUp = scheduleFollowUp;
        }

        public void execute(QueueableContext context) {
            if (taskId == null || ownerId == null) {
                return;
            }

            Task currentTask = [
                SELECT Id, OwnerId
                FROM Task
                WHERE Id = :taskId
                LIMIT 1
            ];

            if (currentTask.OwnerId != ownerId) {
                update new Task(
                    Id = taskId,
                    OwnerId = ownerId
                );
            }

            if (shouldScheduleNextAttempt(currentTask.OwnerId != ownerId)) {
                System.schedule(
                    'OpenTextRazonabilidadTaskOwner-' + String.valueOf(taskId) + '-' + String.valueOf(attemptNumber + 1) + '-' + Datetime.now().getTime(),
                    buildCronExpression(Datetime.now().addMinutes(TASK_OWNER_REASSIGN_DELAY_MINUTES)),
                    new TaskOwnerReassignmentSchedule(taskId, ownerId, attemptNumber + 1)
                );
            }
        }

        private Boolean shouldScheduleNextAttempt(Boolean ownerWasAdjusted) {
            if (Test.isRunningTest() || attemptNumber == null || attemptNumber >= TASK_OWNER_REASSIGN_MAX_ATTEMPTS) {
                return false;
            }

            return scheduleFollowUp == true || ownerWasAdjusted;
        }
    }

    private class TaskOwnerReassignmentSchedule implements Schedulable {
        private Id taskId;
        private Id ownerId;
        private Integer attemptNumber;

        private TaskOwnerReassignmentSchedule(Id taskId, Id ownerId, Integer attemptNumber) {
            this.taskId = taskId;
            this.ownerId = ownerId;
            this.attemptNumber = attemptNumber;
        }

        public void execute(SchedulableContext context) {
            System.enqueueJob(new TaskOwnerReassignmentJob(taskId, ownerId, attemptNumber, false));
        }
    }

    @TestVisible
    private static String buildCronExpression(Datetime scheduledDateTime) {
        return String.format(
            '{0} {1} {2} {3} {4} ? {5}',
            new List<String>{
                String.valueOf(scheduledDateTime.second()),
                String.valueOf(scheduledDateTime.minute()),
                String.valueOf(scheduledDateTime.hour()),
                String.valueOf(scheduledDateTime.day()),
                String.valueOf(scheduledDateTime.month()),
                String.valueOf(scheduledDateTime.year())
            }
        );
    }
}