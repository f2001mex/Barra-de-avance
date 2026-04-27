/**
 *   ------------------------------------------------------------------------------------------------
 * @name     F4_Lead_Facebook_BatchHelper
 * @author   jonas.montoya.landa@pwc.com
 * @date     Created: July 11 2023
 * ------------------------------------------------------------------------------------------------
 * @description Class with helper methods for Lead Facebook Schedulable and Batch
 * ------------------------------------------------------------------------------------------------
 * @changes		July 11 2023 jonas.montoya.landa@pwc.com Class Creation
 * ------------------------------------------------------------------------------------------------
 **/
public without sharing class F4_Lead_Facebook_BatchHelper {
    
    /*
     * @description String Constant with service custom metadata name
     */
    private static final String SERVICE_MDT_NAME = 'Facebook_Leads_Optimization';
    
    /*
     * @description String Constant with service custom settings name
     */
    private static final String SERVICE_CST_NAME = 'Facebook_Leads_Optimization';

    /*
	* @description String Constant with error message when schedulable has no next fire time
	*/
    @TestVisible
    private static final String SCHED_ERR_MSG = 'Error: La clase schedulable debe ser agendada para ejecutarse cada N horas todos los días.';
    
    /*
     * @description Custom exception class. This is thrown when CRON expression from schedulable has no
     * 				next fire time which prevents from calculating datetime range in batch query
     */
    public class F4_Lead_Facebook_CRONException extends Exception {}
    
    /** ------------------------------------------------------------------------------------------------
	 * @description Returns query string for batch start method execution.
	 * 				This query filters records which were created/modified
	 * 				since last batch execution.
	 * 				CronTrigger is queried by the schedulable job ID and a
	 * 				calculation is made in order to get last time batch executed.
	 * ------------------------------------------------------------------------------------------------
	 * @author   jonas.montoya.landa@pwc.com
	 * @date     July 11 2023
	 * @param 	 ID Job ID from schedulable class that called batch execution
	 * @return   String
	 * @example  F4_Lead_Facebook_BatchHelper.getQuery(schedJobID)
	 * ------------------------------------------------------------------------------------------------*
	*/
	public static String getQuery (ID schedJobID) {
        
        CronTrigger[] crt = [SELECT NextFireTime FROM CronTrigger WHERE Id = :schedJobID];

        if (crt.isEmpty() || crt[0].NextFireTime == null) {
            throw new F4_Lead_Facebook_CRONException(SCHED_ERR_MSG);
        }
        
        List<Datetime> timeRange = calculateTimeRange(crt[0]);
        
        return bindQuery(timeRange[0], timeRange[1]);   
    }
    
    /** ------------------------------------------------------------------------------------------------
	 * @description Returns query string for batch start method execution.
	 * 				This query filters records which were created/modified
	 * 				in the specified start datetime (inclusive) and end datetime (exclusive) range.
	 * 				Such range is passed as parameters.
	 * 				This method should be used for manual batch execution,
	 * 				without using any schedulable class.
	 * ------------------------------------------------------------------------------------------------
	 * @author   jonas.montoya.landa@pwc.com
	 * @date     July 11 2023
	 * @param 	 Datetime Start datetime of range
	 * @param	 Datetime End datetime of range
	 * @return   String
	 * @example  F4_Lead_Facebook_BatchHelper.getQuery(startDt, endDt)
	 * ------------------------------------------------------------------------------------------------*
	*/
    public static String getQuery (Datetime startDT, Datetime endDt) {
        return bindQuery(startDT, endDT);
    }
    
    /** ------------------------------------------------------------------------------------------------
	 * @description Returns custom metadata type name that specifies integration settings for the
	 * 				Integration Engine
	 * ------------------------------------------------------------------------------------------------
	 * @author   jonas.montoya.landa@pwc.com
	 * @date     July 11 2023
	 * @param 	 -
	 * @return   String
	 * @example  F4_Lead_Facebook_BatchHelper.getMdtServiceName()
	 * ------------------------------------------------------------------------------------------------*
	*/
    public static String getMdtServiceName() {
        return SERVICE_MDT_NAME;
    }
    
    /** ------------------------------------------------------------------------------------------------
	 * @description Returns custom settings list name that specifies integration settings for the
	 * 				Integration Engine
	 * ------------------------------------------------------------------------------------------------
	 * @author   jonas.montoya.landa@pwc.com
	 * @date     July 11 2023
	 * @param 	 -
	 * @return   String
	 * @example  F4_Lead_Facebook_BatchHelper.getCstServiceName()
	 * ------------------------------------------------------------------------------------------------*
	*/
    public static String getCstServiceName() {
        return SERVICE_CST_NAME;
    }
    
    /** ------------------------------------------------------------------------------------------------
	 * @description Builds serialized JSON with leads that advanced in its lead process.
	 * 				Included fields differ if test is running. This is because actual query
	 * 				is made on LeadHistory object, which isn't available in tests.
	 * 				A wrapper class is used.
	 * ------------------------------------------------------------------------------------------------
	 * @author   jonas.montoya.landa@pwc.com
	 * @date     July 11 2023
	 * @param 	 List<sObject> Leads retrieved in the batch query
	 * @return   String Serialized JSON
	 * @example  F4_Lead_Facebook_BatchHelper.buildJSON([SELECT ...])
	 * ------------------------------------------------------------------------------------------------*
	*/
    public static String buildJSON (List<sObject> leads) {
    
        F4_Lead_Facebook_Wrapper wrapper = new F4_Lead_Facebook_Wrapper();
        
        if (!Test.isRunningTest()) {
            
            for (LeadHistory lead : (List<LeadHistory>) leads) {
            
            	Long eventTime = convertToUnixTimestamp(lead.CreatedDate);
           		Long fbLeadID = Long.valueOf(lead.Lead.CHR_FB_Lead_ID__c);
           		String eventName = lead.NewValue != null ? (String) lead.NewValue : 'Asignado';
           		wrapper.addLead(eventName, eventTime, fbLeadID);
        	}
        }
        else {
            
        	for (Lead lead : (List<Lead>) leads) {
            
            	Long eventTime = convertToUnixTimestamp(lead.LastModifiedDate);
           		Long fbLeadID = Long.valueOf(lead.CHR_FB_Lead_ID__c);
           		String eventName = lead.Status;
                wrapper.addLead(eventName, eventTime, fbLeadID);
        	}
        }
        
       return JSON.serialize(wrapper.getWrapper());
    }

	/** ------------------------------------------------------------------------------------------------
	 * @description Converts a Datetime value into its equivalent UNIX timestamp value
	 * ------------------------------------------------------------------------------------------------
	 * @author   jonas.montoya.landa@pwc.com
	 * @date     July 11 2023
	 * @param 	 Datetime
	 * @return   Long
	 * @example  convertToUnixTimestamp(System.now())
	 * ------------------------------------------------------------------------------------------------*
	*/
    public static Long convertToUnixTimestamp (Datetime dt) {
        return dt.getTime() / 1000;
    }
    
    /** ------------------------------------------------------------------------------------------------
	 * @description Generic exception handler. It logs error information.
	 * ------------------------------------------------------------------------------------------------
	 * @author   jonas.montoya.landa@pwc.com
	 * @date     July 11 2023
	 * @param 	 Exception
	 * @param	 String Custom metadata service name to log
	 * @return   void
	 * @example  F4_Lead_Facebook_BatchHelper.handleException(e)
	 * ------------------------------------------------------------------------------------------------*
	*/
    public static void handleException (Exception e, String mdtServiceName) {
        
        String errMessage = e.getTypeName() + ' ' + e.getMessage() + ' ' + e.getStackTraceString();

        Integration_Logger_Service logger = new Integration_Logger_Service();
            
		Map<Schema.SObjectField, Object> logFields = new Map<Schema.SObjectField, Object>();

        logFields.put(Log__c.F3_IntegrationName__c.getDescribe().getSObjectField(), mdtServiceName);
        logFields.put(Log__c.F3_ErrorsDetail__c.getDescribe().getSObjectField(), errMessage);
            
        logger.addExtraFields(logFields);
            
        logger.upsertLogger();
    }
    
    /** ------------------------------------------------------------------------------------------------
	 * @description Calculates datetime range for batch query. It is based on Next Fire Time from the
	 * 				schedulable CRON Expression, as well as the corresponding hour interval.
	 * 				Hour interval is retrieved from custom metadata type and should make sense with 
	 * 				the CRON Expression.
	 * 				Datetime range is calculated from substracting hour interval from Next Fire Time
	 * 				(end datetime), and susbtracting two times the hour interval from Next Fire Time
	 * 				(start datetime).
	 * ------------------------------------------------------------------------------------------------
	 * @author   jonas.montoya.landa@pwc.com
	 * @date     July 11 2023
	 * @param 	 CronTrigger CronTrigger queried from schedulable job ID
	 * @return   List<Datetime> List with datetime range (First element is start, and second is end)
	 * @example  calculateTimeRange([SELECT NextFireTime FROM CronTrigger WHERE Id = :schedJobID])
	 * ------------------------------------------------------------------------------------------------*
	*/
    private static List<Datetime> calculateTimeRange (CronTrigger crt) {
        
        F4_Facebook_Lead_Optimization_Schedule__mdt schedule = F4_Facebook_Lead_Optimization_Schedule__mdt.getInstance('Schedule');
        
        Integer hourInterval = (Integer) schedule.Hour_Interval__c;
        
        Datetime nextExec = crt.NextFireTime;
        
        return new List<Datetime> {nextExec.addHours((Integer) -(hourInterval * 2)), nextExec.addHours((Integer) -hourInterval)};
    }
   
    /** ------------------------------------------------------------------------------------------------
	 * @description Generates batch query by binding start and end datetime range to filter records.
	 * 				Queried object and fields differ if test is running. This is because actual query
	 * 				is made on LeadHistory object, which isn't available in tests.
	 * ------------------------------------------------------------------------------------------------
	 * @author   jonas.montoya.landa@pwc.com
	 * @date     July 11 2023
	 * @param 	 Datetime Start datetime in range
	 * @param	 Datetime End datetime in range
	 * @return   String Query
	 * @example  bindQuery(startDt, endDt)
	 * ------------------------------------------------------------------------------------------------*
	*/
    private static String bindQuery (Datetime startDt, Datetime endDt) {
        
        return
            
            !Test.isRunningTest() ?
            
            'SELECT Lead.CHR_FB_Lead_ID__c, NewValue, CreatedDate FROM LeadHistory' +
            ' WHERE CreatedDate >= ' + startDt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') +
            ' AND CreatedDate < ' + endDt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') +
            ' AND Field IN (\'Status\', \'created\')' +
            ' AND Lead.CHR_FB_Lead_ID__c != null' :
        
        	'SELECT CHR_FB_Lead_ID__c, Status, LastModifiedDate FROM Lead' +
            ' WHERE LastModifiedDate >= ' + startDt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') +
            ' AND LastModifiedDate < ' + endDt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') +
        	' AND Lead.CHR_FB_Lead_ID__c != null';
    }
}