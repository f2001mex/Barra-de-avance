/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     SCH_WorkTypeTrigger_Helper_Test
 * @Author   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
 * @Date     Created: 14/01/2025
 * @Group    VASS
 * ------------------------------------------------------------------------------------------------
 * @Description Clase test de la clase SCH_WorkTypeTrigger_Helper
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         14/01/2025       Salvador Ramírez López             Class creation.
*--------------------------------------------------------------------------
 **/
@isTest
public class SCH_WorkTypeTrigger_Helper_Test {
    @TestSetup
    static void makeData(){
        DefaultValuesScheduler__c objData = SCH_ServiceUtility_Test.createDefaultValues();
        OperatingHours objOH = SCH_ServiceUtility_Test.createOperatingHours();
        ServiceTerritory objServTerr = SCH_ServiceUtility_Test.createServiceTerritory(objOH);
        EngagementChannelType objECH = SCH_ServiceUtility_Test.createChannels();
    }
    @isTest
    static void test_CreateWorkTypes(){
        Test.startTest();
        List<WorkTypeGroup> lstWTG = SCH_ServiceUtility_Test.createWorkTypeGroups();
        Object res = SCH_WorkTypeTrigger_Helper.createWorkTypes(lstWTG);
        Test.stopTest();
    }
    @isTest
    static void test_createServiceTerritoryWorkType(){
        List<WorkType> lstWT = SCH_ServiceUtility_Test.createWorkTypes();
        insert lstWT;
        List<ServiceTerritory> lstST = SCH_ServiceUtility_Trigger.getActiveServiceTerritories();
        Test.startTest();
        SCH_WorkTypeTrigger_Helper.createServiceTerritoryWorkType(lstWT, lstST);
        Test.stopTest();
    }
    @isTest
    static void test_createWorkTypesGroupMember(){
        List<WorkTypeGroup> lstWTG = SCH_ServiceUtility_Test.createWorkTypeGroups();
        Set<String> setExternalIds = new Set<String>();
        for(WorkTypeGroup objWTG : lstWTG){
            setExternalIds.add(objWTG.External_ID__c);
        }
        List<WorkType> lstWT = SCH_ServiceUtility_Test.createWorkTypes();
        insert lstWT;
        Test.startTest();
        insert lstWTG;
            SCH_WorkTypeTrigger_Helper.createWorkTypesGroupMember(setExternalIds,lstWTG);
        Test.stopTest();
    }
    @isTest
    static void test_createEngagementChannelWorkTypes(){
        List<WorkType> lstWT = SCH_ServiceUtility_Test.createWorkTypes();
        insert lstWT;
        List<EngagementChannelType> lstECT = SCH_ServiceUtility_Trigger.getChannels();
        Test.startTest();
            SCH_WorkTypeTrigger_Helper.createEngagementChannelWorkTypes(lstWT, lstECT);
        Test.stopTest();
    }
}