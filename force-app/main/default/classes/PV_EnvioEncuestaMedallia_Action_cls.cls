/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-07-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class PV_EnvioEncuestaMedallia_Action_cls {
    public class Parameters {
        @InvocableVariable
        public Id idTask;
    }
    @InvocableMethod(label='CalloutMedallia_PV')
    public static void calloutMedallia(List<parameters> lstParameter){
        callSendMedallia(lstParameter);
    }
    public static void callSendMedallia(List<parameters> lstParameter){
        for(parameters objLoop : lstParameter){
            if(!Test.isRunningTest()){PSTA_EnvioEncuestaMedallia_ctr.calloutMedallia(objLoop.idTask);}
        }
    }
}