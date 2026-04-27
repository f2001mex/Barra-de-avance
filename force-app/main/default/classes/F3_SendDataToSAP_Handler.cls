/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_SendDataToSAP_Controller
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 19/10/2022
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Handler class for the F3_SendDataToSAP_Controller class
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 19/10/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public with sharing class F3_SendDataToSAP_Handler {
	Public static String WS_CREATE_CLIENT_SAP_OLD  = 'crearClienteContrato';
	Public static String WS_CREATE_CLIENT_SAP_NEW  = 'crearClienteContrato_NewLed';
	Public static String DEVELOPER_NAME_RT_WM = 'WealthManagement';
    Public static String DEVELOPER_NAME_RT_PATR = 'Patrimonial';
	Public static String DEVELOPER_NAME_RT_PRIVADA = 'Privada';
	static public Integration_Service.ServiceResponse sendLeads(List<String> leadsIds, Boolean FieldsCompleted, String strPatrimonialSettings, String strQuery) {
		String nameSettingWS = '';
		try {
			List<Lead> leadsToUpdate = new List<Lead>();
            Id recordId = leadsids[0];
            String sObjectType = recordId.getSObjectType().getDescribe().getName();
            strQuery = sObjectType =='Lead' ? 'SELECT ' + strQuery + ' FROM Lead WHERE Id IN :leadsIds' : 'SELECT ' + strQuery + ' FROM Opportunity WHERE Id IN :leadsIds';
            System.debug('sobjectype: ' + sObjectType + ' list ids: '+ leadsIds);
			List<Integration_Service.ServiceResponse> responseList = new List<Integration_Service.ServiceResponse>();
			for(sObject[] sObj : Database.query(strQuery)) {
				Map<String, Object> leadMap = sObj[0].getPopulatedFieldsAsMap().clone();
				RecordType objRecordType    = (RecordType) leadMap.get('RecordType');
				if (leadMap.containsKey('Fecha_Nacimiento_Prospecto__c') || leadMap.containsKey('Fecha_de_Nacimiento_Cliente__c')) {
					Date leadBornDate = leadMap.get('Fecha_Nacimiento_Prospecto__c') == null ? (Date) leadMap.get('Fecha_de_Nacimiento_Cliente__c') : (Date) leadMap.get('Fecha_Nacimiento_Prospecto__c');
                    //Date leadBornDate = (Date) leadMap.get('Fecha_Nacimiento_Prospecto__c');
					String leadBornDateDay = String.valueOf(leadBornDate.day()).length() == 1 ? '0' + leadBornDate.day() : String.valueOf(leadBornDate.day());
					String leadBornDateMonth = String.valueOf(leadBornDate.month()).length() == 1 ? '0' + leadBornDate.month() : String.valueOf(leadBornDate.month());
					leadMap.put('Fecha_Nacimiento_Prospecto__c', '' + leadBornDate.year() + leadBornDateMonth + leadBornDateDay);
					leadMap.put('Fecha_de_Nacimiento_Cliente__c', '' + leadBornDate.year() + leadBornDateMonth + leadBornDateDay);
				}
                System.debug('MAPA OBJETO: ' + leadMap);
				Integration_Service.ServiceResponse response = Integration_Service.calloutService(
					strPatrimonialSettings,
					null,
					null,
					leadMap,
					false
				);
				response.serviceHeaders = null;
				response.logger = null;
				responseList.add(response);
				if(objRecordType.Developername != DEVELOPER_NAME_RT_WM && objRecordType.Developername != DEVELOPER_NAME_RT_PRIVADA && objRecordType.Developername != DEVELOPER_NAME_RT_PATR) leadsToUpdate.add(fieldUpdateLead(response,leadMap,fieldsCompleted));
			}
			if (!leadsToUpdate.isEmpty())  update leadsToUpdate;
			System.debug('####response: '+ responseList[0]);
			return responseList[0];
		} catch (Exception e) {
            System.debug('####ERROR CLASS F3_SendDataToSAP_Handler: '+ e.getMessage() + ' LINE: ' +e.getLineNumber());
			throw new F3_RestServices_Exception(e.getMessage());
		}
	}

	static public String sendOpps(List<String> oppsIds) {
		List<Opportunity> oppsList = Database.query(
			'SELECT ' + System.Label.crearActualizarContrato_Fields + ' FROM Opportunity WHERE Id IN :oppsIds'
		);
		Map<String, Object> oppMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(oppsList[0].getPopulatedFieldsAsMap()));
		oppMap.put('Owner.ID_ASESOR__c', ((Map<String, Object>) oppMap.get('Owner')).get('ID_ASESOR__c'));
		oppMap.put('Account.Client_ID__c', ((Map<String, Object>) oppMap.get('Account')).get('Client_ID__c'));
		try {
			Integration_Service.ServiceResponse response = Integration_Service.calloutService(
				'crearActualizarContrato',
				null,
				null,
				oppMap,
				false
			);
			if (String.valueOf(response.serviceCode).startsWithIgnoreCase('2')) {
				String updatedLeads = F3_SendDataToSAP_Helper.updateOpps(oppsIds);
			}

			system.debug(JSON.serializePretty(response));
			response.serviceHeaders = null;
			response.logger = null;
			return JSON.serialize(response);
		} catch (Exception e) {
			throw new F3_RestServices_Exception(e.getMessage());
		}
	}

	static public String getAccount(String accountBP) {
		Set<String> insertedAccount = new Set<String>();
		Map<String, String> jsonInputData = new Map<String, String>{ '#NUM_CLIENTE_PK' => '12560002' };
		try {
			Integration_Service.ServiceResponse response = Integration_Service.calloutService(
				'solicitarCliente',
				null,
				null,
				jsonInputData,
				true
			);
			Map<String, List<SObject>> sObjectMap = F3_JsonToSobject_Service.jsonToSobject(
				(String) response.serviceResponse,
				'crearActualizarCliente'
			);
			if (!sObjectMap.get('Account').isEmpty() && String.valueOf(response.serviceCode).startsWithIgnoreCase('2')) {
				Schema.SObjectField accExternalField = Account.Client_ID__c.getDescribe().getSObjectField();
				List<Database.upsertResult> upsertResults = Database.upsert(sObjectMap.get('Account'), accExternalField, false);
				if (!upsertResults.isEmpty()) {
					for (Database.upsertResult result : upsertResults) {
						if (result.isSuccess() == true) {
							insertedAccount.add(result.getId());
						}
					}
				}
				return String.join(new List<String>(insertedAccount), ',');
			} else {
				throw new F3_RestServices_Exception('Error ' + response.serviceCode + ' en el servicio: ' + response.serviceResponse);
			}
		} catch (Exception e) {
			throw new F3_RestServices_Exception(e.getMessage());
		}
	}

	public static String getPortfolio(String contractNumber, String executiveID) {
		Map<String, Object> parameters = new Map<String, Object>{ 'contractNumber' => contractNumber, 'promoterNumber' => executiveID };
		try {
			System.debug(System.Limits.getHeapSize());
			Integration_Service.ServiceResponse response = Integration_Service.calloutService(
				'PortafolioContrato',
				null,
				null,
				parameters,
				true
			);
			System.debug(System.Limits.getHeapSize());
			response.serviceHeaders = null;
			response.logger = null;
			return JSON.serialize(response);
		} catch (Exception e) {
			throw new F3_RestServices_Exception(e.getMessage());
		}
	}

	public static String getContractList(String startDate, String endDate, String currentUserId) {
		List<User> currentUser = [SELECT ID_ASESOR__c FROM USER WHERE Id = :currentUserId LIMIT 1];
		Map<String, Object> parameters = new Map<String, Object>{
			'startDate' => startDate,
			'endDate' => endDate,
			'currentUserId' => currentUser[0].ID_ASESOR__c
		};
		try {
			Integration_Service.ServiceResponse response = Integration_Service.calloutService(
				'VistaContrato',
				null,
				null,
				parameters,
				true
			);
			response.serviceHeaders = null;
			response.logger = null;
			return JSON.serialize(response);
		} catch (Exception e) {
			throw new F3_RestServices_Exception(e.getMessage());
		}
	}
	public static Lead fieldUpdateLead(Integration_Service.ServiceResponse response,Map<String, Object> leadMap, Boolean fieldsCompleted){
		Lead leadToUpdate = new Lead();
		leadToUpdate.Id =  (String) leadMap.get('Id');
		leadToUpdate.F3_Se_completaron_campos_minimos__c = fieldsCompleted;
		if (String.valueOf(response.serviceCode).startsWithIgnoreCase('2')) {
			leadToUpdate.Status = 'Formalización y Validación';
			leadToUpdate.F3_isCreatedInSAP__c = true;
		}
		return leadToUpdate;
	}

}