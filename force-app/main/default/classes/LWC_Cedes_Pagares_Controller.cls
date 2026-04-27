/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     LWC_Cedes_Pagares_Controller
 * @Author   ivan.mora@pwc.com
 * @Date     Created: 24/04/2024
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Class in Charge to get the result of Cedes/Pagares Interface
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 24/04/2024 ivan.mora@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public without sharing class LWC_Cedes_Pagares_Controller {
    public LWC_Cedes_Pagares_Controller() {}

        /** ------------------------------------------------------------------------------------------------
	 * @Description Calls Outbound 'sendLeadsToOutbound' service
	 * ------------------------------------------------------------------------------------------------
	 * @author   ivan.mora@pwc.com
	 * @date     24/04/2024
	 * @param
	 * @return   void
	 * @example  sendClient({ leadIds: [this.recordId] })
	 * ------------------------------------------------------------------------------------------------**/
	@AuraEnabled
	public static Log__c getCedesLogMessage() {
        return [
            SELECT Id, F3_IntegrationName__c, F3_responseCode__c, CreatedDate, F3_Response__c 
            FROM Log__c WHERE F3_IntegrationName__c = 'getInstrumentsCedes' 
            AND F3_responseCode__c = '200' order by createddate DESC LIMIT 1
        ];
    }
}