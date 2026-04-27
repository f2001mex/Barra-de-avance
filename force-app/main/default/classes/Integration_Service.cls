/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     Integration_Service
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 01/01/2023
 * ------------------------------------------------------------------------------------------------
 * @Description Integration engine
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 01/01/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public with sharing class Integration_Service {
	@TestVisible
	private static Map<String, Object> testSettings;
	/** ------------------------------------------------------------------------------------------------
	 * @Description Start execution of the integration engine and logs the results
	 * ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     01/01/2023
	 * @param 	 String serviceName,
	 * @param 	 String requestBody,
	 * @param 	 Map<String, String> queryStringData,
	 * @param 	 Map<String, Object> bodyTemplateData,
	 * @param 	 Boolean wantRawBody
	 * @return   ServiceResponse
	 * @example  Integration_Service.ServiceResponse response = Integration_Service.calloutService(serviceName, requestBody, queryStringData, bodyTemplateData, wantRawBody);
	 * ------------------------------------------------------------------------------------------------**/
	public static ServiceResponse calloutService(
		String serviceName,
		String requestBody,
		Map<String, Object> queryStringData,
		Map<String, Object> bodyTemplateData,
		Boolean wantRawBody
	) {
		Integration_Handler calloutExecution = new Integration_Handler(
			serviceName,
			requestBody,
			queryStringData,
			bodyTemplateData,
			wantRawBody,
			testSettings
		);
		try {
			ServiceResponse response = calloutExecution.invoke();
			return response;
		} catch (Exception error) {
			throw new Integration_Handler.Integration_Service_Exception(error.getMessage());
		} finally {
			for (Integration_Logger_Service logger : calloutExecution.loggerList) {
				logger.upsertLogger();
			}
			calloutExecution = null;
		}
	}

	/**
	 *   ------------------------------------------------------------------------------------------------
	 * @Name     ServiceResponse
	 * @Author   luis.felipe.ortiz@pwc.com
	 * @Date     Created: 01/01/2023
	 * ------------------------------------------------------------------------------------------------
	 * @Description Wrapper class to encapsulate the relevant data of the integration
	 * ------------------------------------------------------------------------------------------------
	 * @Changes
	 * 01/01/2023 luis.felipe.ortiz@pwc.com
	 *             Class creation.
	 * ------------------------------------------------------------------------------------------------
	 **/
	public class ServiceResponse {
		public String serviceCode { get; set; }
		public String serviceMessage { get; set; }
		public Object serviceResponse { get; set; }
		public Map<String, String> serviceHeaders { get; set; }
		public Integration_Logger_Service logger { get; set; }
	}
}