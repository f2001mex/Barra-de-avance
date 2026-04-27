@RestResource(urlMapping='/ACT_Tasks/*')
global with sharing class ACT_TaskApiRest {
    
    private static final String URL_BASE = '/ACT_Tasks/';
    @HttpGet
    global static void doGet() {
        RestResponse response = RestContext.response;
        Map<String, Object> jsonResponse = new Map<String, Object>();
        jsonResponse.put('result', false); 
        jsonResponse.put('message', '');
 
        try {
            String taskId = RestContext.request.requestURI.substring(URL_BASE.length());
            System.debug(taskId);
            Task task = [SELECT Id, Subject, ActivityDate FROM Task WHERE Id = :taskId LIMIT 1];
            if (task != null) {
                jsonResponse.put('result', true);
                jsonResponse.put('message', 'Ok');

                Map<String, Object> taskInfo = new Map<String, Object>();
                taskInfo.put('Tipo', 'Tarea');
                taskInfo.put('Count', 1);
                Map<String, Object> activityInfo = new Map<String, Object>();
                activityInfo.put('Asunto', task.Subject);
                DateTime activityDateTime = DateTime.newInstance(task.ActivityDate, Time.newInstance(0, 0, 0, 0));
                activityInfo.put('FechaVencimiento', activityDateTime.formatGMT('dd/MM/yyyy'));
                List<Map<String, Object>> activitiesList = new List<Map<String, Object>>();
                activitiesList.add(activityInfo);
                taskInfo.put('Actividades', activitiesList);
                List<Map<String, Object>> recordsList = new List<Map<String, Object>>();
                recordsList.add(taskInfo);
                jsonResponse.put('registros', recordsList);
            } else {
                jsonResponse.put('message', 'Tarea no encontrada');
            }
        } catch (Exception ex) {
 
            jsonResponse.put('message', 'Error: ' + ex.getMessage());
        }
        String responseJson = JSON.serializePretty(jsonResponse);
        response.addHeader('Content-Type', 'application/json');
        response.responseBody = Blob.valueOf(responseJson);
        response.statusCode = 200; 
    }
    
    /*
    @HttpGet
    global static void doGet(){
        
        Data_Structure_Handle_Task.responseWithTasksList result = new Data_Structure_Handle_Task.responseWithTasksList();
        RestRequest request = RestContext.request;
        
        try{        
            if(String.isBlank(request.requestURI.substringAfter(URL_BASE))){
                result.message = 'The Task ID is required.';
                result.result = false;
            } else{
                taskIdParam = request.requestURI.substringAfter(URL_BASE);            
                result = ACT_Controller_Task.consultTask(taskIdParam);
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
        
    }*/
    
    @HttpPost
    global static void doPost(Data_Structure_Handle_Task.TaskObject taskObject){
        
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        
        try{
            
            result = ACT_Controller_Task.createTask(taskObject);
            
            String jsonResult = JSON.serialize(result); 
            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(jsonResult);
            
        } catch(Exception e){
            
            result.message = 'An error occurred during the process.';
            result.result = false;
            
            String jsonResult = JSON.serialize(result); 
            RestResponse res = RestContext.response;
            if(Test.isRunningTest()) res = new RestResponse();
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(jsonResult);
            
        }
        
    }
    
    
    @HttpPut
    global static void doPut(Data_Structure_Handle_Task.TaskObject taskObject){
        
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        RestRequest request = RestContext.request;
        
        try{       
            
            if(String.isBlank(request.requestURI.substringAfter(URL_BASE))){
                
                result.message = 'The Task ID is required.';
                result.result = false;
                
            } else{
                
                Id taskIdParam = (Id)request.requestURI.substringAfter(URL_BASE);            
                result = ACT_Controller_Task.updateTask(taskIdParam, taskObject);
                
            }
            
            String jsonResult = JSON.serialize(result); 
            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(jsonResult);
            
        } catch(Exception e){
            System.debug(e);
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
                result.message = 'The activity ID is required.';
                result.result = false;
            } else{
                Id taskIdParam = (Id)request.requestURI.substringAfter(URL_BASE);            
                result = ACT_Controller_Task.deleteTaskById(taskIdParam);
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