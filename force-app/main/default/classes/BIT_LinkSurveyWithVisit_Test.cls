/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-10-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class BIT_LinkSurveyWithVisit_Test {
	@TestSetup
    static void createData(){
        Account objAcc = BIT_UtilityDataTest.createAccount();
        Contract objContract = BIT_UtilityDataTest.createContract(objAcc);
        BranchUnit objSuc = BIT_UtilityDataTest.createBranchUnit();
        Visita__c objVisita = BIT_UtilityDataTest.createVisita(objAcc, objContract, objSuc);
    }
    @isTest
    static void test1(){
        test.startTest();
        Visita__c objVisita = [SELECT ID, EncuestaEnviada__c, Cuenta__r.Client_ID__c, Contrato__r.IDSap__c  FROM VISITA__C LIMIT 1];
        objVisita.EncuestaEnviada__c = true;
        Datetime dtSalida = Datetime.newInstance(System.today().year(), System.today().month(), System.today().day(), 10,0,0);
        system.debug('hora salida: ' + dtSalida);
        objVisita.ExternalID__c = BIT_SendMedalliaSurvey_ctr.getExternalID(objVisita.Cuenta__r.Client_ID__c, objVisita.Contrato__r.IDSap__c, dtSalida, System.today());
        update objVisita;
        CR_ME_Encuestas_Medallia__c objEncuesta = BIT_UtilityDataTest.createMedalliaSurvey(objVisita.Cuenta__r);
        BIT_LinkSurveyWithVisit_bch batch = new BIT_LinkSurveyWithVisit_bch();
        Database.executeBatch(batch);
        test.stopTest();
    }
    @isTest
    static void test2(){
        test.startTest();
        String CRON_EXP = '0 0 0 * * ?';
        String jobId = System.schedule('BIT_LinkSurveyWithVisit_bch', CRON_EXP, new BIT_LinkSurveyWithVisit_sch());
        test.stopTest();
    }
}