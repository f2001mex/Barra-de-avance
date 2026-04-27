/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-06-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ShiftTrigger_Helper {
    public static void createShiftEngagementChannel(List<Shift> lstShift, List<EngagementChannelType> lstChannels, DefaultValuesScheduler__c objDefaultValues){
        List<ShiftEngagementChannel> lstInsert = new List<ShiftEngagementChannel>();
        for(Shift objShift : lstShift){
            for(EngagementChannelType objChannels : lstChannels){
                ShiftEngagementChannel objSEC = new ShiftEngagementChannel(ShiftId = objShift.Id, EngagementChannelTypeId = objChannels.Id, AreAllEngmtChnlSupported = objDefaultValues.AllEngChanSup_Shift__c);
                lstInsert.add(objSEC);
            }
        }
        insert lstInsert;
    }
}