/********************************************************************************** 
    Name: ACT_setAccountPhone_bch
    Description: Apex Class is used to batch process the records and update the 
                 phone of the parent Account
===================================================================================
    Information about changes (versions)
===================================================================================
    Version     Date                Author              Detail          Description
    1.0         2022-03-01          Antonio Gervacio    Creation        Creation
**********************************************************************************/
global class ACT_setAccountPhone_bch implements Database.Batchable<sObject>, Database.stateful {
	public String query = 'SELECT Id, IDSap__r.Account.PersonContactId, IDSap__r.AccountId, IDSap__r.AccountOpeningDate__c, Phone__c, MainFlag__c FROM Telefono_de_Contrato__c WHERE IDSap__r.AccountId != null AND IDSap__r.AccountOpeningDate__c != null AND MainFlag__c = \'X\' ORDER BY IDSap__r.AccountOpeningDate__c ASC';

	public Map<String, String> errorStatusCodeDetailMap = new Map<String, String>();
	public String results = '';
	public Integer noRecords = 0;

	public Set<String> idRecordErrorSet = new Set<String>();
	public Set<String> idRecordSuccessSet = new Set<String>();

	global Database.QueryLocator start(Database.BatchableContext BC) {
		query = Label.ACT_setAccountPhone_queryStr != 'default' ? Label.ACT_setAccountPhone_queryStr : query;

		System.debug('ACT_setAccountPhone_bch | start');
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Telefono_de_Contrato__c> records) {
		System.debug('ACT_setAccountPhone_bch | execute');
		System.debug('ACT_setAccountPhone_bch | #records to be processed: ' + records.size());

		Map<String, String> accIdPhoneMap = new Map<String, String>();
		List<Account> recordsToBeUpdatedList = new List<Account>();

		if (records.size() > 0) {
			for (Telefono_de_Contrato__c rec : records) {
				accIdPhoneMap.put(rec.IDSap__r.AccountId, rec.Phone__c);
			}
		}

		if (accIdPhoneMap.size() > 0) {
			for (String accId : accIdPhoneMap.keySet()) {
				Account accForUpdate = new Account();
				accForUpdate.Id = accId;
				accForUpdate.Phone = accIdPhoneMap.get(accId);
				recordsToBeUpdatedList.add(accForUpdate);
			}
		}

		System.debug('ACT_setAccountPhone_bch | #records to be updated: ' + recordsToBeUpdatedList.size());
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
			' | ACT_setAccountPhone_bch | # records updated successfully: ' +
			String.valueOf(idRecordSuccessSet.size()) +
			'/' +
			String.valueOf(noRecords);
		System.debug('ACT_setAccountPhone_bch | finish');
		System.debug(results);

		Integer batchSize = Integer.valueOf(Label.ACT_setAccountEmail_batchSize);

		if (!errorStatusCodeDetailMap.isEmpty() || Test.isRunningTest()) {
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setSubject('Errors occurred during ACT_setAccountPhone_bch process. ');
			mail.setTargetObjectId(UserInfo.getUserId());
			mail.setSaveAsActivity(false);
			String plainTextBody = 'Errors occurred during ACT_setAccountPhone_bch process. ' + results;
			for (String str : errorStatusCodeDetailMap.keySet()) {
				plainTextBody = plainTextBody + ' | ' + str + ' ' + errorStatusCodeDetailMap.get(str);
			}
			for (String recId : idRecordErrorSet) {
				plainTextBody = plainTextBody + '|' + recId + '|';
			}
			mail.setPlainTextBody(plainTextBody);
			Messaging.sendEmail(new List<Messaging.Email>{ mail });
		}
	}
}