/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     Integration_Auth_Interface
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 01/01/2023
 * ------------------------------------------------------------------------------------------------
 * @Description Interface to implement authorization for the integration engine
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 01/01/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public interface Integration_Auth_Interface {
	/** ------------------------------------------------------------------------------------------------
	 * @Description get the auth header from the response and returns it on map <authHeader: Token>
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param 	 Map<String, Object> authCalloutResponse
	 * @return   Map<String, Object>
	 * @example  Map<String, Object> authHeaders = authClass.accessToken((Map<String, Object>) authCallout.serviceResponse);
	 * ------------------------------------------------------------------------------------------------**/
	Map<String, Object> accessToken(String authCalloutResponse);
}