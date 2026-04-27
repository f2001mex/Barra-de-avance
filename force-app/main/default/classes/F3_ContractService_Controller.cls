/**
 *   ------------------------------------------------------------------------------------------------
 * Name     F3_ClientService_Controller
 * Author   luis.felipe.ortiz@pwc.com
 * Date     Created: 10/17/2022
 * Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * Description Rest Service for the upsert of contracts and NESTED related records
 *   ------------------------------------------------------------------------------------------------
 * Changes
 * 10/17/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
@RestResource(urlMapping='/crearActualizarContrato/*')
global without sharing class F3_ContractService_Controller {
	/** ------------------------------------------------------------------------------------------------
	 * Description Post Method in charge of the upsert of contracts and NESTED related records
	 *   ------------------------------------------------------------------------------------------------
	 * author   luis.felipe.ortiz@pwc.com
	 * date     10/17/2022
	 * param
	 * return   void
	 * example  POST actinver--actidev.my.salesforce.com/services/apexrest/crearActualizarContrato
	 * ------------------------------------------------------------------------------------------------**/
	@HttpPut
	global static void upsertContractAndRelated() {
		try {
			Map<String, Map<String, Map<String, String>>> contractData = F3_ContractService_Handler.processData(
				RestContext.request.requestBody.toString()
			);
			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf(JSON.serialize(contractData));
			RestContext.response.statusCode = 200;
		} catch (Exception error) {
			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf(F3_WebServices_Utility.exceptionToJson(error));
			RestContext.response.statusCode = 400;
		} finally {
			F3_Integration_Service_Settings__c serviceSettings = F3_Integration_Service_Settings__c.getValues('SFcrearActualizarContrato');
			if (serviceSettings != null && serviceSettings.F3_Enable_Log__c == true) {
				Integration_Logger_Service logger = new Integration_Logger_Service();
				logger.addRequest(
					RestContext.request.requestBody.toString(),
					'/services/apexrest/crearActualizarContrato',
					'SFcrearActualizarContrato',
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
}