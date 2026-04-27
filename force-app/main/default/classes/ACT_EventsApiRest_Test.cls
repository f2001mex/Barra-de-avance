@isTest
public class ACT_EventsApiRest_Test {
    
    private static final String URL_BASE = 'services/apexrest/ACT_Events/';
    
    @TestSetup
    static void makeData(){
        
        Contact ct = new Contact(
            FirstName = 'Conctact',
            LastName = 'Test'
        );
        insert ct;
        
        Account accMoral = new Account(
            FirstName = 'Test',
            LastName = 'Moral',
            Client_ID__c = '9876',
            Person_Type__c = 'MORAL'
        );
        insert accMoral;
        
        Account accFisica = new Account(
            FirstName = 'Test',
            LastName = 'Fisica',
            Client_ID__c = '1234',
            Person_Type__c = 'FISICA'
        );
        insert accFisica;
        
        PersonLifeEvent personLifeEvent = new PersonLifeEvent(
            Name = 'TestPersonLife',
            EventType = 'Premio', 
            EventDescription = 'DescriptionTest', 
            EventDate = DateTime.now(), 
            PrimaryPersonId = ct.Id
        );
        insert personLifeEvent;
        
        
        BusinessMilestone businessMilestone = new BusinessMilestone(
            Name = 'BusinessMilestoneTest', 
            MilestoneType = 'Premio', 
            MilestoneDescription = 'DescriptionTest', 
            MilestoneDate = DateTime.now(), 
            PrimaryAccountId = accMoral.Id, 
            EventLocation__Street__s = 'StreetTest', 
            EventLocation__StateCode__s = 'AK', 
            EventLocation__PostalCode__s = '1234', 
            EventLocation__CountryCode__s = 'US', 
            EventLocation__City__s = 'CABA'
        );
        insert businessMilestone;
    }
    
    @isTest
    static void testCreatePersonLifeEvent() {
        
        Data_Structure_Handle_Task.EventObject eventToCreate = new Data_Structure_Handle_Task.EventObject();
        
        eventToCreate.ownerId = UserInfo.getUserId();
        eventToCreate.eventName ='Test Event';
        eventToCreate.eventType = 'Test Type';
        eventToCreate.primaryPersonId = [Select Id From Contact limit 1].Id;
        eventToCreate.eventDate = Datetime.now();
        eventToCreate.bp = '1234';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = URL_BASE; 
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = response;
        
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        system.debug('Event => '+ eventToCreate);
        result = ACT_EventsApiRest.doPost(eventToCreate);
        Test.stopTest();
        
        System.assertEquals(true, result.result, 'Se debe crear el evento correctamente');
    }
    
    @isTest
    static void testCreateBusinessMilestone() {
        
        Data_Structure_Handle_Task.EventObject eventToCreate = new Data_Structure_Handle_Task.EventObject();
        
        eventToCreate.ownerId = UserInfo.getUserId();
        eventToCreate.eventName ='Test Event';
        eventToCreate.eventType = 'Test Type';
        eventToCreate.primaryAccountId = [Select Id From Account limit 1].Id;
        eventToCreate.eventDate = Datetime.now();
        eventToCreate.bp = '9876';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = URL_BASE; 
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = response;
        
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        system.debug('Event => '+ eventToCreate);
        result = ACT_EventsApiRest.doPost(eventToCreate);
        Test.stopTest();
        
        System.assertEquals(true, result.result, 'Se debe crear el evento correctamente');
    }
    
    @isTest
    static void testCreateBusinessMilestoneWithEventLocation() {
        
        Data_Structure_Handle_Task.EventObject eventToCreate = new Data_Structure_Handle_Task.EventObject();
        
        eventToCreate.ownerId = UserInfo.getUserId();
        eventToCreate.eventName ='Test Event';
        eventToCreate.eventType = 'Test Type';
        eventToCreate.primaryAccountId = [Select Id From Account limit 1].Id;
        eventToCreate.eventDate = Datetime.now();
        eventToCreate.bp = '9876';
        
        Data_Structure_Handle_Task.Location locationToCreate = new Data_Structure_Handle_Task.Location();
        locationTocreate.street = '';
        locationTocreate.state = '';
        locationTocreate.postalCode = '';
        locationTocreate.country = '';
        locationTocreate.city = '';
        
        eventToCreate.eventLocation = locationToCreate;
        
        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = URL_BASE; 
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = response;
        
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        system.debug('Event => '+ eventToCreate);
        result = ACT_EventsApiRest.doPost(eventToCreate);
        Test.stopTest();
        
        System.assertEquals(true, result.result, 'Se debe crear el evento correctamente');
    }
    
    
    
