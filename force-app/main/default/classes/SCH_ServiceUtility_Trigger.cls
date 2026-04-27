/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     SCH_ServiceUtility_Trigger
 * @Author   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
 * @Date     Created: 03/01/2025
 * @Group    VASS
 * ------------------------------------------------------------------------------------------------
 * @Description Clase para almacenar métodos y funciones de apoyo para el trigger.
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         03/01/2025       Salvador Ramírez López             Class creation.
*--------------------------------------------------------------------------
 **/
public class SCH_ServiceUtility_Trigger {
    public static List<ServiceTerritory> getActiveServiceTerritories(){
        return [SELECT ID FROM SERVICETERRITORY WHERE ISACTIVE = TRUE];
    }
    public static List<EngagementChannelType> getChannels(){
        return [SELECT ID FROM ENGAGEMENTCHANNELTYPE WHERE ISACTIVE = TRUE];
    }
    public static DefaultValuesScheduler__c getCustomSettingDefaultValues(){
        return DefaultValuesScheduler__c.getInstance();
    }
    public static Map<String, String> getWorkTypes(Set<String> setExternalIds){
        List<WorkType> lstWT = [SELECT ID, External_ID__c FROM WORKTYPE WHERE External_ID__c IN: setExternalIds];
        Map<String, String> mapWorkTypes = new Map<String, String>();
        for(WorkType objWT : lstWT){
            mapWorkTypes.put(objWT.External_ID__c, objWT.Id);
        }
        return mapWorkTypes;
    }
    public class wpResult {
        public List<WorkType> lstWorkType;
        public Set<String> setIdWorkTypeGroup;
        public wpResult(){
            lstWorkType = new List<WorkType>();
            setIdWorkTypeGroup = new Set<String>();
        }
    }
}