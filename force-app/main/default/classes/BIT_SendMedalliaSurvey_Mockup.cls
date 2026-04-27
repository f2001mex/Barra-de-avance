/**
**/
@IsTest
global class BIT_SendMedalliaSurvey_Mockup implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req){
        HttpResponse res = new HttpResponse();
        res.setBody('{"statusCode" : "202","statusCodeValue":"Ok"}');
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        return res;
    }
}