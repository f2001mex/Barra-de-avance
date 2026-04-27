/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     EscalationCalculateBusinessHours_Batch
 * @Author   ivan.mora@pwc.com
 * @Date     Created: 03/03/2024
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Class that is used to escalate opportunities to their related Asesor and above leadership
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 03/03/2024 ivan.mora@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public without sharing class EscalationOpportunity_Batch implements Database.Batchable<sObject>, Database.Stateful{
    String query;
    
    //Get Bankers Info;
    Map<Id, Banker> bankersMap;
    Map<Id, Banker> bankersMapByUserId;
    List<Banker> bankersList; 

    Map<Id, BranchUnit> branchUnitsMap;
    List<Task> tasksToCreate; 
    List<Opportunity> opportunitiesToUpdate;
    Map<String, OpportunityEscalationRule__mdt> escalationMetadataMap;
    Id businessHoursId;

    public EscalationOpportunity_Batch(String query) {
        this.query = query;
        this.bankersList = EscalationOpportunity_Utils.getBankersInfo();
        this.bankersMap = new Map<Id, Banker>(bankersList);
        this.bankersMapByUserId = EscalationOpportunity_Utils.getBankersInfoByUser(bankersList);

        this.tasksToCreate = new List<Task>();
        this.opportunitiesToUpdate = new List<Opportunity>();
        this.branchUnitsMap = EscalationOpportunity_Utils.getBranchUnitInfo();
        this.escalationMetadataMap = EscalationOpportunity_Utils.getEscalationMetadataMap();
        this.businessHoursId = EscalationOpportunity_Utils.getBusinessHoursId('Workable Days');
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        if(scope.size() > 0){
            OpportunityEscalationRule__mdt escalationMdt;
            Long taskDueDateMiliseconds;
            String escalationKey;
            Id accOwnerId;
            Id parentBranchId;
            Integer currentEscalations = 0;
			Date activityDate;
            
            for(Opportunity opp : scope){
                currentEscalations = Integer.valueOf(opp.Total_Escalations__c);
                escalationKey = String.valueOf(currentEscalations) + opp.MKT_Calculator_Segment__c;
                accOwnerId = opp.Account.OwnerId;
                
                if (!escalationMetadataMap.containsKey(escalationKey)) {
                    continue;
                }

                if(!bankersMapByUserId.containsKey(accOwnerId)){
                    continue;
                }

                escalationMdt = escalationMetadataMap.get(escalationKey);
                
                if(opp.Total_Past_Business_Hours__c >= escalationMdt.Business_Hours__c){
                    if(escalationMdt.Validate_CF__c){
                        Id currentBranchManager = opp.Current_assigned_Branch__r.BranchManagerId;
                        if(currentBranchManager == null){
                            opp.Error_escalationProcess_MKT__c = 'Error: No se encontró el director de CF en la sucursal';
                            opportunitiesToUpdate.add(opp);
                            continue;
                        }
                        currentEscalations ++;
                        escalationKey = String.valueOf(currentEscalations) + opp.MKT_Calculator_Segment__c;
                        escalationMdt = escalationMetadataMap.get(escalationKey);
                        taskDueDateMiliseconds = EscalationOpportunity_Utils.hoursToMilliseconds(escalationMdt.Business_Hours__c);
                    	activityDate = BusinessHours.add(businessHoursId, System.now(), taskDueDateMiliseconds).Date();
                        
                        accOwnerId = bankersMap.get(currentBranchManager).UserOrContactId;                        
                        tasksToCreate.add(
                            createNewTask(escalationMdt.Task_Subject__c, opp.Id, accOwnerId, activityDate)
                        );
                        opp.OwnerId = accOwnerId;
                        
                        opp.Total_Past_Business_Hours__c = 0;
                        opp.Last_Escalation_Date__c = System.now();
                        opp.Total_Escalations__c = currentEscalations;
                        opportunitiesToUpdate.add(opp);
                        
                    } else {
                   		currentEscalations ++;
                        escalationKey = String.valueOf(currentEscalations) + opp.MKT_Calculator_Segment__c;
                        
                        if (!escalationMetadataMap.containsKey(escalationKey)) {
                            continue;
                        }

                        escalationMdt = escalationMetadataMap.get(escalationKey);
                        taskDueDateMiliseconds = EscalationOpportunity_Utils.hoursToMilliseconds(escalationMdt.Business_Hours__c);
                    	activityDate = BusinessHours.add(businessHoursId, System.now(), taskDueDateMiliseconds).Date();
                        
                        if(escalationMdt.Escalate_to_level__c == 'NA'){
                            tasksToCreate.add(
                                createNewTask(escalationMdt.Task_Subject__c, opp.Id, accOwnerId, activityDate)
                            );
    
                        } else {
                            Id currentBranchUnit = opp.Current_assigned_Branch__c;
                            parentBranchId = EscalationOpportunity_Utils.getNthLevelParent(currentBranchUnit, branchUnitsMap, 
                                                                                            Integer.valueOf(escalationMdt.Escalate_to_level__c));
    
                            Id branchManagerId = branchUnitsMap.get(parentBranchId).BranchManagerId;
                            accOwnerId = bankersMap.get(branchManagerId).UserOrContactId;
                            
                            tasksToCreate.add(
                                createNewTask(escalationMdt.Task_Subject__c, opp.Id, accOwnerId, activityDate)
                            );
    
                            opp.OwnerId = accOwnerId;
                            opp.Current_assigned_Branch__c = parentBranchId;
                        }
                    
                        opp.Total_Past_Business_Hours__c = 0;
                        opp.Last_Escalation_Date__c = System.now();
                        opp.Total_Escalations__c = currentEscalations;
                        opportunitiesToUpdate.add(opp);
                	}
                }
            }

            if(tasksToCreate.size() > 0){
                insert tasksToCreate;
            }

            if(opportunitiesToUpdate.size() > 0){
                update opportunitiesToUpdate;
            }
        }
    }

    public void finish(Database.BatchableContext bc) {

    }
    
    public Task createNewTask(String subjet, Id oppId, Id ownerId, Date actDate){
        return new Task (
            Subject = subjet,
            WhatId = oppId,
            OwnerId = ownerId,
            Priority = 'High',
            Status = 'In Progress',
            Type = 'Opportunity Escalation',
            ActivityDate = actDate
        );
    }
}