/**
 * @author Tate Shi
 * @date 10/25/2021
 * @description Test of LogCommon.cls
 */
@isTest(IsParallel=true)
public with sharing class LogCommonTest {
	private static String strCategory_Global = 'Assignment Of The Lead';
	private static String strErrorFileName_Golbal = 'AssignLeadToAdvisor.cls';
	/**
	 * @description test two situations : Error And Normal when write Log
	 */
	@isTest
	static void writeLogTest() {
		Test.startTest();
		String strCategory = strCategory_Global;
		String strErrorFileName = strErrorFileName_Golbal;
		String strErrorMessage = 'This is ErrorMessage Test';
		Integer intErrorLineNumber = 10;
		LogCommon.writeLog(strCategory, strErrorFileName, strErrorMessage, intErrorLineNumber);
		strCategory = strCategory_Global;
		strErrorFileName = strErrorFileName_Golbal;
		strErrorMessage = null;
		intErrorLineNumber = null;
		LogCommon.writeLog(strCategory, strErrorFileName, strErrorMessage, intErrorLineNumber);
		List<Log__c> lstLog = [
			SELECT LogResult__c, Category__c, Error_File__c, ErrorMessage__c, Error_Line_No__c
			FROM Log__c
			WHERE Id != NULL
			LIMIT 10000
		];
		// System.debug(lstLog);
		Test.stopTest();
		System.assertEquals('Error', lstLog[0].LogResult__c);
		System.assertEquals(strCategory_Global, lstLog[0].Category__c);
		System.assertEquals(strErrorFileName_Golbal, lstLog[0].Error_File__c);
		System.assertEquals('This is ErrorMessage Test', lstLog[0].ErrorMessage__c);
		System.assertEquals(10, lstLog[0].Error_Line_No__c);
		System.assertEquals('Normal', lstLog[1].LogResult__c);
		System.assertEquals(strCategory_Global, lstLog[1].Category__c);
		System.assertEquals(strErrorFileName_Golbal, lstLog[1].Error_File__c);
		System.assertEquals(null, lstLog[1].ErrorMessage__c);
		System.assertEquals(null, lstLog[1].Error_Line_No__c);
	}
	/**
	 * Test for ErrorMessage longer than 250 characters
	 * because the field is Text(255)
	 */
	@isTest
	static void writeLogLongerThan250Test() {
		Test.startTest();
		String strCategory = strCategory_Global;
		String strErrorFileName = strErrorFileName_Golbal;
		String strErrorMessage = '';
		for (Integer i = 0; i < 255; i++) {
			strErrorMessage += 'E';
		}
		Integer intErrorLineNumber = 10;
		LogCommon.writeLog(strCategory, strErrorFileName, strErrorMessage, intErrorLineNumber);
		List<Log__c> lstLog = [
			SELECT LogResult__c, Category__c, Error_File__c, ErrorMessage__c, Error_Line_No__c
			FROM Log__c
			WHERE Id != NULL
			LIMIT 10000
		];
		// System.debug(lstLog);
		Test.stopTest();
		System.assertEquals('Error', lstLog[0].LogResult__c);
		System.assertEquals(strCategory_Global, lstLog[0].Category__c);
		System.assertEquals(strErrorFileName_Golbal, lstLog[0].Error_File__c);
		System.assertEquals(250, lstLog[0].ErrorMessage__c.length());
		System.assertEquals(10, lstLog[0].Error_Line_No__c);
	}
	@isTest
	static void writeLogsTest() {
		Test.startTest();
		String strCategory = 'Notification Of The Case';
		String strErrorFileName = 'CaseController.cls';
		String strErrorMessage = ' ';
		List<String> lstErrorMessage = new List<String>();
		List<Integer> lstLineNumberPositive = new List<Integer>();
		List<Integer> lstLineNumberNegative = new List<Integer>();
		for (Integer i = 0; i < 10; i++) {
			strErrorMessage = 'error ' + i;
			lstErrorMessage.add(strErrorMessage);
			lstLineNumberPositive.add(i);
		}
		lstLineNumberNegative.add(10);
		LogCommon.writeLogs(strCategory, strErrorFileName, lstErrorMessage, lstLineNumberPositive);
		LogCommon.writeLogs(strCategory, strErrorFileName, lstErrorMessage, lstLineNumberNegative);
		//test longer than 250
		for (Integer i = 0; i < 255; i++) {
			strErrorMessage += 'E';
		}
		lstErrorMessage.add(strErrorMessage);
		lstLineNumberPositive.add(10);
		LogCommon.writeLogs(strCategory, strErrorFileName, lstErrorMessage, lstLineNumberPositive);
		List<Log__c> lstLog = [
			SELECT LogResult__c, Category__c, Error_File__c, ErrorMessage__c, Error_Line_No__c
			FROM Log__c
			WHERE Id != NULL
			LIMIT 10000
		];
		Test.stopTest();
		System.assertEquals('error 0', lstLog[0].ErrorMessage__c);
		System.assertEquals('Notification Of The Case', lstLog[0].Category__c);
		System.assertEquals('CaseController.cls', lstLog[0].Error_File__c);
	}
}