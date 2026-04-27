/**
* @description       : Class controller for Task Object
* @author            : 
* @group             : 
* @last modified on  : 10-25-2023
* @last modified by  : 
**/

public without sharing class ACT_Controller_Task implements Interface_Handle_Task {
    private static final String STATUS_ALL = 'Todas';
    private static final String STATUS_NEXT = 'Proximas';
    private static final String STATUS_DUE = 'Vencidas';
    private static final String EVENT_TYPE = 'Eventos';
    private static final String TASK_TYPE = 'Tareas';
    private static final String COMPLETED = 'Completado';

     /**
    * @descripción:Este método en Apex, llamado consultTask, consulta tareas y eventos en Salesforce y devuelve una lista que contienen detalles clave de las tareas y eventos consultados.
    * @author Harold Garcia - hgarcia@freewayconsulting.com | 14-11-2023
    * @param records Data_Structure_Handle_Task.TaskObject
    **/
    public static List<Data_Structure_Handle_Task.ResultTaskWrapper> consultTask(Data_Structure_Handle_Task.TaskObject records ){
        List<Data_Structure_Handle_Task.ResultTaskWrapper> ltsTask = new List<Data_Structure_Handle_Task.ResultTaskWrapper>();
        Data_Structure_Handle_Task.ResultTaskWrapper resultado = new Data_Structure_Handle_Task.ResultTaskWrapper();

        try {
            List<SObject> tasksAndEvents = new List<SObject>();
            String claveAsesor = records.claveAsesor;
            String numeroCliente = records.numeroCliente;
            DateTime now = DateTime.now();
            DateTime oneMinuteLater = now.addMinutes(1);
            DateTime oneMinuteEarlier = now.addMinutes(-1);
            Id userId = [SELECT Id, ID_ASESOR__c  FROM User WHERE ID_ASESOR__c = : claveAsesor LIMIT 1].Id;
            if (records.estado == STATUS_ALL) {
                tasksAndEvents.addAll([SELECT Id,Type, Subject,TaskSubType, ActivityDate, Owner.Name, Description,OwnerId, CreatedDate,Status FROM Task WHERE Account.Client_ID__c = :numeroCliente AND TaskSubType!='Email']);
                tasksAndEvents.addAll([SELECT Id, Subject, ActivityDate, Owner.Name, ActivityDateTime, OwnerId, Description, EndDateTime, StartDateTime, CreatedDate FROM Event WHERE Account.Client_ID__c = :numeroCliente]);
            }else if (records.estado == STATUS_NEXT || records.estado == STATUS_DUE) {
                System.debug('2El valor de records.estado es: ' + records.estado);
                String conditionEvent = records.estado == STATUS_NEXT ? ' >= TODAY' : ' = null';
                String conditionTask = records.estado == STATUS_NEXT ? ' >= TODAY OR ActivityDate = null) AND  status != :COMPLETED'  : ' < TODAY  AND status != :COMPLETED)';

                String queryStringEvents = 'SELECT Id, Owner.Name, Subject,CreatedDate, ActivityDate,ActivityDateTime, OwnerId, Description, EndDateTime, StartDateTime FROM Event WHERE (Account.Client_ID__c = :numeroCliente) AND EndDateTime' + conditionEvent;
                String queryStringTask = 'SELECT Id,Owner.Name,Type,TaskSubType, Subject,CreatedDate,Status, ActivityDate, OwnerId, Description FROM Task WHERE TaskSubType!=\'Email\' AND (Account.Client_ID__c = :numeroCliente) AND (ActivityDate' + conditionTask;
                System.debug('queryStringTask es: ' + queryStringTask);
                

                try {
                    tasksAndEvents.addAll(Database.query(queryStringEvents));
                    tasksAndEvents.addAll(Database.query(queryStringTask));
                    
                    System.debug(tasksAndEvents);
                } catch (QueryException ex) {
                    System.debug(ex);
                    handleQueryException(ex, resultado, ltsTask);
                }
            } else {
                System.debug('El valor ingresado es incorrecto.');
                resultado.result = false;
                resultado.message = 'El valor ingresado es incorrecto.';
                ltsTask.add(resultado);
                return ltsTask;
            }
            if (!tasksAndEvents.isEmpty()) {
                for (SObject record : tasksAndEvents) {
                    Data_Structure_Handle_Task.ActividadWrapper act = new Data_Structure_Handle_Task.ActividadWrapper();
                    
                    act.asunto = (String)record.get('Subject');
                    act.fechaVencimiento = record.get('ActivityDate') != null ? ((Date)record.get('ActivityDate')).format() : null;
                    act.asignado_a = Test.isRunningTest() ? 'Test':(String)(record.getSObject('Owner')).get('Name');
                    act.salesforceId = (Id)record.get('Id');
                    act.Descripcion = (String)record.get('Description');
                    act.Comentarios = (String)record.get('Description');
                    act.fechaDeCreacion = ((DateTime)record.get('CreatedDate')).format('dd/MM/yyyy');
                    act.horaDeCreacion = ((DateTime)record.get('CreatedDate')).format('HH:mm:ss');
                    Data_Structure_Handle_Task.ResultTasksAndEvents registro = new Data_Structure_Handle_Task.ResultTasksAndEvents();
                    
                    registro.tipo = (record.getSObjectType() == Task.SObjectType) ? (record.get('TaskSubType') =='Call') ? 'Llamada' : TASK_TYPE : ((record.getSObjectType() == Event.SObjectType) ? EVENT_TYPE : null); 
                    registro.Actividades = new List<Data_Structure_Handle_Task.ActividadItem>();
                    Data_Structure_Handle_Task.ActividadItem actividad = new Data_Structure_Handle_Task.ActividadItem();
                    actividad.Asunto = act.asunto;
                    actividad.FechaVencimiento = act.fechaVencimiento;
                    actividad.Asignado_a = act.asignado_a;
                    actividad.Comentarios = act.Descripcion;
                    actividad.Descripcion = act.Descripcion;
                    actividad.SalesforceId = act.salesforceId;
                    actividad.FechaDeCreacion = act.fechaDeCreacion;
                    actividad.HoraDeCreacion = act.horaDeCreacion;
                    
                    String EstadoItem = null;
                    
                    if (record.getSObjectType() == Event.SObjectType) {
                        actividad.FechaInicio = record.get('StartDateTime') != null ? ((DateTime)record.get('StartDateTime')).format('dd/MM/yyyy') : null;
                        actividad.HoraInicio = record.get('StartDateTime') != null ? ((DateTime)record.get('StartDateTime')).format('HH:mm:ss') : null;
                        actividad.FechaFin = record.get('EndDateTime') != null ? ((DateTime)record.get('EndDateTime')).format('dd/MM/yyyy') : null;
                        actividad.HoraFin = record.get('EndDateTime') != null ? ((DateTime)record.get('EndDateTime')).format('HH:mm:ss') : null;
                        
                        if( 
                            (System.today() <= ((Date)record.get('ActivityDate')))
                        ){
                            EstadoItem = 'Proxima';
                        }else {
                            EstadoItem = 'Completado';
                        }
                        
                    }else {
                        if(((String)record.get('Status')).equals('Completado')){
                            EstadoItem = (String)record.get('Status');
                        }else {
                            if( 
                                record.get('ActivityDate') == null
                                || (System.today() <= ((Date)record.get('ActivityDate')))
                            ){
                                System.debug(actividad.Asunto+' '+((Date)record.get('ActivityDate')));
                                EstadoItem = 'Proxima';
                            }else {
                                System.debug(actividad.Asunto+' '+((Date)record.get('ActivityDate')));
                                EstadoItem = 'Vencida';
                            }
                        }
                    }
                    
                    actividad.Estado = EstadoItem;
                    
                    registro.Actividades.add(actividad);
                    resultado.registros.add(registro);
                    registro.Count = registro.Actividades.size();
                }
                resultado.result = true;
                resultado.message = 'OK';
                ltsTask.add(resultado);
            } else {
                resultado.result = false;
                resultado.message = 'No se encontraron registros';
                ltsTask.add(resultado);
                return ltsTask;
            }
        } catch (QueryException ex) {
            handleQueryException(ex, resultado, ltsTask);
        } catch (Exception ex) {
            handleGeneralException(ex, resultado, ltsTask);
        }
        return ltsTask;
    }
    /**
    * @descripción:Esta es una función de manejo de excepciones para consultas en Apex. Si se produce una excepción de consulta establece el resultado en falso, 
    agrega un mensaje de error a la estructura de resultados
    * @author Harold Garcia - hgarcia@freewayconsulting.com | 14-11-2023
    * @param ex QueryException
    * @param resultado Data_Structure_Handle_Task.ResultTaskWrapper
    * @param ltsTask List<Data_Structure_Handle_Task.ResultTaskWrapper> 
    **/
    private static void handleQueryException(QueryException ex, Data_Structure_Handle_Task.ResultTaskWrapper resultado, List<Data_Structure_Handle_Task.ResultTaskWrapper> ltsTask) {
        resultado.result = false;
        resultado.message = 'Error en la consulta: ' + ex.getMessage();
        ltsTask.add(resultado);
    }
    /**
    * @descripción:Esta función maneja excepciones generales en Apex. Cuando se produce una excepción (Exception), establece el resultado en falso, 
       agrega un mensaje de error junto con la traza de la pila a la estructura de resultados (ResultTaskWrapper), 
       y luego agrega esta estructura a la lista de resultados (ltsTask).
    * @author Harold Garcia - hgarcia@freewayconsulting.com | 14-11-2023
    * @param ex QueryException
    * @param resultado Data_Structure_Handle_Task.ResultTaskWrapper
    * @param ltsTask List<Data_Structure_Handle_Task.ResultTaskWrapper> 
    **/
    private static void handleGeneralException(Exception ex, Data_Structure_Handle_Task.ResultTaskWrapper resultado, List<Data_Structure_Handle_Task.ResultTaskWrapper> ltsTask) {
        resultado.result = false;
        resultado.message = 'Error general: ' + ex.getMessage() + ' : ' + ex.getStackTraceString();
        ltsTask.add(resultado);
    }

  
    
    public static Data_Structure_Handle_Task.ResultTask createTask(Data_Structure_Handle_Task.TaskObject taskObject){
        
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        
        try{
            if(String.isBlank(taskObject.type)){
                result.result = false;
                result.message = 'There are mandatory fields incomplete [Task Type].';
                return result;
            }
            String taskType = String.valueOf(taskObject.type);
            
            if(String.isBlank(taskObject.ownerId)){
                result.result = false;
                result.message = 'There are mandatory fields incomplete [OwnerId].';
                return result;
            }
            List<User> usuarios = [SELECT Id, ID_ASESOR__c,Name FROM User WHERE ID_ASESOR__c = : taskObject.ownerId];
            
            if(usuarios.isEmpty()){
                result.result = false;
                result.message = 'There is no Asesor with that Id [OwnerId].';
                return result;
            } else{
                
                User usuario = usuarios[0];
                
                Account acc;
                
                if(!String.isBlank(taskObject.bp)){         
                    acc = [SELECT Id FROM Account WHERE Client_ID__c =: taskObject.bp];
                }
                
                if(taskType == 'Tarea'){
                    Task tarea = new Task();
                    
                    tarea.Subject = taskObject.subject;
                    tarea.OwnerId = usuario.Id;
                    tarea.Priority = 'Normal';
                    tarea.Status = 'Abierto';
                    tarea.TaskSubtype = 'Task';
                    if(acc != null){
                        tarea.WhatId = acc.Id;
                    }
                    tarea.Description = taskObject.description;
                    tarea.WhoId = taskObject.whoId;
                    tarea.ActivityDate = taskObject.activityDate;
                    
                    if(Task.SObjectType.getDescribe().isCreateable()){
                        insert tarea;
                        
                        result.result = true;
                        result.message = tarea.Id;
                    }
                    
                } else if(taskType == 'Evento'){
                    
                    if(String.isBlank(taskObject.subject) || taskObject.startDateTime == null || taskObject.endDateTime == null){
                        result.result = false;
                        result.message = 'There are mandatory fields incomplete [Subject, StartDateTime, EndDateTime].';
                        return result;
                    } else{
                        Event evento = new Event();
                        
                        evento.Subject = taskObject.subject;
                        evento.StartDateTime = taskObject.startDateTime;
                        evento.EndDateTime = taskObject.endDateTime;
                        evento.OwnerId = usuario.Id;
                        
                        if(acc != null){
                            evento.WhatId = acc.Id;
                        }
                        
                        evento.Description = taskObject.description;
                        evento.Location = taskObject.location;
                        evento.WhoId = taskObject.whoId;
                        
                        if(Event.SObjectType.getDescribe().isCreateable()){
                            insert evento;
                            
                            result.result = true;
                            result.message = evento.Id;
                            return result;
                        }
                    }       
                    
                } else if(taskType == 'Email') {
                if(String.isBlank(taskObject.emailObject.fromAddress) || String.isBlank(taskObject.emailObject.toAddress) || (String.isBlank(taskObject.emailObject.subject) && String.isBlank(taskObject.emailObject.textBody))) {
                    result.result = false;
                    result.message = 'There are mandatory fields incomplete [fromAddress, toAddress, subject, textBody].';
                    return result;
                } else {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    
                    if(!String.isBlank(taskObject.bp)){
                        email.setWhatId(acc.Id);
                       
                    }
                    System.debug('LOG CCO: '+usuario.Name);
                    email.setSenderDisplayName(usuario.Name);
                    email.setSaveAsActivity(true);
                    // Configurar los destinatarios
                    String[] emailListTo = taskObject.emailObject.toAddress.split(';');
                     
                    email.setToAddresses(emailListTo);
                    email.setReplyTo(taskObject.emailObject.fromAddress);
                    email.setCcAddresses(new String[]{taskObject.emailObject.fromAddress});
        
                    email.setSubject(taskObject.emailObject.subject);
                    email.setPlainTextBody(taskObject.emailObject.textBody);
                    
                    if (!String.isBlank(taskObject.emailObject.ccoAddress)) {
                        String[] emailListCco = taskObject.emailObject.ccoAddress.split(';');
                        email.setBccAddresses(emailListCco);
                    }

                    if (!String.isBlank(taskObject.emailObject.filebody)) {
                        Blob fileBody = EncodingUtil.base64Decode(taskObject.emailObject.filebody);
                        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                        attachment.setFileName(taskObject.emailObject.fileName);
                        attachment.setBody(fileBody);
                        email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                    }
                    
                    Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

                    if (sendResults[0].isSuccess()) {
                        result.result = true;
                        result.message = 'Email sent successfully';
                    } else {
                        result.result = false;
                        result.message = 'Failed to send email: ' + sendResults[0].getErrors()[0].getMessage();
                    }
                    
                    return result;
                }
            } else if(taskType == 'Llamada'){
                    Task tarea = new Task();
                    
                    tarea.Subject = taskObject.subject;
                    tarea.OwnerId = usuario.Id;
                    tarea.Priority = 'Normal';
                    tarea.Status = 'Completado';
                    tarea.TaskSubtype = 'Call';
                    
                    
                    if(acc != null){
                        tarea.WhatId = acc.Id;
                    }
                    
                    tarea.Description = taskObject.description;
                    tarea.WhoId = taskObject.whoId;
                    tarea.ActivityDate = taskObject.activityDate;
                    
                    if(Task.SObjectType.getDescribe().isCreateable()){
                        insert tarea;
                        
                        result.result = true;
                        result.message = tarea.Id;
                        return result;
                    }
                } else{
                    result.result = false;
                    result.message = 'Invalid Activity type.';
                    return result;
                }
            }
        } catch(Exception e){
            result.result = false;
            result.message = e.getMessage();
        }
        
        return result;
    }
    
    public static Data_Structure_Handle_Task.ResultTask updateTask(Id taskIdParam, Data_Structure_Handle_Task.TaskObject taskObject){
        
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        
        try{
            
            String objectToQuery = String.valueOf(taskIdParam.getSObjectType());
            
            if(objectToQuery == 'Task'){
                Task tarea = new Task();
                
                tarea.Id = taskIdParam;
                
                if(!String.isBlank(taskObject.subject)){
                    tarea.Subject = taskObject.subject;
                }
                if(!String.isBlank(taskObject.ownerId)){
                    User usuario = [SELECT Id, Name, ID_ASESOR__c FROM User WHERE ID_ASESOR__c = : taskObject.ownerId LIMIT 1];
                    tarea.OwnerId = usuario.Id;
                }
                if(!String.isBlank(taskObject.whatId)){
                    tarea.WhatId = taskObject.whatId;
                }
                if(!String.isBlank(taskObject.description)){
                    tarea.Description = taskObject.description;
                }
                if(!String.isBlank(taskObject.whoId)){
                    tarea.WhoId = taskObject.whoId;
                }
                if(taskObject.activityDate != null){
                    tarea.ActivityDate = taskObject.activityDate;
                }
                if(!String.isBlank(taskObject.status)){
                    tarea.Status = taskObject.status;
                }
                
                if(Task.SObjectType.getDescribe().isCreateable()){
                    upsert tarea;
                    
                    result.result = true;
                    result.message = tarea.Id;
                }
                
            } else if(objectToQuery == 'Event'){
                Event evento = new Event();
                
                evento.Id = taskIdParam;
                
                if(!String.isBlank(taskObject.subject)){
                    evento.Subject = taskObject.subject;
                }
                if(taskObject.startDateTime != null){
                    evento.StartDateTime = taskObject.startDateTime;
                }
                if(taskObject.endDateTime != null){
                    evento.EndDateTime = taskObject.endDateTime;
                }
                if(!String.isBlank(taskObject.whatId)){
                    evento.WhatId = taskObject.whatId;
                }                
                if(!String.isBlank(taskObject.description)){
                    evento.Description = taskObject.description;
                }
                if(!String.isBlank(taskObject.location)){
                    evento.Location = taskObject.location;
                }                
                if(!String.isBlank(taskObject.whoId)){
                    evento.WhoId = taskObject.whoId;
                }
                
                if(Event.SObjectType.getDescribe().isCreateable()){
                    upsert evento;
                    
                    result.result = true;
                    result.message = evento.Id;
                }
                
            } else{
                result.result = false;
                result.message = 'Invalid Activity Type';
            }
        } catch(Exception e){
            result.result = false;
            result.message = e.getMessage();
        }
        
        return result;
    }
    
    public static Data_Structure_Handle_Task.ResultTask deleteTaskById(Id taskId){
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        
        try{
            String objectToQuery = String.valueOf(taskId.getSObjectType());
            
            if(objectToQuery == 'Task'){
                Task event = [SELECT Id FROM Task WHERE Id =: taskId LIMIT 1];
                delete event;
                
                result.result = true;
                result.message = 'The activity was delete successfully.'; 
                
            } else if (objectToQuery == 'Event'){
                Event event = [SELECT Id FROM Event WHERE Id =: taskId LIMIT 1];
                delete event;
                
                result.result = true;
                result.message = 'The activity was delete successfully.'; 
                
            } else{
                result.message = 'The ID does not correspond to a record of an activity object.';
                result.result = false;
            }
            
        } catch(Exception e){
            result.result = false;
            result.message = e.getMessage();
        }
        return result;
    }
    
}