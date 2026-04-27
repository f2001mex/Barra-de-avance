/**
 * @author Tate Shi
 * @date 11/11/2021
 * @description
 *     Schedule send notification when Case hit time limit
 */
public with sharing class CaseDailyEightHalfSchedulable implements Schedulable {
	// schedule frequency daily at 08:30:00
	public static String sch = '0 30 8 * * ?';

	public void execute(SchedulableContext sc) {
		// US#14
		CaseController.handleDifferentTypeOfCaseWhenHitTimeLimit();

		// US#36
		CaseController.handleCaseStatusNotChangeTooLong();
	}
}