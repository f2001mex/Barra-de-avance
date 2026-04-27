/**
 *   ------------------------------------------------------------------------------------------------
 * @name     F4_Lead_Facebook_Test
 * @author   jonas.montoya.landa@pwc.com
 * @date     Created: July 11 2023
 * ------------------------------------------------------------------------------------------------
 * @description Test class for F4_Lead_Facebook_Schedulable, F4_Lead_Facebook_Batch,
 * 				F4_Lead_Facebook_BatchHelper, F4_Lead_Facebook_Wrapper
 * ------------------------------------------------------------------------------------------------
 * @changes		July 11 2023 jonas.montoya.landa@pwc.com Class Creation
 * ------------------------------------------------------------------------------------------------
 **/

@isTest
public class F4_Lead_Facebook_Test {
	
    static final Integer N_RECORDS = 100;
    
    @TestSetup
    static void setup() {
        
        Contact referred = new Contact(FirstName='Random', LastName='Contact');
        
        insert referred;
        
        List<Lead> leads = new List<Lead>();
        
        for (Integer i = 0; i < N_RECORDS; i++) {
            leads.add(new Lead(
                FirstName = 'Lead ',
                LastName = String.valueOf(i),
                PostalCode = '07070',
                CHR_FB_Lead_ID__c = String.valueOf(i),
                FinServ__ReferredByContact__c = referred.Id
            ));
        }
       
        insert leads;
    }
    
    static F3_Integration_Service__mdt createTestMdt() {
        
        return new F3_Integration_Service__mdt(
			F3_Mock_Response__c = '{"Status":"success"}',
			F3_Retrive_Mock__c = true,
			F3_Mock_Status_Code__c = 200,
			F3_Query_String_Input_Template__c = null,
			F3_Named_Credential__c = null,
			F3_Service_Setting__c = F4_Lead_Facebook_BatchHelper.getCstServiceName(),
			F3_Headers__c = null,
			F3_HTTP_Method__c = 'POST',
			F3_JSON_Input_Template__c = null,
			F3_Authorization_Service__c = null,
			F3_Authorization_Class__c = null,
			DeveloperName = F4_Lead_Facebook_BatchHelper.getMdtServiceName()
       );
    }
    
    static F3_Integration_Service_Settings__c createTestCst() {
        
        return new F3_Integration_Service_Settings__c(
			F3_URL__c = 'https://graph.facebook.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ExternalRest'
		);
    }
    
    static Integer getBatchSize() {
        return (Integer) F4_Facebook_Lead_Optimization_Schedule__mdt.getInstance('Schedule').Batch_Size__c;
    }
    
    static String getCRONExp() {
        return F4_Facebook_Lead_Optimization_Schedule__mdt.getInstance('Schedule').CRON_Expression__c;
    }
    
    static String getBadCRONExp() {
        return '0 0 0 30 9 ? 2040';
    }
    
    @isTest
    static void testSchedulable() {
    	
        Test.startTest();
        System.schedule(F4_Lead_Facebook_Batch.class.getName(), getCRONExp(), new F4_Lead_Facebook_Schedulable());
        Test.stopTest();
    }
    
    @isTest
    static void testBadSchedulable() {
        
        F4_Lead_Facebook_Schedulable sched = new F4_Lead_Facebook_Schedulable();
        
        ID schedJobID = System.schedule(F4_Lead_Facebook_Batch.class.getName(), getBadCRONExp(), sched);
            
        sched.handleCRONException(
            new F4_Lead_Facebook_BatchHelper.F4_Lead_Facebook_CRONException(F4_Lead_Facebook_BatchHelper.SCHED_ERR_MSG),
            schedJobID
        );
		
        List<Log__c> logs = [
            SELECT F3_ResponseCode__c, F3_Request__c, F3_Response__c
            FROM Log__c WHERE F3_IntegrationName__c = :F4_Lead_Facebook_BatchHelper.getMdtServiceName()
        ];
        
        System.assert(logs.size() == 1);
        
        System.debug(logs);
    }
    
    @isTest
    static void testManualBatch() {
        
        Datetime startDt = [SELECT LastModifiedDate FROM Lead LIMIT 1].LastModifiedDate;
        Datetime endDt = startDt.addDays(1);
        
        String query = F4_Lead_Facebook_BatchHelper.getQuery(startDt, endDt);

        Integration_Service.testSettings = new Map<String, Object>{ 'serviceMetadata' => createTestMdt(), 'serviceSettings' => createTestCst() };
            
        Integer batchSize = getBatchSize();
        
        Test.startTest();
        Database.executeBatch(new F4_Lead_Facebook_Batch(startDt, endDt), batchSize);
        Test.stopTest();
        
        List<Log__c> logs = [
            SELECT F3_ResponseCode__c, F3_Response__c
            FROM Log__c WHERE F3_IntegrationName__c = :F4_Lead_Facebook_BatchHelper.getMdtServiceName()
        ];
        
        System.assert(logs.size() > 0);
        
        System.debug(logs);
    }
}