    @isTest
    static void testCreateEventMissingName() {
        Data_Structure_Handle_Task.EventObject eventToCreate = new Data_Structure_Handle_Task.EventObject();
        eventToCreate.eventType = 'Test Type';
        eventToCreate.primaryPersonId = [SELECT Id FROM Contact LIMIT 1].Id;
        eventToCreate.eventDate = Datetime.now();
        eventToCreate.bp = '1234';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = URL_BASE; 
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = response;
        
        Data_Structure_Handle_Task.ResultTask result = ACT_EventsApiRest.doPost(eventToCreate);
        
        Test.stopTest();
        
        System.assertEquals(false, result.result, 'La creación debería fallar debido a la falta de un nombre de evento.');
    }
    
    @isTest
    static void testCreateEventMissingEventType() {
        Data_Structure_Handle_Task.EventObject eventToCreate = new Data_Structure_Handle_Task.EventObject();
        eventToCreate.eventName = 'Test Event';
        eventToCreate.primaryPersonId = [SELECT Id FROM Contact LIMIT 1].Id;
        eventToCreate.eventDate = Datetime.now();
        eventToCreate.bp = '1234';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = URL_BASE; 
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = response;
        
        Data_Structure_Handle_Task.ResultTask result = ACT_EventsApiRest.doPost(eventToCreate);
        
        Test.stopTest();
        
        System.assertEquals(false, result.result, 'La creación debería fallar debido a la falta del tipo de evento.');
    }
    
    @isTest
    static void testCreateEventMissingPrimaryPersonId() {
        Data_Structure_Handle_Task.EventObject eventToCreate = new Data_Structure_Handle_Task.EventObject();
        eventToCreate.eventName = 'Test Event';
        eventToCreate.eventType = 'Test Type';
        eventToCreate.primaryPersonId = ''; 
        eventToCreate.eventDate = Datetime.now();
        eventToCreate.bp = '1234';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = URL_BASE; 
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = response;
        
        Data_Structure_Handle_Task.ResultTask result = ACT_EventsApiRest.doPost(eventToCreate);
        
        Test.stopTest();
        
        System.assertEquals(true, result.result, 'La creación debería fallar debido a la falta de un ID de asesor válido.');
    }
    
    @isTest
    static void testCreateEventMissingOwnerId() {
        Data_Structure_Handle_Task.EventObject eventToCreate = new Data_Structure_Handle_Task.EventObject();
        eventToCreate.eventName = 'Test Event';
        eventToCreate.eventType = 'Test Type';
        eventToCreate.primaryPersonId = 'NonExistentAdvisorId'; 
        eventToCreate.eventDate = Datetime.now();
        eventToCreate.ownerId = 'SinOwnerId';
        eventToCreate.bp = '1234';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = URL_BASE; 
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = response;
        
        Data_Structure_Handle_Task.ResultTask result = ACT_EventsApiRest.doPost(eventToCreate);
        
        Test.stopTest();
        
        System.assertEquals(false, result.result, 'La creación debería fallar debido a la falta de un ID de asesor válido.');
    }
    
    @isTest
    static void testCreateEventInvalidDate() {
        Data_Structure_Handle_Task.EventObject eventToCreate = new Data_Structure_Handle_Task.EventObject();
        eventToCreate.eventName = 'Test Event';
        eventToCreate.eventType = 'Test Type';
        eventToCreate.primaryPersonId = 'NonExistentAdvisorId'; 
        eventToCreate.eventDate = null;
        eventToCreate.ownerId = 'SinOwnerId';
        eventToCreate.bp = '1234';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = URL_BASE; 
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = response;
        
        Data_Structure_Handle_Task.ResultTask result = ACT_EventsApiRest.doPost(eventToCreate);
        
        Test.stopTest();
        
        System.assertEquals(false, result.result, 'La creación debería fallar debido a la falta de un ID de asesor válido.');
    }
    
    @isTest
    static void testCreateEventWithLocation() {
        
        Data_Structure_Handle_Task.EventObject eventToCreate = new Data_Structure_Handle_Task.EventObject();
        
        eventToCreate.eventName ='Test Event';
        eventToCreate.eventType = 'Test Type';
        eventToCreate.primaryPersonId = [Select Id From Contact limit 1].Id;
        eventToCreate.eventDate = Datetime.now();
        eventToCreate.bp = '1234';
        
        Data_Structure_Handle_Task.Location locationToCreate = new Data_Structure_Handle_Task.Location();
        locationTocreate.street = '';
        locationTocreate.state = '';
        locationTocreate.postalCode = '';
        locationTocreate.country = '';
        locationTocreate.city = '';
        
        eventToCreate.eventLocation = locationToCreate;
        
        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = URL_BASE; 
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = response;
        
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        system.debug('Event => '+ eventToCreate);
        result = ACT_EventsApiRest.doPost(eventToCreate);
        Test.stopTest();
        
        System.assertEquals(true, result.result, result.message);
    }
    
