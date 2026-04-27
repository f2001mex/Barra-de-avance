/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 07-02-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
@isTest
public class BIT_AdultoMayor_sch_Test {
	@IsTest
	static void testSchedule() {
		BIT_AdultoMayor_sch sched = new BIT_AdultoMayor_sch();
		Test.startTest();
		sched.execute(null);
		Test.stopTest();
	}
}