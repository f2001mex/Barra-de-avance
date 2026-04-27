/****************************************************************************************************
Desarrollado por : Unknown
Proyecto         : -
Descripción      : Clase auxiliar con métodos para acceso WS

Cambios (Versiones)
-----------------------------------------------------------------------------------------------------
No.     Fecha           Autor                   Descripción
-----   ----------      --------------------    -----------------------------------------------------
1.0     2024-08-14      Unknown			Creación de la Clase.                                       
*/
public with sharing class ServiceHelper_cls {

    public static HttpRequest setCommonHeaders(HttpRequest httpRequest, String mdtName, Map<String, String> urlParams) {
        WebServiceInfo__mdt mdtWebServiceInfo = WebServiceInfo__mdt.getInstance(mdtName);
        httpRequest.setEndpoint(formatUrl(mdtWebServiceInfo.Endpoint__c, urlParams));
        System.debug('WebServiceInfo__mdt---> ' + mdtWebServiceInfo);
        httpRequest.setMethod(mdtWebServiceInfo.Method__c);
        httpRequest.setTimeout(Integer.valueOf(mdtWebServiceInfo.Timeout__c));
        if(mdtWebServiceInfo.WebServiceToken__c != null && mdtWebServiceInfo.WebServiceToken__r.DeveloperName!=null) {
            WebServiceTokens__mdt mtdWebServiceTokens = WebServiceTokens__mdt.getInstance(mdtWebServiceInfo.WebServiceToken__r.DeveloperName);
            String strToken = calloutWSToken(mtdWebServiceTokens);
			httpRequest.setHeader('Authorization', String.valueOf(mdtWebServiceInfo.AuthorizationType__c) + ' ' + strToken);
            System.debug('--HEADER--'+httpRequest.getHeader('Authorization'));
        } else if (!String.isEmpty(mdtWebServiceInfo.Authorization__c)) {
			System.debug('Authorization=>>' + mdtWebServiceInfo.Authorization__c);
			httpRequest.setHeader('Authorization', String.valueOf(mdtWebServiceInfo.AuthorizationType__c) + ' ' + mdtWebServiceInfo.Authorization__c);
		} else if (!String.isEmpty(mdtWebServiceInfo.CachePartition__c)) {
			System.debug ('AuthCache=>>' + Cache.Session.get(mdtWebServiceInfo.CachePartition__c));
			httpRequest.setHeader('Authorization', 'Bearer ' + (String) Cache.Session.get(mdtWebServiceInfo.CachePartition__c));
		} else if (!String.isEmpty(mdtWebServiceInfo.XApiKey__c)) {
			System.debug ('X_Api_Key=>>' + mdtWebServiceInfo.XApiKey__c);
			httpRequest.setHeader('x-api-key', (String) mdtWebServiceInfo.XApiKey__c);
		}
        if(mdtWebServiceInfo.ContentType__c != null)  httpRequest.setHeader('content-type', mdtWebServiceInfo.ContentType__c);
        return httpRequest;
    }

    private static String formatUrl(String url, Map<String, String> urlParams) {
        if(urlParams == null) return url;
        
        String responseURL = url;
        for(String key : urlParams.keySet()) {
            System.debug('key ' + key);
            String formattedKey = '{' + key.trim() + '}';
            System.debug('formattedKey ' + formattedKey + ' responseURL ' + responseURL);
            System.debug('contains ' + responseURL.contains(formattedKey));
            if(responseURL.contains(formattedKey)) {
                System.debug('formattedKey ' + urlParams.get(key));
                responseURL = responseURL.replace(formattedKey, urlParams.get(key));
            }
        }
        system.debug('@@@@formatUrl[responseURL]: ' + responseURL);
        return responseURL;
    }

    public static String calloutWSToken(WebServiceTokens__mdt mtdWebServiceTokens) {
        ServiceHelper_cls.TokenResponse objToken = new ServiceHelper_cls.TokenResponse();
        HttpRequest httpReq = new HttpRequest();
        String paramsURL    = urlEncode(getParamsToken(mtdWebServiceTokens));
        httpReq.setEndpoint(mtdWebServiceTokens.URL__c + paramsURL);
        httpReq.setMethod(mtdWebServiceTokens.Method__c);
        httpReq.setTimeout(Integer.valueOf(mtdWebServiceTokens.Timeout__c));

        if( String.isNotBlank(mtdWebServiceTokens.ContentType__c) )   httpReq.setHeader('Content-Type', mtdWebServiceTokens.ContentType__c);
        if( String.isNotBlank(mtdWebServiceTokens.Authorization__c) ) httpReq.setHeader('Authorization', mtdWebServiceTokens.Authorization__c);
        if( String.isNotBlank(mtdWebServiceTokens.ContentLength__c) ) httpReq.setHeader('Content-Length', mtdWebServiceTokens.ContentLength__c);

        //httpReq.setBody(payload);
        Http http = new Http();

        system.debug('@@@@calloutWSToken[httpReq]: '+httpReq);
        HTTPResponse httpRes = http.send(httpReq);
        system.debug('@@@@calloutWSToken[httpRes]: '+httpRes);
        if(httpRes != null && httpRes.getStatusCode() == 200) {
            try {
                objToken = (ServiceHelper_cls.TokenResponse)System.JSON.deserialize(httpRes.getBody(), ServiceHelper_cls.TokenResponse.class);
                system.debug('@@@@calloutWSToken[TokenResponse]: '+objToken);
                return objToken.accessToken;
            } catch(Exception e) {
                System.debug(e);
                return null;
            }
        } else if(httpRes == null || (httpRes.getStatusCode() == 400 || httpRes.getStatusCode() == 403 || httpRes.getStatusCode() == 404 || httpRes.getStatusCode() == 405 || httpRes.getStatusCode() == 503)) {
            return null;
        }
        return null;
    }

    public static String urlEncode(Map<String, String> vals) {
        String result = '';
        for(String thisKey : vals.keySet()) result += EncodingUtil.urlEncode(thisKey, 'UTF-8') + '=' + EncodingUtil.urlEncode(vals.get(thisKey), 'UTF-8') + '&';
        
        return result.removeEnd('&');
    }

    public static  Map<String, String> getParamsToken(WebServiceTokens__mdt mtdWebServiceTokens){
        Map<String, String> mapParams= new Map<String, String>();
        if( String.isNotBlank(mtdWebServiceTokens.Username__c) )     mapParams.put('username',mtdWebServiceTokens.Username__c);
        if( String.isNotBlank(mtdWebServiceTokens.Password__c) )     mapParams.put('password',mtdWebServiceTokens.Password__c);
        if( String.isNotBlank(mtdWebServiceTokens.GrantType__c) )    mapParams.put('grant-type',mtdWebServiceTokens.GrantType__c);
        if( String.isNotBlank(mtdWebServiceTokens.ClientID__c) )     mapParams.put('client_id',mtdWebServiceTokens.ClientID__c);
        if( String.isNotBlank(mtdWebServiceTokens.ClientSecret__c) ) mapParams.put('client_secret',mtdWebServiceTokens.ClientSecret__c);

        return mapParams;
    }

    public class TokenResponse {
        private String accessToken;
        private String clientId;
        private String tokenType;
        private String issuedAt;
        private String expiresIn;
        private String status;
        private String scopes;
    }
}