@IsTest
private class F3_Database_Test {
	@IsTest
	static void updateEnrolamiento() {
		Account acc = new Account();
		acc.Client_ID__c = '1234567890123';
		acc.Industry = 'Agriculture';
		acc.Name = 'Test';
		List<SObject> sObjectosAcc = new List<SObject>();
		sObjectosAcc.add(acc);
		acc.Client_ID__c = '65153467879';
		sObjectosAcc.add(acc);
		acc.Client_ID__c = '12135678794';
		sObjectosAcc.add(acc);

		acc.Client_ID__c = null;
		sObjectosAcc.add(acc);

		List<SObject> sObjectosAcc2 = new List<SObject>();
		sObjectosAcc2.add(acc);

		Schema.SObjectField accExternalField = Account.Client_ID__c.getDescribe().getSObjectField();
		List<Database.upsertResult> upsertResults;
		List<Database.upsertResult> upsertResult2;

		Test.startTest();
		Map<String, Map<String, String>> upsertedAccounts = (Map<String, Map<String, String>>) F3_Database_Utility.upsertRecords(
			sObjectosAcc,
			accExternalField,
			false,
			true
		);
		Map<String, Map<String, String>> upsertedAccount2 = (Map<String, Map<String, String>>) F3_Database_Utility.upsertRecords(
			sObjectosAcc2,
			accExternalField,
			false,
			true
		);
		Test.stopTest();

		System.assertEquals(upsertedAccounts.get('Errors AllOrNone').get('Errors AllOrNone'), '4');
		System.assertEquals(upsertedAccount2.get('Errors Descriptions').get('Client_ID__c not specified'), '1');
	}
}