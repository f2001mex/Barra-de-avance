/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     SCH_ServiceUtility_Trigger_Test
 * @Author   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
 * @Date     Created: 13/01/2025
 * @Group    VASS
 * ------------------------------------------------------------------------------------------------
 * @Description Clase Test para clase SCH_ServiceUtility_Trigger.
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         13/01/2025       Salvador Ramírez López             Class creation.
*--------------------------------------------------------------------------
 **/
@isTest
public class SCH_ServiceUtility_Trigger_Test {
    @isTest
    static void test_getActiveServiceTerritories(){
        Test.startTest();
        Object res = SCH_ServiceUtility_Trigger.getActiveServiceTerritories();
        Test.stopTest();
    }
    @isTest
    static void test_getChannels(){
        Test.startTest();
        Object res = SCH_ServiceUtility_Trigger.getChannels();
        Test.stopTest();
    }
    @isTest
    static void test_getCustomSettingDefaultValues(){
        Test.startTest();
        Object res = SCH_ServiceUtility_Trigger.getCustomSettingDefaultValues();
        Test.stopTest();
    }
    @isTest
    static void test_getWorkTypes(){
        Set<String> setTest = new Set<String>{'123','456'};
        Test.startTest();
        Object wp = new SCH_ServiceUtility_Trigger.wpResult();
        Object res = SCH_ServiceUtility_Trigger.getWorkTypes(setTest);
        Test.stopTest();
    }
}