@isTest
public class ACT_TasksApiRest_Test {
    
    private static final String URL_BASE = 'services/apexrest/ACT_Tasks/';
    
    @TestSetup
    static void makeData(){

        Account acc = new Account(
            FirstName = 'Test',
            LastName = 'Moral',
            Client_ID__c = '9876'        
        );
        insert acc;
        
        Task tarea = new Task(
            Subject = 'Llamada', 
        	TaskSubtype = 'Task',
            Priority = 'Normal',
            Status = 'Abierto',
            WhatId = acc.Id,
            ActivityDate = System.today()
        );
        insert tarea;
        
        Event event = new Event(
            Subject = 'Llamada', 
            StartDateTime = Datetime.now(),
            EndDatetime = Datetime.now().addDays(1)
        );
        insert event;
    }
    
    @isTest
    static void createTask(){
        Data_Structure_Handle_Task.TaskObject taskToCreate = new Data_Structure_Handle_Task.TaskObject();
        
        taskToCreate.type = 'Tarea';
        taskToCreate.subject = 'Llamada';
        taskToCreate.description = 'Descripcion...';
        taskToCreate.activityDate = Date.today();
        taskToCreate.bp = '9876';
        taskToCreate.ownerId = 'E001680';
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE;
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        
        ACT_TaskApiRest.doPost(taskToCreate);
        
        Test.stopTest();
        
    }
    
    @isTest
    static void createEmail(){
        Data_Structure_Handle_Task.TaskObject taskToCreate = new Data_Structure_Handle_Task.TaskObject();
        
        taskToCreate.type = 'Email';
        taskToCreate.bp = '9876';
        taskToCreate.ownerId = 'E001680';
 
        Data_Structure_Handle_Task.EmailObject emailObject = new Data_Structure_Handle_Task.EmailObject();

        emailObject.textBody = 'Cuerpo del correo..';
        emailObject.subject = 'Asunto del correo..';
        emailObject.fromAddress = 'sf_actinver@freewayconsulting.net';
        emailObject.toAddress = 'amassieri@freewayconsulting.com';
        emailObject.ccoAddress = 'amassieri@freewayconsulting.com';
        emailObject.fileName = 'Nombre archivo adj...';
        emailObject.fileBody = 'SGVsbG8gV29ybGQ=';
        
        taskToCreate.emailObject = emailObject;
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE;
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doPost(taskToCreate);
        Test.stopTest();
        
    }
    
