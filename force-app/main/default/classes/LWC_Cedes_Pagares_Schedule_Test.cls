/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     LWC_Cedes_Pagares_Schedule_Test
 * @Author   ivan.mora@pwc.com
 * @Date     Created: 20/05/2024
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Test for all the apex classes related to cedes/Pagarés functionality 
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 20/05/2024 ivan.mora@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
@isTest
public class LWC_Cedes_Pagares_Schedule_Test {
	public static String CRON_EXP = '0 0 0 3 9 ? 2042';
    
    @IsTest
	public static void testSchedule() {
        F3_Integration_Service__mdt testMetadata = createMetadataGetCedes();
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest'
		);
        Integration_Service.testSettings = new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings };

        Test.startTest();
            String jobId = System.schedule('getInstrumentsCedes', 
                LWC_Cedes_Pagares_Schedule_Test.CRON_EXP, 
                new LWC_Cedes_Pagares_Schedule()
            );
        Test.stopTest();

        try{
            LWC_Cedes_Pagares_Controller cedesCtrl = new LWC_Cedes_Pagares_Controller();
            LWC_Cedes_Pagares_Controller.getCedesLogMessage();
        } catch(Exception e){
            System.debug(e.getMessage());
        }
    }

    private static F3_Integration_Service__mdt createMetadataGetCedes() {
		F3_Integration_Service__mdt serviceMetadata = new F3_Integration_Service__mdt();
		serviceMetadata.F3_Mock_Response__c = '{"Status":"success"}';
		serviceMetadata.F3_Retrive_Mock__c = true;
		serviceMetadata.F3_Mock_Status_Code__c = 200;
		serviceMetadata.F3_Query_String_Input_Template__c = '';
		serviceMetadata.F3_Named_Credential__c = null;
		serviceMetadata.F3_Service_Setting__c = 'getInstrumentsCedes';
		serviceMetadata.F3_Headers__c = '{"Content-Length":"0"}';
		serviceMetadata.F3_HTTP_Method__c = 'POST';
		serviceMetadata.F3_JSON_Input_Template__c = '{"parameter":"#change#","delete":"#delete#"}';
		serviceMetadata.F3_Authorization_Service__c = 'TestAuth';
		serviceMetadata.F3_Authorization_Class__c = 'F3_AccessToken_Utility';
		serviceMetadata.DeveloperName = 'getInstrumentsCedes';
		return serviceMetadata;
	}
}