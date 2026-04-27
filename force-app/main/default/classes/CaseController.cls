/**
 * @author Tate Shi
 * @date 11/05/2021
 * @description update Case.Tiempo_de_caso_abierto__c, calculate numebr of days a case has been open
 */
public with sharing class CaseController {
	private static String strFormat = 'EEEE';
	private static String strSaturday = 'Saturday';
	private static String strSunday = 'Sunday';
	// Case.Status : Cierre (Closed)
	static final String CASE_STATUS_CLOSED = Label.CASE_STATUS_CLOSED;
	// Case Status : Proceso de resolución
	static final String CASE_STATUS_RESOLUTION_PROCESS = Label.CASE_STATUS_RESOLUTION_PROCESS;

	// Case RecordType Name
	//72hour
	static final String CASE_RECORDTYPE2 = Label.CASE_RECORDTYPE_CUSTOMER_CANCELLATION;
	//72hour
	static final String CASE_RECORDTYPE5 = Label.CASE_RECORDTYPE_RECEIPTS;
	//72hour
	static final String CASE_RECORDTYPE8 = Label.CASE_RECORDTYPE_INTERNAL_CANCELLATION;
	//24hour
	static final String CASE_RECORDTYPE3 = Label.CASE_RECORDTYPE_SENDING_ACCOUNT_STATEMENTS;
	//24hour
	static final String CASE_RECORDTYPE4 = Label.CASE_RECORDTYPE_BAD_SERVICE;
	//24 hour
	static final String CASE_RECORDTYPE10 = Label.CASE_RECORDTYPE_SENDING_TAX_CERTIFICATE;
	//5 business days
	static final String CASE_RECORDTYPE6 = Label.CASE_RECORDTYPE_LETTERS_OF_RATIFICATION;
	//Up to 30 business days
	static final String CASE_RECORDTYPE7 = Label.CASE_RECORDTYPE_CONSULTATION_ERRORS_IN_ACCOUNT_STATEMENT;
	//Up to 30 business days
	static final String CASE_RECORDTYPE9 = Label.CASE_RECORDTYPE_CONSULTATION_ERRORS_IN_TAX_CERTIFICATE;
	//15 business days
	static final String CASE_RECORDTYPE1 = Label.CASE_RECORDTYPE_CHANGE_OF_ADVISOR_AND_OR_FINANCIAL_CENTER;

	// Email Template Name used in handleDifferentTypeOfCaseWhenHitTimeLimit 'Notificacion_de_caso'
	static final String strEmailTemplateName1 = Label.Case_Notification_Template;
	// Email Template used when Case.Conrtact has no related Email List
	static final String strEmailTemplateName3 = Label.Case_Notification_Template2;
	// a week contains 7 days.
	static final Integer DAYS_A_WEEK = 7;
	// Email Template Name used in handleCaseStatusNotChangeTooLong 'Support_Notificaci_n_al_cliente_Proceso_de_Resoluci_n2'
	static final String strEmailTemplateName2 = Label.Support_Client_Notification_Template;

	//Error Log : Category
	private static final String CATEGORY_NOTIFICATION = 'Notification Of Case';
	private static final String CATEGORY_EMAIL = 'SENDEMAIL of CASE';
	private static final String CALCULATE_DAYS_OF_CASE_HAVE_BEEN_OPEN = 'DAYS OF CASE HAVE BEEN OPEN';
	//Error Log : Error File Name
	private static final String ERROR_FILE = 'CaseController.cls';

	/**
	 * @description update Case.Tiempo_de_caso_abierto__c, calculate numebr of days a case has been open
	 */
	public static void calculateDaysOfCaseHaveBeenOpen() {
		// List<Holiday> all holiday set in salesforce
		List<Holiday> lstHolidays = [SELECT Id, ActivityDate FROM Holiday WHERE ActivityDate = THIS_YEAR OR ActivityDate = LAST_YEAR];
		// Set<Date> Holiday.ActivityDate
		Set<Date> setHolidayDate = new Set<Date>();
		for (Holiday objHoliday : lstHolidays) {
			setHolidayDate.add(objHoliday.ActivityDate);
		}
		// all Cases : Tiempo_de_caso_abierto__c(number of days has been open)
		List<Case> lstCases = [
			SELECT Id, Status, ClosedDate, CreatedDate, Tiempo_de_caso_abierto__c
			FROM Case
			WHERE Id != NULL
			LIMIT 10000
		];
		for (Case objCase : lstCases) {
			Date dtCreate = objCase.CreatedDate.date();
			Date dtToday = Datetime.now().date();
			Integer intDays = 0;
			Integer intDaysToMinus = 0;
			// End Date used in For Loop; when open, this equals today; when closed, this equals case.closeddate
			Date dtEndDate;
			// Closed Case
			if (objCase.Status == CASE_STATUS_CLOSED) {
				Date dtClosed = objCase.ClosedDate.date();
				dtEndDate = dtClosed;
			} else {
				// Open Case
				dtEndDate = dtToday;
			}
			intDays += dtCreate.daysBetween(dtEndDate) + 1;
			for (Date dtTmpDate = dtCreate; dtTmpDate <= dtEndDate; dtTmpDate = dtTmpDate.addDays(1)) {
				Datetime dtimeTmp = (DateTime) dtTmpDate;
				String strDayOfWeek = dtimeTmp.formatGmt(strFormat);
				//count number of weekends
				if (strDayOfWeek == strSunday || strDayOfWeek == strSaturday) {
					intDaysToMinus++;
					continue;
				}
				//count holidays
				if (setHolidayDate.contains(dtTmpDate)) {
					intDaysToMinus++;
				}
			}

			objCase.Tiempo_de_caso_abierto__c = intDays - intDaysToMinus;
		}
		// update lstCases;
		List<String> lstErrMsg = new List<String>();
		Database.SaveResult[] lstUpResult = Database.update(lstCases, false);
		// for (Database.SaveResult upResult : lstUpResult) {
		for (Integer i = 0; i < lstCases.size(); i++) {
			Database.SaveResult upResult = lstUpResult[i];
			Case origRecord = lstCases[i];
			if (!upResult.isSuccess()) {
				for (Database.Error err : upResult.getErrors()) {
					lstErrMsg.add(origRecord.Id + ' : ' + err.getMessage());
				}
			}
		}
		if (lstErrMsg.size() > 0) {
			LogCommon.writeLogs(CALCULATE_DAYS_OF_CASE_HAVE_BEEN_OPEN, ERROR_FILE, lstErrMsg, null);
		}
	}

	/**
	 * @description
	 *     handle different RecordType of Case when hit time limit
	 *     will be scheduled with frequency: daily
	 *     send Notification to User corresponding to Case.Account.Owner
	 *     send Email to User corresponding to Case.Contact.Owner
	 */
	public static void handleDifferentTypeOfCaseWhenHitTimeLimit() {
		try {
			//RecordType_Time
			Integer RecordType_Time_Hours_72 = Integer.valueOf(Label.RecordType_Time_Hours_72);
			Integer RecordType_Time_Hours_24 = Integer.valueOf(Label.RecordType_Time_Hours_24);
			Integer RecordType_Time_BDays_5 = Integer.valueOf(Label.RecordType_Time_BDays_5);
			Integer RecordType_Time_BDays_15 = Integer.valueOf(Label.RecordType_Time_BDays_15);
			Integer RecordType_Time_BDays_30 = Integer.valueOf(Label.RecordType_Time_BDays_30);
			//Email Template
			EmailTemplate et = [SELECT Id, Body, Subject FROM EmailTemplate WHERE DeveloperName = :strEmailTemplateName1];
			// org id
			String strDisplayName = System.Label.EmailSenderForCase; //'ActinverUNE';
			List<OrgWideEmailAddress> listAddresses = [
				SELECT Id, DisplayName, Address
				FROM OrgWideEmailAddress
				WHERE DisplayName = :strDisplayName
			];
			Id orgWideEmailId = null;
			if (listAddresses.size() > 0) {
				orgWideEmailId = listAddresses[0].Id;
			}
			// List<Holiday> all holiday set in salesforce
			List<Holiday> lstHolidays = [SELECT Id, ActivityDate FROM Holiday WHERE ActivityDate = THIS_YEAR OR ActivityDate = LAST_YEAR];
			// Set<Date> Holiday.ActivityDate
			Set<Date> setHolidayDate = new Set<Date>();
			for (Holiday objHoliday : lstHolidays) {
				// convert to local time zone
				setHolidayDate.add(objHoliday.ActivityDate);
			}

			// Email need to send List
			List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
			// All Open Case
			List<Case> lstCase = [
				SELECT Id, RecordTypeId, CreatedDate, OwnerId, CaseNumber, Motivo__c, Contact.Owner.Email, Contact.Id, Owner.Email
				FROM CASE
				WHERE Status != :CASE_STATUS_CLOSED
			];

			// All Case Record Type
			List<RecordType> lstRecordType = [SELECT Id, Name, SobjectType FROM RecordType WHERE SobjectType = 'CASE'];

			// Map RecordType Name to Id

			Map<String, Id> mapRecordNameToId = new Map<String, Id>();
			for (RecordType objRecordType : lstRecordType) {
				mapRecordNameToId.put(objRecordType.Name, objRecordType.Id);
			}
			//zjiale modify
			Set<Id> lst5BDRecordTypeId = new Set<Id>();
			Set<Id> lst15BDRecordTypeId = new Set<Id>();
			Set<Id> lst24HoursRecordTypeId = new Set<Id>();
			Set<Id> lst72HoursRecordTypeId = new Set<Id>();
			Set<Id> lst30BDRecordTypeId = new Set<Id>();
			lst5BDRecordTypeId.add(mapRecordNameToId.get(CASE_RECORDTYPE6));
			lst15BDRecordTypeId.add(mapRecordNameToId.get(CASE_RECORDTYPE1));
			lst24HoursRecordTypeId.add(mapRecordNameToId.get(CASE_RECORDTYPE3));
			lst24HoursRecordTypeId.add(mapRecordNameToId.get(CASE_RECORDTYPE4));
			lst24HoursRecordTypeId.add(mapRecordNameToId.get(CASE_RECORDTYPE10));
			lst72HoursRecordTypeId.add(mapRecordNameToId.get(CASE_RECORDTYPE2));
			lst72HoursRecordTypeId.add(mapRecordNameToId.get(CASE_RECORDTYPE8));
			lst72HoursRecordTypeId.add(mapRecordNameToId.get(CASE_RECORDTYPE5));
			lst30BDRecordTypeId.add(mapRecordNameToId.get(CASE_RECORDTYPE7));
			lst30BDRecordTypeId.add(mapRecordNameToId.get(CASE_RECORDTYPE9));
			// Time Now Gmt time zone
			Datetime dtimeNow = Datetime.now();
			// this is to test if emial will be sent on weekends
			// Datetime dtimeNow = Datetime.newInstanceGmt(2021, 11, 7, 0, 0, 0);
			// this is to test if emial will be sent on holidays
			// Datetime dtimeNow = Datetime.newInstanceGmt(2021, 11, 15, 0, 0, 0);
			// Time Now Local time zone stored in Gmt form, if use, use dirctly
			Datetime dtimeNowLocal = ActinverCommon.getLocalDateTime(dtimeNow);
			// convert to Local Date
			Date dtNow = dtimeNow.date();
			// get what day it is today
			String strTodayOfWeek = dtimeNow.format(strFormat);

			String strNotificationId = null;
			// Get the Id for our custom notification type
			CustomNotificationType notificationType = [
				SELECT Id, DeveloperName
				FROM CustomNotificationType
				WHERE DeveloperName = :Label.CASE_NOTIFICATION
			];
			if (notificationType != null) {
				strNotificationId = notificationType.id;
			}

			for (Case objCase : lstCase) {
				// recipent Email address
				String[] toAddresses = new List<String>{ objCase.Owner.Email };
				// Recipients Ids Set
				Set<String> setStrRecipientsIds = new Set<String>();
				setStrRecipientsIds.add(objCase.OwnerId);
				//Record Id
				String strTargetId = objCase.Id;
				// System.debug(toAddresses);
				// Days of Weekends & Holidays
				Integer intDaysToMinus = 0;
				// Case Created DateTime convert to local time zone , if use ,use directly
				Datetime dtimeCreated = ActinverCommon.getLocalDateTime(objCase.CreatedDate);
				// Hours Between Now and Created DateTime in Local Time zone
				Double dbHoursBetween = Double.valueOf((dtimeNowLocal.getTime() - dtimeCreated.getTime()) / 1000 / 60 / 60);
				// System.debug(dtimeNowLocal + '-------' + dtimeCreated);
				// Case Create Date  local time zone
				Date dtCreated = dtimeCreated.dateGmt();
				// End Date : Date Now , Used in For Loop  local time zone
				Date dtEndDate = dtNow;
				for (Date dtTmpDate = dtCreated; dtTmpDate <= dtEndDate; dtTmpDate = dtTmpDate.addDays(1)) {
					Datetime dtimeTmp = (DateTime) dtTmpDate;
					// day of week
					String strDayOfWeek = dtimeTmp.formatGmt(strFormat);

					//count number of weekends
					if (strDayOfWeek == strSunday || strDayOfWeek == strSaturday) {
						intDaysToMinus++;
						continue;
					}
					//count holidays
					if (setHolidayDate.contains(dtTmpDate)) {
						intDaysToMinus++;
					}
				}
				Integer intDaysBetween = dtCreated.daysBetween(dtEndDate) + 1;
				intDaysBetween = intDaysBetween - intDaysToMinus;
				// remove weekends and holidays
				// scheduled  8:30 every day for 8.5, 24 hour a day for 24
				if (intDaysToMinus != 0) {
					dbHoursBetween = dbHoursBetween - 24 * (intDaysToMinus - 1) - 8.5;
				}
				//weekends and hoildays don't send email
				if (strTodayOfWeek == strSunday || strTodayOfWeek == strSaturday || setHolidayDate.contains(dtNow)) {
					// System.debug('dtNow:' + dtNow + '' + 'not send email');
					continue;
				} else if (objCase.RecordTypeId != null) {
					// System.debug('toAddresses is ' + toAddresses);
					// 15 business days
					if (lst15BDRecordTypeId.contains(objCase.RecordTypeId)) {
						if (intDaysBetween >= RecordType_Time_BDays_15) {
							sendNotificationWhenHitTimeLimit(setStrRecipientsIds, strTargetId, objCase, strNotificationId);
							Messaging.SingleEmailMessage mail = getEmailWhenHitTimeLimit(et, toAddresses, objCase, orgWideEmailId);
							allmsg.add(mail);
						}
					} else if (lst5BDRecordTypeId.contains(objCase.RecordTypeId)) {
						//5 business days
						if (intDaysBetween >= RecordType_Time_BDays_5) {
							sendNotificationWhenHitTimeLimit(setStrRecipientsIds, strTargetId, objCase, strNotificationId);
							Messaging.SingleEmailMessage mail = getEmailWhenHitTimeLimit(et, toAddresses, objCase, orgWideEmailId);
							allmsg.add(mail);
						}
					} else if (lst30BDRecordTypeId.contains(objCase.RecordTypeId)) {
						//Up to 30 business days
						if (intDaysBetween >= RecordType_Time_BDays_30) {
							sendNotificationWhenHitTimeLimit(setStrRecipientsIds, strTargetId, objCase, strNotificationId);
							Messaging.SingleEmailMessage mail = getEmailWhenHitTimeLimit(et, toAddresses, objCase, orgWideEmailId);
							allmsg.add(mail);
						}
					} else if (lst72HoursRecordTypeId.contains(objCase.RecordTypeId)) {
						//72 hrs
						if (dbHoursBetween >= RecordType_Time_Hours_72) {
							sendNotificationWhenHitTimeLimit(setStrRecipientsIds, strTargetId, objCase, strNotificationId);
							Messaging.SingleEmailMessage mail = getEmailWhenHitTimeLimit(et, toAddresses, objCase, orgWideEmailId);
							allmsg.add(mail);
						}
					} else if (lst24HoursRecordTypeId.contains(objCase.RecordTypeId)) {
						//24 hrs
						if (dbHoursBetween >= RecordType_Time_Hours_24) {
							sendNotificationWhenHitTimeLimit(setStrRecipientsIds, strTargetId, objCase, strNotificationId);
							Messaging.SingleEmailMessage mail = getEmailWhenHitTimeLimit(et, toAddresses, objCase, orgWideEmailId);
							allmsg.add(mail);
						}
					}
				}
			}
			Messaging.SendEmailResult[] results = Messaging.sendEmail(allmsg, false);
			// System.debug('results : ' + results);
		} catch (Exception e) {
			String strErrorMessage = e.getMessage();
			Integer intErrorLine = e.getLineNumber();
			LogCommon.writeLog(CATEGORY_NOTIFICATION, ERROR_FILE, strErrorMessage, intErrorLine);
		}
	}
	/**
	 * @description send Notification to User corresponding to Case.Account.Owner
	 */
	public static void sendNotificationWhenHitTimeLimit(
		Set<String> setStrRecipientsIds,
		String strTargetId,
		Case objCase,
		String strNotificationTypeId
	) {
		// Create a new custom notification
		Messaging.CustomNotification notification = new Messaging.CustomNotification();
		// Set the contents for the notification
		notification.setTitle(Label.CASE_NOTIFICATION_TITLE);
		notification.setBody(
			Label.CASE_NOTIFICATION_BODY1 +
				' ' +
				objCase.CaseNumber +
				Label.CASE_NOTIFICATION_BODY2 +
				' ' +
				objCase.Motivo__c +
				Label.CASE_NOTIFICATION_BODY3
		);
		// Set the notification type and target
		notification.setNotificationTypeId(strNotificationTypeId);
		notification.setTargetId(strTargetId);
		// Actually send the notification
		try {
			notification.send(setStrRecipientsIds);
		} catch (Exception e) {
			// System.debug('Problem sending notification: ' + e.getMessage());
		}
	}
	/**
	 * @description get Email to User corresponding to Case.Contact.Owner
	 */
	public static Messaging.SingleEmailMessage getEmailWhenHitTimeLimit(
		EmailTemplate et,
		String[] toAddresses,
		Case objCase,
		Id orgWideEmailId
	) {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String mailBody = et.Body;
		mailBody = mailBody.replace('{!Case.CaseNumber}', objCase.CaseNumber);
		mailBody = mailBody.replace('{!Case.Motivo__c}', objCase.Motivo__c);
		mail.setTemplateId(et.Id);
		mail.setToAddresses(toAddresses);
		mail.setSubject(et.Subject);
		mail.setPlainTextBody(mailBody);
		mail.setSaveAsActivity(false);
		mail.setUseSignature(false);
		mail.setCharset('UTF-8');
		mail.setOrgWideEmailAddressId(orgWideEmailId);
		return mail;
	}

	/**
	 * only active for Case.Status = 'Proceso de Resolución'
	 * send Email Weekly unitl Case.Status changes
	 * don`t count weekends and holidays
	 */
	public static void handleCaseStatusNotChangeTooLong() {
		try {
			// Specific Email Address For US#11 & US#36
			String strEmailAddress = '';
			// List<Case> all Case with Status_2_Time__c not null && Status = 'Proceso de resolución'
			List<Case> lstCases = [
				SELECT
					Id,
					CaseNumber,
					Status_2_Time__c,
					Contact.Name,
					Contact.Email,
					Contrato__c,
					SAP_Contract_Number__c,
					Motivo__c,
					Account.Name,
					Owner.Email
				FROM Case
				WHERE Status_2_Time__c != NULL AND Status = :CASE_STATUS_RESOLUTION_PROCESS
				// AND Id = '5001k00000FseriAAB'
			];
			// set for SOQL
			Set<Id> setContractId = new Set<Id>();
			for (Case objCase : lstCases) {
				setContractId.add(objCase.Contrato__c);
			}
			// get all related Correo_de_Contrato__c
			List<Correo_de_Contrato__c> lstCorreoDeContrato = [
				SELECT Id, Principal__c, MainFlag__c, Contract_email__c, NUM_CONTRATO__c
				FROM Correo_de_Contrato__c
				WHERE NUM_CONTRATO__c IN :setContractId
				ORDER BY LastModifiedDate ASC
				LIMIT 10000
			];
			// map Contract Id -> Email List
			Map<Id, List<Correo_de_Contrato__c>> mapContractIdToListCorreo = new Map<Id, List<Correo_de_Contrato__c>>();
			for (Correo_de_Contrato__c objCorreo : lstCorreoDeContrato) {
				if (mapContractIdToListCorreo.get(objCorreo.NUM_CONTRATO__c) == null) {
					List<Correo_de_Contrato__c> lstCorreo = new List<Correo_de_Contrato__c>();
					lstCorreo.add(objCorreo);
					mapContractIdToListCorreo.put(objCorreo.NUM_CONTRATO__c, lstCorreo);
				} else {
					mapContractIdToListCorreo.get(objCorreo.NUM_CONTRATO__c).add(objCorreo);
				}
			}
			//Email Template
			EmailTemplate et = [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = :strEmailTemplateName2];
			// Email Template when Case.Contract has no related Email
			EmailTemplate et2 = [SELECT Id, Body, Subject FROM EmailTemplate WHERE DeveloperName = :strEmailTemplateName3];
			// org id
			String strDisplayName = System.Label.EmailSenderForCase; //'ActinverAdmin';
			List<OrgWideEmailAddress> listAddresses = [
				SELECT Id, DisplayName, Address
				FROM OrgWideEmailAddress
				WHERE DisplayName = :strDisplayName
			];
			Id orgWideEmailId = null;
			if (listAddresses.size() > 0) {
				orgWideEmailId = listAddresses[0].Id;
			}
			if (lstCases != null && lstCases.size() > 0 && et != null && orgWideEmailId != null) {
				// List<Holiday> holidays in this year and next year set in salesforce
				List<Holiday> lstHolidays = [
					SELECT Id, ActivityDate
					FROM Holiday
					WHERE ActivityDate = THIS_YEAR OR ActivityDate = LAST_YEAR
				];
				// Set<Date> Holiday.ActivityDate
				Set<Date> setHolidayDate = new Set<Date>();
				for (Holiday objHoliday : lstHolidays) {
					setHolidayDate.add(objHoliday.ActivityDate);
				}
				// get Custom Label, Specific Email For Case
				if (Label.Specific_Email_For_Case != null) {
					strEmailAddress = Label.Specific_Email_For_Case;
				}
				// send mail
				List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
				for (Case objCase : lstCases) {
					String[] toAddresses;
					List<Correo_de_Contrato__c> lstCorreoTmp = new List<Correo_de_Contrato__c>();
					if (mapContractIdToListCorreo.size() != 0) {
						lstCorreoTmp = mapContractIdToListCorreo.get(objCase.Contrato__c);
					}

					// recipent Email address
					// String[] toAddresses = new String[] {objCase.Contact.Email, strEmailAddress};
					Date dtStatus = objCase.Status_2_Time__c.date();

					Date dtToday = Datetime.now().date();
					Integer intDays = 0;
					Integer intDaysToMinus = 0;
					Integer intDaysBetween = 0;
					String strWeekDayNow = Datetime.now().format(strFormat);
					// End Date used in For Loop; when open, this equals today; when closed, this equals case.closeddate
					Date dtEndDate = dtToday;
					intDays += dtStatus.daysBetween(dtEndDate) + 1;
					for (Date dtTmpDate = dtStatus; dtTmpDate <= dtEndDate; dtTmpDate = dtTmpDate.addDays(1)) {
						Datetime dtimeTmp = (DateTime) dtTmpDate;
						String strDayOfWeek = dtimeTmp.formatGmt(strFormat);
						//count number of weekends
						if (strDayOfWeek == strSunday || strDayOfWeek == strSaturday) {
							intDaysToMinus++;
							continue;
						}
						//count holidays
						if (setHolidayDate.contains(dtTmpDate)) {
							intDaysToMinus++;
						}
					}
					// Days of case has been status: (Proceso de resolución)
					intDaysBetween = intDays - intDaysToMinus;
					// System.debug('casenumber : ' + objCase.CaseNumber + '  intdaysbetween : ' + intDaysBetween);
					//send every 7 days and shouldn`t send on holidays and weekends, because weekends won't be counted in
					// if (!setHolidayDate.contains(dtToday) && strWeekDayNow !=strSunday && strWeekDayNow != strSaturday) {
					if (!setHolidayDate.contains(dtToday)) {
						if (intDaysBetween != 0 && Math.mod(intDaysBetween, DAYS_A_WEEK) == 0) {
							Messaging.SingleEmailMessage mail;
							// there's no record of email of contract
							if (lstCorreoTmp.size() == 0) {
								toAddresses = new List<String>{ objCase.Owner.Email, strEmailAddress };
								mail = getEmailDueToCaseStatusWhenNoRelatedEmail(et2, toAddresses, objCase, orgWideEmailId);
								// System.debug('null email of contract');
							} else {
								for (Correo_de_Contrato__c objCorreo : lstCorreoTmp) {
									// has main email
									if (objCorreo.Principal__c == true && objCorreo.MainFlag__c != '' && objCorreo.MainFlag__c != null) {
										toAddresses = new List<String>{ objCorreo.Contract_email__c, strEmailAddress };
										break;
									}
									// don't have main email, use last modified one
									toAddresses = new List<String>{ objCorreo.Contract_email__c, strEmailAddress };
								}
								mail = getEmailDueToCaseStatus(et, toAddresses, objCase, orgWideEmailId);
							}
							// System.debug('casenumber : ' + objCase.CaseNumber + '  intdaysbetween : ' + intDaysBetween + '  toaddress : ' + toAddresses);
							allmsg.add(mail);
						}
					}
				}
				Messaging.SendEmailResult[] results = Messaging.sendEmail(allmsg, false);
				// for (Messaging.SendEmailResult res :results) {
				//     System.debug(res);
				// }
			}
		} catch (Exception e) {
			// System.debug(e.getMessage());
			// System.debug(e.getLineNumber());
			List<String> lstErrorMSG = new List<String>();
			List<Integer> lstErrorLines = new List<Integer>();
			String strErrorMessage = e.getMessage();
			Integer intErrorLine = e.getLineNumber();
			lstErrorMSG.add(strErrorMessage);
			lstErrorLines.add(intErrorLine);
			LogCommon.writeLogs(CATEGORY_EMAIL, ERROR_FILE, lstErrorMSG, lstErrorLines);
		}
	}
	/**
	 * used in handleCaseStatusNotChangeTooLong
	 * use Email Templaate :
	 * Send Email To Case.Owner & Case.Contact
	 */
	public static Messaging.SingleEmailMessage getEmailDueToCaseStatus(
		EmailTemplate et,
		String[] toAddresses,
		Case objCase,
		Id orgWideEmailId
	) {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		// get email Htmlbody
		String mailBody = et.HtmlValue;
		mailBody = mailBody.replace('{!Case.CaseNumber}', objCase.CaseNumber);
		mailBody = mailBody.replace('{!Contact.Name}', objCase.Contact.Name);
		// replace picture 1 with url in label
		if (Label.Logo_UNE_email != null) {
			mailBody = mailBody.replace('{!Label.Logo_UNE_email}', Label.Logo_UNE_email);
		}
		// replace picture 2 with url in label
		if (Label.Ecolo_mail != null) {
			mailBody = mailBody.replace('{!Label.Ecolo_mail}', Label.Ecolo_mail);
		}
		// set template
		mail.setTemplateId(et.Id);
		// set recipient address
		mail.setToAddresses(toAddresses);
		// set email Subject
		mail.setSubject(et.Subject);
		// set email HtmlBNody
		mail.setHtmlBody(mailBody);
		mail.setSaveAsActivity(false);
		mail.setUseSignature(false);
		mail.setCharset('UTF-8');
		// set sender address
		mail.setOrgWideEmailAddressId(orgWideEmailId);
		return mail;
	}

	/**
	 * used in handleCaseStatusNotChangeTooLong
	 * use Email Templaate  when  Case.Contract has no related email List
	 * Send Email To Case.Contact & Specific Email Address in Label
	 */
	public static Messaging.SingleEmailMessage getEmailDueToCaseStatusWhenNoRelatedEmail(
		EmailTemplate et,
		String[] toAddresses,
		Case objCase,
		Id orgWideEmailId
	) {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		// get email Htmlbody
		String mailBody = et.Body;
		if (objCase.SAP_Contract_Number__c != null) {
			mailBody = mailBody.replace('{!Case.SAP_Contract_Number__c}', objCase.SAP_Contract_Number__c);
		}
		if (objCase.Account.Name != null) {
			mailBody = mailBody.replace('{!Case.Account}', objCase.Account.Name);
		}
		if (objCase.CaseNumber != null) {
			mailBody = mailBody.replace('{!Case.CaseNumber}', objCase.CaseNumber);
		}
		if (objCase.Motivo__c != null) {
			mailBody = mailBody.replace('{!Case.Motivo__c}', objCase.Motivo__c);
		}

		// set template
		mail.setTemplateId(et.Id);
		// set recipient address
		mail.setToAddresses(toAddresses);
		// set email Subject
		mail.setSubject(et.Subject);
		mail.setPlainTextBody(mailBody);
		// mail.setHtmlBody(mailBody);
		mail.setSaveAsActivity(false);
		mail.setUseSignature(false);
		mail.setCharset('UTF-8');
		// set sender address
		mail.setOrgWideEmailAddressId(orgWideEmailId);
		return mail;
	}
}