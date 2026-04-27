/**
 *   ------------------------------------------------------------------------------------------------
 * Name     F3_Enrolamiento_Controller
 * Author   omar.espinosa@pwc.com
 * Date     Created: 24/08/2022
 * Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * Description Rest Service for the update of accounts for web activation
 *   ------------------------------------------------------------------------------------------------
 * Changes
 * 24/08/2022 omar.espinosa@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
@RestResource(urlMapping='/crearActualizarEnrolamiento/*')
global without sharing class F3_Enrolamiento_Controller {
	/** ------------------------------------------------------------------------------------------------
	 * Description Post Method in charge of the upsert of Accounts
	 *   ------------------------------------------------------------------------------------------------
	 * author   omar.espinosa@pwc.com
	 * date     24/08/2022
	 * param
	 * return   void
	 * example  POST actinver--actidev.my.salesforce.com/services/apexrest/crearActualizarEnrolamiento
	 * ------------------------------------------------------------------------------------------------**/
	@HttpPut
	global static void insertUpdateClient() {
		F3_Integration_Service_Settings__c serviceSettings = F3_Integration_Service_Settings__c.getValues('SFcrearActualizarEnrolamiento');
		try {
			Map<String, Map<String, Map<String, String>>> clientsData = F3_Enrolamiento_Handler.processData(
				RestContext.request.requestBody.toString()
			);
			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf(JSON.serialize(clientsData));
			RestContext.response.statusCode = 200;
		} catch (Exception error) {
			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf(F3_WebServices_Utility.exceptionToJson(error));
			RestContext.response.statusCode = 400;
		}
		if (serviceSettings != null && serviceSettings.F3_Enable_Log__c == true) {
			Type logService = Type.forName('Integration_Logger_Service');
			Integration_Logger_Service logger = (Integration_Logger_Service) logService.newInstance();
			logger.addRequest(
				RestContext.request.requestBody.toString(),
				'/services/apexrest/crearActualizarEnrolamiento',
				'SFcrearActualizarEnrolamiento',
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