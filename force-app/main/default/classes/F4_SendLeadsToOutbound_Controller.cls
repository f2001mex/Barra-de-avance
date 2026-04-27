/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F4_SendLeadsToOutbound_Controller
 * @Author   ivan.mora@pwc.com
 * @Date     Created: 05/11/2023
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Class in Charge to send leads to Actinver Outbound system
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 05/11/2023 ivan.mora@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public with sharing class F4_SendLeadsToOutbound_Controller {
    /** ------------------------------------------------------------------------------------------------
	 * @Description Calls Outbound 'sendLeadsToOutbound' service
	 * ------------------------------------------------------------------------------------------------
	 * @author   ivan.mora@pwc.com
	 * @date     05/11/2023
	 * @param
	 * @return   void
	 * @example  sendClient({ leadIds: [this.recordId] })
	 * ------------------------------------------------------------------------------------------------**/
	@AuraEnabled
	public static string sendLeads(List<String> campaignIds, Boolean isTwice) {
		Outbound_Settings__mdt outboundMetadata = F4_SendLeadsToOutbound_Controller.getOutboundMetadata('sendLeadsToOutbound_v1');
		F3_Integration_Service__mdt serviceMetadata = F4_SendLeadsToOutbound_Controller.getIntegrationMetadata('sendLeadsToOutbound');
		List<String> newStatus = new List<String>{'Nuevo'};
		List<String> sentStatus = new List<String>{'Outbound'};
		List<CampaignMember> membersList;
		String query;

		try {
			
			if(isTwice == true){
				query = 'SELECT ' + outboundMetadata.Fields_To_Query__c + 
				' FROM CampaignMember' +
				' WHERE CampaignId =\'' + campaignIds[0] + '\'' +
				//' AND Status =\'' + sentStatus[0] + '\'' +
				//' AND HasResponded = false' +
				' AND Available_Second_Outbound__c = true';

			} else {
				query = 'SELECT ' + outboundMetadata.Fields_To_Query__c + 
				' FROM CampaignMember' +
				' WHERE CampaignId =\'' + campaignIds[0] + '\'' +
                ' AND Outbound_Sent_Time__c = null' +
				' AND Status =\'' + newStatus[0] + '\'';
			}

			membersList = Database.query(query);
			
			if(membersList.size() > 0){
				return Database.executeBatch(
					new F4_SendLeadsToOutbound_Batch(query, isTwice, serviceMetadata, outboundMetadata), 
						Integer.valueOf(outboundMetadata.Batch_size__c)
					);

			} else {
				throw new Integration_Service_Exception('No hay registros para procesar');
			}



		} catch (Exception e) {
			AuraHandledException error = new AuraHandledException(e.getMessage());
			error.setMessage(e.getMessage());
			throw error;
		}
	}

	public static F3_Integration_Service__mdt getIntegrationMetadata(String serviceName) {
		return [
			SELECT
				F3_Mock_Response__c,
				F3_Retrive_Mock__c,
				F3_Mock_Status_Code__c,
				F3_Query_String_Input_Template__c,
				F3_Named_Credential__c,
				F3_Service_Setting__c,
				F3_Headers__c,
				F3_HTTP_Method__c,
				F3_JSON_Input_Template__c,
				F3_Authorization_Service__c,
				F3_Authorization_Class__c,
				DeveloperName
			FROM F3_Integration_Service__mdt
			WHERE DeveloperName = :serviceName
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
	}


	public static Outbound_Settings__mdt getOutboundMetadata(String serviceName) {
		return [
			SELECT
				JSON_Input_Footer_Template__c,
				Batch_size__c,
				Fields_To_Query__c,
            	DeveloperName
			FROM Outbound_Settings__mdt
			WHERE DeveloperName = :serviceName
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
	}

	@AuraEnabled
    public static AsyncApexJob getBatchJobStatus(Id jobID){
        AsyncApexJob jobInfo = [SELECT Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, ExtendedStatus FROM AsyncApexJob WHERE Id = :jobID];
        return jobInfo;
    }
	
	public class Integration_Service_Exception extends Exception {
	}
}