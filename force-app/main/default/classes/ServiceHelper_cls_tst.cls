/****************************************************************************************************
Desarrollado por : Isaac Canche
Proyecto         : Bitacora Anfitrion
Descripción      : Clase test para la clase Service Helper
*/
@isTest
public class ServiceHelper_cls_tst {

    public static  WebServiceInfo__mdt mdtWebServiceInfo = WebServiceInfo__mdt.getInstance('MEDALLIA_SendSurvey_WebService');
    public static WebServiceTokens__mdt mdtWebServiceToken = WebServiceTokens__mdt.getInstance('Accesstoken_Medallia');
   
     private class MockHttpResponse200 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            ServiceHelper_cls.TokenResponse tokenResponse = new ServiceHelper_cls.TokenResponse();
            
            res.setStatusCode(200);
            res.setBody(JSON.serialize(tokenResponse));
            
            return res;
        }
    }

    private class MockHttpResponse400 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            res.setStatusCode(400);
            res.setBody('{"error": "Bad Request"}');
            
            return res;
        }
    }

    @IsTest
    static void testSetCommonHeaders() {
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse200());
        
        HttpRequest httpRequest = new HttpRequest();
        Map<String, String> urlParams = new Map<String, String>{
            'param1' => 'value1',
            'param2' => 'value2'
        };
        
        httpRequest = ServiceHelper_cls.setCommonHeaders(httpRequest,mdtWebServiceInfo.DeveloperName, urlParams);
        Test.stopTest();
    }
	@IsTest
	static void testSetCommonHeadersAuthorization() {
		WebServiceInfo__mdt mdtTest = WebServiceInfo__mdt.getInstance('Doctos_GetOTP');
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse200());
		HttpRequest httpRequest = new HttpRequest();
		Map<String, String> urlParams = new Map<String, String>{
			'param1' => 'value1',
			'param2' => 'value2'
		};
		httpRequest = ServiceHelper_cls.setCommonHeaders(httpRequest, mdtTest.DeveloperName, urlParams);
		Test.stopTest();
	}
	@IsTest
	static void testSetCommonHeadersCachePartition() {
		WebServiceInfo__mdt mdtTest = WebServiceInfo__mdt.getInstance('Doctos_GetConstancies');
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse200());
		HttpRequest httpRequest = new HttpRequest();
		Map<String, String> urlParams = new Map<String, String>{
			'param1' => 'value1',
			'param2' => 'value2'
		};
		httpRequest = ServiceHelper_cls.setCommonHeaders(httpRequest, mdtTest.DeveloperName, urlParams);
		Test.stopTest();
	}

    @IsTest
    static void testUrlEncode() {
        Map<String, String> params = new Map<String, String>{
            'username' => 'testUser',
            'password' => 'testPassword'
        };

        String encodedUrl = ServiceHelper_cls.urlEncode(params);
        System.assertEquals('username=testUser&password=testPassword', encodedUrl, 'La URL debe estar correctamente codificada');
    }

    @IsTest
    static void testCalloutWith200Response() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse200());
        
        String token = ServiceHelper_cls.calloutWSToken(mdtWebServiceToken);
        System.assertEquals(null, token, 'El token de acceso debe ser "null"');
    }

    @IsTest
    static void testCalloutWith400Response() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse400());
        String token = ServiceHelper_cls.calloutWSToken(mdtWebServiceToken);
        System.assertEquals(null, token, 'El token de acceso debe ser "null"');
        
    }

}