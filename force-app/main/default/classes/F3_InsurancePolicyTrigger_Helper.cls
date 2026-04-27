/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_InsurancePolicyTrigger_Helper
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 31/01/2023
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Helper class for the policy trigger
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 31/01/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/

public without sharing class F3_InsurancePolicyTrigger_Helper {
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final Map<string, string> that contains a list with the active users
	 * ------------------------------------------------------------------------------------------------**/
	private static final Map<string, string> USER_LIST;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final String that contains the name of the default owner
	 **/
	private static final String DEFAULT_USER_NAME = 'IntegrationUser';
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static User that contains default owner
	 * ------------------------------------------------------------------------------------------------**/
	private static User defaultOwner;
	private static F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.label.F3_InsurancePolicyTrigger);
	/** ------------------------------------------------------------------------------------------------
	 * Class as a Singleton. Prevents instantiation
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private F3_InsurancePolicyTrigger_Helper() {
	}
	/** ------------------------------------------------------------------------------------------------
	 * Static initialization block for USER_LIST
	 * ------------------------------------------------------------------------------------------------**/
	static {
		USER_LIST = fillUserMap();
	}

	/** -----------------------------------------------------------------------------
	 * @Description policy preparation before insert
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @param    list<InsurancePolicy> policyNew
	 * @return   void
	 * @example  F3_InsurancePolicyTrigger_Helper.setNextPaymentDate(policyNew)
	 **/
	public static void preparePoliciesInsert(list<InsurancePolicy> policyNew) {
		for (InsurancePolicy newPolicy : policyNew) {
			newPolicy.F3_Numero_de_Poliza__c = newPolicy.UniversalPolicyNumber;
			newPolicy.Name = newPolicy.UniversalPolicyNumber;
			newPolicy.EffectiveDate = newPolicy.F3_Temp_EffectiveDate__c != null
				? newPolicy.F3_Temp_EffectiveDate__c
				: newPolicy.EffectiveDate;
			newPolicy.ExpirationDate = newPolicy.F3_Temp_ExpirationDate__c != null
				? newPolicy.F3_Temp_ExpirationDate__c
				: newPolicy.ExpirationDate;
			newPolicy.PaymentDueDate = newPolicy.F3_Temp_PaymentDueDate__c != null
				? newPolicy.F3_Temp_PaymentDueDate__c
				: newPolicy.PaymentDueDate;
			newPolicy.SaleDate = newPolicy.F3_Temp_SaleDate__c != null ? newPolicy.F3_Temp_SaleDate__c : newPolicy.SaleDate;
			calculateNextPaymentDate(newPolicy);
		}
	}

	/** -----------------------------------------------------------------------------
	 * @Description policy preparation before Update
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @param    list<InsurancePolicy> policyNew
	 * @return   void
	 * @example  F3_InsurancePolicyTrigger_Helper.setNextPaymentDate(policyNew)
	 **/
	public static void preparePoliciesUpdate(list<InsurancePolicy> policyNew) {
		for (InsurancePolicy newPolicy : policyNew) {
			calculateNextPaymentDate(newPolicy);
		}
	}

	/** -----------------------------------------------------------------------------
	 * @Description create account for the contractor
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @param    list<InsurancePolicy> policyNew
	 * @return   void
	 * @example  F3_InsurancePolicyTrigger_Helper.createAccountIfNotClient(policyNew)
	 **/
	public static void createAccountIfNotClient(list<InsurancePolicy> policyNew) {
		Map<Integer, Account> accountsMap = new Map<Integer, Account>();
		String insuranceAccountTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
			.get('F3_Cliente_Seguros')
			.getRecordTypeId();
		for (Integer i = 0; i < policyNew.size(); i++) {
			if (policyNew[i].NameInsuredId == null) {
				Map<String, String> names = F3_Generic_Utility.splitCompleteName(policyNew[i].F3_Nombre_Contratante__c);
				if (!names.isEmpty()) {
					Account contractor = new Account();
					contractor.recordTypeId = insuranceAccountTypeId;
					contractor.FirstName = names.get('FirstName');
					contractor.LastName = names.get('LastName');
					accountsMap.put(i, contractor);
				}
			}
		}
		if (!accountsMap.values().isEmpty()) {
			insert accountsMap.values();
			for (Integer index : accountsMap.keySet()) {
				policyNew[index].NameInsuredId = accountsMap.get(index).Id;
			}
		}
	}

	/** -----------------------------------------------------------------------------
	 * @Description create contact for the insured
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @param    list<InsurancePolicy> policyNew
	 * @return   void
	 * @example  F3_InsurancePolicyTrigger_Helper.createInsuredContact(policyNew)
	 **/
	/*public static void createInsuredContact(list<InsurancePolicy> policyNew) {
		Map<Integer, AccountContactRelation> accountContactsMap = new Map<Integer, AccountContactRelation>();
		Map<Integer, Contact> contactsMap = new Map<Integer, Contact>();
		String ContactTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('IndustriesIndividual').getRecordTypeId();
		for (Integer i = 0; i < policyNew.size(); i++) {
			if (policyNew[i].NameInsuredId != null && policyNew[i].F3_Nombre_Contratante__c != policyNew[i].Nom_Aseg__c) {
				Map<String, String> names = F3_Generic_Utility.splitCompleteName(policyNew[i].Nom_Aseg__c);
				if (!names.isEmpty()) {
					Contact insured = new Contact();
					insured.FirstName = names.get('FirstName');
					insured.LastName = names.get('LastName');
					insured.RecordTypeId = ContactTypeId;
					contactsMap.put(i, insured);
					accountContactsMap.put(
						i,
						new AccountContactRelation(AccountId = policyNew[i].NameInsuredId, isActive = true, StartDate = System.today())
					);
				}
			}
		}

		if (!contactsMap.values().isEmpty() && !accountContactsMap.values().isEmpty()) {
			insert contactsMap.values();
			for (Integer index : accountContactsMap.keySet()) {
				accountContactsMap.get(index).ContactId = contactsMap.get(index).Id;
			}
			insert accountContactsMap.values();
		}
	}*/

	/** -----------------------------------------------------------------------------
	 * @Description calculate next Payment date, if not workable, substract 1
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @param    list<InsurancePolicy> policyNew
	 * @return   void
	 * @example  calculateNextPaymentDate(policyNew)
	 **/
	private static void calculateNextPaymentDate(InsurancePolicy newPolicy) {
		if (newPolicy.saleDate == null) {
			newPolicy.addError('La póliza no tiene fecha de emisión');
			return;
		}
		Boolean isWorkable = false;
		Datetime targetDate = Datetime.newInstanceGmt(
			newPolicy.saleDate.year(),
			newPolicy.saleDate.month(),
			newPolicy.saleDate.day(),
			23,
			59,
			59
		);
		targetDate = targetDate.addDays(Integer.valueOf(System.Label.F3_Insurance_Limit_Days));
		do {
			isWorkable = F3_Generic_Utility.isDayWorkable(targetDate, System.Label.F3_Insurance_Business_Hours);
			if (isWorkable == false) {
				targetDate = targetDate - 1;
			}
		} while (isWorkable == false);
		if (targetDate <= newPolicy.saleDate) {
			newPolicy.addError('La proxima fecha de pago no puede ser menor a la fecha de emisión');
		}
		newPolicy.F3_Fecha_limite_pago__c = Date.newInstance(targetDate.year(), targetDate.month(), targetDate.day());
	}

	/** -----------------------------------------------------------------------------
	 * @Description change the owner of the policy based on the field "F3_Id_Asesor__c"
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     03/11/2021
	 * @param    list<InsurancePolicy> policyNew
	 * @return   void
	 * @example  InsurancePolicyTrigger_Helper.changeOwner(policyNew)
	 **/
	public static void changeOwner(list<InsurancePolicy> policyNew, Map<Id, InsurancePolicy> policyOldMap) {
		for (InsurancePolicy newPolicy : policyNew) {
			if (
				triggerMetadata.F3_Run_For_All_Changes__c == false &&
				policyOldMap != null &&
				newPolicy.F3_Id_Asesor__c == policyOldMap.get(newPolicy.Id).F3_Id_Asesor__c
			) {
				continue;
			}
			newPolicy.OwnerId = USER_LIST.get(newPolicy.F3_Id_Asesor__c) != null
				? USER_LIST.get(newPolicy.F3_Id_Asesor__c)
				: defaultOwner.Id;
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