/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     WorkTypeGroupTrigger_Test
 * @Author   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
 * @Date     Created: 03/01/2025
 * @Group    VASS
 * ------------------------------------------------------------------------------------------------
 * @Description Clase test de la clase WorkTypeGroupTrigger_Handler y su trigger.
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         03/01/2025       Salvador Ramírez López             Class creation.
*--------------------------------------------------------------------------
 **/
@isTest
public  class WorkTypeGroupTrigger_Test {
    @TestSetup
    static void makeData(){
        DefaultValuesScheduler__c objData = SCH_ServiceUtility_Test.createDefaultValues();
        OperatingHours objOH = SCH_ServiceUtility_Test.createOperatingHours();
        ServiceTerritory objServTerr = SCH_ServiceUtility_Test.createServiceTerritory(objOH);
        EngagementChannelType objECH = SCH_ServiceUtility_Test.createChannels();
    }
    @isTest
    static void test_Insert(){
        test.startTest();
        List<WorkTypeGroup> res = SCH_ServiceUtility_Test.createWorkTypeGroups();
        insert res;
        test.stopTest();
    }
}