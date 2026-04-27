/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Alvarez Oscar
* Project           :   Actinver
* Clase test		:   Workaround_sch
* Description       :   Actualizar Correo y telefono partiendo de los datos de la cuenta relacionada a la oportunidad
*--------------------------------------------------------------------------
* No.            Date              Author             Description
* 1.0         31-Jul-2024       Canche Isaac           Creación
*--------------------------------------------------------------------------
*******************************************************************************/
global class Workaround_sch implements Schedulable{

    @TestVisible 
    //public static final String CRON_EXPR = '0 0,15,30,45 8-20 ? * * *';

    global static String executeSchedule(String CRON_EXPR, String strScheduler) {
        unSchedule(strScheduler);
        Workaround_sch job = new Workaround_sch();
        return System.schedule((Test.isRunningTest() ? (strScheduler + System.now()) : strScheduler), CRON_EXPR, job);
    }


    global void execute(SchedulableContext sc) {
        Opportunity[] lstOpportunity = [SELECT Id, Account.Phone, Account.PersonEmail,F3_Telefono__c,F3_Email__c, CreatedDate 
                                FROM Opportunity 
                                WHERE CreatedDate = TODAY  
								AND F3_Telefono__c = null 
                                AND F3_Email__c = null];
        
        System.debug('#### lstOpportunity: '+lstOpportunity.size());
        for(Opportunity objOpportunity : lstOpportunity){
            if(objOpportunity.Account.Phone != null) objOpportunity.F3_Telefono__c = objOpportunity.Account.Phone;
            if(objOpportunity.Account.PersonEmail != null) objOpportunity.F3_Email__c    = objOpportunity.Account.PersonEmail;    
        }
        Update lstOpportunity;
    }

    public static void unSchedule(String name) {
        for (CronTrigger ct : [select Id,CronExpression from CronTrigger where CronJobDetail.Name like :(name+'%')] )  System.abortJob(ct.Id);
    }
}