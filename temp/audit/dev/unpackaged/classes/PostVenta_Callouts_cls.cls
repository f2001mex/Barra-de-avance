/**
 * @description       : Clase para llamar y crear instancias de todos los servicios web utilizados en Post Venta.
 * @author            : Martin Martinez
 * @group             : 
 * @last modified on  : 07-03-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class PostVenta_Callouts_cls {
    @TestVisible
	private static String buildErrorMessage (Integer statusCode) {
		return statusCode >= 400 && statusCode < 500 ? 'Datos erróneos, favor de intentarlo nuevamente.' : 'Error al obtener la información del servidor.';
	}
    public class PV_OpenText_WebService extends ServiceVirtual_cls {
        public PV_OpenText_WebService() {
            mdtName      = 'PV_OpenText_WebService';
            responseBody = new PV_OpenText_Response();
        }
        public override void manageErrorStatus ( HTTPResponse response ) {
            System.debug('@Error Response: ' + response.getBody() );
            ServiceException serviceException = new ServiceException();
            serviceException.aplicacionOrigen     = 'PV_OpenText_WebService';
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

    public class PV_EnvioEncuestaMedallia extends ServiceVirtual_cls {
        public PV_EnvioEncuestaMedallia(){
            mdtName = 'MEDALLIA_SendSurvey_WebService';
            responseBody = new BIT_Medallia_Response();
        }
        public override void manageErrorStatus(HttpResponse response) {
			ServiceException serviceException = new ServiceException();
			serviceException.aplicacionOrigen     = 'MEDALLIA_SendSurvey_WebService';
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