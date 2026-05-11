@RestResource(urlMapping='/ACT_Event_Contact/*')
global with sharing class ACT_Event_Contact {
    private static final String URL_BASE = '/ACT_Event_Contact/';
    @HttpGet
    global static void doGet(){
        Data_Structure_Handle_Task.ResponseWithRelatedPerson result = new Data_Structure_Handle_Task.ResponseWithRelatedPerson();
        RestRequest request = RestContext.request;
        try {
            if (String.isBlank(request.requestURI.substringAfter(URL_BASE))) {
                result.message = 'Contact Name is required.';
                result.result = false;
            } else {
                string contactName = (String) request.requestURI.substringAfter(URL_BASE);
                result = ACT_Controller_Event.consultRelatedPerson(contactName);
            }
            String jsonResult = JSON.serialize(result); 
            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(jsonResult);
        } catch(Exception e){
            result.message = e.getmessage();
            result.result = false;
            String jsonResult = JSON.serialize(result); 
            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(jsonResult);
        }
    }
}