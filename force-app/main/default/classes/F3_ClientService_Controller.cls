/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_ClientService_Controller
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 12/08/2022
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Rest Service for the creation of accounts and lead linking to the account
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 12/08/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
@RestResource(urlMapping='/crearActualizarCliente/*')
global without sharing class F3_ClientService_Controller {
	public static String DEVELOPER_NAME_RT_WM = 'WealthManagement';
	public static String DEVELOPER_NAME_RT_PRIVADA = 'Privada';
	/** ------------------------------------------------------------------------------------------------
	 * @Description Post Method in charge of the upsert of Accounts and Lead linking and Update
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     12/08/2022
	 * @param
	 * @return   void
	 * @example  POST actinver--actidev.my.salesforce.com/services/apexrest/crearActualizarCliente
	 * ------------------------------------------------------------------------------------------------**/
	@HttpPut
	global static void insertUpdateClient() {
		F3_Integration_Service_Settings__c serviceSettings = F3_Integration_Service_Settings__c.getValues('SFcrearActualizarCliente');
		try {
			Map<String, Map<String, Map<String, String>>> clientsData = new Map<String, Map<String, Map<String, String>>>();
			String clientsJson= RestContext.request.requestBody.toString();
			Map<String,Object> dataRequest = F3_ClientService_Handler.processRequest(clientsJson);
			Set<String> setRecordTypes     = (Set<String>) dataRequest.get('setRecordTypes');
			Map<String,Account> mapAccountsUpdate        = (Map<String,Account>) dataRequest.get('mapAccountsUpdate');
			Map<String,Lead> mapConsecutiveByLead        = (Map<String,Lead>) dataRequest.get('mapConsecutiveByLead');
			Map<String, List<SObject>> sObjectMapRequest = (Map<String, List<SObject>>) dataRequest.get('sObjectMap');
			// Nuevo proceso de para la división de WM y Privada
			if(setRecordTypes.contains(DEVELOPER_NAME_RT_WM) ||setRecordTypes.contains(DEVELOPER_NAME_RT_PRIVADA)) clientsData = F3_ClientService_Handler.processData(sObjectMapRequest,mapAccountsUpdate,mapConsecutiveByLead);
			
			// Proceso para la división diferente de WM y Privada
			if(!setRecordTypes.contains(DEVELOPER_NAME_RT_WM) && !setRecordTypes.contains(DEVELOPER_NAME_RT_PRIVADA)) {
				clientsData= F3_ClientService_Handler.processDataOld(sObjectMapRequest);
			}

			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf(JSON.serialize(clientsData));
			RestContext.response.statusCode = 200;
		} catch (Exception error) {
			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf(F3_WebServices_Utility.exceptionToJson(error));
			RestContext.response.statusCode = 400;
		}
		if (serviceSettings != null && serviceSettings.F3_Enable_Log__c == true) {
			Integration_Logger_Service logger = new Integration_Logger_Service();
			logger.addRequest(
				RestContext.request.requestBody.toString(),
				'/services/apexrest/crearActualizarCliente',
				'SFcrearActualizarCliente',
				JSON.serialize(RestContext.request.headers),
				RestContext.request.httpMethod,
				serviceSettings.F3_Service_Type__c
			);
			logger.addResponse(
				String.valueOf(RestContext.response.statusCode),
				RestContext.response.responseBody.toString(),
				JSON.serialize(RestContext.response.headers)
			);
			logger.asyncUpsertLogger();
		}
	}
}