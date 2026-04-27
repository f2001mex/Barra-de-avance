@IsTest
public class BIT_SendMedalliaSurvey_cls_Test {
	@TestSetup
    static void createData(){
        Account objAcc = BIT_UtilityDataTest.createAccount();
        Contract objContract = BIT_UtilityDataTest.createContract(objAcc);
        Telefono_de_Contrato__c objPhones = BIT_UtilityDataTest.createPhones(objContract);
        Correo_de_Contrato__c objEmails = BIT_UtilityDataTest.createEmails(objContract);
        BranchUnit objSuc = BIT_UtilityDataTest.createBranchUnit();
        Visita__c objVisita = BIT_UtilityDataTest.createVisita(objAcc, objContract, objSuc);
        Servicio__c objServ = BIT_UtilityDataTest.createServicio(objVisita);
    }
    @isTest
    static void test1(){
        test.startTest();
        test.setMock(HttpCalloutMock.class, new BIT_SendMedalliaSurvey_Mockup());
        Visita__c objVisita = [SELECT ID, HoraSalida__c FROM VISITA__C LIMIT 1];
        List<BIT_SendMedalliaSurvey_cls.parameters> lstId = new List<BIT_SendMedalliaSurvey_cls.parameters>();
        BIT_SendMedalliaSurvey_cls.parameters param = new BIT_SendMedalliaSurvey_cls.parameters();
        param.IdVisita = objVisita.Id;
        lstId.add(param);
        BIT_SendMedalliaSurvey_cls.calloutMedallia(lstId);
        test.stopTest();
    }
}