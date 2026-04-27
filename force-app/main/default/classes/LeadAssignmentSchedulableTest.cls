/**
 * @author Tianhao Wu
 * @date 12/6/2021
 * @description
 *     Test for LeadAssignmentSchedulable.cls
 */
@isTest
public with sharing class LeadAssignmentSchedulableTest {
	@isTest
	static void testMethod1() {
		//Data Setup
		String jobName = 'LeadAssignmentSchedulable';
		String sch = '0 0 * * * ?';
		// Integer intBatchSize = 200;
		LeadAssignmentSchedulable leadAssignmentSchedulableObj = new LeadAssignmentSchedulable();
		//Start the testing
		Test.startTest();
		String jobId = System.schedule(jobName, sch, leadAssignmentSchedulableObj);
		Test.stopTest();
		//Assertion starts here
		System.assert(jobId != null);
	}
}