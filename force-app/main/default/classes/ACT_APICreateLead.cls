/**
* @description       : Endpoint Class for Lead Object
* @author            : Dalila Conti
* @group             : 
* @last modified on  : 12-18-2023
* @last modified by  : JC Cruz
**/
@RestResource(urlMapping='/ACT_Leads/*')
global without sharing class ACT_APICreateLead {
    
    private static final String URL_BASE = '/ACT_Leads/';
    
    @HttpPost
    global static String createLead(Data_Structure_Handle_Lead.LeadObject leadsRecords) {
        Data_Structure_Handle_Lead.ResultWithLeads result = New Data_Structure_Handle_Lead.ResultWithLeads();
        
        result = ACT_Controller_Lead.createLead(leadsRecords);
        
        String jsonResult = JSON.serialize(result); 
        
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(jsonResult);
        return jsonResult;   
    }
    
    @HttpGet
    global static Data_Structure_Handle_Lead.ResponseWithRelatedLead doGet(){
        Data_Structure_Handle_Lead.ResponseWithRelatedLead result = new Data_Structure_Handle_Lead.ResponseWithRelatedLead();
        RestRequest request = RestContext.request;
        
        try {
            string leadName = RestContext.request.params.get('leadName'); 
            string idAsesor = RestContext.request.params.get('idAsesor'); 
            result = ACT_Controller_Lead.consultLead(leadName, idAsesor);
            
            return result;
        } catch(Exception e){
            result.message = e.getmessage() + e.getStackTraceString();
            result.result = false;
            return result;
        }
    }
}