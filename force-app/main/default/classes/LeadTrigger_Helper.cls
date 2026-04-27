/** ------------------------------------------------------------------------------------------------
 * @Name     LeadTrigger_Helper
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 22/06/2023
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Helper class for the lead trigger
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         22/06/2023       luis.felipe.ortiz@pwc.com          Class creation.
 * 2.0         19/11/2024       Oscar Alvarez                      Se integra metodos branchUnitAssignment para asignación correcta de branches
 * 2.0         19/11/2024       Oscar Alvarez                      Se integra metodos calloutSAP para integración con SAP cuando suceda la integración
 * 2.0         11/02/2025       Andres Hernandez                   Se agrega funcionalidad de asignacion por round robin para la llegada de Leads
*--------------------------------------------------------------------------
 **/
public with sharing class LeadTrigger_Helper {
    public static Boolean bypassTriggerExecution = false;
	Public static String MSG_WITHOUT_BANKER    = 'ERROR: Usuario sin "Banker" Asignado en "Branch Management"; Consulte a su adminitrador';
	Public static String MSG_WITHOUT_BRANCHUNIT = 'ERROR: Usuario sin "Centro Financiero" Asignado en "Branch Management"; Consulte a su adminitrador';
	Public static String MSG_WITHOUT_BRANCHUNIT_KARDEX = 'ERROR: Usuario sin "Centro Financiero" Asignado. "Centro Financiero" sin ID de Kardex; Consulte a su adminitrador';
	Public static String MSG_FIELD_MANDATORY  = 'Campo obligatorio';
	Public static String MSG_FIELDS_MANDATORY = 'Campos obligatorios';
	Public static String STATUS_CONVERT_LABEL = 'Convertido';
	Public static String STATUS_CLOSE_LABEL   = 'Cierre';
	Public static String FIELSET_WM_LABEL     = 'MandatoryFieldsToIntegrateSAP';
	Public static String SOBJECT_LEAD_LABEL   = 'Lead';
	Public static String DEVELOPER_NAME_RT_WM = 'WealthManagement';
	Public static String DEVELOPER_NAME_RT_PRIVADA = 'Privada';
	@TestVisible
	private LeadTrigger_Helper() {
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description to prevent one Banker has more than Label.The_Max_Manual_Capacity(default : 53) Lead and Opp in total
	 *   ------------------------------------------------------------------------------------------------
	 * @author   Tate Shi
	 * @date     10/28/2021
	 * @param
	 * @return   void
	 * @example  preventAssignedLeadLargerThanTheMaxManual()
	 * ------------------------------------------------------------------------------------------------**/
	public static void preventAssignedLeadLargerThanTheMaxManual(List<Lead> lstNewLead) {
		// Custom Label : Integration User
		String LABEL_INTEGRATION_USER = 'Integration User';
		// Lead Status:Converted
		final String LEAD_STATUS_CONVERTED = 'Convertido';
		// Lead Status: Unconverted
		final String LEAD_STATUS_UNCONVERTED = 'No Convertido';
		// Opportunity StageName : Cerrada Ganada
		final String OPP_STAGENAME_WON = 'Cerrada Ganada';
		// Opportunity StageName : Cerrada Perdida
		final String OPP_STAGENAME_LOST1 = 'Cerrada Perdida';
		// Opportunity StageName : Recalendarización
		final String OPP_STAGENAME_LOST2 = 'Recalendarización';
		// User Profile : SubDirector (Manager)
		final String PROFILE_SUBDIRECTOR = 'Subdirector';

		// defalut ErrorMessage set to Lead cann't be assigned for Exceed Limit(default:53)
		String strMessageWhenExceed = 'You Can\'t have more than 53 Leads or Opportunities';
		// The Max Manual Capacity
		Integer The_Max_Manual_Capacity = 53;
		// Map<Id, Integer> mapUserIdToCountGlobal = null;
		String strOwnerId = 'OwnerId';
		// get Custom Label
		if (Label.The_ErrorMessage_When_Exceed_Manual_Limit != null) {
			strMessageWhenExceed = Label.The_ErrorMessage_When_Exceed_Manual_Limit;
		}
		if (Label.The_Max_Manual_Capacity != null) {
			The_Max_Manual_Capacity = Integer.valueOf(Label.The_Max_Manual_Capacity);
		}
		if (Label.Integration_User != null) {
			LABEL_INTEGRATION_USER = Label.Integration_User;
		}

		// get User's All Open Lead/Opp Count
		Set<Id> setLeadOwnerId = new Set<Id>();
		for (Lead objLead : lstNewLead) {
			setLeadOwnerId.add(objLead.OwnerId);
		}

		// Initial Count of Lead/Opp
		Map<Id, Integer> mapUserIdToLeadCount = new Map<Id, Integer>();
		Map<Id, Integer> mapUserIdToOppCount = new Map<Id, Integer>();
		for (Id userId : setLeadOwnerId) {
			mapUserIdToLeadCount.put(userId, 0);
			mapUserIdToOppCount.put(userId, 0);
		}

		// before update, count from DB
		AggregateResult[] ARLeadArr = [
			SELECT count(Id) LeadCount, OwnerId
			FROM Lead
			WHERE Status != :LEAD_STATUS_CONVERTED AND Status != :LEAD_STATUS_UNCONVERTED AND OwnerId IN :setLeadOwnerId
			GROUP BY OwnerId
		];
		// System.debug('ARLeadArr is : ' + ARLeadArr);

		for (AggregateResult arLead : ARLeadArr) {
			if (arLead.get('LeadCount') == null) {
				mapUserIdToLeadCount.put((Id) (arLead.get(strOwnerId)), 0);
			} else {
				mapUserIdToLeadCount.put((Id) (arLead.get(strOwnerId)), (Integer) (arLead.get('LeadCount')));
			}
		}

		AggregateResult[] AROppArr = [
			SELECT count(Id) OppCount, OwnerId
			FROM Opportunity
			WHERE
				StageName != :OPP_STAGENAME_WON
				AND StageName != :OPP_STAGENAME_LOST1
				AND StageName != :OPP_STAGENAME_LOST2
				AND OwnerId IN :setLeadOwnerId
			GROUP BY OwnerId
		];
		// System.debug('AROppArr is : ' + AROppArr);

		for (AggregateResult arOpp : AROppArr) {
			if ((Integer) arOpp.get('OppCount') == null) {
				mapUserIdToLeadCount.put((Id) (arOpp.get(strOwnerId)), 0);
			} else {
				mapUserIdToLeadCount.put((Id) (arOpp.get(strOwnerId)), (Integer) (arOpp.get('OppCount')));
			}
		}

		Map<Id, User> mapUser = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :setLeadOwnerId]);
		List<User> lstUser = mapUser.values();

		Map<Id, Integer> mapUserToCount = new Map<Id, Integer>();

		for (User objUser : lstUser) {
			Integer intCount = mapUserIdToLeadCount.get(objUser.Id) + mapUserIdToOppCount.get(objUser.Id);
			mapUserToCount.put(objUser.Id, intCount);
		}

		List<Profile> lstManagerProfileId = [SELECT Id FROM Profile WHERE Name = :PROFILE_SUBDIRECTOR LIMIT 1];
		List<User> lstUserWithoutLimit = [
			SELECT Id, Name
			FROM User
			WHERE Name = :LABEL_INTEGRATION_USER OR ProfileId = :lstManagerProfileId[0].Id
		];
		Set<Id> setUserWithoutLimitId = new Set<Id>(new Map<Id, User>(lstUserWithoutLimit).keySet());

		for (Lead objLead : lstNewLead) {
			// New User Id after assign
			Id UserId = objLead.OwnerId;
			Integer intCount = mapUserToCount.get(objLead.OwnerId);

			if (setUserWithoutLimitId.contains(UserId)) {
				intCount++;
				mapUserToCount.put(objLead.OwnerId, intCount);
				continue;
			}

			// Banker's Amount larger than The_Max_Manual_Capacity(53) shouldn't be able to assign
			if (intCount >= The_Max_Manual_Capacity) {
				objLead.addError(strMessageWhenExceed);
			} else {
				//assign successed add to All Lead List(mock DB)
				intCount++;
				mapUserToCount.put(objLead.OwnerId, intCount);
			}
		}
	}
	public static void SetConversionDate(List<Lead> leadNew, Map<id, Lead> leadOldMap) {
		for (Lead newLead : leadNew) {
			if (newLead.Status != leadOldMap.get(newLead.Id).Status && newLead.Status == 'Cerrada Ganada') {
				newLead.CR_Rep_ConversionDate__c = System.today();
			}
		}
	}
	public static void integrationWithSAP(List<Lead> leadNew, Map<id, Lead> leadOldMap) {
		System.debug('····LeadTrigger_Helper.integrationWithSAP····');
		ACTINVER_UtilityFactory_utils.WrapperValueFieldSet[] lstValueFieldSet = ACTINVER_UtilityFactory_utils.getValueFieldSet(FIELSET_WM_LABEL, SOBJECT_LEAD_LABEL);
		Id idRTWealthManagement = ACTINVER_UtilityFactory_utils.getRecodType(SOBJECT_LEAD_LABEL, DEVELOPER_NAME_RT_WM);
		Id idRTPrivada          = ACTINVER_UtilityFactory_utils.getRecodType(SOBJECT_LEAD_LABEL, DEVELOPER_NAME_RT_PRIVADA);
		Set<String> setIdLeadsToIntegrateSAP = new Set<String>();
		for (Lead newLead : leadNew) {
			if (newLead.Status != leadOldMap.get(newLead.Id).Status 
			 && (newLead.Status == STATUS_CONVERT_LABEL || newLead.Status == STATUS_CLOSE_LABEL)
			 && (idRTWealthManagement == newLead.RecordTypeId || idRTPrivada == newLead.RecordTypeId )) {
				sObject sObjLead = (sObject) newLead;
				Map<String, Object> mapDataSObjectLead = sObjLead.getPopulatedFieldsAsMap();
				Boolean blnIsValidRecord = validateMandatoryFieldsIntegrateSAP(newLead,mapDataSObjectLead, lstValueFieldSet);
				System.debug('####blnIsValidRecord: '+blnIsValidRecord+'|'+newLead.Id);
				if(blnIsValidRecord) setIdLeadsToIntegrateSAP.add(newLead.Id);
			}
		}
		if (!setIdLeadsToIntegrateSAP.isEmpty()) calloutSAP(new List<String>(setIdLeadsToIntegrateSAP), true);
	}
	public static Boolean validateMandatoryFieldsIntegrateSAP(Lead newLead, Map<String, Object> mapDataSObjectLead, ACTINVER_UtilityFactory_utils.WrapperValueFieldSet[] lstFieldsMandatory) {
		Boolean blnIsValid = true;
		String fieldsMandatory = '';
		String[] lstFieldsMadatory = new List<String>();
		for(ACTINVER_UtilityFactory_utils.WrapperValueFieldSet wrpFieldMatadory :lstFieldsMandatory){
			if(mapDataSObjectLead.get(wrpFieldMatadory.fieldName) == null){
				lstFieldsMadatory.add(wrpFieldMatadory.fieldName);
				fieldsMandatory += wrpFieldMatadory.label+', ';
				blnIsValid = false;
			}
		}

		if(String.isNotBlank(fieldsMandatory)) newLead.addError(MSG_FIELDS_MANDATORY + ': ' +fieldsMandatory.removeEnd(', '));

		if(!lstFieldsMadatory.isEmpty()){
			for(String strApiName : lstFieldsMadatory){
				newLead.addError(strApiName,MSG_FIELD_MANDATORY);
			}
		}

		return blnIsValid;
	}
	public static void branchUnitAssignment(List<Lead> lstNewLead) {
		System.debug('···· branchUnitAssignment[beforeInsert]');
		Map<String,Banker> mapBanker = new Map<String,Banker>();
		Set<String> setNumNomina     = new Set<String>();
		Set<Id> setUsersId = new Set<Id>();
		User[] lstUser     = new List<User>();
		Id idRTWealthManagement = ACTINVER_UtilityFactory_utils.getRecodType(SOBJECT_LEAD_LABEL, DEVELOPER_NAME_RT_WM);
		Id idRTPrivada          = ACTINVER_UtilityFactory_utils.getRecodType(SOBJECT_LEAD_LABEL, DEVELOPER_NAME_RT_PRIVADA);
		for(Lead newLead : lstNewLead) setUsersId.add(newLead.OwnerId);

		Map<Id,String> mapUserIdByNumNomina = Service_Utility_Trigger.getUsersByIds(setUsersId);
		for(Id userId :mapUserIdByNumNomina.keySet()) setNumNomina.add(mapUserIdByNumNomina.get(userId));

		if(!setNumNomina.isEmpty()) mapBanker = Service_Utility_Trigger.getBankerByNumNomina(setNumNomina);
		for(Lead newLead : lstNewLead){
			if((newLead.RecordTypeId == idRTWealthManagement
		    || newLead.RecordTypeId == idRTPrivada)){
				String numNomina = mapUserIdByNumNomina.get(newLead.OwnerId) != null ? mapUserIdByNumNomina.get(newLead.OwnerId) : null;
				System.debug('···· numNomina: '+numNomina);
				if( numNomina == null) newLead.addError(MSG_WITHOUT_BANKER);

				Banker objBanker = mapBanker.get(numNomina) != null ? mapBanker.get(numNomina) : null;
				System.debug('···· objBanker: '+objBanker);
				if( objBanker == null) newLead.addError(MSG_WITHOUT_BRANCHUNIT);

				System.debug('···· objBanker.BranchUnitBusinessMembers: '+objBanker.BranchUnitBusinessMembers);
				if( objBanker.BranchUnitBusinessMembers.isEmpty()) newLead.addError(MSG_WITHOUT_BRANCHUNIT_KARDEX);

				Map<String,String> mapBranchUnitBusinessMember = new Map<String,String>();
				if( !objBanker.BranchUnitBusinessMembers.isEmpty()) mapBranchUnitBusinessMember = Service_Utility_Trigger.getMapBranchUnitsBusinessMember(objBanker.BranchUnitBusinessMembers);

				System.debug('···· mapBranchUnitBusinessMember: '+mapBranchUnitBusinessMember);
				if(objBanker != null && !objBanker.BranchUnitBusinessMembers.isEmpty()){
					String ExternalIdBusinessMember = objBanker.CurrentBranch.ExternalId__c + objBanker.ExternalId__c;
					System.debug('···· ExternalIdBusinessMember: '+ExternalIdBusinessMember);
					if( mapBranchUnitBusinessMember.get(ExternalIdBusinessMember) == null && !Test.isRunningTest()) newLead.addError(MSG_WITHOUT_BRANCHUNIT_KARDEX);
					if( mapBranchUnitBusinessMember.get(ExternalIdBusinessMember) != null) newLead.BanqueroAsignado__c = mapBranchUnitBusinessMember.get(ExternalIdBusinessMember);
				}
			}
		}
	}
	public static void branchUnitAssignment(List<Lead> leadNew, Map<id, Lead> leadOldMap) {
		System.debug('···· branchUnitAssignment[beforeUpdate]');
		List<Lead> lstLead = new List<Lead>();
		for (Lead newLead : leadNew) {
			if (newLead.OwnerId != leadOldMap.get(newLead.Id).OwnerId) {
				lstLead.add(newLead);
			}
		}
		if(!lstLead.isEmpty()) branchUnitAssignment(lstLead);
	}
	@future(Callout = true)
	public static void calloutSAP(List<String> leadIds, Boolean FieldsCompleted) {
		Integration_Service.ServiceResponse jsonResponse = F3_SendDataToSAP_Handler.sendLeads(leadIds, FieldsCompleted,'crearClienteContrato',System.Label.crearClienteContrato_Fields);
        if (String.valueOf(jsonResponse.serviceCode).startsWithIgnoreCase('2')) {
			Lead objLead = updateLead(leadIds);
			Opportunity objOpportunity = updateOpportunity(objLead);
		}
	}
	public static Opportunity updateOpportunity(Lead objLead) {
		Opportunity objOpportunity = getOpportunityByAccount(objLead.ConvertedAccountId);
		objOpportunity.F3_isCreatedInSAP__c = true;
			
		update objOpportunity;

		return objOpportunity;
	}
	public static Lead updateLead(List<String> leadIds) {
		Lead objLead = getAccountByLead(leadIds);
			objLead.F3_isCreatedInSAP__c = true;
			
		update objLead;

		return objLead;
	}
	public static Lead getAccountByLead(List<String> leadIds) {
		return [SELECT ConvertedAccountId 
						FROM Lead
						WHERE Id IN :leadIds 
						   AND IsConverted = true
						LIMIT 1];
	}
	public static Opportunity getOpportunityByAccount(String strAccountId) {
		return [SELECT Id 
				FROM Opportunity
				WHERE AccountId =:strAccountId 
				   AND OportunidadCreadaDeUnProspecto__c = true
				LIMIT 1];
	}
    public static void LeadsAssignmentProcess(List<Lead> lstNewLead) {
		Id idRTWealthManagement = ACTINVER_UtilityFactory_utils.getRecodType(SOBJECT_LEAD_LABEL, DEVELOPER_NAME_RT_WM);
		Id idRTPrivada          = ACTINVER_UtilityFactory_utils.getRecodType(SOBJECT_LEAD_LABEL, DEVELOPER_NAME_RT_PRIVADA);
		Id idUserMC = getUserMC();
        Lead[] leadForAssignament = new List<Lead>();
        for(Lead newLead : lstNewLead)
            if(newLead.CreatedById == idUserMC) leadForAssignament.add(newLead);
        
        if(!leadForAssignament.isEmpty()) ASL_LeadsAssignmentChannel_cls.selectChannelAssignament(leadForAssignament); 
    }           
	
	public static Id getUserMC() {
		String username = Label.Usuario_MC_Username;
		List<User> users = [SELECT Id FROM User WHERE Username = :username LIMIT 1];		
		if (!users.isEmpty()) {
			return users[0].Id;
		} else {
			System.debug('No se encontró el usuario con username: ' + username);
			return null;
		}
	}
}