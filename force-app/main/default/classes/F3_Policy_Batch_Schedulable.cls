public with sharing class F3_Policy_Batch_Schedulable implements Schedulable {
	private static Integer intBatchSize = 200;

	public void execute(SchedulableContext sc) {
		if (Label.F3_Batch_Policy_Size != null) {
			intBatchSize = Integer.valueOf(Label.F3_Batch_Policy_Size);
		}
		Database.executeBatch(new F3_Policy_Batch(), intBatchSize);
	}
}