/**
 * @author Tate Shi
 * @date 11/05/2021
 * @description
 *     Schedule update case.Tiempo_de_caso_abierto__c
 *     Schedule send notification when Case hit time limit
 */
public with sharing class CaseDailySchedulable implements Schedulable {
	// schedule frequency daily at 00:00:00
	public static String sch = '0 0 0 * * ?';

	public void execute(SchedulableContext sc) {
		// US#15
		CaseController.calculateDaysOfCaseHaveBeenOpen();
	}
}