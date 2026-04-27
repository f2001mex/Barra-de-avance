@isTest
public class WorkaroundSch_test {
    @isTest
    static void testExecuteSchedule() {
        Test.startTest();
		Workaround_sch.executeSchedule('0 0 8-23 * * ?','Workaround_sch_0'); 
    	Test.stopTest();
    }
}