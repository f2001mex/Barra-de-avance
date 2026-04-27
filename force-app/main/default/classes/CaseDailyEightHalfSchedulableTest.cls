/**
 * @author Tianhao Wu
 * @date 12/6/2021
 * @description
 *     Test for CaseDailyEightHalfSchedulable.cls
 */
@isTest
private class CaseDailyEightHalfSchedulableTest {
	@isTest
	static void testMethod1() {
		//Data Setup
		String jobName = 'CaseDailyEightHalfSchedulable';
		String sch = '0 30 8 * * ?';
		CaseDailyEightHalfSchedulable caseDailyEightHalfSchedulableObj = new CaseDailyEightHalfSchedulable();
		//Start the testing
		Test.startTest();
		String jobId = System.schedule(jobName, sch, caseDailyEightHalfSchedulableObj);
		Test.stopTest();
		//Assertion starts here
		System.assert(jobId != null);
	}
}