/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     EscalationCalculateBusinessHours_Utils
 * @Author   ivan.mora@pwc.com
 * @Date     Created: 04/03/2024
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Class that contains auxiliar methods to accomplish opportunity escalation rules.
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 04/03/2024 ivan.mora@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public without sharing class EscalationOpportunity_Utils {
    public static Map<String, OpportunityEscalationRule__mdt> getEscalationMetadataMap(){
        Map<String, OpportunityEscalationRule__mdt> escalationMap = new Map<String, OpportunityEscalationRule__mdt>();
        for(OpportunityEscalationRule__mdt mdt: [SELECT Business_Hours__c, Segment__c, Task_Subject__c, Escalate_to_level__c, Escalation_count__c, Validate_CF__c
                                                FROM OpportunityEscalationRule__mdt
                                                WHERE IsActive__c = TRUE]){
            String key = String.valueOf(Integer.valueOf(mdt.Escalation_count__c)) + mdt.Segment__c;
            if(!escalationMap.containsKey(key)){
                escalationMap.put(key, mdt);
            }
        }

        return escalationMap;
    }

    public static Map<Id, BranchUnit> getBranchUnitInfo(){
        return new Map<Id, BranchUnit>(
            [SELECT Id, ParentBranchUnitId, BranchManagerId FROM BranchUnit]
        );
    }

    public static Map<Id, Banker> getBankersInfoByUser(List<Banker> bankersList){
        Map<Id, Banker> bankerMap = new Map<Id, Banker>();
        for(Banker banker: bankersList){
            if(!bankerMap.containsKey(banker.UserOrContactId)){
                bankerMap.put(banker.UserOrContactId, banker);
            }
        }

        return bankerMap;
    }
    
    public static List<Banker> getBankersInfo(){
        return [SELECT CurrentBranchId, Disponible__c, UserOrContactId FROM Banker
                WHERE Disponible__c = TRUE];
    }

    public static Id getNthLevelParent(Id branchId, Map<Id, BranchUnit> hierarchyMap, Integer numLevels) {
        BranchUnit currentBranch = hierarchyMap.get(branchId);
        for (Integer i = 0; i < numLevels - 1; i++) {
            if (currentBranch != null && currentBranch.ParentBranchUnitId != null) {
                currentBranch = hierarchyMap.get(currentBranch.ParentBranchUnitId);
            } else {
                // Return null or handle the case where there is no Nth level parent
                return null;
            }
        }

        return currentBranch.ParentBranchUnitId;
    }

    public static Long hoursToMilliseconds(Decimal totalHours) {
        // Check if the input value is not null
        if (totalHours != null) {
            // 1 hour = 60 minutes = 60 seconds = 1000 milliseconds
            return (Long) (totalHours * 60 * 60 * 1000);
        } else {
            // Handle null input gracefully (you can modify this part based on your requirements)
            return null;
        }
    }

    public static Id getBusinessHoursId(String businessHoursName){
        return [SELECT Id FROM BusinessHours WHERE name = :businessHoursName LIMIT 1][0].id;
    }
}