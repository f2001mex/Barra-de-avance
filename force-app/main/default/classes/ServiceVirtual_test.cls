@isTest
public class ServiceVirtual_test {
	@isTest static void testMethods() {
        Test.startTest();
        ServiceVirtual_CLS clsServiceVirtual = new ServiceVirtual_CLS();
            clsServiceVirtual.setUrlParams(new Map<String, String>());
            clsServiceVirtual.getUrlParams();
            clsServiceVirtual.getMdtName();
        	BIT_Medallia_Request request = new BIT_Medallia_Request();
        	clsServiceVirtual.setRequestBody(request);
            //clsServiceVirtual.setMockResponseNoDefinedObj();
            HTTPResponse res = new HTTPResponse();
        	res.setBody('{}');
            try{
                clsServiceVirtual.manageErrorStatus(res);
            }catch(ServiceException e){
                system.debug('Error');        
            }
        Test.stopTest();
    }
}