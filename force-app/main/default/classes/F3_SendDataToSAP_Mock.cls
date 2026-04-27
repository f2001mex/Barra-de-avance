/** ---------------------------------------------------------------------------------------------------
    * @Description: Test class for F3_SendDataToSAP_Handler and Helper classes
    *   ------------------------------------------------------------------------------------------------
    Author                  Date                Version                 Changes
    Victor Galvan           20/02/2023          1.0                     Class creation
* ------------------------------------------------------------------------------------------------**/
@isTest(IsParallel=true)
global class F3_SendDataToSAP_Mock implements HttpCalloutMock {
	global HTTPResponse respond(HTTPRequest request) {
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody('{"clients": {"id":1, "name":"Test"}}');
		response.setStatusCode(200);
		return response;
	}
}