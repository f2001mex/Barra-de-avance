@isTest
public class BIT_SendMedalliaSurvey_qbl_test {
	@TestSetup
    static void makeData(){
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
        test.setMock(HttpCalloutMock.class, new BIT_SendMedalliaSurvey_Mockup());
        Set<Id> setIds = new Set<Id>();
        for(Visita__c objVisita : [SELECT ID FROM VISITA__C]){
            setIds.add(objVisita.Id);
        }
        System.Queueable job = new BIT_SendMedalliaSurvey_qbl(new map<String, Set<Id>>{'idVisita' => setIds});
        test.startTest();
        System.enqueueJob(job);
        test.stopTest();
    }
}