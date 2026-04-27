/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     EscalationCalculateBusinessHours_Batch
 * @Author   ivan.mora@pwc.com
 * @Date     Created: 03/03/2024
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Class to calculate the total business hours since the last escalation date time
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 03/03/2024 ivan.mora@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public without sharing class EscalationCalculateBusinessHours_Batch implements Database.Batchable<sObject>, Database.Stateful {
    public class EscalationException extends Exception {}

    String query;
    Id businessHoursId;
    List<BusinessHours> bh;

    public EscalationCalculateBusinessHours_Batch(String query) {
        this.query = query;
        this.bh = [SELECT Id, Name FROM BusinessHours 
                    WHERE name = 'Workable Days'
                    AND IsActive = true];

        if(this.bh.size() > 0){
            this.businessHoursId = bh[0].Id;
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        if(businessHoursId != null){
            if(scope.size() > 0){
                for(Opportunity opp : scope){
                    if(opp.Last_Escalation_Date__c != null){
                        opp.Total_Past_Business_Hours__c = calculateWorkDays(
                            opp.Last_Escalation_Date__c, 
                            System.now(),
                            'Workable Days'
                        );
                    } else {
                        opp.Error_escalationProcess_MKT__c = 'Last_Escalation_Date__c is null. Check the formula.';
                        opp.Total_Past_Business_Hours__c = null;
                        opp.Total_Escalations__c = null;
                    }
                }

                update scope;
            }
        } else {
            throw new EscalationException('No businessHoursId found. Check the formula.');
        }
    }

    public void finish(Database.BatchableContext bc) {
        String OPP_VALID_STAGES = '\'Identificar Necesidades\','+ '\'Presentación de oferta\'';
        String query = 'SELECT Id, Last_Escalation_Date__c, Total_Past_Business_Hours__c, Account.OwnerId, MKT_Calculator_Segment__c, Total_Escalations__c, Current_assigned_Branch__c, Current_assigned_Branch__r.BranchManagerId, Error_escalationProcess_MKT__c '+ 
        ' FROM Opportunity' +
        ' WHERE Is_From_MKT_Calculator__c = true' +
        ' AND IsClosed = false' +
        ' AND Error_escalationProcess_MKT__c = null' +
		' AND StageName IN('+ OPP_VALID_STAGES + ')';
        
        Database.executeBatch(new EscalationOpportunity_Batch(query), 100);
    }


    public Decimal calculateWorkDays(Datetime startDate, Datetime endDate, String businessHoursName) {
		/*if (String.isBlank(businessHoursId)) {
			businessHoursId = [SELECT Id FROM BusinessHours WHERE name = :businessHoursName LIMIT 1][0].id;
		}*/
        
		Decimal result = BusinessHours.diff(businessHoursId, startDate, endDate);
		Decimal hours = result/(60*60*1000);
		return hours.setScale(1);
	}
}