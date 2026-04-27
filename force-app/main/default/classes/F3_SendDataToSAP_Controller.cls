/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_SendDataToSAP_Controller
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 19/10/2022
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Class in Charge to send data to SAP external system
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 19/10/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public with sharing class F3_SendDataToSAP_Controller {
	/** ------------------------------------------------------------------------------------------------
	 * @Description Calls SAP 'crearClienteContrato' service and updates Lead
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     19/10/2022
	 * @param
	 * @return   void
	 * @example  sendClient({ leadIds: [this.recordId] })
	 * ------------------------------------------------------------------------------------------------**/
	@AuraEnabled
	public static string createClientSAP(List<String> leadIds, Boolean FieldsCompleted) {
		try {
			return JSON.serialize(F3_SendDataToSAP_Handler.sendLeads(leadIds, FieldsCompleted,'crearClienteContrato',System.Label.crearClienteContrato_Fields));
		} catch (Exception e) {
			AuraHandledException error = new AuraHandledException(e.getMessage());
			error.setMessage(e.getMessage());
			throw error;
		}
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Calls SAP 'crearContrato' service and updates Opportunity
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     19/10/2022
	 * @param
	 * @return   void
	 * @example  sendClient({ oppIds: [this.recordId] })
	 * ------------------------------------------------------------------------------------------------**/
	@AuraEnabled
	public static string createContractSAP(List<String> oppIds) {
		try {
			return F3_SendDataToSAP_Handler.sendOpps(oppIds);
		} catch (Exception e) {
			AuraHandledException error = new AuraHandledException(e.getMessage());
			error.setMessage(e.getMessage());
			throw error;
		}
	}

	@AuraEnabled(cacheable=true)
	public static List<account> getAccountFrom(String actName) {
		return String.isNotBlank(actName) ? [SELECT Id, Name, Client_ID__c, Owner.name FROM Account WHERE Client_ID__c = :actName] : null;
	}

	@AuraEnabled
	public static String retrieveClientSAP(String accountBP) {
		try {
			return String.isNotBlank(accountBP) ? F3_SendDataToSAP_Handler.getAccount(accountBP) : null;
		} catch (Exception e) {
			AuraHandledException error = new AuraHandledException(e.getMessage());
			error.setMessage(e.getMessage());
			throw error;
		}
	}

	@AuraEnabled
	public static string getExecutiveContracts(Date startDate, Date endDate, String currentUserId) {
		try {
			String startDay = String.valueOf(startDate.day()).length() == 2 ? String.valueOf(startDate.day()) : '0' + startDate.day();
			String startMonth = String.valueOf(startDate.month()).length() == 2
				? String.valueOf(startDate.month())
				: '0' + startDate.month();
			String startYear = String.valueOf(startDate.year()).substring(2, 4);
			String formattedStartDate = startDay + startMonth + startYear;
			String endDay = String.valueOf(endDate.day()).length() == 2 ? String.valueOf(endDate.day()) : '0' + endDate.day();
			String endMonth = String.valueOf(endDate.month()).length() == 2 ? String.valueOf(endDate.month()) : '0' + endDate.month();
			String endYear = String.valueOf(endDate.year()).substring(2, 4);
			String formattedendDate = endDay + endMonth + endYear;
			return F3_SendDataToSAP_Handler.getContractList(formattedStartDate, formattedEndDate, currentUserId);
		} catch (Exception e) {
			AuraHandledException error = new AuraHandledException(e.getMessage());
			error.setMessage(e.getMessage());
			throw error;
		}
	}

	@AuraEnabled
	public static String getContractPortfolio(String contractNumber, String executiveID) {
		try {
			return F3_SendDataToSAP_Handler.getPortfolio(contractNumber, executiveID);
		} catch (Exception e) {
			AuraHandledException error = new AuraHandledException(e.getMessage());
			error.setMessage(e.getMessage());
			throw error;
		}
	}

	@AuraEnabled
	public static string createPolicySAP(List<String> policiesIds) {
		try {
			return 'exito';
		} catch (Exception e) {
			AuraHandledException error = new AuraHandledException(e.getMessage());
			error.setMessage(e.getMessage());
			throw error;
		}
	}
}