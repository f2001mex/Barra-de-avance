@isTest
public class ACT_AccountAPITest {
 @TestSetup
    static void testGetClienteInfo() {
       Account accFisica = new Account(
            FirstName = 'FISICA TEST',
            LastName = 'FISICA',
            Client_ID__c = '1234',
            Person_Type__c = 'FISICA'
            , RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
        );
        insert accFisica;
        
        CR_ME_Encuestas_Medallia__c encuesta = new CR_ME_Encuestas_Medallia__c(
            act_rel_sat_asesoria_scale11na__c = 'Alto',
            surveyid__c = '332',
            CR_ME_Cliente_unico__c = accFisica.Id
        );
        insert encuesta;
    }
    
    
    @istest
    static void getResultsGr(){
        ACT_AccountAPI.objtask params = new ACT_AccountAPI.objtask();

        //Get FISICA
        params.BP = '1234';

        List<ACT_AccountAPI.ResultTask> result = ACT_AccountAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for FISICA.');
    }
    @istest
    static void getResultsGr1(){
        ACT_AccountAPI.objtask params = new ACT_AccountAPI.objtask();

        //Get FISICA
        params.BP = null;

        List<ACT_AccountAPI.ResultTask> result = ACT_AccountAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for FISICA.');
    }    
}