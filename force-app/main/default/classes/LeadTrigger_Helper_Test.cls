/** ------------------------------------------------------------------------------------------------
 * @Name     LeadTrigger_Helper_Test
 * @Author   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
 * @Date     08/04/2025
 * @Group    VASS Latam
 *   ------------------------------------------------------------------------------------------------
 * @Description Clase test de la clase LeadTrigger_Helper
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         08/04/2025       salvador.ramirez@vasscompany.com   Class creation.
*--------------------------------------------------------------------------
 **/
@isTest
public class LeadTrigger_Helper_Test {
    @TestSetup
    static void makeData(){
        OD_Account_cls.bypassTriggerExecution = true;
        User objUser = LeadTrigger_Utility.updateIDAsesorToUser();
        update objUser;
        F3_Integration_Service_Settings__c objService = LeadTrigger_Utility.createService();
        insert objService;
        BranchUnit objBranch = BIT_UtilityDataTest.createBranchUnit();
        Lead objLead = LeadTrigger_Utility.createLeadRTGeneral();
        insert objLead;
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId([SELECT Id FROM LEAD LIMIT 1].Id);
        leadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE MasterLabel = 'Convertido'];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(false);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
        Opportunity objOpp = [SELECT ID, NAME, PatrimConsecutivoIDLead__c, Fecha_de_Nacimiento_Cliente__c FROM OPPORTUNITY WHERE ID = :lcr.getOpportunityId()];
        objOpp.PatrimConsecutivoIDLead__c = '1234';
        objOpp.Productos_ofertados__c = '01';
        objOpp.Sub_Ramo__c = '1';
        objOpp.Fecha_de_Nacimiento_Cliente__c = System.today().addYears(-40);
        update objOpp;
    }
    @isTest
    static void test_branchUnitAssignment(){
        Test.startTest();
        LeadTrigger_Helper.branchUnitAssignment([SELECT Id, RecordTypeId, OwnerId, BanqueroAsignado__c FROM LEAD LIMIT 1]);
        Test.stopTest();
    }
    @isTest
    static void test_validateMandatoryFieldsIntegrateSAP(){
        ACTINVER_UtilityFactory_utils.WrapperValueFieldSet[] lstValueFieldSet = ACTINVER_UtilityFactory_utils.getValueFieldSet('MandatoryFieldsToIntegrateSAP', 'Lead');
        Test.startTest();
        sObject sObjLead = (sObject) [SELECT Id FROM LEAD LIMIT 1][0];
        Map<String, Object> mapDataSObjectLead = sObjLead.getPopulatedFieldsAsMap();
        Lead objLead = LeadTrigger_Utility.createLeadRTGeneral();
        Boolean blnIsValidRecord = LeadTrigger_Helper.validateMandatoryFieldsIntegrateSAP(objLead,mapDataSObjectLead, lstValueFieldSet);
        Test.stopTest();
    }
    @isTest
    static void test_updateOpportunity(){
        Test.startTest();
        List<Lead> lstLead = [SELECT Id, ConvertedAccountId FROM LEAD LIMIT 1];
        LeadTrigger_Helper.updateOpportunity(lstLead[0]);
        Test.stopTest();
    }
    @isTest
    static void test_updateLead(){
        Test.startTest();
        LeadTrigger_Helper.updateLead(new List<String>{[SELECT Id FROM LEAD].Id});
        Test.stopTest();
    }
    @isTest
    static void test_getAccountByLead(){
        Test.startTest();
        LeadTrigger_Helper.getAccountByLead(new List<String>{[SELECT Id FROM LEAD LIMIT 1].Id});
        Test.stopTest();
    }
    @isTest
    static void test_getOpportunityByAccount(){
        Test.startTest();
        Opportunity objOpp = LeadTrigger_Helper.getOpportunityByAccount([SELECT ConvertedAccountId FROM LEAD WHERE IsConverted = TRUE LIMIT 1].ConvertedAccountId);
        Test.stopTest();
    }
    @isTest
    static void test_LeadsAssignmentProcess(){
        test.startTest();
        LeadTrigger_Helper.LeadsAssignmentProcess([SELECT Id, CreatedById, RecordTypeId FROM LEAD LIMIT 1]);
        test.stopTest();
    }
}