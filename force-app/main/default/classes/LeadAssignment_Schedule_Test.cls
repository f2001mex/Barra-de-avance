@isTest
private class LeadAssignment_Schedule_Test {

    @isTest
    static void testScheduleExecution() {
        
        Test.startTest();
        String jobID = System.schedule('Test Lead Assignment Job', 
                                        '0 0 0 15 3 ? 2030', 
                                        new LeadAssignment_Schedule());
        Test.stopTest();

        
        CronTrigger job = [SELECT Id, CronExpression, CronJobDetail.Name 
                            FROM CronTrigger 
                            WHERE Id = :jobID];
        System.assertNotEquals(null, job, 'Job was not scheduled');
        System.assertEquals('0 0 0 15 3 ? 2030', job.CronExpression, 'Incorrect cron expression');
        System.assertNotEquals('LeadAssignment_Schedule', job.CronJobDetail.Name, 'Incorrect job name');
    }

}