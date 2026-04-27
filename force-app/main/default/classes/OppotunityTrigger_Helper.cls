public with sharing class OppotunityTrigger_Helper {
	Public static String MSG_WITHOUT_BANKER     = 'ERROR: Usuario sin "Banker" Asignado en "Branch Management"; Consulte a su adminitrador';
	Public static String MSG_WITHOUT_BRANCHUNIT = 'ERROR: Usuario sin "Centro Financiero" Asignado en "Branch Management"; Consulte a su adminitrador';
	Public static String MSG_WITHOUT_BRANCHUNIT_KARDEX = 'ERROR: Usuario sin "Centro Financiero" Asignado. "Centro Financiero" sin ID de Kardex; Consulte a su adminitrador';
	Public static String MSG_FIELD_MANDATORY    = 'Campo obligatorio';
	Public static String MSG_FIELDS_MANDATORY   = 'Campos obligatorios';
	Public static String STATUS_SEND_SAP_LABEL  = 'Propuesta de inversión';
	Public static String FIELSET_CONTRACT_LABEL       = 'MandatoryFieldsToIntegrateSAP';
	Public static String FIELSET_CONTRACT_BP_LABEL       = 'MandatoryFieldsIntegrateSAP_BP';
	Public static String SOBJECT_OPP_LABEL      = 'Opportunity';
	Public static String DEVELOPER_NAME_RT_WM   = 'Wealth_Management';
	Public static String DEVELOPER_NAME_RT_PRIVADA = 'Privada';
    Public static String DEVELOPER_NAME_RT_PATRIMONIAL = 'Patrimonial'; //Mike
    Public static String STATUS_SEND_SAP_LABEL_PATRIMONIAL  ='Formalización y Validación';

    public static void branchUnitAssignment(List<Opportunity> lstNewOpportunity) {
		System.debug('···· branchUnitAssignment[beforeInsert]');
		Map<String,Banker> mapBanker = new Map<String,Banker>();
		Set<String> setNumNomina     = new Set<String>();
		Set<Id> setUsersId = new Set<Id>();
		User[] lstUser     = new List<User>();
		Id idRTWealthManagement = ACTINVER_UtilityFactory_utils.getRecodType(SOBJECT_OPP_LABEL, DEVELOPER_NAME_RT_WM);
		Id idRTPrivada          = ACTINVER_UtilityFactory_utils.getRecodType(SOBJECT_OPP_LABEL, DEVELOPER_NAME_RT_PRIVADA);
		for(Opportunity newOpportunity : lstNewOpportunity) setUsersId.add(newOpportunity.OwnerId);

		Map<Id,String> mapUserIdByNumNomina = Service_Utility_Trigger.getUsersByIds(setUsersId);
		for(Id userId :mapUserIdByNumNomina.keySet()) setNumNomina.add(mapUserIdByNumNomina.get(userId));
		System.debug('@@@ SET NUMEOR DE NOMINA : ' + setNumNomina);
		if(!setNumNomina.isEmpty()) mapBanker = Service_Utility_Trigger.getBankerByNumNomina(setNumNomina);
		for(Opportunity newOpportunity : lstNewOpportunity){
			if((newOpportunity.RecordTypeId == idRTWealthManagement 
			 || newOpportunity.RecordTypeId == idRTPrivada )){
				String numNomina = mapUserIdByNumNomina.get(newOpportunity.OwnerId) != null ? mapUserIdByNumNomina.get(newOpportunity.OwnerId) : null;
				System.debug('···· numNomina: '+numNomina);
				if( numNomina == null) newOpportunity.addError(MSG_WITHOUT_BANKER);

				Banker objBanker = mapBanker.get(numNomina) != null ? mapBanker.get(numNomina) : null;
				System.debug('···· objBanker: '+objBanker);
				if( objBanker == null) newOpportunity.addError(MSG_WITHOUT_BRANCHUNIT);

				System.debug('···· objBanker.BranchUnitBusinessMembers: '+objBanker.BranchUnitBusinessMembers);
				if( objBanker.BranchUnitBusinessMembers.isEmpty()) newOpportunity.addError(MSG_WITHOUT_BRANCHUNIT_KARDEX);

				Map<String,String> mapBranchUnitBusinessMember = new Map<String,String>();
				if( !objBanker.BranchUnitBusinessMembers.isEmpty()) mapBranchUnitBusinessMember = Service_Utility_Trigger.getMapBranchUnitsBusinessMember(objBanker.BranchUnitBusinessMembers);

				System.debug('···· mapBranchUnitBusinessMember: '+mapBranchUnitBusinessMember);
				if(objBanker != null && !objBanker.BranchUnitBusinessMembers.isEmpty()){
					String ExternalIdBusinessMember = objBanker.CurrentBranch.ExternalId__c + objBanker.ExternalId__c;
					System.debug('···· ExternalIdBusinessMember: '+ExternalIdBusinessMember);
					if( mapBranchUnitBusinessMember.get(ExternalIdBusinessMember) == null) newOpportunity.addError(MSG_WITHOUT_BRANCHUNIT_KARDEX);
					if( mapBranchUnitBusinessMember.get(ExternalIdBusinessMember) != null) newOpportunity.BanqueroAsignado__c = mapBranchUnitBusinessMember.get(ExternalIdBusinessMember);
				}
			}
		}
	}

    public static void mappingContactDataToOpp(List<Opportunity> lstNewOpportunity){ // hotfix con alto sentido de urgencia 11 de julio
		Set<Id> setAccountIds = new set<Id>();
		for(Opportunity objOpportunity : lstNewOpportunity) setAccountIds.add(objOpportunity.AccountId);

		Map<ID, Account> mapAccount = new Map<ID, Account>([SELECT Account.Phone, Account.PersonEmail FROM Account WHERE Id IN :setAccountIds]); 

		for(Opportunity newOpportunity : lstNewOpportunity){
			Account objAccount = mapAccount.get(newOpportunity.AccountId);
			newOpportunity.F3_Email__c = objAccount.PersonEmail;
			newOpportunity.F3_Telefono__c = objAccount.Phone;
		}
	}

	public static void branchUnitAssignment(List<Opportunity> opportunityNew, Map<id, Opportunity> opportunityOldMap) {
		System.debug('···· branchUnitAssignment[beforeUpdate]');
		List<Opportunity> lstOpportunity = new List<Opportunity>();
		for (Opportunity newOpportunity : opportunityNew) {
			if (newOpportunity.OwnerId != opportunityOldMap.get(newOpportunity.Id).OwnerId) {
				lstOpportunity.add(newOpportunity);
			}
		}
		if(!lstOpportunity.isEmpty()) branchUnitAssignment(lstOpportunity);
	}

	public static void integrationWithSAP(List<Opportunity> opportunityNew, Map<id, Opportunity> opportunityOldMap) {
		System.debug('OppotunityTrigger_Helper.integrationWithSAP····');
		ACTINVER_UtilityFactory_utils.WrapperValueFieldSet[] lstValueFieldSet_CreateContract  = ACTINVER_UtilityFactory_utils.getValueFieldSet(FIELSET_CONTRACT_LABEL, SOBJECT_OPP_LABEL);
		ACTINVER_UtilityFactory_utils.WrapperValueFieldSet[] lstValueFieldSet_CreateContractBP = ACTINVER_UtilityFactory_utils.getValueFieldSet(FIELSET_CONTRACT_BP_LABEL, SOBJECT_OPP_LABEL);
		Id idRTWealthManagement = ACTINVER_UtilityFactory_utils.getRecodType(SOBJECT_OPP_LABEL, DEVELOPER_NAME_RT_WM);
		Id idRTPatrimonial = ACTINVER_UtilityFactory_utils.getRecodType(SOBJECT_OPP_LABEL, DEVELOPER_NAME_RT_PATRIMONIAL);
		Id idRTPrivada          = ACTINVER_UtilityFactory_utils.getRecodType(SOBJECT_OPP_LABEL, DEVELOPER_NAME_RT_PRIVADA);
		Set<String> setIntegrateSAPByContract = new Set<String>();
        Set<String> setIntegrateSAPByContractBP = new Set<String>();
        
        System.debug('tamaño: ' + opportunityNew.size());
		for (Opportunity newOpportunity : opportunityNew) {
			// Integrar con SAP para crear BP & CONTRATO - CROSS Selling
			if ((idRTWealthManagement == newOpportunity.RecordTypeId || idRTPrivada == newOpportunity.RecordTypeId)
			   && newOpportunity.StageName != opportunityOldMap.get(newOpportunity.Id).StageName
			   && !newOpportunity.F3_isCreatedInSAP__c
			   && !newOpportunity.OportunidadCreadaDeUnProspecto__c
			   && newOpportunity.StageName == STATUS_SEND_SAP_LABEL) {

				sObject sObjOpportunity = (sObject) newOpportunity;
				Map<String, Object> mapDataSObjectOpportunity = sObjOpportunity.getPopulatedFieldsAsMap();
				Boolean blnIsValidRecord = validateMandatoryFieldsIntegrateSAP(newOpportunity,mapDataSObjectOpportunity, lstValueFieldSet_CreateContract);
				if(blnIsValidRecord) setIntegrateSAPByContract.add(newOpportunity.Id);
			}
			// Integrar con SAP para crear BP
			if (idRTPatrimonial == newOpportunity.RecordTypeId 
			   && newOpportunity.StageName != opportunityOldMap.get(newOpportunity.Id).StageName
			   && !newOpportunity.F3_isCreatedInSAP__c
			   && newOpportunity.StageName == STATUS_SEND_SAP_LABEL_PATRIMONIAL) {

				sObject sObjOpportunity = (sObject) newOpportunity;
				Map<String, Object> mapDataSObjectOpportunity = sObjOpportunity.getPopulatedFieldsAsMap();
				ACTINVER_UtilityFactory_utils.WrapperValueFieldSet[] nameFieldSetByValid = newOpportunity.OportunidadCreadaDeUnProspecto__c ? lstValueFieldSet_CreateContractBP : lstValueFieldSet_CreateContract;
				Boolean blnIsValidRecord = validateMandatoryFieldsIntegrateSAP(newOpportunity,mapDataSObjectOpportunity, nameFieldSetByValid);
				if(blnIsValidRecord && newOpportunity.OportunidadCreadaDeUnProspecto__c) setIntegrateSAPByContractBP.add(newOpportunity.Id);
				if(blnIsValidRecord && !newOpportunity.OportunidadCreadaDeUnProspecto__c) setIntegrateSAPByContract.add(newOpportunity.Id);
			}
		}
		if (!setIntegrateSAPByContract.isEmpty()) calloutSAPByContract(new List<String>(setIntegrateSAPByContract));
        if (!setIntegrateSAPByContractBP.isEmpty()) calloutSAPByContractBP(new List<String>(setIntegrateSAPByContractBP));
        
	}

    public static Boolean validateMandatoryFieldsIntegrateSAP(Opportunity newOpportunity, Map<String, Object> mapDataSObjectOpportunity, ACTINVER_UtilityFactory_utils.WrapperValueFieldSet[] lstFieldsMandatory) {
		Boolean blnIsValid = true;
		String fieldsMandatory = '';
		String[] lstFieldsMadatory = new List<String>();
		for(ACTINVER_UtilityFactory_utils.WrapperValueFieldSet wrpFieldMatadory :lstFieldsMandatory){
			if(mapDataSObjectOpportunity.get(wrpFieldMatadory.fieldName) == null){
				lstFieldsMadatory.add(wrpFieldMatadory.fieldName);
				fieldsMandatory += wrpFieldMatadory.label+', ';
				blnIsValid = false;
			}
		}
		System.debug('···· MSG ERROR fieldsMandatory: '+fieldsMandatory);
		if(String.isNotBlank(fieldsMandatory)) newOpportunity.addError(MSG_FIELDS_MANDATORY + ': ' +fieldsMandatory.removeEnd(', '));

		return blnIsValid;
	}

     @future(Callout = true)
	public static void calloutSAPByContractBP(List<String> opportunityIds){
		Integration_Service.ServiceResponse jsonResponse = F3_SendDataToSAP_Handler.sendLeads(opportunityIds, true,'crearClienteContrato_Patrimonial',System.Label.crearClienteContratoFieldsPatrimonial);
		
		if(String.valueOf(jsonResponse.serviceCode).startsWithIgnoreCase('2')) updateOpportunitySuccess(opportunityIds);

		if(!String.valueOf(jsonResponse.serviceCode).startsWithIgnoreCase('2')) {
			String strMensajeError = String.valueOf(jsonResponse.serviceResponse);
			updateOpportunityError(opportunityIds,strMensajeError);
		}
	}

    @future(Callout = true)
	public static void calloutSAPByContract(List<String> opportunityIds){
			F3_SendDataToSAP_Handler.sendOpps(opportunityIds);
	}
    public static void updateOpportunitySuccess(String[] opportunityIds) {
		Opportunity[] lstOpportunity = new List<Opportunity>();
		for(String idOpportunity :opportunityIds){
			Opportunity objOpportunity = new Opportunity();
			objOpportunity.Id = idOpportunity;
			objOpportunity.F3_isCreatedInSAP__c = true;
			objOpportunity.ErrorSap__c = '';
			lstOpportunity.add(objOpportunity);
		}
		update lstOpportunity;
		Opportunity objOpportunity = getOpportunityById(opportunityIds);
		Account objAccount = setValuesOfAccount(objOpportunity);
		update objAccount;
	}
    public static void updateOpportunityError(String[] opportunityIds,String strMessageError) {
		Opportunity[] lstOpportunity = new List<Opportunity>();
		for(String idOpportunity :opportunityIds){
			Opportunity objOpportunity = new Opportunity();
			objOpportunity.Id = idOpportunity;
			objOpportunity.F3_isCreatedInSAP__c = false;
			objOpportunity.ErrorSap__c = strMessageError.abbreviate(99999);
			objOpportunity.StageName = 'Solicitar documentación';
			lstOpportunity.add(objOpportunity);
		}

		update lstOpportunity;
	}
	public static Opportunity getOpportunityById(String[] opportunityIds) {
        Opportunity objOpportunity = [SELECT Id
                    , toLabel(EstadoCivil__c)        //objAccount.MaritalStatus__c
                    , toLabel(EstadoDeNacimiento__c) //objAccount.Birth_City__c
                    , F3_Genero__c            		 //objAccount.Gender__c
                    , toLabel(Nacionalidad__c)   	 //objAccount.Nationality__c
                    , toLabel(PaisDeNacimiento__c)   //objAccount.Country_Birth__c
                    , toLabel(TipoDePersona__c)   	 //objAccount.Person_Type__c
                    , ClasificacionDePersona__c
                    , PatrimConsecutivoIDLead__c
                    , Fecha_de_Nacimiento_Cliente__c 
					, AccountId
					, SAPCURP__c
					, F3_RFC__c
                FROM Opportunity 
                WHERE Id IN :opportunityIds LIMIT 1];
        return objOpportunity;
    }
    public static Account setValuesOfAccount(Opportunity objOpportunity) {
        	//Lead objLead = new Lead();
			Account objAccount = new Account();
			objAccount.Id = objOpportunity.AccountId;
            objAccount.MaritalStatus__c = objOpportunity.EstadoCivil__c;
            objAccount.Birth_City__c    = objOpportunity.EstadoDeNacimiento__c;
            objAccount.Gender__c        = objOpportunity.F3_Genero__c;
            objAccount.Nationality__c   = objOpportunity.Nacionalidad__c;
            objAccount.Country_Birth__c = objOpportunity.PaisDeNacimiento__c;
            objAccount.Person_Type__c   = objOpportunity.TipoDePersona__c;
            objAccount.F3_Clasificacion_Persona__c   = objOpportunity.ClasificacionDePersona__c;
            objAccount.F3_CURP__c   = objOpportunity.SAPCURP__c;
            objAccount.RFC__c   = objOpportunity.F3_RFC__c;
			//if(!Test.isRunningTest()) objLead = [SELECT Id FROM Lead WHERE F3_Consecutivo_ID__c =: objOpportunity.PatrimConsecutivoIDLead__c LIMIT 1];
			//if(!Test.isRunningTest()) objAccount.Prospecto_Origen__c = objLead.Id;
            if(objAccount.IsPersonAccount) objAccount.PersonBirthdate = objOpportunity.Fecha_de_Nacimiento_Cliente__c;
		return objAccount;
    }
}