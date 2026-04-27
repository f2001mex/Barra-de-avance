global class LeadAssignment_Schedule implements Schedulable {

    global void execute(SchedulableContext sc) {
     
        LeadAssignment_Batch leadBatch = new LeadAssignment_Batch();

        // Start the batch job
        Database.executeBatch(leadBatch, 100); 

    }
}