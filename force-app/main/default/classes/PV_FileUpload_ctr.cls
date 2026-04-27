/**
 * @description       : Clase controlador del componente para cargar archivos en Salesforce y enviarlo a OpenText
 * @author            : Martin Martinez
 * @group             : 
 * @last modified on  : 08-20-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class PV_FileUpload_ctr {

    @AuraEnabled(cacheable=true)
    public static Task getTaskFields(Id taskId) {
        return [
            SELECT RefenciaOpenText__c, ClienteNoQuiereSerContactado__c
            FROM Task
            WHERE Id = :taskId
            LIMIT 1
        ];
    }

    public static String strSourceBanco = 'Contrato de Banco';
    public static String valorBanco= '999';
    public static String valorCasaDeBolsa= '998';
    public static String strPostVenta = 'MPV';
    public static String planeacionFinanciera = PSTA_UtilityClass.DEVELOPERNAME_PLANEACION_FINANCIERA;
    public static String propuestaInversion = PSTA_UtilityClass.DEVELOPERNAME_PROPUESTA_INVERSION;


    public class Resultado {
        @AuraEnabled public String resultado { get; set; }
        @AuraEnabled public String error { get; set; }
        @AuraEnabled public List<Contract> contratos;
        @AuraEnabled public Boolean mostrarContratos;
        @AuraEnabled public String referenciaOpenText;
    }
    
    public class ContractResult {
        @AuraEnabled public List<Contract> contratos;
        @AuraEnabled public Boolean mostrarContratos;
        @AuraEnabled public task tarea;
        @AuraEnabled public Boolean visibilidadComponente;
        @AuraEnabled public Boolean requiereEvidencia;
    }

    @AuraEnabled(cacheable=true)
    public static ContractResult getContractsByTaskId(Id recordId) {
        ContractResult resultado = new ContractResult();        

        if (recordId == null) {
            return resultado;
        }

        try {            
            if (String.valueOf(recordId).startsWith('00T')) {
                Task t = PV_FileUpload_soql.getTask(recordId);
                resultado.tarea = t;
                Boolean vsComponente = PV_FileUpload_soql.getCadence(t.DeveloperName__c);

                resultado.contratos = new List<Contract>();
                resultado.visibilidadComponente = vsComponente || t.ClienteNoQuiereSerContactado__c;
                resultado.requiereEvidencia = vsComponente;


                Id relatedId = t.AccountId;
                if (relatedId != null && String.valueOf(relatedId).startsWith('001')) {
                    List<Contract> ltsContratos = PV_FileUpload_soql.getListContractAccount(relatedId,t.DeveloperName__c);
                    resultado.mostrarContratos = !ltsContratos.isEmpty();
                    resultado.contratos = ltsContratos;
                }
            }           
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage() + ' - Línea: ' + ex.getLineNumber());
        }
        return resultado;
    }

    @AuraEnabled
    public static Resultado enviarArchivo(Task tarea, String recordIdContrato, String documentId, Boolean requiereEvidencia) {
        Resultado res = new Resultado();

        ContentVersion version = PV_FileUpload_soql.getVersionFile(documentId);

        String base64Content = EncodingUtil.base64Encode(version.VersionData);
        try {
            enviarArchivoFuture(tarea.Id, tarea.DeveloperName__c, tarea.WhoId, recordIdContrato, documentId, version.FileExtension, version.Title,base64Content, requiereEvidencia);
        } catch (Exception e) {
            System.debug('Excepción: ' + e.getMessage() + ' - Línea: ' + e.getLineNumber());
            res.error = 'Excepción: ' + e.getMessage();
            throw new CalloutException('Excepción en callout: ' + e.getMessage());
        }
        return res;
    }

    @AuraEnabled(cacheable=true)
    public static Resultado obtenerReferenciaOpenText(Id taskId) {
        Resultado res = new Resultado();
        Task tarea = PV_FileUpload_soql.getTask(taskId);
        res.referenciaOpenText = tarea.RefenciaOpenText__c;
        Boolean requiereEvidencia = PV_FileUpload_soql.getCadence(tarea.DeveloperName__c);

        if (requiereEvidencia) {
            res.contratos = new List<Contract>();
            List<Contract> ltsContratos = PV_FileUpload_soql.getListContractAccount(tarea.AccountId,tarea.DeveloperName__c);
            res.mostrarContratos = !ltsContratos.isEmpty();
            res.contratos = ltsContratos;
        }
        return res;
    }

    @future(callout=true)
    public static void enviarArchivoFuture(String taskId, String developerName, String accountId, String recordIdContrato, String documentId,String FileExtension, String Title, String base64Content, Boolean requiereEvidencia) {
        try {
            // Simulación del objeto Task
            Task tarea = PV_FileUpload_soql.getTask(taskId);//new Task(Id = taskId, DeveloperName__c = developerName);
            System.debug('tarea: '+tarea);

            Contract contrato = PV_FileUpload_soql.getContract(recordIdContrato);
            System.debug('contrato: '+contrato);

            PV_OpenText_Request request = PV_FileUpload_ctr.generarRequest(FileExtension,Title, base64Content, tarea, contrato);
            PV_OpenText_Response response = (PV_OpenText_Response) Callout_cls.callService(
                new PostVenta_Callouts_cls.PV_OpenText_WebService(),
                request
            );
             System.debug('@response: ' + response);

            if (response.status == 200) {
                PV_FileUpload_ctr.actualizarData(tarea, contrato, response.payload.referenceId);
            }

        } catch (Exception e) {
            System.debug('Excepción en enviarArchivoFuture: ' + e.getMessage() + ' - Línea: ' + e.getLineNumber());
        }
    }

    public static void actualizarData(Task tarea, Contract contrato, String referenciaOpentex){
        tarea.RefenciaOpenText__c = referenciaOpentex;
        update tarea;
        if (tarea.DeveloperName__c.contains(planeacionFinanciera)) {
            contrato.PlaneacionFinancieraCompletada__c = true;
        } else if (tarea.DeveloperName__c.contains(propuestaInversion)) {
            contrato.PropuestaInversionCompletada__c = true;
        }
        System.debug('contrato =>: '+contrato);
        update contrato;
    }
    /**
     * Modificada: 20/08/2025: Modificó: Salvador Ramírez. Se agregan campos clientId, clientName, advisorId, advisorName
     */
    public static PV_OpenText_Request generarRequest(String FileExtension, String Title,String base64Content,Task tarea, Contract contrato){
        PV_OpenText_Request request = new PV_OpenText_Request();
        request.contractNumber = contrato.ContractNumber__c;
        request.bankingArea = contrato.Source__c == strSourceBanco ? valorBanco : valorCasaDeBolsa;
        request.extension = FileExtension;
        request.fileName = Title;
        request.file = base64Content;
        request.instruction = !tarea.ClienteNoQuiereSerContactado__c ? strPostVenta : '';
        //20/08/2025 salvador: Se agregan campos de razonabilidad
        request.clientId = tarea.Account.Client_ID__c;
        request.clientName = tarea.Account.Name;
        request.advisorId = tarea.Account.Owner.ID_ASESOR__c;
        request.advisorName = tarea.Account.Owner.Name;
        return request;
    }

    @AuraEnabled
    public static Resultado eliminarArchivo(String documentId) {
        Resultado res = new Resultado();
        try {
            ContentDocument doc = PV_FileUpload_soql.getDocument(documentId);
            delete doc;

            res.resultado = 'Archivo eliminado exitosamente en SF.';
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + '. Linea: ' + e.getLineNumber());
            res.error = 'Error al eliminar el archivo: ' + e.getMessage();
        }
        return res;
    }    
}