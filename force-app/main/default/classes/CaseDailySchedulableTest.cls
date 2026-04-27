/**
 * @author Tianhao Wu
 * @date 12/6/2021
 * @description
 *     Test for CaseDailySchedulable.cls
 */
@isTest
private class CaseDailySchedulableTest {
	@isTest
	static void testMethod1() {
		//Data Setup
		String jobName = 'CaseDailySchedulable';
		String sch = '0 0 0 * * ?';
		CaseDailySchedulable caseDailySchedulableObj = new CaseDailySchedulable();
		//Start the testing
		Test.startTest();
		String jobId = System.schedule(jobName, sch, caseDailySchedulableObj);
		Test.stopTest();
		//Assertion starts here
		System.assert(jobId != null);
	}
}