/**
 *   ------------------------------------------------------------------------------------------------
 * Name     F4_CaseOutsideWorkingHours_Controller
 * Author   ivan.mora@pwc.com
 * Date     Created: 09/26/2023
 * Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * Description Rest Service for case creation for agent Outside Working Hours
 *   ------------------------------------------------------------------------------------------------
 * Changes
 * 09/26/2023 ivan.mora@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
@RestResource(urlMapping='/crearCasoFueraHorario/*')
global without sharing class F4_CaseOutsideWorkingHours_Controller {
    /** ------------------------------------------------------------------------------------------------
     * Description Post Method in charge of create a case when agent is unavailable.
     *   ------------------------------------------------------------------------------------------------
     * author   ivan.mora@pwc.com
     * date     09/26/2023
     * param
     * return   void
     * example  POST actinver--actidev.my.salesforce.com/services/apexrest/crearCasoFueraHorario
     * ------------------------------------------------------------------------------------------------**/
    @HttpPost
    global static void createCase() {
        try {
            List<Database.SaveResult> casesData = F4_CaseOutsideWorkingHours_Handler.processData(
                RestContext.request.requestBody.toString()
            );
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(casesData));
            RestContext.response.statusCode = 200;
        } catch (Exception error) {
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(F3_WebServices_Utility.exceptionToJson(error));
            RestContext.response.statusCode = 400;
        } finally {
            F3_Integration_Service_Settings__c serviceSettings = F3_Integration_Service_Settings__c.getValues('SFcrearCasoFueraHorario');
            if (serviceSettings != null && serviceSettings.F3_Enable_Log__c == true) {
                Integration_Logger_Service logger = new Integration_Logger_Service();
                logger.addRequest(
                    RestContext.request.requestBody.toString(),
                    '/services/apexrest/crearCasoFueraHorario',
                    'SFcrearCasoFueraHorario',
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