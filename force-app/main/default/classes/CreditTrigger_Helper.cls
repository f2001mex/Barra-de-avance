/** ------------------------------------------------------------------------------------------------
 * @Name     CreditTrigger_Helper
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 03/11/2021
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Helper class for the credit trigger
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 03/11/2021 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/

public without sharing class CreditTrigger_Helper {
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

	private static F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.Label.F3_CreditTrigger);

	/** ------------------------------------------------------------------------------------------------
	 * Static initialization block for USER_LIST
	 * ------------------------------------------------------------------------------------------------**/
	static {
		USER_LIST = fillUserMap();
	}
	/** ------------------------------------------------------------------------------------------------
	 * Class as a Singleton. Prevents instantiation
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private CreditTrigger_Helper() {
	}

	/** -----------------------------------------------------------------------------
	 * @Description change the owner of the credit based on the field "NUM_ASESOR__c"
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     03/11/2021
	 * @param    list<Credit> creditNew
	 * @return   void
	 * @example  CreditTrigger_Helper.changeOwner(creditNew)
	 **/
	public static void changeOwner(list<Credito__c> creditNew, Map<Id, Credito__c> creditOldMap) {
		for (Credito__c newCredit : creditNew) {
			if (
				triggerMetadata.F3_Run_For_All_Changes__c == false &&
				creditOldMap != null &&
				newCredit.NUM_ASESOR__c == creditOldMap.get(newCredit.Id).NUM_ASESOR__c
			) {
				continue;
			}
			newCredit.OwnerId = USER_LIST.get(newCredit.NUM_ASESOR__c) != null ? USER_LIST.get(newCredit.NUM_ASESOR__c) : defaultOwner.Id;
		}
	}

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
		final List<User> users = [
			SELECT Id, ID_ASESOR__c, Name
			FROM user
			WHERE IsActive = TRUE AND (ID_ASESOR__c != NULL OR Name = :DEFAULT_USER_NAME)
		];
		for (User selectedUser : users) {
			userList.put(selectedUser.ID_ASESOR__c, selectedUser.id);
			if (selectedUser.Name == DEFAULT_USER_NAME) {
				defaultOwner = selectedUser;
			}
		}
		return userList;
	}
}