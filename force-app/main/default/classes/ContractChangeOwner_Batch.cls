public with sharing class ContractChangeOwner_Batch implements Database.Batchable<sObject>, Database.Stateful {
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final Map<string, string> that contains a list with the active users
	 * ------------------------------------------------------------------------------------------------**/
	static final Map<string, string> USER_LIST;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final String that contains the name of the default owner
	 * ------------------------------------------------------------------------------------------------**/
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
	public String query;
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

	public ContractChangeOwner_Batch(String query) {
		this.query = !String.isBlank(query)
			? query
			: 'SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contract WHERE ID_ASESOR__c !=null)';
	}
	public ContractChangeOwner_Batch() {
		this.query = 'SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contract WHERE ID_ASESOR__c !=null)';
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		System.debug(query);
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext bc, List<Account> scope) {
		List<Contract> tmpContractsList = [SELECT Id, ID_ASESOR__c, OwnerId, AccountId FROM Contract WHERE AccountId IN :scope];
		Map<Id, List<Contract>> accountContracts = new Map<Id, List<Contract>>();
		for (Contract con : tmpContractsList) {
			if (accountContracts.get(con.AccountId) == null) {
				List<Contract> addContract = new List<Contract>{ con };
				accountContracts.put(con.AccountId, addContract);
				continue;
			}
			accountContracts.get(con.AccountId).add(con);
		}

		List<Account> accountUpdate = new List<Account>();
		List<Contract> contractUpdate = new List<Contract>();
		Map<String, String> accountError = new Map<String, String>();
		for (Id proccessedAccount : accountContracts.keySet()) {
			Set<String> asesores = new Set<String>();
			for (Contract proccessedContract : accountContracts.get(proccessedAccount)) {
				if (!String.isBlank(proccessedContract.ID_ASESOR__c)) {
					asesores.add(proccessedContract.ID_ASESOR__c);
				}
				if (USER_LIST.get(proccessedContract.ID_ASESOR__c) <> null) {
					proccessedContract.OwnerId = USER_LIST.get(proccessedContract.ID_ASESOR__c);
					contractUpdate.add(proccessedContract);
				}
			}

			if (!asesores.isEmpty() && asesores.size() == 1) {
				String asesorID = (new List<String>(asesores))[0];
				if (USER_LIST.get(asesorID) <> null) {
					accountUpdate.add(new Account(id = proccessedAccount, OwnerId = USER_LIST.get(asesorID)));
				} else {
					accountUpdate.add(new Account(id = proccessedAccount, OwnerId = defaultOwner.Id));
					accountError.put(proccessedAccount, 'No existe el asesor en Salesforce');
				}
			} else if (asesores.size() != 1) {
				accountUpdate.add(new Account(id = proccessedAccount, OwnerId = defaultOwner.Id));
				accountError.put(proccessedAccount, '0 o más de un asesor por cuenta');
			}
		}

		if (!accountUpdate.isEmpty() && !contractUpdate.isEmpty()) {
			upsert accountUpdate;
			upsert contractUpdate;
		}
		if (!accountError.isEmpty()) {
			for (String key : accountError.keySet()) {
				String row = key + ',' + accountError.get(key);
				csvRowValues.add(row);
			}
		}
		if (csvRowValues.size() > 150000) {
			csvColumnHeader = 'ID_CUENTA, ERROR\n';
			String csvFile = csvColumnHeader + String.join(csvRowValues, '\n');
			Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
			blob csvBlob = Blob.valueOf(csvFile);
			csvAttc.setFileName('ErroresCambioAsesor.csv');
			csvAttc.setBody(csvBlob);
			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			String[] toAddresses = new List<string>{ 'luis.felipe.ortiz@pwc.com', 'luis_ot1@outlook.com' };
			String subject = 'Errores Cambio Asesor';
			email.setSubject(subject);
			email.setToAddresses(toAddresses);
			email.setPlainTextBody('Resumen errores');
			email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ csvAttc });
			Messaging.SendEmailResult[] sr = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
			csvRowValues.clear();
		}
	}

	public void finish(Database.BatchableContext bc) {
		if (!csvRowValues.isEmpty()) {
			csvColumnHeader = 'ID_CUENTA, ERROR\n';
			String csvFile = csvColumnHeader + String.join(csvRowValues, '\n');
			Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
			blob csvBlob = Blob.valueOf(csvFile);
			csvAttc.setFileName('ErroresCambioAsesor.csv');
			csvAttc.setBody(csvBlob);
			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			String[] toAddresses = new List<string>{ 'luis.felipe.ortiz@pwc.com', 'luis_ot1@outlook.com' };
			String subject = 'Errores Cambio Asesor';
			email.setSubject(subject);
			email.setToAddresses(toAddresses);
			email.setPlainTextBody('Resumen errores');
			email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ csvAttc });
			Messaging.SendEmailResult[] sr = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
		}
	}
}