/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     ShiftTrigger_Test
 * @Author   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
 * @Date     Created: 03/01/2025
 * @Group    VASS
 * ------------------------------------------------------------------------------------------------
 * @Description Clase test de la clase ShiftTrigger_Handler y del trigger ShiftTrigger
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         13/01/2025       Salvador Ramírez López             Class creation.
*--------------------------------------------------------------------------
 **/
@isTest
public class ShiftTrigger_Test {
    @isTest
    static void test1(){
        DefaultValuesScheduler__c objData = SCH_ServiceUtility_Test.createDefaultValues();
        Test.startTest();
        Shift objShift = SCH_ServiceUtility_Test.createTurnos();
        Test.stopTest();
    }
}