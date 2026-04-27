/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_LeadDuplicateChecker_Test
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 01/01/2023
 * ------------------------------------------------------------------------------------------------
 * @Description Test class for the F3_LeadDuplicateChecker_Service
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 01/01/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
@isTest
public with sharing class F3_LeadDuplicateChecker_Test {
	@IsTest
	static void verifyDuplicateLeads() {
		Map<Schema.SObjectField, Object> leadDuplicateData = new Map<Schema.SObjectField, Object>{
			Lead.Phone => '5511223344',
			Lead.Email => 'Test@actinver.com'
		};
		insert UtilitiesDataTest.createLeads(2, leadDuplicateData);
		Map<Schema.SObjectField, Object> baseLeadData = new Map<Schema.SObjectField, Object>{
			Lead.Phone => '5511223344',
			Lead.Email => 'Test@actinver.com',
			Lead.LastName => 'WithDuplicate'
		};
		List<Lead> baseLead = UtilitiesDataTest.createLeads(1, baseLeadData);
		insert baseLead;
		List<Lead> duplicates = F3_LeadDuplicateChecker_Service.getDuplicates(baseLead[0].Email, baseLead[0].Phone, baseLead[0].Id);
		System.assertEquals(2, duplicates.size());
	}

	@IsTest
	static void verifyNoDuplicateLeads() {
		Map<Schema.SObjectField, Object> leadDuplicateData = new Map<Schema.SObjectField, Object>{
			Lead.Phone => '5511223344',
			Lead.Email => 'Test@actinver.com'
		};
		insert UtilitiesDataTest.createLeads(2, leadDuplicateData);
		Map<Schema.SObjectField, Object> baseLeadData = new Map<Schema.SObjectField, Object>{
			Lead.Phone => '5511223345',
			Lead.Email => 'Test@actinver.com',
			Lead.LastName => 'WithNoDuplicate'
		};
		List<Lead> baseLead = UtilitiesDataTest.createLeads(1, baseLeadData);
		insert baseLead;
		List<Lead> duplicates = F3_LeadDuplicateChecker_Service.getDuplicates(baseLead[0].Email, baseLead[0].Phone, baseLead[0].Id);
		System.assertEquals(0, duplicates.size());
	}

	@IsTest
	static void verifyLeadNoPhone() {
		Map<Schema.SObjectField, Object> leadDuplicateData = new Map<Schema.SObjectField, Object>{
			Lead.Phone => '5511223344',
			Lead.Email => 'Test@actinver.com'
		};
		insert UtilitiesDataTest.createLeads(2, leadDuplicateData);
		Map<Schema.SObjectField, Object> baseLeadData = new Map<Schema.SObjectField, Object>{
			Lead.Email => 'Test@actinver.com',
			Lead.LastName => 'WithNoPhone'
		};
		List<Lead> baseLead = UtilitiesDataTest.createLeads(1, baseLeadData);
		insert baseLead;
		List<Lead> duplicates = F3_LeadDuplicateChecker_Service.getDuplicates(baseLead[0].Email, baseLead[0].Phone, baseLead[0].Id);
		System.assertEquals(0, duplicates.size());
	}

	@IsTest
	static void verifyLeadNoEmail() {
		Map<Schema.SObjectField, Object> leadDuplicateData = new Map<Schema.SObjectField, Object>{
			Lead.Phone => '5511223344',
			Lead.Email => 'Test@actinver.com'
		};
		insert UtilitiesDataTest.createLeads(2, leadDuplicateData);
		Map<Schema.SObjectField, Object> baseLeadData = new Map<Schema.SObjectField, Object>{
			Lead.Phone => '5511223345',
			Lead.LastName => 'WithNoEmail'
		};
		List<Lead> baseLead = UtilitiesDataTest.createLeads(1, baseLeadData);
		insert baseLead;
		List<Lead> duplicates = F3_LeadDuplicateChecker_Service.getDuplicates(baseLead[0].Email, baseLead[0].Phone, baseLead[0].Id);
		System.assertEquals(0, duplicates.size());
	}
}