global without sharing class EscalationOpportunity_Scheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        String OPP_VALID_STAGES = '\'Identificar Necesidades\','+ '\'Presentación de oferta\'';
            
        String query = 'SELECT '+ Label.CalculateBusinessHoursFields + 
        ' FROM Opportunity' +
        ' WHERE Is_From_MKT_Calculator__c = true' +
		' AND IsClosed = false' +
        ' AND Error_escalationProcess_MKT__c = null' +
        ' AND StageName IN('+ OPP_VALID_STAGES + ')';

        Database.executeBatch(new EscalationCalculateBusinessHours_Batch(query), 100);
    }
}