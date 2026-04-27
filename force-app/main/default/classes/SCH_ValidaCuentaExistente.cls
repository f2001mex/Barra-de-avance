/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Reingeniería scheduler
    Descripción     : Clase que contendrá la acción para validar si el número de cuenta o contrato existen y están
                        relacionados a una cuenta.

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-11-27      Salvador Ramírez	    Creación de la Clase.
*/
public  class SCH_ValidaCuentaExistente {
    public class objCuenta {
        @InvocableVariable
        public String BPOrContract;
    }
    public class Response {
        @InvocableVariable
        public Boolean blnExiste;
        @invocableVariable
        public String strAccountName;
        @InvocableVariable
        public String strIdAccount;
        @InvocableVariable
        public String strPhone;
        @InvocableVariable
        public String strEmail;
    }
    @InvocableMethod(label='Validar cuenta por contrato o correo')
    public static List<Response> validaCuentaExistente(List<objCuenta> lstCuentas) {
        List<Response> lstRespuesta = new List<Response>();
        List<Telefono_de_Contrato__c> lstTel = new List<Telefono_de_Contrato__c>();
        List<Correo_de_Contrato__c> lstEmail = new List<Correo_de_Contrato__c>();
        Response resp = new Response();
        Account objAcc = new Account();
        Contract objContract = new Contract();
        Telefono_de_Contrato__c objTel = new Telefono_de_Contrato__c();
        Correo_de_Contrato__c objEmail = new Correo_de_Contrato__c();
        SCH_SchedulerFunctions_cls.wpDataClient wpDataClient = new SCH_SchedulerFunctions_cls.wpDataClient();
        wpDataClient = SCH_SchedulerFunctions_cls.validarCuentaExistente(lstCuentas[0].BPOrContract);
        resp.blnExiste = wpDataClient.blnEncontradoPorCuenta ? true : wpDataClient.blnEncontradoPorContrato ? true : false;
        if(resp.blnExiste){
            objAcc = wpDataClient.blnEncontradoPorCuenta ? wpDataClient.objAcc : null;
            objContract = wpDataClient.blnEncontradoPorContrato ? wpDataClient.objContract : null;
            lstTel = wpDataClient.blnEncontradoPorContrato ? objContract.Telefono_de_Contratos__r : wpDataClient.blnEncontradoPorCuenta ? objAcc.Contracts[0].Telefono_de_Contratos__r : null;
            lstEmail = wpDataClient.blnEncontradoPorContrato ? objContract.Contrato__r : wpDataClient.blnEncontradoPorCuenta ? objAcc.Contracts[0].Contrato__r : null;
            objTel = BIT_SendMedalliaSurvey_ctr.getPrincipalPhone(lstTel);
            objEmail = BIT_SendMedalliaSurvey_ctr.getPrincipalEmail(lstEmail);
            resp.strAccountName = wpDataClient.blnEncontradoPorContrato ? objContract.Account.Name : wpDataClient.blnEncontradoPorCuenta ? objAcc.Name : '';
            resp.strIdAccount = wpDataClient.blnEncontradoPorContrato ? objContract.AccountId : wpDataClient.blnEncontradoPorCuenta ? objAcc.Id : '';
            resp.strEmail = BIT_SendMedalliaSurvey_ctr.getPrincipalEmail(lstEmail).Contract_email__c;
            resp.strPhone = BIT_SendMedalliaSurvey_ctr.getPrincipalPhone(lstTel).Phone__c;
        }
        lstRespuesta.add(resp);
        return lstRespuesta;
    }
}