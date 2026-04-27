/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_AccessToken_Utility
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 01/01/2023
 * ------------------------------------------------------------------------------------------------
 * @Description Class that implements the Integration_Auth_Interface
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 01/01/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public with sharing class F3_AccessToken_Utility implements Integration_Auth_Interface {
	/** ------------------------------------------------------------------------------------------------
	 * @Description get the auth header from the response and returns it on map <authHeader: Token>
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param 	 Map<String, Object> authCalloutResponse
	 * @return   Map<String, Object>
	 * @example  Map<String, Object> authHeaders = authClass.accessToken((Map<String, Object>) authCallout.serviceResponse);
	 * ------------------------------------------------------------------------------------------------**/
	public static Map<String, Object> accessToken(String authCalloutResponse) {
		Map<String, Object> authResponseMap = (Map<String, Object>) JSON.deserializeUntyped(authCalloutResponse);
		Map<String, Object> authHeader = new Map<String, Object>();
		authHeader.put('Authorization', 'Bearer ' + authResponseMap.get('accessToken'));
		return authHeader;
	}
}