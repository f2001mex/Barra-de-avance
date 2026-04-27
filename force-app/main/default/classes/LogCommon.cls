/**
 * @author Tate Shi
 * @date 10/25/2021
 * @description write log in AssignLeadToAdvisor.cls
 */
public without sharing class LogCommon {
	/**
	 * write Log
	 */
	public static void writeLog(String strCategory, String strErrorFileName, String strErrorMessage, Integer intErrorLineNumber) {
		Log__c objLog = new Log__c();

		// Log Result = 'Error'
		if (strErrorMessage != null) {
			objLog.LogResult__c = 'Error';
			objLog.Category__c = strCategory;
			objLog.Error_File__c = strErrorFileName;
			objLog.Error_Line_No__c = intErrorLineNumber;
			objLog.ErrorMessage__c = strErrorMessage;
		}
		// LogResult = 'Normal'
		else {
			// 在catch中调用此方法 不能运行到这里，e.getMessage()一定不为空;  仅在updateLeadList 后调用 正常 结束 会运行到此
			objLog.LogResult__c = 'Normal';
			objLog.Category__c = strCategory;
			objLog.Error_File__c = strErrorFileName;
		}
		if (objLog.ErrorMessage__c != null && objLog.ErrorMessage__c.length() >= 250) {
			objLog.ErrorMessage__c = objLog.ErrorMessage__c.subString(0, 250);
		}
		insert objLog;
	}

	/**
	 *
	 */
	public static void writeLogs(
		String strCategory,
		String strErrorFileName,
		List<String> lstErrorMessage,
		List<Integer> lstErrorLineNumber
	) {
		List<Log__c> lstLog = new List<log__c>();
		// Log Result = 'Error'
		if (lstErrorMessage != null && lstErrorMessage.size() > 0) {
			for (Integer i = 0; i < lstErrorMessage.size(); i++) {
				log__c objLog = new log__c();
				objLog.LogResult__c = 'Error';
				objLog.Category__c = strCategory;
				objLog.Error_File__c = strErrorFileName;
				if (lstErrorLineNumber != null && lstErrorMessage.size() == lstErrorLineNumber.size()) {
					objLog.Error_Line_No__c = lstErrorLineNumber[i];
				}
				objLog.ErrorMessage__c = lstErrorMessage[i];
				if (objLog.ErrorMessage__c != null && objLog.ErrorMessage__c.length() >= 250) {
					objLog.ErrorMessage__c = objLog.ErrorMessage__c.subString(0, 250);
				}
				lstLog.add(objLog);
			}
		}

		if (lstLog.size() > 0) {
			insert lstLog;
		}
	}
}