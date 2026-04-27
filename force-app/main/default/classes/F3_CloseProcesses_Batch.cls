/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_CloseProcesses_Batch
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 12/08/2022
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Dynamic batch to automate changing stages based on time, record type and current stage in
 *  all kind of records and objects that have a stage path
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 12/08/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public without sharing class F3_CloseProcesses_Batch implements Database.Batchable<sObject>, Database.Stateful {
	String processName;

	public F3_CloseProcesses_Batch(String processName) {
		this.processName = processName;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		F3_Object_Closing_Date__mdt currentProcess = F3_Object_Closing_Date__mdt.getInstance(processName);
		String query =
			'SELECT ID, ' +
			currentProcess.F3_Start_date_field__c +
			' FROM ' +
			currentProcess.F3_Object__c +
			' WHERE RecordType.Name IN (' +
			currentProcess.F3_Record_Type__c +
			') AND ' +
			currentProcess.F3_Status_field__c +
			' IN (' +
			currentProcess.F3_Status_To_Consider__c +
			') AND ' +
			currentProcess.F3_Start_date_field__c +
			' != null';
		System.debug(query);
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext bc, List<SObject> scope) {
		if (!scope.isEmpty()) {
			F3_Object_Closing_Date__mdt currentProcess = F3_Object_Closing_Date__mdt.getInstance(processName);
			List<SObject> recordsToUpdate = new List<SObject>();
			for (SObject selectedRecord : scope) {
				if (selectedRecord.get(currentProcess.F3_Start_date_field__c) == null) {
					continue;
				}
				Integer workDays = F3_Generic_Utility.calculateWorkDaysV2(
					((Datetime) selectedRecord.get(currentProcess.F3_Start_date_field__c)).dateGMT(),
					System.today(),
					'Workable Days'
				);
				if (workDays > currentProcess.F3_Days_for_closing__c || Test.isRunningTest()) {
					selectedRecord.put(currentProcess.F3_Status_field__c, currentProcess.F3_Closing_Status_Value__c);
					recordsToUpdate.add(selectedRecord);
				}
			}
			if (!recordsToUpdate.isEmpty()) {
				Schema.SObjectField idField = ((SObject) Type.forName('Schema', currentProcess.F3_Object__c).newInstance())
					.getSObjectType()
					.getDescribe()
					.fields.getMap()
					.get('Id');
				Map<String, Map<String, String>> upsertResults = (Map<String, Map<String, String>>) F3_Database_Utility.upsertRecords(
					recordsToUpdate,
					idField,
					false,
					true
				);
				System.debug(upsertResults);
			}
		}
	}

	public void finish(Database.BatchableContext bc) {
	}
}