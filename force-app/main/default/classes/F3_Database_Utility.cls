/**
 *   ------------------------------------------------------------------------------------------------
 * Name     F3_Database_Utility
 * Author   luis.felipe.ortiz@pwc.com
 * Date     Created: 12/08/2022
 * Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * Description Utility class for Database operations
 *   ------------------------------------------------------------------------------------------------
 * Changes
 * 12/08/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public with sharing class F3_Database_Utility {
	/** ------------------------------------------------------------------------------------------------
	 * Description Upsert the records and return the stadistics of the operations
	 * If stadistics are needed, boolean to true and cast to (Map<String, Map<String, String>>) else
	 * cast to List<Database.upsertResult>
	 *   ------------------------------------------------------------------------------------------------
	 * author   luis.felipe.ortiz@pwc.com
	 * date     12/08/2022
	 * param    List<SObject> recordsToUpsert, Schema.SObjectField externalIdField, Boolean allOrNone
	 * return   Map<String, Map<String, String>>
	 * example  (Map<String, Map<String, String>>)F3_Database_Utility.upsertRecords(clientsRecieved, null, false);
	 * ------------------------------------------------------------------------------------------------**/
	static public Object upsertRecords(
		List<SObject> recordsToUpsert,
		Schema.SObjectField externalIdField,
		Boolean allOrNone,
		Boolean withStadistics
	) {
		try {
			List<Database.upsertResult> upsertResults;
			if (!recordsToUpsert.isEmpty()) {
				if (externalIdField != null) {
					upsertResults = Database.upsert(recordsToUpsert, externalIdField, allOrNone);
				} else {
					upsertResults = Database.upsert(recordsToUpsert, allOrNone);
				}
			}
			if (withStadistics == true) {
				return createDMLStadistics(upsertResults);
			}
			return upsertResults;
		} catch (Exception error) {
			return new Map<String, Map<String, String>>{
				'Errors AllOrNone' => new Map<String, String>{
					'Errors AllOrNone' => String.valueOf(recordsToUpsert.size()),
					'Error Description' => error.getMessage()
				}
			};
		}
	}

	/** ------------------------------------------------------------------------------------------------
	 * Description Insert the records and return the stadistics of the operations
	 * If stadistics are needed, boolean to true and cast to (Map<String, Map<String, String>>) else
	 * cast to List<Database.SaveResult>
	 *   ------------------------------------------------------------------------------------------------
	 * author   luis.felipe.ortiz@pwc.com
	 * date     12/08/2022
	 * param    List<SObject> recordsToInsert, Schema.SObjectField externalIdField, Boolean allOrNone
	 * return   Map<String, Map<String, String>>
	 * example  (Map<String, Map<String, String>>)F3_Database_Utility.insertRecords(clientsRecieved, false);
	 * ------------------------------------------------------------------------------------------------**/
	static public Object insertRecords(List<SObject> recordsToInsert, Boolean allOrNone, Boolean withStadistics) {
		try {
			List<Database.SaveResult> insertResults;
			if (!recordsToInsert.isEmpty()) {
				insertResults = Database.insert(recordsToInsert, allOrNone);
			}
			if (withStadistics == true) {
				return createDMLStadistics(insertResults);
			}
			return insertResults;
		} catch (Exception error) {
			return new Map<String, Map<String, String>>{
				'Errors AllOrNone' => new Map<String, String>{ 'Errors AllOrNone' => String.valueOf(recordsToInsert.size()) }
			};
		}
	}

	/** ------------------------------------------------------------------------------------------------
	 * Description Update the records and return the stadistics of the operations
	 * If stadistics are needed, boolean to true and cast to (Map<String, Map<String, String>>) else
	 * cast to List<Database.SaveResult>
	 *   ------------------------------------------------------------------------------------------------
	 * author   luis.felipe.ortiz@pwc.com
	 * date     12/08/2022
	 * param    List<SObject> recordsToUpdate, Schema.SObjectField externalIdField, Boolean allOrNone
	 * return   Map<String, Map<String, String>>
	 * example  (Map<String, Map<String, String>>)F3_Database_Utility.updateRecords(clientsRecieved, false);
	 * ------------------------------------------------------------------------------------------------**/
	static public Object updateRecords(List<SObject> recordsToUpdate, Boolean allOrNone, Boolean withStadistics) {
		try {
			List<Database.SaveResult> updateResults;
			if (!recordsToUpdate.isEmpty()) {
				updateResults = Database.update(recordsToUpdate, allOrNone);
			}
			if (withStadistics == true) {
				return createDMLStadistics(updateResults);
			}
			return updateResults;
		} catch (Exception error) {
			return new Map<String, Map<String, String>>{
				'Errors AllOrNone' => new Map<String, String>{ 'Errors AllOrNone' => String.valueOf(recordsToUpdate.size()) }
			};
		}
	}

	/** ------------------------------------------------------------------------------------------------
	 * Description Creates stadistics of the results of the operation
	 *   ------------------------------------------------------------------------------------------------
	 * author   luis.felipe.ortiz@pwc.com
	 * date     12/08/2022
	 * param    List<SObject> recordsToInsert, Schema.SObjectField externalIdField, Boolean allOrNone
	 * return   Map<String, Map<String, String>>
	 * example  (Map<String, Map<String, String>>)F3_Database_Utility.insertRecords(clientsRecieved, false);
	 * ------------------------------------------------------------------------------------------------**/
	static public Map<String, Map<String, String>> createDMLStadistics(Object dmlResults) {
		Map<String, Map<String, String>> stadisticsMap;
		Integer countSuccess = 0;
		Integer countCreated = 0;
		Integer countError = 0;
		Map<String, String> errorDescriptions = new Map<String, String>();
		if (dmlResults instanceof List<Database.upsertResult>) {
			List<Database.upsertResult> resultList = (List<Database.upsertResult>) dmlResults;
			for (Database.upsertResult result : resultList) {
				if (result.isSuccess() == true) {
					countSuccess++;
					if (result.isCreated() == true) {
						countCreated++;
					}
				} else if (!result.getErrors().isEmpty()) {
					for (Database.Error error : result.getErrors()) {
						if (errorDescriptions.get(error.getMessage()) == null) {
							errorDescriptions.put(error.getMessage(), '1');
						} else {
							errorDescriptions.put(
								error.getMessage(),
								String.valueOf(Integer.valueOf(errorDescriptions.get(error.getMessage())) + 1)
							);
						}
						countError++;
					}
				}
			}
			stadisticsMap = new Map<String, Map<String, String>>{
				'Stadistics' => new Map<String, String>{
					'Total' => String.valueOf(resultList.size()),
					'Success' => String.valueOf(countSuccess),
					'Created' => String.valueOf(countCreated),
					'Errors' => String.valueOf(countError)
				},
				'Errors Descriptions' => errorDescriptions
			};
		} else if (dmlResults instanceof List<Database.SaveResult>) {
			List<Database.SaveResult> resultList = (List<Database.SaveResult>) dmlResults;
			for (Database.SaveResult result : resultList) {
				if (result.isSuccess() == true) {
					countSuccess++;
				} else if (!result.getErrors().isEmpty()) {
					for (Database.Error error : result.getErrors()) {
						if (errorDescriptions.get(error.getMessage()) == null) {
							errorDescriptions.put(error.getMessage(), '1');
						} else {
							errorDescriptions.put(
								error.getMessage(),
								String.valueOf(Integer.valueOf(errorDescriptions.get(error.getMessage())) + 1)
							);
						}
						countError++;
					}
				}
			}
			stadisticsMap = new Map<String, Map<String, String>>{
				'Stadistics' => new Map<String, String>{
					'Total' => String.valueOf(resultList.size()),
					'Success' => String.valueOf(countSuccess),
					'Errors' => String.valueOf(countError)
				},
				'Errors Descriptions' => errorDescriptions
			};
		}
		System.debug('···· Errore(s) - insert[sObject]: '+stadisticsMap);
		return stadisticsMap;
	}
}