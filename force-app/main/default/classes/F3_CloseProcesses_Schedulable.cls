/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_CloseProcesses_Schedulable
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 12/08/2022
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Scheduler for the F3_CloseProcesses_Batch process
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 12/08/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public without sharing class F3_CloseProcesses_Schedulable implements Schedulable {
	@TestVisible
	private static List<String> batchesIds = new List<String>();

	public void execute(SchedulableContext sc) {
		List<F3_Object_Closing_Date__mdt> processesToClose = F3_Object_Closing_Date__mdt.getAll().values();
		for (F3_Object_Closing_Date__mdt process : processesToClose) {
			String jobId = Database.executeBatch(new F3_CloseProcesses_Batch(process.DeveloperName), 10000);
			batchesIds.add(jobId);
		}
	}
}