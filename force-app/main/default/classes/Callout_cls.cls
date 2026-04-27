/****************************************************************************************************
Desarrollado por :  Unknown
Proyecto         :  Actinver
Descripción      :  Clase que centraliza las llamadas a los servicios externos

Cambios (Versiones)
-----------------------------------------------------------------------------------------------------
No.     Fecha           Autor                   Descripción
-----   ----------      --------------------    -----------------------------------------------------
1.0     2024-08-14      Unknown			Creación de la Clase.            /survys?BR=001                            
*/
public with sharing class Callout_cls {
	Service_cls service;
	RequestBody_cls request;
	static String accessToken;
	static Map<String, WebServiceInfo__mdt> serviceInfosByDeveloperName {
	  get {
		if ( serviceInfosByDeveloperName == null ) {
		  List<WebServiceInfo__mdt> serviceInfos = [SELECT Id, IsMock__c, DeveloperName FROM WebServiceInfo__mdt];
		  serviceInfosByDeveloperName = new Map<String, WebServiceInfo__mdt>();
		  for ( WebServiceInfo__mdt serviceInfo : serviceInfos ) {
			serviceInfosByDeveloperName.put( serviceInfo.DeveloperName, serviceInfo );
		  }
		}
		return serviceInfosByDeveloperName;
	  }
	  set;
	}
	static Callout_cls singletonInstance;
	private Callout_cls () {}

	public static Callout_cls getInstance() {
	    if(singletonInstance == null){
		    singletonInstance = new Callout_cls();
	    }
	    return singletonInstance;
	}

	public static ResponseBody_cls callService( Service_cls service, RequestBody_cls requestBody, Map<String, String> urlParams) {
        Callout_cls callout = Callout_cls.getInstance();
        ResponseBody_cls responseBody;
        service.setRequestBody( requestBody );
        service.setUrlParams(urlParams);
        System.debug(JSON.serializePretty(requestBody));
        Boolean isMock = serviceInfosByDeveloperName.get( service.getMdtName() ).isMock__c;

        try {
            responseBody = isMock ? service.setMockResponse() : service.run();
        } catch (Exception e) {
            throw e;
        }
  
	  return responseBody;
	}

	public static ResponseBody_cls callService( Service_cls service, Map<String, String> urlParams) {
        Callout_cls callout = Callout_cls.getInstance();
        ResponseBody_cls responseBody;
        service.setUrlParams(urlParams);
        Boolean isMock = serviceInfosByDeveloperName.get( service.getMdtName() ).isMock__c;

        try {
            responseBody = isMock ? service.setMockResponse() : service.run();
        } catch (Exception e) {
            throw e;
        }
    
        return responseBody;
	}

	public static ResponseBody_cls callService(Service_cls service) {
		Callout_cls callout = Callout_cls.getInstance();
		ResponseBody_cls responseBody;
		Boolean isMock = serviceInfosByDeveloperName.get( service.getMdtName() ).isMock__c;
	
		try {
		  responseBody = isMock ? service.setMockResponse() : service.run();
		} catch (Exception e) {
		  throw e;
		}
	
		return responseBody;
	}
  
	public static ResponseBody_cls callService( Service_cls service, RequestBody_cls requestBody ) {
        Callout_cls callout = Callout_cls.getInstance();
        ResponseBody_cls responseBody;
        System.debug(JSON.serializePretty(requestBody));
        service.setRequestBody( requestBody );
        Boolean isMock = serviceInfosByDeveloperName.get( service.getMdtName() ).isMock__c;
    
        try {
            responseBody = isMock ? service.setMockResponse() : service.run();
        } catch (Exception e) {
            throw e;
        }
  
	  return responseBody;
	}
}