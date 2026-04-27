/**
 * @author Tate Shi
 * @date 10/27/2021
 * @description Schedule for AssignLeadToAdvisor
 */
public class LeadAssignmentSchedulable implements Schedulable {
	// schedule frequency : hourly
	public static String sch = '0 0 * * * ?';

	private static Integer intBatchSize = 200;

	public void execute(SchedulableContext sc) {
		// AssignLeadToAdvisor.updateLeadList();
		if (Label.Lead_Assignment_Batch_Size != null) {
			intBatchSize = Integer.valueOf(Label.Lead_Assignment_Batch_Size);
		}
		Database.executeBatch(new LeadAssignBatch(), intBatchSize);
	}
}