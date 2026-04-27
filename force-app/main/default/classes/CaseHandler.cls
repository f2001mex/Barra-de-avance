/**
 * @author jiale Zhang
 * @date 11/21/2021
 * @description
 *      Used in CaseTrigger.trigger
 *      this class only used in CaseTrigger.
 * story16
 * story40
 * story41
 * issue 25
 *
 */
public without sharing class CaseHandler implements Triggers.Handler {
	List<Case> lstNewCase = (List<Case>) Trigger.new;

	List<Case> lstOldCase = (List<Case>) Trigger.old;

	Map<Id, Case> mapOldCase = (Map<Id, Case>) Trigger.oldMap;

	private static final String strEjecutivoUser = 'Ejecutivo UNE';

	private static final String strSuperviserUser = 'Supervisor UNE';

	private static final String strSysAdmin = 'System Administrator';

	private static final String strFieldOfStatus = 'Status';

	private static final String CASE_CANCELLATION = 'Si_cancela_folio';

	private static final String CASE_STATUS_CLOSED = 'Cierre';

	private static final String ERR_MSG_NOT_NEARBY = Label.ERR_MSG_NOT_NEARBY;

	private static final String ERR_MSG_CAN_NOT_REOPEN = Label.ERR_MSG_CAN_NOT_REOPEN;

	private static final String ERR_MSG_CAN_NOT_CHANGE_ASESOR = Label.ERR_MSG_CAN_NOT_CHANGE_ASESOR;

	private static final Id CASE_CAT_RT = [SELECT Id, DeveloperName FROM RecordType 
	WHERE SObjectType = 'Case' and DeveloperName = 'CAT' LIMIT 1].Id; 

	public void handle() {
		Id userProfileId = UserInfo.getProfileId();
		
		//String userType = UserInfo.getUserType();

		try {
			//String strProfileName = [SELECT name FROM profile WHERE Id = :userProfileId].Name;
			List<Profile> profiles = [SELECT name FROM Profile WHERE Id = :userProfileId];

			if (Trigger.isBefore) {
				if (Trigger.isUpdate) {
					if(profiles.size() > 0){
						String strProfileName = profiles[0].Name;
						for (Case newCase : lstNewCase) {
							Case oldCase = mapOldCase.get(newCase.Id);
							//issue 25 Asesor can't be changed
							if (strProfileName != strSysAdmin) {
								if (newCase.Asesor__c != oldCase.Asesor__c) {
									newCase.addError(ERR_MSG_CAN_NOT_CHANGE_ASESOR);
									continue;
								}
							}

							// Story 41 ：The supervisors are the only ones who can reopen the cases, the executives, once the case is closed, they will not be able to open it
							if (newCase.Status != CASE_STATUS_CLOSED && oldCase.Status == CASE_STATUS_CLOSED) {
								if (strProfileName != strSuperviserUser && strProfileName != strSysAdmin) {
									newCase.addError(ERR_MSG_CAN_NOT_REOPEN);
									continue;
								} else {
									newCase.Cancelacion_de_caso__c = null;
								}
							}

							// Story 40 ：when the picklist value of "Cancelación de Caso", is "Si, se cancela el folio", then the case should go directly to the "cierre" stage.
							if (newCase.Cancelacion_de_caso__c == CASE_CANCELLATION) {
								newCase.Status = CASE_STATUS_CLOSED;
							} /*else {
								// Story 16 ：Creation of a validation rule in the fields of each stage of the path
								if (strProfileName != strSuperviserUser && strProfileName != strSysAdmin) {
									Boolean isResult = ActinverCommon.isNearBy(newCase, strFieldOfStatus, oldCase.Status, newCase.Status);
									if (!isResult) {
										newCase.addError(ERR_MSG_NOT_NEARBY);
										continue;
									}
								}
							}*/
						}
					}
				} else if (Trigger.isInsert) {
					Set<String> setContractId = new Set<String>();
					Set<String> accountExtIds = new Set<String>();
					Map<String, Id> accountIdsMap = new Map<String, Id>();

                    for (Case objCase : lstNewCase) {
						if(objCase.Origin == 'Chat'){
							if(objCase.Chat_ClientExternalId__c != null){
								accountExtIds.add(objCase.Chat_ClientExternalId__c);
                                //Account accountReference = new Account(Client_ID__c = objCase.Chat_ClientExternalId__c);
                                //objCase.Account = new Account(Client_ID__c = String.valueOf(objCase.Chat_ClientExternalId__c));
                            }
                             
                            objCase.Type= 'Transferencia interna CAT';
							objCase.Submotivo__c = 'Consulta';
							objCase.RecordTypeId = CASE_CAT_RT;
						}

						if (!String.isEmpty(objCase.Contrato__c)) {
							setContractId.add(objCase.Contrato__c);
						}
                        //System.debug(objCase);
					}
					List<Contract> lstContract = new List<Contract>();
					if (setContractId.size() > 0) {
						lstContract = [SELECT Id, AccountId, Account.OwnerId FROM Contract WHERE Id IN :setContractId];
						//System.debug('Dio test : ' + lstContract);
					}
					Map<Id, Id> mapAccToAccOwner = new Map<Id, Id>();
					for (Contract ctract : lstContract) {
						mapAccToAccOwner.put(ctract.Id, ctract.Account.OwnerId);
					}

					//Get Accounts from Cases:
					if (accountExtIds.size() > 0) {
						for(Account acc: [SELECT Id, Client_ID__c FROM Account WHERE Client_ID__c IN:accountExtIds]){
							if(!accountIdsMap.containsKey(acc.Client_ID__c)){
								accountIdsMap.put(acc.Client_ID__c, acc.Id);
							}
						}
					}


					//System.debug('zjl test:' + mapAccToAccOwner);
					for (Case newCase : lstNewCase) {
						if(newCase.Origin == 'Chat' && newCase.Chat_ClientExternalId__c != null){
							if(accountIdsMap.containsKey(newCase.Chat_ClientExternalId__c)){
								newCase.AccountId = accountIdsMap.get(newCase.Chat_ClientExternalId__c);
							}
						}

						// Story 40 ：when the picklist value of "Cancelación de Caso", is "Si, se cancela el folio", then the case should go directly to the "cierre" stage.
						if (newCase.Cancelacion_de_caso__c == CASE_CANCELLATION) {
							newCase.Status = CASE_STATUS_CLOSED;
						}
						// issue 25 , the asesor of new Case needs to be inserted with account owner(which origins contract);
						if (!String.isEmpty(mapAccToAccOwner.get(newCase.Contrato__c))) {
							newCase.Asesor__c = mapAccToAccOwner.get(newCase.Contrato__c);
						}
					}
				}
			}
		} catch (Exception ex) {
			 System.debug('Error Msg : ' + ex.getMessage());
			 System.debug('Error Line : ' + ex.getLineNumber());
		}
	}
}