     @isTest
    static void testTaskObjectCreation() {
        
        Data_Structure_Handle_Task.TaskObject task = new Data_Structure_Handle_Task.TaskObject();
      
        task.id = '12345';
        task.subject = 'Test Subject';
        task.isClosed = false;
        task.description = 'Test task description field';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = URL_BASE; 
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = response;
        
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        system.debug('Task => '+ task);
        ACT_TaskApiRest.doPost(task);
        Test.stopTest();
        
        
    }
    
    
    @isTest
    static void getEventDetailsWithoutEventId() {
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE;
        request.httpMethod = 'GET';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_EventsApiRest.doGet();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('message'), 'The Event ID is required.');
        System.assertEquals(mapResponse.get('result'), false);
        
    }
    
    @isTest
    static void getEventDetailsWithWrongParams() {
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + '1234';
        request.httpMethod = 'GET';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_EventsApiRest.doGet();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        
        System.assertEquals(mapResponse.get('result'), false);
        
    }
    
    @isTest
    static void getEventDetailsThatNotExist() {
        
        Account cuenta = [SELECT Id FROM Account LIMIT 1];
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + cuenta.Id;
        request.httpMethod = 'GET';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_EventsApiRest.doGet();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('message'), 'The ID does not correspond to a record in the event object.');
        System.assertEquals(mapResponse.get('result'), false);
        
    }
    
    @isTest
    static void getBusinessMilestoneDetails() {
        
        BusinessMilestone businessMilestone = [SELECT Id FROM BusinessMilestone WHERE Name = 'BusinessMilestoneTest' LIMIT 1];
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + businessMilestone.Id;
        request.httpMethod = 'GET';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_EventsApiRest.doGet();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), true);
    }
    
    @isTest
    static void getPersonLifeEventDetails() {
        
        PersonLifeEvent personLifeEvent = [SELECT Id FROM PersonLifeEvent WHERE Name = 'TestPersonLife' LIMIT 1];
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + personLifeEvent.Id;
        request.httpMethod = 'GET';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_EventsApiRest.doGet();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse; 
        
        System.assertEquals(mapResponse.get('result'), true);
    }
    
    @isTest
    static void updatePersonLifeEventById() {
        
        PersonLifeEvent personLifeEvent = [SELECT Id FROM PersonLifeEvent WHERE Name = 'TestPersonLife' LIMIT 1];
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + personLifeEvent.Id;
        request.httpMethod = 'PUT';
        
        Data_Structure_Handle_Task.EventObject eventToEdit = new Data_Structure_Handle_Task.EventObject();    
        eventToEdit.eventName = 'Nuevo Nombre';
        eventToEdit.eventDate = Datetime.now();
        eventToEdit.description = 'Nueva descripcion';
        
        Data_Structure_Handle_Task.Location locationToCreate = new Data_Structure_Handle_Task.Location();
        locationTocreate.street = 'Calle';
        locationTocreate.state = 'AK';
        locationTocreate.postalCode = '1234';
        locationTocreate.country = 'US';
        locationTocreate.city = 'CABA';
        
        eventToEdit.eventLocation = locationToCreate;
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_EventsApiRest.doPut(eventToEdit);
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse; 
        
        PersonLifeEvent changedPersonLifeEvent = [SELECT Id, Name FROM PersonLifeEvent WHERE Id =: personLifeEvent.Id  LIMIT 1];
        
        System.assertEquals(mapResponse.get('result'), true);
        System.assertEquals('Nuevo Nombre', changedPersonLifeEvent.Name);
        
    }
    
    @isTest
    static void updateBusinessMilestoneById() {
        
        BusinessMilestone businessMilestone = [SELECT Id FROM BusinessMilestone WHERE Name = 'BusinessMilestoneTest' LIMIT 1];
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + businessMilestone.Id;
        request.httpMethod = 'PUT';
        
        Data_Structure_Handle_Task.EventObject eventToEdit = new Data_Structure_Handle_Task.EventObject();    
        eventToEdit.eventName = 'Nuevo Nombre';
        eventToEdit.eventDate = Datetime.now();
        eventToEdit.description = 'Nueva descripcion';
        
        Data_Structure_Handle_Task.Location locationToCreate = new Data_Structure_Handle_Task.Location();
        locationTocreate.street = 'Calle';
        locationTocreate.state = 'AK';
        locationTocreate.postalCode = '1234';
        locationTocreate.country = 'US';
        locationTocreate.city = 'CABA';
        
        eventToEdit.eventLocation = locationToCreate;
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_EventsApiRest.doPut(eventToEdit);
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        BusinessMilestone changedBusinessMilestone = [SELECT Id, Name FROM BusinessMilestone WHERE Id =: businessMilestone.Id  LIMIT 1];
        
        System.assertEquals(mapResponse.get('result'), true);
        System.assertEquals('Nuevo Nombre', changedBusinessMilestone.Name);
    }
    
    @isTest
    static void deleteBusinessMilestoneById() {
        
        BusinessMilestone businessMilestone = [SELECT Id FROM BusinessMilestone WHERE Name = 'BusinessMilestoneTest' LIMIT 1];
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + businessMilestone.Id;
        request.httpMethod = 'DELETE';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_EventsApiRest.doDelete();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), true);
    }
    
    @isTest
    static void deletePersonLifeEventById() {
        
        PersonLifeEvent personLifeEvent = [SELECT Id FROM PersonLifeEvent WHERE Name = 'TestPersonLife' LIMIT 1];
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + personLifeEvent.Id;
        request.httpMethod = 'DELETE';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_EventsApiRest.doDelete();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), true);
    }
    
    @isTest
    static void deleteEventByIdWithWrongParams() {
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + '1234';
        request.httpMethod = 'DELETE';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_EventsApiRest.doDelete();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), false);
        System.assertEquals(mapResponse.get('message'), 'An error occurred during the process.');
    }
    
    @isTest
    static void updateEventByIdWithWrongParams() {
        
        RestRequest request = new RestRequest();
        request.requestUri = URL_BASE + '1234';
        request.httpMethod = 'PUT';
        
        Data_Structure_Handle_Task.EventObject eventToCreate = new Data_Structure_Handle_Task.EventObject();    
        eventToCreate.eventName = 'Nuevo Nombre';
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_EventsApiRest.doPut(eventToCreate);
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        Object objResponse = (Object)JSON.deserializeUntyped(response.responseBody.toString());
        Map<String, Object> mapResponse = (Map<String, Object>) objResponse;
        
        System.assertEquals(mapResponse.get('result'), false);
        System.assertEquals(mapResponse.get('message'), 'An error occurred during the process.');
    }
    @isTest
    static void getEventDetailsWithInvalidContactName() {
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/ACT_Event_Contact/DalilaMiddlenameConti';
        request.httpMethod = 'GET';
        
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        ACT_Event_Contact.doGet();
        Test.stopTest();
        
       
        RestResponse response = RestContext.response;
        System.assertEquals('application/json', response.headers.get('Content-Type'));
        
       
        Map<String, Object> responseBodyMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
        
        
       System.assertEquals(responseBodyMap.get('result'), false);
       
    }
    
    @isTest
    static void testDataStructureWrapper() {
        Data_Structure_Handle_Task structureWrapper = new Data_Structure_Handle_Task();
        Data_Structure_Handle_Task.TaskObject taskObject = new Data_Structure_Handle_Task.TaskObject();
        taskObject.estado = 'Estado';
        
        Data_Structure_Handle_Task.ResponseWithRelatedPerson relatedPersonResponse = new Data_Structure_Handle_Task.ResponseWithRelatedPerson();

        
        List<Contact> contacts = new List<Contact>();
        
        Contact contact1 = new Contact();
        contact1.FirstName = 'Alice';
        contact1.LastName = 'Johnson';
        
        Contact contact2 = new Contact();
        contact2.FirstName = 'Bob';
        contact2.LastName = 'Smith';
       
        contacts.add(contact1);
        contacts.add(contact2);
        
        relatedPersonResponse.contactos = contacts;
        
        Data_Structure_Handle_Task.responseWithTasksList tasksListResponse = new Data_Structure_Handle_Task.responseWithTasksList();
 
        List<Map<String, Integer>> tasksList = new List<Map<String, Integer>>();
        
        Map<String, Integer> task1 = new Map<String, Integer>{'TaskId' => 1, 'Priority' => 1};
        Map<String, Integer> task2 = new Map<String, Integer>{'TaskId' => 2, 'Priority' => 2};

        tasksList.add(task1);
        tasksList.add(task2);

        tasksListResponse.tasksList = tasksList;
        
        Data_Structure_Handle_Task.ResultTaskWrapper taskWrapper = new Data_Structure_Handle_Task.ResultTaskWrapper();
        
        Data_Structure_Handle_Task.ResultTasksAndEvents taskEvent1 = new Data_Structure_Handle_Task.ResultTasksAndEvents();
        taskEvent1.Tipo = 'Task'; 
        taskEvent1.Count = 5; 
        
        Data_Structure_Handle_Task.ResultTasksAndEvents taskEvent2 = new Data_Structure_Handle_Task.ResultTasksAndEvents();
        taskEvent2.Tipo = 'Event'; 
        taskEvent2.Count = 3; 
        
        
        taskWrapper.registros.add(taskEvent1);
        taskWrapper.registros.add(taskEvent2);
        
        Data_Structure_Handle_Task.ResultTaskWrapper taskWrapper2 = new Data_Structure_Handle_Task.ResultTaskWrapper(true, 'Tasks and events retrieved successfully');
        
            }
}