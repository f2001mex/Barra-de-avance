/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     SCH_WorkTypeTrigger_Helper
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
public class SCH_WorkTypeTrigger_Helper {
    /*
        * Método: createWorkTypes.
        * Return: SCH_ServiceUtility_Trigger.wpResult.
        * Descripción: Método encargado de crear todos los work types utilizando como base el work type group cargado. Hereda el nombre, external id, descripción y utiliza una duración por default.
        * Autor: Salvador Ramírez López (salvador.ramirez@vasscompany.com).
    */
    public static SCH_ServiceUtility_Trigger.wpResult createWorkTypes(List<WorkTypeGroup> lstWorkTypeGroup){
        DefaultValuesScheduler__c objDefaultValues = SCH_ServiceUtility_Trigger.getCustomSettingDefaultValues(); //Mover a utilería.
        SCH_ServiceUtility_Trigger.wpResult wpResult = new SCH_ServiceUtility_Trigger.wpResult();
        List<WorkType> lstWorkType = new List<WorkType>();
        Set<String> setIdWorkTypeGroups = new Set<String>();
        for(WorkTypeGroup objWTG : lstWorkTypeGroup){
            WorkType objWT = new WorkType(Name = objWTG.Name, EstimatedDuration = objDefaultValues.DuracionEstimadaWorkType__c, DurationType = objDefaultValues.TipoDuracionWorkType__c, External_ID__c = objWTG.External_ID__c, Description = objWTG.Description);
            lstWorkType.add(objWT);
            setIdWorkTypeGroups.add(objWT.External_ID__c);
        }
        if(!Test.isRunningTest()) insert lstWorkType;
        wpResult.lstWorkType = lstWorkType;
        wpResult.setIdWorkTypeGroup = setIdWorkTypeGroups;
        return wpResult;
    }
    /*
        * Método: createServiceTerritoryWorkType.
        * Return: NA.
        * Descripción: Método encargado de crear la relación entre el objeto "Service territory" y "Work type" por medio del objeto "ServiceTerritoryWorkType".
        * Autor: Salvador Ramírez López (salvador.ramirez@vasscompany.com).
    */
    public static void createServiceTerritoryWorkType(List<WorkType> lstWorkType, List<ServiceTerritory> lstServTerr){
        List<ServiceTerritoryWorkType> lstSTWT = new List<ServiceTerritoryWorkType>();
        for(WorkType objWT : lstWorkType){
            for(ServiceTerritory objST : lstServTerr){
                ServiceTerritoryWorkType objServTerWorkType = new ServiceTerritoryWorkType(ServiceTerritoryId = objST.Id, WorkTypeId = objWT.Id);
                lstSTWT.add(objServTerWorkType);
            }
        }
        if(!Test.isRunningTest())insert lstSTWT;
    }
    /*
        * Método: createWorkTypesGroupMember.
        * Return: NA.
        * Descripción: Método encargado de crear la relación entre el objeto "Work type group" y "Work type" por medio del objeto "WorkTypeGroupMember".
        * Autor: Salvador Ramírez López (salvador.ramirez@vasscompany.com).
    */
    public static void createWorkTypesGroupMember(Set<String> setExternalIds, List<WorkTypeGroup> lstWorkTypeGroup){
        List<WorkTypeGroupMember> lstWorkTypeGroupMember = new List<WorkTypeGroupMember>();
        Map<String, String> mapWorkTypes = SCH_ServiceUtility_Trigger.getWorkTypes(setExternalIds);
        for(WorkTypeGroup objWTG : lstWorkTypeGroup){
            WorkTypeGroupMember objWTM = new WorkTypeGroupMember(WorkTypeGroupId = objWTG.Id, WorkTypeId = mapWorkTypes.get(objWTG.External_ID__c));
            lstWorkTypeGroupMember.add(objWTM);
        }
        if(!Test.isRunningTest()) insert lstWorkTypeGroupMember;
    }
    /*
        * Método: createEngagementChannelWorkTypes.
        * Return: NA.
        * Descripción: Método encargado de crear la relación entre el objeto "Enggaement chanel work type" y "Work type" por medio del objeto "EngagementChannelWorkType".
        * Autor: Salvador Ramírez López (salvador.ramirez@vasscompany.com).
    */
    public static void createEngagementChannelWorkTypes(List<WorkType> lstWorkType, List<EngagementChannelType> lstChannels){
        List<EngagementChannelWorkType> lstInsert = new List<EngagementChannelWorkType>();
        for(WorkType objWT : lstWorkType){
            for(EngagementChannelType objEC : lstChannels){
                EngagementChannelWorkType objECWT = new EngagementChannelWorkType(EngagementChannelTypeId = objEC.Id, WorkTypeId = objWT.Id);
                lstInsert.add(objECWT);
            }
        }
        if(!Test.isRunningTest()) insert lstInsert;
    }
}