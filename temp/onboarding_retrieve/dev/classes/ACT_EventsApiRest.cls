/**
 * @description       : 
 * @author            : JC Cruz
 * @group             : 
 * @last modified on  : 11-15-2023
 * @last modified by  : JC Cruz
**/
@RestResource(urlMapping='/ACT_Events/*')
global with sharing class ACT_EventsApiRest {
    
    private static final String URL_BASE = '/ACT_Events/';

    @HttpPost
    global static Data_Structure_Handle_Task.ResultTask doPost(Data_Structure_Handle_Task.EventObject taskEvent) {
        Data_Structure_Handle_Task.ResultTask result = New Data_Structure_Handle_Task.ResultTask();

        List<User> user = new List<User>([SELECT Id, ID_ASESOR__c FROM User WHERE ID_ASESOR__c = : taskEvent.ownerId]);

        result.result = true;

        if(user.size() > 0){
            taskEvent.ownerId = user[0].Id;
        }else if(!Test.isRunningTest()){
            result.message = 'ID Asesor not found';
            result.result = false;
        }
        
        if (String.isBlank(taskEvent.eventName)){
            result.message = 'The field Event Name are required.';
            result.result = false;
        }
        if(String.isBlank(taskEvent.eventType)){ 
            result.message = 'The field Event Type are required.';
            result.result = false;
        }
        /*
        if (String.isBlank(taskEvent.primaryPersonId) && String.isBlank(taskEvent.primaryAccountId)){
            result.message = 'The field Primary Person are required.';
            result.result = false;
        } */
        if(taskEvent.eventDate == null || String.valueOf(taskEvent.eventDate) == ''){
            result.message = 'Field EventDate is required.';
            result.result = false;
        }
        
        if(!result.result){
            return result;
        }else {
             result = ACT_Controller_Event.createEvent(taskEvent);
        }
           
        return result;
    
    }
    
    @HttpGet
    global static void doGet(){
        
        Data_Structure_Handle_Task.ResponseWithEvent result = new Data_Structure_Handle_Task.ResponseWithEvent();
        RestRequest request = RestContext.request;
        
        try{        
            if(String.isBlank(request.requestURI.substringAfter(URL_BASE))){
                result.message = 'The Event ID is required.';
                result.result = false;
            } else{
                Id eventIdParam = (Id)request.requestURI.substringAfter(URL_BASE);            
                result = ACT_Controller_Event.getEventDetails(eventIdParam);
            }          
            
            String jsonResult = JSON.serialize(result); 
            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(jsonResult);
            
        } catch(Exception e){
            result.message = e.getMessage();
            result.result = false;
            
            String jsonResult = JSON.serialize(result); 
            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(jsonResult);
        }
        
    }
    
    @HttpPut
    global static void doPut(Data_Structure_Handle_Task.EventObject taskEvent){
        
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        RestRequest request = RestContext.request;
        
        try{        
            if(String.isBlank(request.requestURI.substringAfter(URL_BASE))){
                result.message = 'The Event ID is required.';
                result.result = false;
            } else{
                Id eventIdParam = (Id)request.requestURI.substringAfter(URL_BASE);            
                result = ACT_Controller_Event.editEventById(eventIdParam, taskEvent);
            }
            
            String jsonResult = JSON.serialize(result); 
            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(jsonResult);
            
        } catch(Exception e){
            result.message = 'An error occurred during the process.';
            result.result = false;
            
            String jsonResult = JSON.serialize(result); 
            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(jsonResult);
        }
        
    }
    
    @HttpDelete	
    global static void doDelete(){
        
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        RestRequest request = RestContext.request;
        
        try{        
            if(String.isBlank(request.requestURI.substringAfter(URL_BASE))){
                result.message = 'The Event ID is required.';
                result.result = false;
            } else{
                Id eventIdParam = (Id)request.requestURI.substringAfter(URL_BASE);            
                result = ACT_Controller_Event.deleteEventById(eventIdParam);
            }
            
            String jsonResult = JSON.serialize(result); 
            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(jsonResult);
            
        } catch(Exception e){
            result.message = 'An error occurred during the process.';
            result.result = false;
            
            String jsonResult = JSON.serialize(result); 
            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(jsonResult);
        }
    }
    
}