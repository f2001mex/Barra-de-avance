/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_CloseProcesses_Test
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 12/08/2022
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Test for the F3_CloseProcesses_Batch process
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 12/08/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
@isTest
public with sharing class F3_CloseProcesses_Test {
	static final Integer NUMBER_OF_RECORDS = 10;
	static final Integer NUMBER_OF_PARENT_RECORDS = 2;

	@TestSetup
	public static void setup() {
		List<F3_Object_Closing_Date__mdt> processesToClose = F3_Object_Closing_Date__mdt.getAll().values();
		for (F3_Object_Closing_Date__mdt process : processesToClose) {
			List<SObject> recordToInsert = new List<SObject>();
			Schema.SObjectField statusField = ((SObject) Type.forName('Schema', process.F3_Object__c).newInstance())
				.getSObjectType()
				.getDescribe()
				.fields
				.getMap()
				.get(process.F3_Status_field__c);
			String recordTypeID = ((SObject) Type.forName('Schema', process.F3_Object__c).newInstance())
				.getSObjectType()
				.getDescribe()
				.getRecordTypeInfosByName()
				.get(process.F3_Record_Type__c.split(',')[0].replace('\'', ''))
				.getRecordTypeId();
			switch on process.F3_Object__c {
				when 'Lead' {
					final Map<Schema.SObjectField, Object> mapFields = new Map<Schema.SObjectField, Object>{
						statusField => process.F3_Status_To_Consider__c.split(',')[0].replace('\'', ''),
						Lead.RecordTypeId => recordTypeID
					};
					insert UtilitiesDataTest.createLeads(NUMBER_OF_RECORDS, mapFields);
				}
				when 'Opportunity' {
					final Map<Schema.SObjectField, Object> mapFields = new Map<Schema.SObjectField, Object>{
						statusField => process.F3_Status_To_Consider__c.split(',')[0].replace('\'', ''),
						Opportunity.RecordTypeId => recordTypeID
					};
					final Map<Schema.SObjectField, Object> accMapFields = new Map<Schema.SObjectField, Object>{
						Account.Client_ID__c => null
					};
					Map<String, List<SObject>> accountsAndOpportunitiesMap = UtilitiesDataTest.createAccountOpportunities(
						NUMBER_OF_PARENT_RECORDS,
						NUMBER_OF_RECORDS,
						accMapFields,
						mapFields
					);
					insert accountsAndOpportunitiesMap.get('Opportunity');
				}
				when else {
				}
			}
		}
	}

	@isTest
	static void testScheduled() {
		List<F3_Object_Closing_Date__mdt> processesToClose = F3_Object_Closing_Date__mdt.getAll().values();
		Test.startTest();
		F3_CloseProcesses_Schedulable processScheduler = new F3_CloseProcesses_Schedulable();
		String chron = '0 0 23 * * ?';
		system.schedule('Test processScheduler', chron, processScheduler);
		Test.stopTest();
		System.assertEquals(
			processesToClose.size(),
			F3_CloseProcesses_Schedulable.batchesIds.size(),
			'Metadata list size must be equal to the executed batches'
		);
	}

	@isTest
	static void testBatch() {
		List<F3_Object_Closing_Date__mdt> processesToClose = F3_Object_Closing_Date__mdt.getAll().values();
		Test.startTest();
		for (F3_Object_Closing_Date__mdt process : processesToClose) {
			String jobId = Database.executeBatch(new F3_CloseProcesses_Batch(process.DeveloperName), 10000);
		}
		Test.stopTest();
		for (F3_Object_Closing_Date__mdt process : processesToClose) {
			List<SObject> updatedRecords = Database.query(
				'SELECT ID, ' +
					process.F3_Status_field__c +
					', ' +
					process.F3_Start_date_field__c +
					' FROM ' +
					process.F3_Object__c +
					' WHERE RecordType.Name IN (' +
					process.F3_Record_Type__c +
					') AND ' +
					process.F3_Status_field__c +
					' IN (' +
					process.F3_Status_To_Consider__c +
					', \'' +
					process.F3_Closing_Status_Value__c +
					'\')'
			);
			for (SObject updatedRecord : updatedRecords) {
				if (updatedRecord.get(process.F3_Start_date_field__c) != null) {
					System.assertEquals(process.F3_Closing_Status_Value__c, updatedRecord.get(process.F3_Status_field__c));
				}
			}
		}
	}
}