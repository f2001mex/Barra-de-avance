/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     F4_SendLeadsToOutbound_Test
 * @Author   ivan.mora@pwc.com
 * @Date     Created: 14/03/2024
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Test for all the apex classes related to MKT Outbound 
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 14/03/2024 ivan.mora@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
@isTest
public class F4_SendLeadsToOutbound_Test {            
	@TestSetup
    public static void setup() {
        Id CAMP_OUTBOUND_RT = Schema.getGlobalDescribe().get('Campaign').getDescribe().
        getRecordTypeInfosByName().get('Outbound').getRecordTypeId();
        
        List<Lead> newTestLeads = UtilitiesDataTest.createLeads(8, null);
        List<CampaignMember> outboundMembers = new List<CampaignMember>();
        Integer phoneCounter = 1;
        
        for(Lead l : newTestLeads){
            l.Suffix = 'Test AP';
            l.Numero_Telefono__c = '555555555' + String.valueOf(phoneCounter);
            phoneCounter ++;
        }
		insert newTestLeads;
        
        Campaign outbound1 = new Campaign(
            RecordTypeId = CAMP_OUTBOUND_RT,
            Name = 'TestCampaignOutbound1',
            Outbound_Campaign_Template__c = 'dev_url_prospecto_asignado_01',
            Outbound_Second_Sending__c = true,
            Status = 'In Progress'
        );        
        insert outbound1;
        
        for(Lead l : newTestLeads){
            outboundMembers.add(new CampaignMember(
            	CampaignId = outbound1.Id,
                LeadId = l.Id,
                Outbound_Sent_Time__c = null,
                Status = 'Nuevo'
            ));
        }
        insert outboundMembers;
    }
    
    @IsTest
    private static void sendLeadsToOutbound_Test_success() {
        Campaign camp1 = [SELECT Id, Name FROM Campaign WHERE Name = 'TestCampaignOutbound1' LIMIT 1];
        List<CampaignMember> membersList;
        Id batchJobId;
        
        F3_Integration_Service__mdt testMetadata = createMetadataSendLeadsOutbound();
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest'
		);
		Integration_Service.testSettings = new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings };
        
		//Primer envío exitoso
        F4_SendLeadsToOutbound_Controller.sendLeads(new List<String>{camp1.Id}, false);
        
        //Segundo envío: No hay registros para procesar        
        try {
			F4_SendLeadsToOutbound_Controller.sendLeads(new List<String>{camp1.Id}, true);            
        } catch (Exception ex){
            System.debug(ex.getMessage());
        }
        
        membersList = [SELECT Id, Name, Outbound_Sent_Time__c, HasResponded, Available_Second_Outbound__c FROM CampaignMember WHERE CampaignId =:camp1.Id];
        
        for(CampaignMember cm: membersList){
            Datetime outboundSentTime = System.now()-2;            
            cm.Outbound_Sent_Time__c = outboundSentTime;
        }
        
        update membersList;
        Formula.recalculateFormulas(membersList);        
        
        //Segundo envío exitoso
        batchJobId = F4_SendLeadsToOutbound_Controller.sendLeads(new List<String>{camp1.Id}, true);
        System.debug(F4_SendLeadsToOutbound_Controller.getBatchJobStatus(batchJobId));
    }
    
    @IsTest
    private static void sendLeadsToOutbound_Test_fail() {
		F4_SendLeadsToOutbound_Handler obj = new F4_SendLeadsToOutbound_Handler(null, null);
        try {
			obj.sendLeadsToOutbound(null, false);
        } catch (Exception ex){
            System.debug(ex.getMessage());
        }
    }
    
    private static F3_Integration_Service__mdt createMetadataSendLeadsOutbound() {
		F3_Integration_Service__mdt serviceMetadata = new F3_Integration_Service__mdt();
		serviceMetadata.F3_Mock_Response__c = '{"Status":"success"}';
		serviceMetadata.F3_Retrive_Mock__c = true;
		serviceMetadata.F3_Mock_Status_Code__c = 200;
		serviceMetadata.F3_Query_String_Input_Template__c = '';
		serviceMetadata.F3_Named_Credential__c = null;
		serviceMetadata.F3_Service_Setting__c = 'sendLeadsToOutbound';
		serviceMetadata.F3_Headers__c = '{"Content-Length":"0"}';
		serviceMetadata.F3_HTTP_Method__c = 'POST';
		serviceMetadata.F3_JSON_Input_Template__c = '{"template_name": "#Campaign.Outbound_Campaign_Template__c#","campaign": "#Campaign.Name#",' +
													'"client_phone_number": "#Lead.Numero_Telefono__c#", "from_phone_number": "5570055228", "template_params": {' +
													'"body": ["#Name#","#Lead.Numero_Telefono__c#","#Id#"]}}';
        
		serviceMetadata.F3_Authorization_Service__c = 'TestAuth';
		serviceMetadata.F3_Authorization_Class__c = 'F3_AccessToken_Utility';
		serviceMetadata.DeveloperName = 'sendLeadsToOutbound';
		return serviceMetadata;
	}
}