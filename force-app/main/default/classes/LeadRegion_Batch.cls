public with sharing class LeadRegion_Batch implements Database.Batchable<sObject>, Database.Stateful {
	static final String INTEGRATION_USER = 'IntegrationUser';
	static final String MKT_USER = 'MC Connect-CRM';
	static final Map<string, string> USER_ROLE;
	static final Map<String, String> BRANCH_UNITS;
	static final Map<String, String> BRANCH_MEMBERS;
	public String csvColumnHeader;
	public List<String> csvRowValues = new List<String>();
	static {
		USER_ROLE = fillUserMap();
		BRANCH_UNITS = fillBranchMap();
		BRANCH_MEMBERS = fillBranchMemberMap();
	}

	private static Map<string, string> fillUserMap() {
		Map<string, string> userList = new Map<string, string>();
		final List<User> users = [SELECT Id, UserRole.Name FROM user WHERE IsActive = TRUE];
		for (User selectedUser : users) {
			userList.put(selectedUser.Id, selectedUser.UserRole.Name);
		}
		return userList;
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
		return Database.getQueryLocator(
			'select id, F3_Tipo_Banca__c,Branch_Unit__c, Regi_n__c, Divisi_n__c, OwnerId from lead where Owner.Name != \'' +
				INTEGRATION_USER +
				'\' and Owner.Name != \'' +
				MKT_USER +
				'\''
		);
	}

	public void execute(Database.BatchableContext bc, List<Lead> scope) {
		if (!scope.isEmpty()) {
			List<Lead> leadsToUpdate = new List<Lead>();
			for (Lead selectedLead : scope) {
				String branchUnit = BRANCH_MEMBERS.get(selectedLead.OwnerId);
				String region = BRANCH_UNITS.get(branchUnit);
				String division = BRANCH_UNITS.get(region);
				leadsToUpdate.add(new Lead(Id = selectedLead.Id, Branch_Unit__c = branchUnit, Regi_n__c = region, Divisi_n__c = division));
			}
			if (!leadsToUpdate.isEmpty()) {
				Schema.SObjectField leadIdField = Lead.ID.getDescribe().getSObjectField();
				List<Database.UpsertResult> upsertResults = Database.upsert(leadsToUpdate, leadIdField, false);
				for (Database.UpsertResult upsertResult : upsertResults) {
					String upsertError = null;
					if (!upsertResult.getErrors().isEmpty()) {
						upsertError = String.join(upsertResult.getErrors(), ',');
					}
					String row = String.valueOf(upsertResult.getId()) + ',' + String.valueOf(upsertResult.isSuccess()) + ',' + upsertError;
					csvRowValues.add(row);
				}
			}
			if (csvRowValues.size() > 150000) {
				csvColumnHeader = 'ID_LEAD, ACTUALIZADO, ERRORES\n';
				String csvFile = csvColumnHeader + String.join(csvRowValues, '\n');
				Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
				blob csvBlob = Blob.valueOf(csvFile);
				csvAttc.setFileName('BATCH_REGION_LEAD.csv');
				csvAttc.setBody(csvBlob);
				Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
				String[] toAddresses = new List<string>{ 'luis.felipe.ortiz@pwc.com', 'luis_ot1@outlook.com' };
				String subject = 'BATCH REGION LEAD';
				email.setSubject(subject);
				email.setToAddresses(toAddresses);
				email.setPlainTextBody('Resumen Batch');
				email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ csvAttc });
				Messaging.SendEmailResult[] sr = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
				csvRowValues.clear();
			}
		}
	}

	public void finish(Database.BatchableContext bc) {
		if (!csvRowValues.isEmpty()) {
			csvColumnHeader = 'ID_LEAD, ACTUALIZADO, ERRORES\n';
			String csvFile = csvColumnHeader + String.join(csvRowValues, '\n');
			Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
			blob csvBlob = Blob.valueOf(csvFile);
			csvAttc.setFileName('BATCH_REGION_LEAD.csv');
			csvAttc.setBody(csvBlob);
			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			String[] toAddresses = new List<string>{ 'luis.felipe.ortiz@pwc.com', 'luis_ot1@outlook.com' };
			String subject = 'BATCH REGION LEAD';
			email.setSubject(subject);
			email.setToAddresses(toAddresses);
			email.setPlainTextBody('Resumen Batch');
			email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ csvAttc });
			Messaging.SendEmailResult[] sr = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
			csvRowValues.clear();
		}
	}
}