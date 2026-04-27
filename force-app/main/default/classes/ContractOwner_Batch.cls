public with sharing class ContractOwner_Batch implements Database.Batchable<sObject>, Database.Stateful {
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final Map<string, string> that contains a list with the active users
	 * ------------------------------------------------------------------------------------------------**/
	static final Map<string, string> USER_LIST;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final String that contains the name of the default owner
	 **/
	static final String DEFAULT_USER_NAME = 'IntegrationUser';
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static User that contains default owner
	 * ------------------------------------------------------------------------------------------------**/
	static User defaultOwner;
	/** ------------------------------------------------------------------------------------------------
	 * Static initialization block for USER_LIST
	 * ------------------------------------------------------------------------------------------------**/
	static {
		USER_LIST = fillUserMap();
	}
	public String csvColumnHeader;
	public List<String> csvRowValues = new List<String>();
	/** ------------------------------------------------------------------------------------------------
    * @Description retrieves the active users on the org and puts them on a map that 
                   allows .get() based on the ID_ASESOR__c custom field and populate
                   the default owner static variable
    *   ------------------------------------------------------------------------------------------------
    * @author   luis.felipe.ortiz@pwc.com
    * @date     03/11/2021
    * @param    
    * @return   Map<string, string>
    * @example  fillUserMap()
    * ------------------------------------------------------------------------------------------------**/
	private static Map<string, string> fillUserMap() {
		Map<string, string> userList = new Map<string, string>();
		final List<User> users = [SELECT Id, ID_ASESOR__c, Name FROM user WHERE IsActive = TRUE];
		for (User selectedUser : users) {
			userList.put(selectedUser.ID_ASESOR__c, selectedUser.id);
			if (selectedUser.Name == DEFAULT_USER_NAME) {
				defaultOwner = selectedUser;
			}
		}
		return userList;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator('SELECT Id, OwnerId, ID_ASESOR__c FROM Contract');
	}

	public void execute(Database.BatchableContext bc, List<Contract> scope) {
		List<Contract> contractsToUpdate = scope;
		for (Contract newContract : contractsToUpdate) {
			if (newContract.ID_ASESOR__c == null) {
				newContract.OwnerId = defaultOwner.Id;
			} else {
				if (USER_LIST.get(newContract.ID_ASESOR__c) <> null)
					newContract.OwnerId = USER_LIST.get(newContract.ID_ASESOR__c);
				else {
					newContract.OwnerId = defaultOwner.Id;
				}
			}
		}
		if (!contractsToUpdate.isEmpty()) {
			update contractsToUpdate;
		}
	}

	public void finish(Database.BatchableContext bc) {
	}
}