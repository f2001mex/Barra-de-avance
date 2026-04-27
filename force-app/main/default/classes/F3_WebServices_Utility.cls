/**
 *   ------------------------------------------------------------------------------------------------
 * Name     F3_WebServices_Utility
 * Author   luis.felipe.ortiz@pwc.com
 * Date     Created: 11/06/2022
 * Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * Description Utility Class for Apex Web Services
 *   ------------------------------------------------------------------------------------------------
 * Changes
 * 11/06/2022 Aranzazu Sereno
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public without sharing class F3_WebServices_Utility {
	/** ------------------------------------------------------------------------------------------------
	 * Create a JSON with the information of an Exception
	 * -------------------------------------------------------------------------------------------------
	 * author   luis.felipe.ortiz@pwc.com
	 * date     12/08/2022
	 * param    Exception error
	 * return   String
	 * example	F3_WebServices_Utility.exceptionToJson(error);
	 * ------------------------------------------------------------------------------------------------**/
	public static String exceptionToJson(Exception error) {
		Map<String, String> exceptionData = new Map<String, String>{
			'Traza' => error.getStackTraceString(),
			'Tipo' => error.getTypeName(),
			'Mensaje' => error.getMessage()
		};
		return JSON.serialize(exceptionData);
	}

	public static String generateHASH_VAL(String toHASH) {
		return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', blob.valueOf(toHASH))).toUpperCase();
	}
}