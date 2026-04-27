/****************************************************************************************************
Desarrollado por : VASS MÉXICO
Proyecto         : Actinver - Bitácora
Descripción      : Clase test para la clase Bitacora_Callouts_cls
*/
@isTest
public class Bitacora_Callouts_tst {

    public static Map<String,String> endpointsMap = BIT_UtilityDataTest.getEndpointsMap();
    @isTest
    static void test4MEDALLIA_SendSurvey_WS() {
        Test.startTest();
        BIT_Medallia_Request request = new BIT_Medallia_Request();
        	try{
                BIT_UtilityDataTest.instanceMock4Services(false,true, endpointsMap);
                BIT_Medallia_Response response = (BIT_Medallia_Response)Callout_cls.callService(new Bitacora_Callouts_cls.MEDALLIA_SendSurvey_WebService(),request);
                Service_CLS service = new Bitacora_Callouts_cls.MEDALLIA_SendSurvey_WebService();
                ResponseBody_CLS responsebody = service.setMockResponse();
            }catch(ServiceException e){
                system.debug('Error');
            }
        Test.stopTest();
    }
	@IsTest
	static void testStatusError() {
		Test.startTest();
		String message = Bitacora_Callouts_cls.buildErrorMessage(200);
		Test.stopTest();
	}
	@IsTest
	static void testDoctos_GetOTP() {
		Test.startTest();
		BIT_GetOTP_Request request = new BIT_GetOTP_Request();
			try{
				HTTPMockFactory mock = new HTTPMockFactory(401, 'Unauthorized', 'No Content', new Map<String, String>());
				Test.setMock(HttpCalloutMock.class, mock);
				BIT_GetOTP_Response response = (BIT_GetOTP_Response)Callout_cls.callService(new Bitacora_Callouts_cls.Doctos_GetOTP(),request);
				Service_CLS service = new Bitacora_Callouts_cls.Doctos_GetOTP();
			} catch(ServiceException e){
				system.debug('Error');
			}
		Test.stopTest();
	}
	@IsTest
	static void testBIT_GetTokenCF() {
		Test.startTest();
		BIT_GetTokenCF_Request request = new BIT_GetTokenCF_Request();
			try{
				HTTPMockFactory mock = new HTTPMockFactory(401, 'Unauthorized', 'No Content', new Map<String, String>());
				Test.setMock(HttpCalloutMock.class, mock);
				BIT_GetTokenCF_Response response = (BIT_GetTokenCF_Response)Callout_cls.callService(new Bitacora_Callouts_cls.BIT_GetTokenCF(),request);
				Service_CLS service = new Bitacora_Callouts_cls.BIT_GetTokenCF();
			} catch(ServiceException e){
				system.debug('Error');
			}
		Test.stopTest();
	}
	@IsTest
	static void testBIT_GetConstancies() {
		Test.startTest();
		BIT_GetConstancies_Request request = new BIT_GetConstancies_Request();
			try{
				HTTPMockFactory mock = new HTTPMockFactory(401, 'Unauthorized', 'No Content', new Map<String, String>());
				Test.setMock(HttpCalloutMock.class, mock);
				BIT_GetConstancies_Response response = (BIT_GetConstancies_Response)Callout_cls.callService(new Bitacora_Callouts_cls.BIT_GetConstancies(),request);
				Service_CLS service = new Bitacora_Callouts_cls.BIT_GetConstancies();
			} catch(ServiceException e){
				system.debug('Error');
			}
		Test.stopTest();
	}
	@IsTest
	static void testBIT_SendConstancie() {
		Test.startTest();
		BIT_SendConstancie_Request request = new BIT_SendConstancie_Request();
			try{
				HTTPMockFactory mock = new HTTPMockFactory(401, 'Unauthorized', 'No Content', new Map<String, String>());
				Test.setMock(HttpCalloutMock.class, mock);
				BIT_SendConstancie_Response response = (BIT_SendConstancie_Response)Callout_cls.callService(new Bitacora_Callouts_cls.BIT_SendConstancie(),request);
				Service_CLS service = new Bitacora_Callouts_cls.BIT_SendConstancie();
			} catch(ServiceException e){
				system.debug('Error');
			}
		Test.stopTest();
	}
	@IsTest
	static void testBIT_GetStatements() {
		Test.startTest();
		BIT_GestStatements_Request request = new BIT_GestStatements_Request();
			try{
				HTTPMockFactory mock = new HTTPMockFactory(401, 'Unauthorized', 'No Content', new Map<String, String>());
				Test.setMock(HttpCalloutMock.class, mock);
				BIT_GetStatements_Response response = (BIT_GetStatements_Response)Callout_cls.callService(new Bitacora_Callouts_cls.BIT_GetStatements(),request);
				Service_CLS service = new Bitacora_Callouts_cls.BIT_GetStatements();
			} catch(ServiceException e){
				system.debug('Error');
			}
		Test.stopTest();
	}
	@IsTest
	static void testBIT_SendStatements() {
		Test.startTest();
		BIT_SendStatements_Request request = new BIT_SendStatements_Request();
			try{
				HTTPMockFactory mock = new HTTPMockFactory(401, 'Unauthorized', 'No Content', new Map<String, String>());
				Test.setMock(HttpCalloutMock.class, mock);
				BIT_SendStatements_Response response = (BIT_SendStatements_Response)Callout_cls.callService(new Bitacora_Callouts_cls.BIT_SendStatements(),request);
				Service_CLS service = new Bitacora_Callouts_cls.BIT_SendStatements();
			} catch(ServiceException e){
				system.debug('Error');
			}
		Test.stopTest();
	}
}