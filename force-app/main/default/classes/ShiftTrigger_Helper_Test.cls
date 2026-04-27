/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     ShiftTrigger_Helper_Test
 * @Author   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
 * @Date     Created: 03/01/2025
 * @Group    VASS
 * ------------------------------------------------------------------------------------------------
 * @Description Clase test de la clase ShiftTrigger_Helper
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         14/01/2025       Salvador Ramírez López             Class creation.
*--------------------------------------------------------------------------
 **/
@isTest
public class ShiftTrigger_Helper_Test {
    @isTest
    static void test_createShiftEngagementChannel(){
        Shift objShift = SCH_ServiceUtility_Test.createTurnos();
        EngagementChannelType objChannel = SCH_ServiceUtility_Test.createChannels();
        DefaultValuesScheduler__c objData = SCH_ServiceUtility_Test.createDefaultValues();
        Test.startTest();
        ShiftTrigger_Helper.createShiftEngagementChannel(new List<Shift>{objShift}, new List<EngagementChannelType>{objChannel}, objData);
        Test.stopTest();
    }
}