    @isTest
    static void createCall(){
        Data_Structure_Handle_Task.TaskObject taskToCreate = new Data_Structure_Handle_Task.TaskObject();
        
        taskToCreate.type = 'Llamada';
        taskToCreate.subject = 'Llamada';
        taskToCreate.description = 'Descripcion...';
        taskToCreate.bp = '9876';
        taskToCreate.ownerId = 'E001680';
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE;
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doPost(taskToCreate);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void createEvent(){
        Data_Structure_Handle_Task.TaskObject taskToCreate = new Data_Structure_Handle_Task.TaskObject();
        
        taskToCreate.type = 'Evento';
        taskToCreate.subject = 'Llamada';
        taskToCreate.description = 'Descripcion...';
        taskToCreate.startDateTime = Datetime.now();
        taskToCreate.endDateTime = Datetime.now();
        taskToCreate.bp = '9876';
        taskToCreate.ownerId = 'E001680';
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE;
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doPost(taskToCreate);
        Test.stopTest();
        
        
    }
    
     @isTest
    static void createExeption(){
        Data_Structure_Handle_Task.TaskObject taskToCreate = new Data_Structure_Handle_Task.TaskObject();
        
        taskToCreate.type = 'Evento';
        taskToCreate.subject = 'Llamada';
        taskToCreate.description = 'Descripcion...';
        taskToCreate.startDateTime = Datetime.now();
        taskToCreate.endDateTime = Datetime.now();
        taskToCreate.bp = '9876';
        taskToCreate.ownerId = '123456';
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE;
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        
        Test.startTest();
        ACT_TaskApiRest.doPost(taskToCreate);
        Test.stopTest();
       
        
    }
    
 @isTest
    static void testdoPostExceptionHandling() {
        
        Data_Structure_Handle_Task.TaskObject invalidTaskObject = new Data_Structure_Handle_Task.TaskObject();
        
        invalidTaskObject.type = '1234';
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE;
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        ACT_TaskApiRest.doPost(invalidTaskObject);
        Test.stopTest();

        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), false);
        
    }

    
    @isTest
    static void createActivityError(){
        Data_Structure_Handle_Task.TaskObject taskToCreate = new Data_Structure_Handle_Task.TaskObject();
        
        taskToCreate.subject = 'Llamada';
        taskToCreate.description = 'Descripcion...';
        taskToCreate.startDateTime = Datetime.now();
        taskToCreate.endDateTime = Datetime.now();
        taskToCreate.bp = '9876';
        taskToCreate.ownerId = 'E001680';
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE;
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doPost(taskToCreate);
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), false);
    }
    
    @isTest
    static void deleteTaskOk(){
        
        Task tarea = [SELECT Id FROM Task ORDER BY CreatedDate DESC LIMIT 1];
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + tarea.Id;
        request.httpMethod = 'DELETE';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doDelete();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), true);
    }
    
    @isTest
    static void deleteEventOk(){
        
        Event event = [SELECT Id FROM Event ORDER BY CreatedDate DESC LIMIT 1];
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + event.Id;
        request.httpMethod = 'DELETE';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doDelete();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), true);
    }
    
    @isTest
    static void deleteActivityWithoutIdParam(){
                
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE;
        request.httpMethod = 'DELETE';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doDelete();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), false);
    }
    
    @isTest
    static void deleteActivityWithInvalidIdFormatParam(){
                
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + 'noExiste';
        request.httpMethod = 'DELETE';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doDelete();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), false);
    }
    
    @isTest
    static void deleteActivityWithInvalidIdObjectParam(){
        
        Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
                
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + acc.Id;
        request.httpMethod = 'DELETE';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doDelete();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), false);
    }
    
    @isTest
    static void updateTask(){
        
        Data_Structure_Handle_Task.TaskObject taskToCreate = new Data_Structure_Handle_Task.TaskObject();
        
        Task tarea = [SELECT Id FROM Task ORDER BY CreatedDate DESC LIMIT 1];

        taskToCreate.subject = 'Llamada';
        taskToCreate.description = 'Descripcion...';
        taskToCreate.activityDate = Date.today();
        taskToCreate.bp = '9876';
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + tarea.Id;
        request.httpMethod = 'PUT';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doPut(taskToCreate);
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), true);
    }
    
    @isTest
    static void updateEvent(){
        
        Data_Structure_Handle_Task.TaskObject taskToCreate = new Data_Structure_Handle_Task.TaskObject();
        
        Event event = [SELECT Id FROM Event ORDER BY CreatedDate DESC LIMIT 1];

        taskToCreate.subject = 'Llamada';
        taskToCreate.description = 'Descripcion...';
        taskToCreate.startDateTime = Datetime.now();
        taskToCreate.endDateTime = Datetime.now();
        taskToCreate.bp = '9876';
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + event.Id;
        request.httpMethod = 'PUT';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doPut(taskToCreate);
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), true);
    }
    
    @isTest
    static void updateActivityWithInvalidIdObjectParam(){
        
        Data_Structure_Handle_Task.TaskObject taskToCreate = new Data_Structure_Handle_Task.TaskObject();
        
        Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];

        taskToCreate.subject = 'Llamada';
        taskToCreate.description = 'Descripcion...';
        taskToCreate.startDateTime = Datetime.now();
        taskToCreate.endDateTime = Datetime.now();
        taskToCreate.bp = '9876';
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + acc.Id;
        request.httpMethod = 'PUT';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doPut(taskToCreate);
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), false);
    }
    
    @isTest
    static void updateActivityWithoutIdParam(){
        
        Data_Structure_Handle_Task.TaskObject taskToCreate = new Data_Structure_Handle_Task.TaskObject();
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE;
        request.httpMethod = 'PUT';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doPut(taskToCreate);
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), false);
    }
    
    @isTest
    static void updateActivityWithInvalidIdFormatParam(){
        
        Data_Structure_Handle_Task.TaskObject taskToCreate = new Data_Structure_Handle_Task.TaskObject();
                
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + 'noExiste';
        request.httpMethod = 'PUT';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doPut(taskToCreate);
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), false);
    }
    
    @isTest
    static void testInvalidTaskApiRestDoGet(){
        
                
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + 'noExiste';
        request.httpMethod = 'GET';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doGet();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), false);
    }
    
     @isTest
    static void testvalidTaskApiRestDoGet(){
        
        string tarea = [SELECT Id FROM Task ORDER BY CreatedDate DESC LIMIT 1].id;
        system.debug('Tarea ID> ' + tarea);
        RestRequest request = new RestRequest();
        request.requestUri = '/ACT_Tasks/' + tarea;
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_TaskApiRest.doGet();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), true);
    }
    

    @isTest
    static void testvalidTaskAndEventApiRestDoGet(){
        
        string tarea = [SELECT Id FROM Task ORDER BY CreatedDate DESC LIMIT 1].id;
        RestRequest request = new RestRequest();
        request.requestUri = '/ActivityList/';
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Data_Structure_Handle_Task.TaskObject records = new Data_Structure_Handle_Task.TaskObject();
        records.numeroCliente = '9876';
        records.estado = 'Todas';
        Test.startTest();
        ACT_TaskAndEventApiRest.getTaskList(records);
        Test.stopTest();
    }
    
    @isTest
    static void testvalidTaskAndEventApiRestDoGetProximas(){
        
        string tarea = [SELECT Id FROM Task ORDER BY CreatedDate DESC LIMIT 1].id;
        RestRequest request = new RestRequest();
        request.requestUri = '/ActivityList/';
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Data_Structure_Handle_Task.TaskObject records = new Data_Structure_Handle_Task.TaskObject();
        records.numeroCliente = '9876';
        records.estado = 'Proximas';
        Test.startTest();
        ACT_TaskAndEventApiRest.getTaskList(records);
        Test.stopTest();
    }
    
    @isTest
    static void testDoGetWithException() {

        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/ACT_Event_Contact/\'';
        RestResponse res = new RestResponse();
        RestContext.request = request;
		RestContext.response = res;
        Test.startTest();
        ACT_Event_Contact.doGet();
        Test.stopTest();


        RestResponse response = RestContext.response;
        System.assertEquals('application/json', response.headers.get('Content-Type'));
        System.assertNotEquals(null, response.responseBody);


        Data_Structure_Handle_Task.ResponseWithRelatedPerson result = (Data_Structure_Handle_Task.ResponseWithRelatedPerson) JSON.deserialize(response.responseBody.toString(), Data_Structure_Handle_Task.ResponseWithRelatedPerson.class);
        System.assertEquals(false, result.result);
        System.assertNotEquals(null, result.message);
    }
    
    @isTest
    static void testDoGet() {
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/ACT_Event_Contact/TestName';
        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        Test.startTest();
        ACT_Event_Contact.doGet();
        Test.stopTest();
        
        
        RestResponse response = RestContext.response;
        System.assertEquals('application/json', response.headers.get('Content-Type'));
        System.assertNotEquals(null, response.responseBody);
        
        
        Data_Structure_Handle_Task.ResponseWithRelatedPerson result = (Data_Structure_Handle_Task.ResponseWithRelatedPerson) JSON.deserialize(response.responseBody.toString(), Data_Structure_Handle_Task.ResponseWithRelatedPerson.class);
        System.assertEquals(false, result.result);
        System.assertNotEquals(null, result.message);
    }
    
    @isTest
    static void testDoGetRequiredName() {
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/ACT_Event_Contact/';
        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        Test.startTest();
        ACT_Event_Contact.doGet();
        Test.stopTest();
        
        
        RestResponse response = RestContext.response;
        System.assertEquals('application/json', response.headers.get('Content-Type'));
        System.assertNotEquals(null, response.responseBody);
        
        
        Data_Structure_Handle_Task.ResponseWithRelatedPerson result = (Data_Structure_Handle_Task.ResponseWithRelatedPerson) JSON.deserialize(response.responseBody.toString(), Data_Structure_Handle_Task.ResponseWithRelatedPerson.class);
        System.assertEquals(false, result.result);
        System.assertNotEquals(null, result.message);
    }
    
}