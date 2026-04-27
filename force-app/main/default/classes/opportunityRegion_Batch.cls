public with sharing class opportunityRegion_Batch implements Database.Batchable<sObject>, Database.Stateful {
	static final Map<String, String> BRANCH_UNITS;
	static final Map<String, String> BRANCH_MEMBERS;
	static {
		BRANCH_UNITS = fillBranchMap();
		BRANCH_MEMBERS = fillBranchMemberMap();
	}

	private static Map<string, string> fillBranchMap() {
		Map<string, string> branchList = new Map<string, string>();
		final List<BranchUnit> branches = [SELECT id, ParentBranchUnitId FROM BranchUnit];
		for (BranchUnit selectedBranch : branches) {
			branchList.put(selectedBranch.id, selectedBranch.ParentBranchUnitId);
		}
		return branchList;
	}
	private static Map<string, string> fillBranchMemberMap() {
		Map<string, string> branchMemberList = new Map<string, string>();
		Map<string, string> branchMemberIDList = new Map<string, string>();
		final List<BranchUnitBusinessMember> branchMembers = [SELECT BusinessUnitMemberId, BranchUnitId FROM BranchUnitBusinessMember];
		final List<BusinessUnitMember> branchMembersIDS = [SELECT id, BusinessMemberId FROM BusinessUnitMember];
		for (BusinessUnitMember selectedMember : branchMembersIDS) {
			branchMemberIDList.put(selectedMember.id, selectedMember.BusinessMemberId);
		}
		for (BranchUnitBusinessMember selectedMember : branchMembers) {
			branchMemberList.put(branchMemberIDList.get(selectedMember.BusinessUnitMemberId), selectedMember.BranchUnitId);
		}
		return branchMemberList;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator('select id, Branch_Unit__c, Regi_n__c, Divisi_n__c, OwnerId from Opportunity');
	}

	public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
		if (!scope.isEmpty()) {
			List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
			for (Opportunity selectedOpportunity : scope) {
				String branchUnit = BRANCH_MEMBERS.get(selectedOpportunity.OwnerId);
				String region = BRANCH_UNITS.get(branchUnit);
				String division = BRANCH_UNITS.get(region);
				opportunitiesToUpdate.add(
					new Opportunity(Id = selectedOpportunity.Id, Branch_Unit__c = branchUnit, Regi_n__c = region, Divisi_n__c = division)
				);
			}
			if (!opportunitiesToUpdate.isEmpty()) {
				upsert opportunitiesToUpdate;
			}
		}
	}

	public void finish(Database.BatchableContext bc) {
	}
}