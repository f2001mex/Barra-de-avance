/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-30-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class SCH_ObtieneHoraCita_Test {
    @isTest
    static void test_convertDateTimeToTimeZone(){
        SCH_ObtieneHoraCita_Cls.wpParameters objParam = new SCH_ObtieneHoraCita_Cls.wpParameters();
        List<SCH_ObtieneHoraCita_Cls.wpParameters> lstParams = new List<SCH_ObtieneHoraCita_Cls.wpParameters>();
        objParam.dtTimeToConvert = system.now();
        objParam.strTimeZoneSidKey = 'America/Mexico City';
        lstParams.add(objParam);
        test.startTest();
        Object res = SCH_ObtieneHoraCita_Cls.convertDateTimeToTimeZone(lstParams);
        test.stopTest();
    }
}