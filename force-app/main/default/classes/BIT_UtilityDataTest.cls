/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase que generará data de pruebas para clases test.

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-09-05     Salvador Ramírez        Creación de la Clase.
*/
public class BIT_UtilityDataTest {
    public static Account createAccount(){
        Account objAcc = new Account();
        objAcc.FirstName = 'Test';
        objAcc.MiddleName = 'Test';
        objAcc.LastName = 'Test';
        objAcc.F3_CURP__c = 'TESTING1';
        objAcc.Client_ID__c = '123456789';
        objAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        insert objAcc;
        return objAcc;
    }
    public static Contract createContract(Account objAcc){
        Contract objContract = new Contract();
        objContract.AccountId = objAcc.Id;
        objContract.ContractNumber__c = '142536';
        objContract.Status__c = 'Aprobado.';
        objContract.IDSap__c = '142536';
        objContract.ID_ASESOR__c = '1234';
        insert objContract;
        return objContract;
    }
    public static Telefono_de_Contrato__c createPhones(Contract objContract){
        Telefono_de_Contrato__c objTel = new Telefono_de_Contrato__c();
        objTel.Name = 'Test';
        objTel.IDSap__c = objContract.Id;
        objTel.Phone_Type__c = 'CELULAR';
        objTel.Phone__c = '2711768347';
        objTel.principal__c = false;
        insert objTel;
        return objTel;
    }
    public static Correo_de_Contrato__c createEmails(Contract objContract){
        Correo_de_Contrato__c objEmail = new Correo_de_Contrato__c();
        objEmail.Name = 'Test';
        objEmail.NUM_CONTRATO__c = objContract.Id;
        objEmail.Contract_email__c = 'test@mail.com';
        objEmail.Principal__c = false;
        insert objEmail;
        return objEmail;
    }
    public static BranchUnit createBranchUnit(){
        BranchUnit objSuc = new BranchUnit();
        objSuc.Name = 'Test';
        objSuc.IsActive = true;
        insert objSuc;
        return objSuc;
    }
    public static Visita__c createVisita(Account objAcc, Contract objContract, BranchUnit objSuc){
        Visita__c objVisita = new Visita__c();
        objVisita.Cuenta__c = objAcc.Id;
        objVisita.Contrato__c = objContract.Id;
        objVisita.RecordTypeId = Schema.SObjectType.Visita__c.getRecordTypeInfosByName().get('Cliente').getRecordTypeId();
        objVisita.CentroFinanciero__c = objSuc.Id;
        objVisita.HoraEntradaVisita__c = System.now();
        insert objVisita;
        return objVisita;
    }
    public static Servicio__c createServicio(Visita__c objVisita){
        Servicio__c objServ = new Servicio__c();
        objServ.Visita__c = objVisita.Id;
        objServ.TipoVisita__c = 'Cliente';
        objServ.Motivo__c = 'Trámites Administrativos';
        objServ.Submotivo__c = 'Actualización Datos Videollamada';
        objServ.QuienAtiende__c = 'CAT';
        insert objServ;
        return objServ;
    }
    public static CR_ME_Encuestas_Medallia__c createMedalliaSurvey(Account objAcc){
        CR_ME_Encuestas_Medallia__c objEncuesta = new CR_ME_Encuestas_Medallia__c(
            act_rel_sat_asesoria_scale11na__c = 'Alto', surveyid__c = '12345', CR_ME_Cliente_unico__c = objAcc.Id, contrato__c = '142536', FechaVisita__c = System.today(), HoraSalida__c = '10:00');
        insert objEncuesta;
        return objEncuesta;
    }
    public static void instanceMock4Services(Boolean isSuccess, Boolean isErrorServer, Map<String,String> endpointsMap) {
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
            multimock.setStaticResource(endpointsMap.get('MEDALLIA_SendSurvey_WebService'),(isSuccess == true ? 'mockSuccessSendSurvey' : 'mockErrorSendSurvey'));
            multimock.setStaticResource(endpointsMap.get('Accesstoken_Medallia')+'grant-type=client_credentials','mockSuccesToken');
            multimock.setStatusCode(isErrorServer ? 500 : 200);
        Test.setMock(HttpCalloutMock.class, multimock);
    }
      public static Map<String,String> getEndpointsMap() {
        Map<String,String> endpointsMap = new Map<String,String>();
 
        for (WebServiceInfo__mdt webServiceMdt : WebServiceInfo__mdt.getall().Values()){
            endpointsMap.put(webServiceMdt.DeveloperName, webServiceMdt.Endpoint__c);
        }
 
        for (WebServiceTokens__mdt webServiceTokenMdt : WebServiceTokens__mdt.getall().Values()){
            endpointsMap.put(webServiceTokenMdt.DeveloperName, webServiceTokenMdt.url__c);
        }
        return endpointsMap;
    }
}