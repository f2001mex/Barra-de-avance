/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F4_SendLeadsToOutbound_Handler
 * @Author   ivan.mora@pwc.com
 * @Date     Created: 06/11/2023
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Handler class for the F4_SendLeadsToOutbound_Controller class
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 06/11/2023 ivan.mora@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/

public with sharing class F4_SendLeadsToOutbound_Handler {

	private F3_Integration_Service__mdt serviceMetadata;
	private Outbound_Settings__mdt outboundMetadata;
	private set<String> statusSecondSending = new set<String>{'Outbound'};
	
	public F4_SendLeadsToOutbound_Handler(F3_Integration_Service__mdt serviceMetadata, Outbound_Settings__mdt outboundMetadata){
		this.serviceMetadata = serviceMetadata;
		this.outboundMetadata = outboundMetadata;
	}

	public String sendLeadsToOutbound(List<CampaignMember> campaignMemberList, Boolean secondSend) {
		try {

			List<Integration_Service.ServiceResponse> responseList = new List<Integration_Service.ServiceResponse>();
			Map<String, Object> campaignMap;
			String requestBody = '{"messages": [';
			String requestBody2;

			for (CampaignMember cmpMember : campaignMemberList) {
				campaignMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(cmpMember.getPopulatedFieldsAsMap()));
				campaignMap.put('Campaign.Outbound_Campaign_Template__c', ((Map<String, Object>) campaignMap.get('Campaign')).get('Outbound_Campaign_Template__c'));
				campaignMap.put('Campaign.Name', ((Map<String, Object>) campaignMap.get('Campaign')).get('Name'));
				campaignMap.put('Lead.Numero_Telefono__c', ((Map<String, Object>) campaignMap.get('Lead')).get('Numero_Telefono__c'));
				requestBody += constructBodyByTemplate(campaignMap, false) + ', ';
			}

			requestBody2 = requestBody.removeEnd(', ') + '],\n';

			campaignMap.clear();
			campaignMap.put('send_at', System.now().format('MM/dd/yyyy h:mm a'));
			requestBody2 += constructBodyByTemplate(campaignMap, true);
			System.debug(requestBody2);

			Integration_Service.ServiceResponse response = Integration_Service.calloutService(
				'sendLeadsToOutbound',
				requestBody2,
				null,
				null,
				false
			);
			response.serviceHeaders = null;
			response.logger = null;
			responseList.add(response);

			if (String.valueOf(response.serviceCode).startsWithIgnoreCase('2')) {
				for(CampaignMember cmpMember : campaignMemberList){
					cmpMember.Status = secondSend? 'Outbound2': 'Outbound';
					cmpMember.Outbound_Sent_Time__c = System.now();
				}
				update campaignMemberList;
			}

			return JSON.serialize(responseList[0]);

		} catch (Exception e) {
			throw new F3_RestServices_Exception(e.getMessage());
		}
	}

	public String constructBodyByTemplate(Map<String, Object> bodyTemplateData, boolean isOutboundMetadata) {
		String builtBody = isOutboundMetadata ? outboundMetadata.JSON_Input_Footer_Template__c : serviceMetadata.F3_JSON_Input_Template__c;
		if (String.isNotBlank(builtBody) && (bodyTemplateData != null && !bodyTemplateData.isEmpty())) {
			for (String parameter : bodyTemplateData.keySet()) {
				if (builtBody.containsIgnoreCase('#' + parameter + '#')) {
					builtBody = builtBody.replace('#' + parameter + '#', String.valueOf(bodyTemplateData.get(parameter)));
				}
			}
		}
		builtBody = String.isNotBlank(builtBody) ? builtBody.replaceAll('#.+?#', '') : builtBody;
		return builtBody;
	}
}