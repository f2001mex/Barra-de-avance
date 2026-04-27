/**
 * @description Send Email Controller
 * @auther Dio Xi 2021/08/22
 */
public with sharing class SendMailCtrl {
	/**
	 * @description Normal Send email
	 *
	 * @param strMailDevelopName
	 * @param lstToMailAddress
	 * @param mapMailParam
	 * @return
	 */
	@AuraEnabled
	public static Map<String, Object> doSendMailCommon(String strMailDevelopName, String strRecordId) {
		Map<String, Object> resMap = new Map<String, Object>();
		Map<String, Object> dataMap = new Map<String, Object>();

		try {
			// System.debug('strMailDevelopName' + strMailDevelopName);
			// テンプレートを取得する
			EmailTemplate et = [SELECT Id, Subject, Body FROM EmailTemplate WHERE DeveloperName = :strMailDevelopName];
			// Id of Record
			Id idRecord = strRecordId;
			// Email template Body
			String mailBody = '';
			// Recipient Email Address
			String strEmailAddress = '';

			if (et != null) {
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				Schema.SObjectType schemaSObjectType = idRecord.getSObjectType();

				// Opportunity
				if (schemaSObjectType == Opportunity.getSObjectType()) {
					Opportunity objOpp = [
						SELECT Id, Account.Name, Account.PersonEmail, Owner.FirstName, Owner.LastName, Owner.City
						FROM Opportunity
						WHERE Id = :strRecordId
					];

					// set Recipient Address
					strEmailAddress = objOpp.Account.PersonEmail;
					// mail id
					mail.setTemplateId(et.Id);
					// mail to
					List<String> lstToMailAddress = new List<String>();
					lstToMailAddress.add(strEmailAddress);
					mail.setToAddresses(lstToMailAddress);

					mailBody = et.Body;
					mailBody = mailBody.replace('{!Opportunity.Account}', objOpp.Account.Name);
					if (String.isEmpty(objOpp.Owner.FirstName)) {
						mailBody = mailBody.replace('{!Opportunity.OwnerFirstName}', '');
					} else {
						mailBody = mailBody.replace('{!Opportunity.OwnerFirstName}', objOpp.Owner.FirstName);
					}
					mailBody = mailBody.replace('{!Opportunity.OwnerLastName}', objOpp.Owner.LastName);
					// mailBody = mailBody.replace('{!User.City}', String.isBlank(objOpp.Owner.City)?'None':objOpp.Owner.City);
					String strToday = Datetime.now().format('yyyy-MM-dd');
					mailBody = mailBody.replace('(fecha)', strToday);
				} else if (schemaSObjectType == Lead.getSObjectType()) {
					// Lead
					Lead objLead = [
						SELECT Id, FinServ__ReferredByUser__r.Name, FinServ__ReferredByUser__r.Email, Owner.FirstName, Owner.LastName
						FROM Lead
						WHERE Id = :strRecordId
					];

					// set Recipient Address
					strEmailAddress = objLead.FinServ__ReferredByUser__r.Email;
					// mail id
					mail.setTemplateId(et.Id);
					// mail to
					List<String> lstToMailAddress = new List<String>();
					lstToMailAddress.add(strEmailAddress);
					mail.setToAddresses(lstToMailAddress);

					mailBody = et.Body;
					mailBody = mailBody.replace('{!Lead.FinServ__ReferredByUser__c}', objLead.FinServ__ReferredByUser__r.Name);
					if (String.isEmpty(objLead.Owner.FirstName)) {
						mailBody = mailBody.replace('{!Lead.OwnerFirstName}', '');
					} else {
						mailBody = mailBody.replace('{!Lead.OwnerFirstName}', objLead.Owner.FirstName);
					}
					mailBody = mailBody.replace('{!Lead.OwnerLastName}', objLead.Owner.LastName);
					String strToday = Datetime.now().format('yyyy-MM-dd');
					mailBody = mailBody.replace('(fecha)', strToday);
				}

				mail.setSubject(et.Subject);
				mail.setPlainTextBody(mailBody);

				mail.setSaveAsActivity(false);
				mail.setUseSignature(false);
				mail.setCharset('UTF-8');
				// org id
				String strDisplayName = System.Label.EmailSender; //'ActinverAdmin';
				List<OrgWideEmailAddress> listAddresses = [
					SELECT Id, DisplayName, Address
					FROM OrgWideEmailAddress
					WHERE DisplayName = :strDisplayName
				];
				Id orgWideEmailId = null;
				if (listAddresses.size() > 0) {
					orgWideEmailId = listAddresses[0].Id;
				}
				mail.setOrgWideEmailAddressId(orgWideEmailId);

				List<ContentDocumentLink> lstContentDocumentLink = [
					SELECT id, contentDocumentid
					FROM ContentDocumentLink
					WHERE LinkedEntityId = :strRecordId
				];
				Set<String> setContentDocumentId = new Set<String>();
				for (ContentDocumentLink objLink : lstContentDocumentLink) {
					setContentDocumentId.add(objLink.contentDocumentid);
				}

				List<ContentVersion> lstContentVersion = [
					SELECT Title, VersionData, FileExtension
					FROM ContentVersion
					WHERE ContentDocumentId IN :setContentDocumentId AND IsLatest = TRUE
				];
				List<Messaging.EmailFileAttachment> lstAttachments = new List<Messaging.EmailFileAttachment>();
				for (ContentVersion objContentVersion : lstContentVersion) {
					Messaging.EmailFileAttachment attatchment = new Messaging.EmailFileAttachment();
					attatchment.setFileName(objContentVersion.title + '.' + objContentVersion.FileExtension);
					attatchment.setBody(objContentVersion.VersionData);
					lstAttachments.add(attatchment);
				}
				mail.setFileAttachments(lstAttachments);
				// System.debug('strEmailAddress ------ is : '+ strEmailAddress);
				if (String.isEmpty(strEmailAddress)) {
					resMap.put('result', 'NG');
					resMap.put('message', 'NoEmail');
				} else {
					// send mail
					List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
					allmsg.add(mail);
					Messaging.SendEmailResult[] results = Messaging.sendEmail(allmsg, false);

					// System.debug('results : ' + results);
					if (results[0].isSuccess()) {
						resMap.put('result', 'OK');
					} else {
						resMap.put('result', 'NG');
						resMap.put('message', results[0].getErrors());
					}
				}
			}
		} catch (Exception e) {
			// System.debug('Error : ' + e.getMessage());
			// System.debug('Error Line : ' + e.getLineNumber());
			resMap.put('result', 'NG');
			resMap.put('message', e.getMessage());
		}

		return resMap;
	}

	/**
	 *
	 */
	@AuraEnabled(cacheable=true)
	public static String returnRecordType(Id recordId) {
		String strResult = '';
		try {
			Schema.SObjectType objType = recordId.getSobjectType();
			Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
			strResult = objDescribe.getName();
		} catch (Exception e) {
			// System.debug('Error Msg : ' + e.getMessage());
			// System.debug('Error Line No : ' + e.getLineNumber());
		}
		return strResult;
	}
}