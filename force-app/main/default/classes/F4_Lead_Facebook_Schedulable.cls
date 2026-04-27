/**
 *   ------------------------------------------------------------------------------------------------
 * @name     F4_Lead_Facebook_Schedulable
 * @author   jonas.montoya.landa@pwc.com
 * @date     Created: July 11 2023
 * ------------------------------------------------------------------------------------------------
 * @description Schedulable class to invoke batch execution of F4_Lead_Facebook_Batch class
 * ------------------------------------------------------------------------------------------------
 * @changes		July 11 2023 jonas.montoya.landa@pwc.com Class Creation
 * ------------------------------------------------------------------------------------------------
 **/
public without sharing class F4_Lead_Facebook_Schedulable implements Schedulable {
    
    /** ------------------------------------------------------------------------------------------------
	 * @description Override method of Schedulable interface.
	 * 				Generates batch query prior to invoking batch execution. Batch size is set based on
	 * 				custom metadata type.
	 * *************************************************************************************************
	 * 				IMPORTANT: Class should be scheduled using CRON expression from custom metadata type
	 * *************************************************************************************************
	 * @author   jonas.montoya.landa@pwc.com
	 * @date     July 11 2023
	 * @param 	 SchedulableContext
	 * @return   void
	 * @example  System.schedule('Facebook Leads Optimization', cronExp, new F4_Lead_Facebook_Schedulable)
	 * ------------------------------------------------------------------------------------------------*
	*/
    public void execute (SchedulableContext sc) {
        
        ID schedJobID = sc.getTriggerId();
        
        try {
        	String query = F4_Lead_Facebook_BatchHelper.getQuery(schedJobID);
            Integer batchSize = (Integer) F4_Facebook_Lead_Optimization_Schedule__mdt.getInstance('Schedule').Batch_Size__c;
            Database.executeBatch(new F4_Lead_Facebook_Batch(query), batchSize);
        }
        catch (F4_Lead_Facebook_BatchHelper.F4_Lead_Facebook_CRONException e) { handleCRONException(e, schedJobID); }
        catch (Exception e) { F4_Lead_Facebook_BatchHelper.handleException(e, F4_Lead_Facebook_BatchHelper.getMdtServiceName()); }
    }
    
    /** ------------------------------------------------------------------------------------------------
	 * @description Method to handle CRON exception. It adds CRON Expression and job ID information and passes
	 * 				the exception to the general batch exception handler.
	 * 				This method should be test visible as it is impossible to test a null NextFireTime field
	 * 				in CronTrigger object (this case raises the exception handled in this method)
	 * ------------------------------------------------------------------------------------------------
	 * @author   jonas.montoya.landa@pwc.com
	 * @date     July 11 2023
	 * @param 	 Exception CRON Exception
	 * @param	 ID Job ID from schedulable
	 * @return   void
	 * @example  handleCRONException(e, schedJobID)
	 * ------------------------------------------------------------------------------------------------*
	*/
    @TestVisible
    private void handleCRONException(Exception e, ID schedJobID) {
        
		CronTrigger[] crt = [SELECT CronExpression FROM CronTrigger WHERE Id = :schedJobID];
        
        String errMessage = crt.isEmpty() ? e.getMessage() : e.getMessage() + ' Expresión CRON utilizada: ' + crt[0].CronExpression + '. Job ID: ' + schedJobID;
        e.setMessage(errMessage);
        
        F4_Lead_Facebook_BatchHelper.handleException(e, F4_Lead_Facebook_BatchHelper.getMdtServiceName());        
    }
    
}