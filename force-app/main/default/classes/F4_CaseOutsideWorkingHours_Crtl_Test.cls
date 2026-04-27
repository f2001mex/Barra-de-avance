/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     F4_CaseOutsideWorkingHours_Crtl_Test
 * @Author   ivan.mora@pwc.com
 * @Date     Created: 20/05/2024
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Test for interface that creates a new case after working hours
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 20/05/2024 ivan.mora@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
@isTest
public class F4_CaseOutsideWorkingHours_Crtl_Test {
    @IsTest
	public static void testPostCall_Success() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest',
			Name = 'SFcrearCasoFueraHorario'
		);
		insert testSettings;

        request.requestUri = 'https://actinver--actidev.sandbox.my.salesforce.com/services/apexrest/crearCasoFueraHorario/';
        request.httpMethod = 'POST';
        String requestBody2 = '{"casos":[{"nombre": "Julio", "apellido": "Gonzalez", "email": "julio@correo.com", "asunto": "Perdida de Tarjeta"}]}';
        request.requestBody = Blob.valueOf(requestBody2);
        
        RestContext.request = request;
		RestContext.response = response;

        Test.startTest();
            F4_CaseOutsideWorkingHours_Controller.createCase();
		Test.stopTest();
    }

    @IsTest
    public static void testPostCall_Failed() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestUri = 'https://actinver--actidev.sandbox.my.salesforce.com/services/apexrest/crearCasoFueraHorario/';
        request.httpMethod = 'POST';
        String requestBody2 = '{"clientes":[{"NUM_CLIENTE_PK":"1","NOMBRE":"Test","APELLIDO_PATERNO":"Client","PROSPECTOID":""}]}';
        request.requestBody = Blob.valueOf(requestBody2);
        
        RestContext.request = request;
		RestContext.response = response;

        Test.startTest();
            F4_CaseOutsideWorkingHours_Controller.createCase();
		Test.stopTest();
    }
}