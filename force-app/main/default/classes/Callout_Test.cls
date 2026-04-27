/**
**/
@isTest
public with sharing class Callout_Test {
    public static Map<String,String> endpointsMap = BIT_UtilityDataTest.getEndpointsMap();
    public static BIT_Medallia_Request request = new BIT_Medallia_Request();
    @isTest
    static void test1(){
        test.startTest();
        BIT_UtilityDataTest.instanceMock4Services(true, false, endpointsMap);
        BIT_Medallia_Response response = (BIT_Medallia_Response)Callout_cls.callService(new Bitacora_Callouts_cls.MEDALLIA_SendSurvey_WebService(),request, endpointsMap);
        test.stopTest();
    }
    @isTest
    static void test2(){
        test.startTest();
        BIT_UtilityDataTest.instanceMock4Services(true, false, endpointsMap);
        BIT_Medallia_Response response = (BIT_Medallia_Response)Callout_cls.callService(new Bitacora_Callouts_cls.MEDALLIA_SendSurvey_WebService());
        test.stopTest();
    }
    @isTest
    static void test3(){
        test.startTest();
        BIT_UtilityDataTest.instanceMock4Services(true, false, endpointsMap);
        BIT_Medallia_Response response = (BIT_Medallia_Response)Callout_cls.callService(new Bitacora_Callouts_cls.MEDALLIA_SendSurvey_WebService(), endpointsMap);
        test.stopTest();
    }
}