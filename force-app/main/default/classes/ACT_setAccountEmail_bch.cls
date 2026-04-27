/********************************************************************************** 
    Name: ACT_setAccountEmail_bch
    Description: Apex Class is used to batch process the records and update the 
                 email of the parent Account
===================================================================================
    Information about changes (versions)
===================================================================================
    Version     Date                Author              Detail          Description
    1.0         2022-02-28          Antonio Gervacio    Creation        Creation
**********************************************************************************/
global class ACT_setAccountEmail_bch implements Database.Batchable<sObject>, Database.stateful {
	public String query = 'SELECT Id, NUM_CONTRATO__r.Account.PersonContactId, NUM_CONTRATO__r.AccountId, NUM_CONTRATO__r.AccountOpeningDate__c, Contract_email__c, MainFlag__c FROM Correo_de_Contrato__c WHERE NUM_CONTRATO__r.AccountId != null AND NUM_CONTRATO__r.Account.PersonContactId != null AND NUM_CONTRATO__r.AccountOpeningDate__c != null AND MainFlag__c = \'X\' ORDER BY NUM_CONTRATO__r.AccountOpeningDate__c ASC';
	public Map<String, String> errorStatusCodeDetailMap = new Map<String, String>();
	public String results = '';
	public Integer noRecords = 0;
	public Set<String> idRecordErrorSet = new Set<String>();
	public Set<String> idRecordSuccessSet = new Set<String>();

	global Database.QueryLocator start(Database.BatchableContext BC) {
		query = Label.ACT_setAccountEmail_queryStr != 'default' ? Label.ACT_setAccountEmail_queryStr : query;
		System.debug('ACT_setAccountEmail_bch | start');
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Correo_de_Contrato__c> records) {
		System.debug('ACT_setAccountEmail_bch | execute');
		System.debug('ACT_setAccountEmail_bch | #records to be processed: ' + records.size());

		Map<String, String> accIdEmailMap = new Map<String, String>();
		List<Account> recordsToBeUpdatedList = new List<Account>();

		if (records.size() > 0) {
			for (Correo_de_Contrato__c rec : records) {
				accIdEmailMap.put(rec.NUM_CONTRATO__r.AccountId, rec.Contract_email__c);
			}
		}

		if (accIdEmailMap.size() > 0) {
			for (String accId : accIdEmailMap.keySet()) {
				Account accForUpdate = new Account();
				accForUpdate.Id = accId;
				accForUpdate.PersonEmail = accIdEmailMap.get(accId);
				recordsToBeUpdatedList.add(accForUpdate);
			}
		}
		System.debug('ACT_setAccountEmail_bch | #records to be updated: ' + recordsToBeUpdatedList.size());
		noRecords = recordsToBeUpdatedList.size() > 0 ? noRecords + recordsToBeUpdatedList.size() : noRecords;
		System.debug('ACT_setAccountEmail_bch | # records processed:' + noRecords);

		if (recordsToBeUpdatedList.size() > 0) {
			List<Database.SaveResult> updateResults = Database.update(recordsToBeUpdatedList, false);
			for (Integer i = 0; i < updateResults.size(); i++) {
				if (updateResults.get(i).isSuccess()) {
					idRecordSuccessSet.add(recordsToBeUpdatedList.get(i).Id);
				} else if (!updateResults.get(i).isSuccess()) {
					Database.Error error = updateResults.get(i).getErrors().get(0);
					errorStatusCodeDetailMap.put(String.valueOf(error.getStatusCode()), String.valueOf(error.getMessage()));
					idRecordErrorSet.add(recordsToBeUpdatedList.get(i).Id);
				}
			}
		}
	}

	global void finish(Database.BatchableContext BC) {
		results =
			' | ACT_setAccountEmail_bch | # records updated successfully: ' +
			String.valueOf(idRecordSuccessSet.size()) +
			'/' +
			String.valueOf(noRecords);
		System.debug('ACT_setAccountEmail_bch | finish');
		System.debug(results);

		Integer batchSize = Integer.valueOf(Label.ACT_setAccountEmail_batchSize);

		if (!errorStatusCodeDetailMap.isEmpty() || Test.isRunningTest()) {
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setSubject('Errors occurred during ACT_setAccountEmail_bch process. ');
			mail.setTargetObjectId(UserInfo.getUserId());
			mail.setSaveAsActivity(false);
			String plainTextBody = 'Errors occurred during ACT_setAccountEmail_bch process. ' + results;
			for (String str : errorStatusCodeDetailMap.keySet()) {
				plainTextBody = plainTextBody + ' | ' + str + ' ' + errorStatusCodeDetailMap.get(str);
			}
			for (String recId : idRecordErrorSet) {
				plainTextBody = plainTextBody + '|' + recId + '|';
			}
			mail.setPlainTextBody(plainTextBody);
			Messaging.sendEmail(new List<Messaging.Email>{ mail });
		}

		if (!Test.isRunningTest()) {
			Database.executeBatch(new ACT_setAccountPhone_bch(), batchSize);
		}
	}
}