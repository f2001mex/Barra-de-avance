/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     WorkTypeGroupTrigger_Handler
 * @Author   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
 * @Date     Created: 03/01/2025
 * @Group    VASS
 * ------------------------------------------------------------------------------------------------
 * @Description Work type group handler. This trigger uses the Kevin O'Hara trigger framework.
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         03/01/2025       Salvador Ramírez López             Class creation.
*--------------------------------------------------------------------------
 **/
public class WorkTypeGroupTrigger_Handler extends TriggerHandler {
    List<WorkTypeGroup> lstWorkTypeGroup = Trigger.new;
    /*
        * Método: afterInsert.
        * Return: NA.
        * Descripción: Método encargado de Realizar todos los llamados correspondientes a acciones a realizar en el evento after Insert del trigger.
        * Autor: Salvador Ramírez López (salvador.ramirez@vasscompany.com).
    */
    @TestVisible
    protected override void afterInsert(){
        SCH_ServiceUtility_Trigger.wpResult wp = new SCH_ServiceUtility_Trigger.wpResult();
        wp = SCH_WorkTypeTrigger_Helper.createWorkTypes(lstWorkTypeGroup);
        List<ServiceTerritory> lstServTerr = SCH_ServiceUtility_Trigger.getActiveServiceTerritories();
        List<EngagementChannelType> lstChannels = SCH_ServiceUtility_Trigger.getChannels();
        SCH_WorkTypeTrigger_Helper.createServiceTerritoryWorkType(wp.lstWorkType, lstServTerr);
        SCH_WorkTypeTrigger_Helper.createWorkTypesGroupMember(wp.setIdWorkTypeGroup, lstWorkTypeGroup);
        SCH_WorkTypeTrigger_Helper.createEngagementChannelWorkTypes(wp.lstWorkType, lstChannels);
    }
}