/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     OpportunityTriggerHandler
 * @Author   ivan.mora@pwc.com
 * @Date     Created: 03/03/2024
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Opportunity trigger Handler. This trigger uses the Kevin O'Hara trigger framework.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 03/03/2024 ivan.mora@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public without sharing class OpportunityTriggerHandler extends TriggerHandler {
	Set<Id> oppAccountIds;
	list<Opportunity> opportunityNew = Trigger.new;
	list<Opportunity> opportunityOld = Trigger.Old;
	List<Banker> bankersList;
	Map<Id, Banker> bankersMapByUserId;
	Map<id, Opportunity> oppRelatedFieldsMap;
	Map<id, Account> accRelatedFieldsMap;
	Map<id, Opportunity> opportunityNewMap = ((Map<Id, Opportunity>) (Trigger.NewMap));
	Map<id, Opportunity> opportunityOldMap = ((Map<Id, Opportunity>) (Trigger.OldMap)); 
	Map<String, OpportunityEscalationRule__mdt> escalationMetadataMap;
	Id businessHoursId;
	static Id PLANES_BENEFICIO_FISCAL_RT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Planes con Beneficio Físcal').getRecordTypeId();
	static Id WALLET_RT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Opportunity (Wallet Share)').getRecordTypeId();
	static Id MC_CONNECT_CRM_ID = [SELECT Id FROM User WHERE Name = 'MC Connect-CRM'].Id;

	public OpportunityTriggerHandler(){
		this.oppAccountIds = new Set<Id>();
		this.bankersList = EscalationOpportunity_Utils.getBankersInfo();
		this.bankersMapByUserId = EscalationOpportunity_Utils.getBankersInfoByUser(bankersList);
		this.oppRelatedFieldsMap = new Map<id, Opportunity>([SELECT Account.OwnerId FROM Opportunity WHERE Id IN:Trigger.new]);
		this.escalationMetadataMap = EscalationOpportunity_Utils.getEscalationMetadataMap();
		this.businessHoursId = EscalationOpportunity_Utils.getBusinessHoursId('Workable Days');
	}
	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before inserting an Opportunity created by MC Connect-CRM User
	 *   ------------------------------------------------------------------------------------------------
	 * @author   ivan.mora@pwc.com
	 * @date     03/03/2024
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeInsert() {
		for(Opportunity opp: opportunityNew){
			oppAccountIds.add(opp.AccountId);
		}
		accRelatedFieldsMap = new Map<id, Account>([SELECT Id, OwnerId FROM Account WHERE Id IN:oppAccountIds]);
		String accOwnerId;

		for(Opportunity opp: opportunityNew){
			if(
				UserInfo.getUserId() == MC_CONNECT_CRM_ID &&
				(opp.RecordTypeId == PLANES_BENEFICIO_FISCAL_RT || opp.RecordTypeId == WALLET_RT)
			){
				accOwnerId = accRelatedFieldsMap.get(opp.AccountId).OwnerId;
					if(
						bankersMapByUserId.containsKey(accOwnerId)
					){
                        if(bankersMapByUserId.get(accOwnerId).CurrentBranchId != null){
                            opp.Last_Escalation_Date__c = System.now();
                        	opp.Current_assigned_Branch__c = bankersMapByUserId.get(accOwnerId).CurrentBranchId;
							opp.OwnerId = accOwnerId;
                            
                        } else {
                            opp.addError('El registro de banquero no tiene una sucursal asociada');
                        }
					} else {
						opp.addError('Cliente asociado no tiene registro de Banquero');
					}
			}
		}
	}


    /** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic after inserting an Opportunity
	 *   ------------------------------------------------------------------------------------------------
	 * @author   ivan.mora@pwc.com
	 * @date     03/03/2024
	 * @param
	 * @return   void
	 * @example  afterInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void afterInsert() {
		String escalationKey;
		Long taskDueDateMiliseconds;
		list<Task> newInitTasks = new list<Task>();
        OpportunityEscalationRule__mdt escalationMdt;

		for(Opportunity opp: opportunityNew){
            if(opp.Is_From_MKT_Calculator__c == true){
				escalationKey = String.valueOf(opp.Total_Escalations__c) + opp.MKT_Calculator_Segment__c;
                
				if (!escalationMetadataMap.containsKey(escalationKey)) {
                    continue;
                }

				escalationMdt = escalationMetadataMap.get(escalationKey);
				Decimal escalationTime = escalationMdt.Business_Hours__c;
				taskDueDateMiliseconds = EscalationOpportunity_Utils.hoursToMilliseconds(escalationMdt.Business_Hours__c);

				newInitTasks.add(new Task(
					Subject = escalationMdt.Task_Subject__c,
					WhatId = opp.Id,
					OwnerId = oppRelatedFieldsMap.get(opp.Id).Account.OwnerId,
					Priority = 'High',
					Status = 'In Progress',
					Type = 'Opportunity Escalation',
					ActivityDate = BusinessHours.add(businessHoursId, System.now(), taskDueDateMiliseconds).Date()
				));
			}
        }

        if(newInitTasks.size() > 0){
            insert newInitTasks;
        }
	}
}