/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase Controlador del componente BIT_ConsultaDocumentos_lwc encargado del encio de encuesta a Medallia

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-08-20      Salvador Ramírez	    Creación de la Clase.
*/
public with sharing class BIT_ConsultaDocumentos_ctr {
	/**
	* @description Método para solicitar el código OTP conforme los datos del cliente
	* @author erik.romero@vasscompany.com | 06-12-2024 
	* @param strContractNumber Número de contrato para consultar
	* @param blMailNotification Indicador de envío de correo
	* @return Integer Status de respuesta del servicio
	**/
	@AuraEnabled
	public static String getOTP(String strContractNumber, Boolean blMailNotification) {
		BIT_GetOTP_Request request = new BIT_GetOTP_Request();
		Contract objContract = new Contract();
		try {
			String strPhone = '';
			List<Contract> lstContract = BIT_ConsultaDocumentos_soql.getContractInfo(strContractNumber);
			Map<String, Object> mapParameters = new Map<string, Object>();
			Telefono_de_Contrato__c objTelefono = new Telefono_de_Contrato__c();
			if(lstContract.size() > 0){
				objContract = lstContract[0];
				objTelefono = getPrincipalPhone(objContract.Telefono_de_Contratos__r);
				if (objTelefono.Phone__c != null) {
					strPhone = objTelefono.Phone__c;
					strPhone = strPhone.substring(strPhone.length() - 4);
				} else {
					NullPointerException nullException = new NullPointerException();
					nullException.setMessage('Teléfono inválido');
					throw nullException;
				}
			}
			mapParameters.put('clientNumber', Integer.valueOf(objContract.Account.Client_ID__c));
			mapParameters.put('lastDigitsPhoneNumber', strPhone);
			mapParameters.put('mailNotificationFlag', String.valueOf(blMailNotification));
			request = BIT_GetOTP_Payload.getRequest(mapParameters);
			BIT_GetOTP_Response response = (BIT_GetOTP_Response) Callout_cls.callService(new Bitacora_Callouts_cls.Doctos_GetOTP(), request);
			return String.valueOf(response.status);
		} catch(ServiceException serviceException) {
			System.debug ('serviceError=>>' + ServiceException.getMessage());
			generateLogError('SERVICE_ERROR_OTP', ServiceException.getMessage(), JSON.serializePretty(request));
			return serviceException.getMessage();
		} catch (Exception executionException) {
			System.debug ('executionException=>>' + executionException.getMessage());
			generateLogError('EXECUTION_ERROR_OTP', executionException.getMessage(), JSON.serializePretty(request));
			return executionException.getMessage();
		}
	}
	@AuraEnabled
	public static String getTokenCF(String strContractNumber, String strOTPCode) {
		BIT_GetTokenCF_Request request = new BIT_GetTokenCF_Request();
		Contract objContract = new Contract();
		try {
			List<Contract> lstContract = BIT_ConsultaDocumentos_soql.getContractInfo(strContractNumber);
			objContract = lstContract.size() > 0 ? lstContract [0] : objContract;
			Map<String, Object> mapParameters = new Map<string, Object>();
			mapParameters.put('userId', String.valueOf(objContract.Account.Client_ID__c));
			mapParameters.put('password', strOTPCode);
			request = BIT_GetTokenCF_Payload.getRequest(mapParameters);
			BIT_GetTokenCF_Response response = (BIT_GetTokenCF_Response) Callout_cls.callService(new Bitacora_Callouts_cls.BIT_GetTokenCF(), request);
			Cache.Session.put('local.partitionCF.tokenCF', response.accessToken);
			return String.valueOf(response.status);
		} catch (ServiceException serviceException) {
			System.debug ('erBody=>>' + json.deserializeUntyped(ServiceException.responseBody));
			generateLogError('SERVICE_ERROR_TOKENCF', ServiceException.getMessage(), JSON.serializePretty(request));
			return serviceException.getMessage();
		} catch (Exception executionException) {
			System.debug ('executionException=>>' + executionException.getMessage());
			generateLogError('EXECUTION_ERROR_TOKENCF', executionException.getMessage(), JSON.serializePretty(request));
			return executionException.getMessage();
		}
	}
	@AuraEnabled
	public static String GetConstancies (String strContractNumber) {
		BIT_GetConstancies_Request request = new BIT_GetConstancies_Request();
		Contract objContract = new Contract();
		try {
			List<Contract> lstContract = BIT_ConsultaDocumentos_soql.getContractInfo(strContractNumber);
			objContract = lstContract.size() > 0 ? lstContract [0] : objContract;
			Map<String, Object> mapParameters = new Map<string, Object>();
			mapParameters.put('contractNumber', strContractNumber);
			request = BIT_GetConstancies_Payload.getRequest(mapParameters);
			BIT_GetConstancies_Response response = (BIT_GetConstancies_Response) Callout_cls.callService(new Bitacora_Callouts_cls.BIT_GetConstancies(), request);
			return JSON.serialize(response.payload);
		} catch (ServiceException serviceException) {
			System.debug ('serviceError=>>' + ServiceException.getMessage());
			generateLogError('SERVICE_ERROR_GETCONSTANCIES', ServiceException.getMessage(), JSON.serializePretty(request));
			return serviceException.getMessage();
		} 
		catch (Exception executionException) {
			System.debug ('executionException=>>' + executionException.getMessage());
			generateLogError('EXECUTION_ERROR_GETCONSTANCIES', executionException.getMessage(), JSON.serializePretty(request));
			return executionException.getMessage();
		}
	}
	@AuraEnabled
	public static String SendConstancie (String strContractNumber, String strPeriod, String strPassword) {
		BIT_SendConstancie_Request request = new BIT_SendConstancie_Request();
		Contract objContract = new Contract();
		try {
			List<Contract> lstContract = BIT_ConsultaDocumentos_soql.getContractInfo(strContractNumber);
			objContract = lstContract.size() > 0 ? lstContract [0] : objContract;
			Map<String, Object> mapParameters = new Map<string, Object>();
			mapParameters.put('contractNumber', strContractNumber);
			mapParameters.put('password', strPassword);
			mapParameters.put('period', strPeriod);
			request = BIT_SendConstancie_Payload.getRequest(mapParameters);
			BIT_SendConstancie_Response response = (BIT_SendConstancie_Response) Callout_cls.callService(new Bitacora_Callouts_cls.BIT_SendConstancie(), request);
			createHistoryRecord(strContractNumber, new List<String> {strPeriod}, 'Constancia fiscal');
			return String.valueOf(response.status);
		} catch (ServiceException serviceException) {
			System.debug ('serviceError=>>' + ServiceException.getMessage());
			generateLogError('SERVICE_ERROR_SENDCONSTANCIE', ServiceException.getMessage(), JSON.serializePretty(request));
			return serviceException.getMessage();
		} 
		catch (Exception executionException) {
			System.debug ('executionException=>>' + executionException.getMessage());
			generateLogError('EXECUTION_ERROR_SENDCONSTANCIE', executionException.getMessage(), JSON.serializePretty(request));
			return executionException.getMessage();
		}
	}
	@AuraEnabled
	public static String GetStatements (String strContractNumber) {
		BIT_GestStatements_Request request = new BIT_GestStatements_Request();
		Contract objContract = new Contract();
		try {
			List<Contract> lstContract = BIT_ConsultaDocumentos_soql.getContractInfo(strContractNumber);
			objContract = lstContract.size() > 0 ? lstContract [0] : objContract;
			Map<String, Object> mapParameters = new Map<string, Object>();
			mapParameters.put('contractNumber', strContractNumber);
			request = BIT_GetStatements_Payload.getRequest(mapParameters);
			BIT_GetStatements_Response response = (BIT_GetStatements_Response) Callout_cls.callService(new Bitacora_Callouts_cls.BIT_GetStatements(), request);
			return JSON.serialize(response.payload);
		} catch (ServiceException serviceException) {
			System.debug ('serviceError=>>' + ServiceException.getMessage());
			generateLogError('SERVICE_ERROR_GETSTATEMENTS', ServiceException.getMessage(), JSON.serializePretty(request));
			return serviceException.getMessage();
		} 
		catch (Exception executionException) {
			System.debug ('executionException=>>' + executionException.getMessage());
			generateLogError('EXECUTION_ERROR_GETSTATEMENTS', executionException.getMessage(), JSON.serializePretty(request));
			return executionException.getMessage();
		}
	}
	@AuraEnabled
	public static String SendStatements (String strContractNumber, List<String> lstPeriods, String strPassword) {
		BIT_SendStatements_Request request = new BIT_SendStatements_Request();
		Contract objContract = new Contract();
		try {
			List<Contract> lstContract = BIT_ConsultaDocumentos_soql.getContractInfo(strContractNumber);
			objContract = lstContract.size() > 0 ? lstContract [0] : objContract;
			Map<String, Object> mapParameters = new Map<string, Object>();
			mapParameters.put('contractNumber', strContractNumber);
			mapParameters.put('password', strPassword);
			for (String period: lstPeriods) {
				mapParameters.put('period' + period, period);
			}
			System.debug ('params=>>' + mapParameters);
			request = BIT_SendStatements_Payload.getRequest(mapParameters);
			BIT_SendStatements_Response response = (BIT_SendStatements_Response) Callout_cls.callService(new Bitacora_Callouts_cls.BIT_SendStatements(), request);
			createHistoryRecord(strContractNumber, lstPeriods, 'Estado de cuenta');
			return String.valueOf(response.status);
		} catch (ServiceException serviceException) {
			System.debug ('serviceError=>>' + ServiceException.getMessage());
			generateLogError('SERVICE_ERROR_SENDSTATEMENTS', ServiceException.getMessage(), JSON.serializePretty(request));
			return serviceException.getMessage();
		} 
		catch (Exception executionException) {
			System.debug ('executionException=>>' + executionException.getMessage() + executionException.getLineNumber());
			generateLogError('EXECUTION_ERROR_SENDSTATEMENTS', executionException.getMessage(), JSON.serializePretty(request));
			return executionException.getMessage();
		}
	}
	@future
	private static void createHistoryRecord (String strContractNumber, List<String> lstPeriods, String strRequestType) {
		List<Contract> lstContract = BIT_ConsultaDocumentos_soql.getContractInfo(strContractNumber);
		HistoricoEnvio__c objHistory = new HistoricoEnvio__c(
			Cliente__c = lstContract[0].AccountId,
			Contrato__c = lstContract[0].Id,
			PeriodosSolicitados__c = String.join(lstPeriods, ';'),
			Formatos__c = 'PDF;XML',
			TipoSolicitud__c = strRequestType,
			TotalSolicitados__c = lstPeriods.size(),
			CFEnvio__c = BIT_ConsultaDocumentos_soql.getCFEnvio(),
			IdentificadorCliente__c = lstContract[0].Account.Client_ID__c
		);
		Database.insert(objHistory);
	}
    public static Telefono_de_Contrato__c getPrincipalPhone(List<Telefono_de_Contrato__c> lstTel){
        Datetime dtLastDay = null;
        Telefono_de_Contrato__c objPhone = new Telefono_de_Contrato__c();
        for(Telefono_de_Contrato__c objTel : lstTel){
            if(!objTel.principal__c){
                if(dtLastDay != null && objTel.CreatedDate > dtLastDay || dtLastDay == null){
                    objPhone = objTel;
                }
                dtLastDay = objTel.CreatedDate;
            } else {
                objPhone = objTel;
                break;
            }
        }
        return objPhone;
    }
	private static void generateLogError (String strErrorCode, String strMessage, String strRequest) {
		EventLogger.error(new Map<String, String>{
			'contextId' => null,
			'type' => '',
			'errorCode' => strErrorCode,
			'message' => strMessage,
			'request' => strRequest});
	}
}