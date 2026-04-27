/****************************************************************************************************
Desarrollado por : VASS MÉXICO
Proyecto         : -
Descripción      : Clase para llamar y crear instancias de todos los servicios web utilizados.

Cambios (Versiones)
-----------------------------------------------------------------------------------------------------
No.     Fecha           Autor                   Descripción
-----   ----------      --------------------    -----------------------------------------------------
1.0     2024-08-14      VASS MÉXICO			    Creación de la Clase.                                       
*/
public class Bitacora_Callouts_cls {
	@TestVisible
	private static String buildErrorMessage (Integer statusCode) {
		return statusCode >= 400 && statusCode < 500 ? 'Datos erróneos, favor de intentarlo nuevamente.' : 'Error al obtener la información del servidor.';
	}
	public class MEDALLIA_SendSurvey_WebService extends ServiceVirtual_cls {
        public MEDALLIA_SendSurvey_WebService() {
            mdtName      = 'MEDALLIA_SendSurvey_WebService';
            responseBody = new BIT_Medallia_Response();
        }
        public override void manageErrorStatus ( HTTPResponse response ) {
            System.debug('@Error Response: ' + response.getBody() );
            ServiceException serviceException = new ServiceException();
            serviceException.aplicacionOrigen     = 'MEDALLIA_SendSurvey_WebService';
            serviceException.status               = response.getStatus();
            serviceException.statusCode           = response.getStatusCode();
            serviceException.requestBody          = this.requestBodyJSON;
            serviceException.responseBody         = response.getBody();
            serviceException.webServiceName       = this.mdtName;
            
            String message = 'There was a problem calling the HOST service: ' + response.getStatusCode() + ' not expected!';
            serviceException.setMessage( message );
            system.debug('@ServiceExceptionMessage' + message);
            system.debug('@ServiceException' + serviceException);
            throw serviceException;
        }
    }
    public class Doctos_GetOTP extends ServiceVirtual_cls{
        public Doctos_GetOTP(){
            mdtName = 'Doctos_GetOTP';
            responseBody = new BIT_GetOTP_Response();
        }
        public override void manageErrorStatus ( HTTPResponse response ) {
            System.debug('@Error Response: ' + response.getBody() );
            ServiceException serviceException = new ServiceException();
            serviceException.aplicacionOrigen     = 'Doctos_GetOTP';
            serviceException.status               = response.getStatus();
            serviceException.statusCode           = response.getStatusCode();
            serviceException.requestBody          = this.requestBodyJSON;
            serviceException.responseBody         = response.getBody();
            serviceException.webServiceName       = this.mdtName;
            String message = buildErrorMessage(serviceException.statusCode);
            // String message = 'There was a problem calling the HOST service: ' + response.getStatusCode() + ' not expected!';
            serviceException.setMessage( message );
            system.debug('@ServiceExceptionMessage' + message);
            system.debug('@ServiceException' + serviceException);
            throw serviceException;
        }
    }
	public class BIT_GetTokenCF extends ServiceVirtual_cls {
		public BIT_GetTokenCF() {
			mdtName = 'Doctos_TokenCF';
			responseBody = new BIT_GetTokenCF_Response();
		}
		public override void manageErrorStatus(HttpResponse response) {
			ServiceException serviceException = new ServiceException();
			serviceException.aplicacionOrigen     = 'Doctos_TokenCF';
			serviceException.status               = response.getStatus();
			serviceException.statusCode           = response.getStatusCode();
			serviceException.requestBody          = this.requestBodyJSON;
			serviceException.responseBody         = response.getBody();
			serviceException.webServiceName       = this.mdtName;
			String message = buildErrorMessage(serviceException.statusCode);
			// String message = 'There was a problem calling the HOST service: ' + response.getStatusCode() + ' not expected!';
			serviceException.setMessage(message);
			throw serviceException;
		}
	}
	public class BIT_GetConstancies extends ServiceVirtual_cls {
		public BIT_GetConstancies() {
			mdtName = 'Doctos_GetConstancies';
			responseBody = new BIT_GetConstancies_Response();
		}
		public override void manageErrorStatus(HttpResponse response) {
			ServiceException serviceException = new ServiceException();
			serviceException.aplicacionOrigen     = 'Doctos_GetConstancies';
			serviceException.status               = response.getStatus();
			serviceException.statusCode           = response.getStatusCode();
			serviceException.requestBody          = this.requestBodyJSON;
			serviceException.responseBody         = response.getBody();
			serviceException.webServiceName       = this.mdtName;
			String message = buildErrorMessage(serviceException.statusCode);
			// String message = 'There was a problem calling the HOST service: ' + response.getStatusCode() + ' not expected!';
			serviceException.setMessage(message);
			throw serviceException;
		}
	}
	public class BIT_SendConstancie extends ServiceVirtual_cls {
		public BIT_SendConstancie() {
			mdtName = 'Doctos_SendConstancies';
			responseBody = new BIT_SendConstancie_Response();
		}
		public override void manageErrorStatus(HttpResponse response) {
			ServiceException serviceException = new ServiceException();
			serviceException.aplicacionOrigen     = 'Doctos_SendConstancies';
			serviceException.status               = response.getStatus();
			serviceException.statusCode           = response.getStatusCode();
			serviceException.requestBody          = this.requestBodyJSON;
			serviceException.responseBody         = response.getBody();
			serviceException.webServiceName       = this.mdtName;
			String message = buildErrorMessage(serviceException.statusCode);
			// String message = 'There was a problem calling the HOST service: ' + response.getStatusCode() + ' not expected!';
			serviceException.setMessage(message);
			throw serviceException;
		}
	}
	public class BIT_GetStatements extends ServiceVirtual_cls {
		public BIT_GetStatements() {
			mdtName = 'Doctos_GetStatements';
			responseBody = new BIT_GetStatements_Response();
		}
		public override void manageErrorStatus(HttpResponse response) {
			ServiceException serviceException = new ServiceException();
			serviceException.aplicacionOrigen     = 'Doctos_GetStatements';
			serviceException.status               = response.getStatus();
			serviceException.statusCode           = response.getStatusCode();
			serviceException.requestBody          = this.requestBodyJSON;
			serviceException.responseBody         = response.getBody();
			serviceException.webServiceName       = this.mdtName;
			String message = buildErrorMessage(serviceException.statusCode);
			// String message = 'There was a problem calling the HOST service: ' + response.getStatusCode() + ' not expected!';
			serviceException.setMessage(message);
			throw serviceException;
		}
	}
	public class BIT_SendStatements extends ServiceVirtual_cls {
		public BIT_SendStatements() {
			mdtName = 'Doctos_SendStatements';
			responseBody = new BIT_SendStatements_Response();
		}
		public override void manageErrorStatus(HttpResponse response) {
			ServiceException serviceException = new ServiceException();
			serviceException.aplicacionOrigen     = 'Doctos_SendStatements';
			serviceException.status               = response.getStatus();
			serviceException.statusCode           = response.getStatusCode();
			serviceException.requestBody          = this.requestBodyJSON;
			serviceException.responseBody         = response.getBody();
			serviceException.webServiceName       = this.mdtName;
			String message = buildErrorMessage(serviceException.statusCode);
			// String message = 'There was a problem calling the HOST service: ' + response.getStatusCode() + ' not expected!';
			serviceException.setMessage(message);
			throw serviceException;
		}
	}
}