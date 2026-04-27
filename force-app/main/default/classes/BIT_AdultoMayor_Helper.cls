/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 07-02-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
public without sharing class BIT_AdultoMayor_Helper {
	public static Map<String, String> updateAccounts (List<Account> records) {
		Map<String, String> errors = new Map<String, String>();
		List<Database.SaveResult> updateList = Database.update(records, false);
		for (Database.SaveResult saveResult: updateList) {
			if (!saveResult.isSuccess()) {
				Integer intCount = 0;
				for(Database.Error error : saveResult.getErrors()) {
					errors.put('Error' + intCount, error.getMessage());
					errors.put('Registro', saveResult.getId());
					intCount++;
				}
			}
		}
		return errors;
	}
	public static void saveLogError(Map<String, String> mapErrors, String message, String errorCode){
		EventLogger.error(new Map<String, String>{'contextId' => null,
													'type' => '',
													'errorCode' => errorCode,
													'message'   => message,
													'request'   => JSON.serializePretty(mapErrors)});
	}
}