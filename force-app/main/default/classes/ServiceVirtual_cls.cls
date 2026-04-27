/****************************************************************************************************
Desarrollado por : VASS MÉXICO
Proyecto         : Actinver - Bitácora
Descripción      : Implementaciones comunes a los callouts

Cambios (Versiones)
-----------------------------------------------------------------------------------------------------
No.     Fecha           Autor                   Descripción
-----   ----------      --------------------    -----------------------------------------------------
1.0     2024-08-14      VASS MÉXICO			    Creación de la Clase.                                       
*/
public with sharing virtual class ServiceVirtual_cls implements Service_cls{

    protected String mdtName;
    protected Map<String, String> urlParams;
    protected HttpRequest httpRequest = new HttpRequest();
    protected String requestBodyJSON;
    protected ResponseBody_cls responseBody;
    protected Object undefinedResponseBody;
    
    public String getMdtName() {
        return mdtName;
    }
    
    public Map<String, String> getUrlParams() {
        return urlParams;
    }
    
    public virtual void setUrlParams(Map<String, String> urlParams) {
        this.urlParams = urlParams;
    }
    
    public virtual void setRequestBody(RequestBody_cls requestBody) {
        String serializedBody = requestBody.serializeRequestBody( requestBody );
        httpRequest.setBody( serializedBody );
        setRequestBodyJSON( serializedBody );
    }
    
    public virtual ResponseBody_cls run() {
        Http http = new Http();
        httpRequest = ServiceHelper_cls.setCommonHeaders(httpRequest, mdtName, urlParams);
        system.debug(httpRequest);
        system.debug(httpRequest.getBody());
        HTTPResponse response = http.send(httpRequest);
        
        System.debug('@statusCode: ' + response.getStatusCode() );
        System.debug('@responseBodySerialize: ' + response.getBody());
        System.debug('@response: ' + response);
        
        if (response.getStatusCode() >= 200 && response.getStatusCode() < 300 ) {
            responseBody = String.isNotBlank(response.getBody()) ? responseBody.deserializeResponseBody(response.getBody()) : null;
			System.debug('@responseBody: ' + JSON.serializePretty(responseBody));
        } else {
            manageErrorStatus(response);
        }
        
        return responseBody;
    }
    
    
    public virtual void manageErrorStatus ( HTTPResponse response ) {
        System.debug('@Response: ' + JSON.serializePretty( response.getBody() ));
        ServiceException serviceException = new ServiceException();
        serviceException.status = response.getStatus();
        serviceException.statusCode = response.getStatusCode();
        serviceException.setMessage('Status code ' + response.getStatusCode() + ' not expected!');
        serviceException.responseBody = response.getBody();
        serviceException.requestBody = this.requestBodyJSON;
        serviceException.webServiceName = this.mdtName;
        throw serviceException;
    }
    
    
    public virtual ResponseBody_cls setMockResponse() {
        List<WebServiceInfo__mdt> lst_wsInfo = [SELECT Endpoint__c
                                                     , Method__c
                                                     , ContentType__c
                                                     , MockResponse__c
                                                FROM WebServiceInfo__mdt
                                                WHERE DeveloperName = :mdtName];
        
        ResponseBody_cls responseBody = lst_wsInfo.get(0).mockResponse__c != null ? responseBody.deserializeResponseBody( lst_wsInfo.get(0).mockResponse__c ) : null;
        
        return responseBody;
    }
    
    public void setRequestBodyJSON( String requestBody ) {
        this.requestBodyJSON = setLogBody( requestBody );
    }
    
    private String setLogBody( String body ) {
        return body.length() > 32768 ? body.mid( 0, 32768 ) : body;
    }
    
}