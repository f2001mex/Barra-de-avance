/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_WebServices_Test
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 01/01/2023
 * ------------------------------------------------------------------------------------------------
 * @Description Test Class for the F3_WebServices class
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 01/01/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
@isTest(IsParallel=true)
public with sharing class F3_WebServices_Test {
	@isTest
	static void errorToJson() {
		String jsonError;
		try {
			Object testList = new List<Id>();
			Map<String, String> testMap = (Map<String, String>) testList;
		} catch (Exception error) {
			jsonError = F3_WebServices_Utility.exceptionToJson(error);
		}
		Map<String, String> jsonErrorMap = (Map<String, String>) JSON.deserialize(jsonError, Map<String, String>.class);
		System.assert(!jsonErrorMap.isEmpty());
		for (String key : jsonErrorMap.keySet()) {
			System.assert(jsonErrorMap.get(key) != null);
		}
	}
}