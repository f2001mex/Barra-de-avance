/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase PSTA_ChangeAccountInfo_soql
------------------------------------------------------------------------------------------
No.        Fecha               Autor                            Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     18-06-2025      Salvador Ramirez Lopez                   Creación
*******************************************************************************************/
public class PSTA_ChangeAccountInfo_soql {
    public static List<Account> getAccountsInfo(Set<Id> setIdAcc){
        return [SELECT Id, EstatusContacto__c, FechaUltimoContacto__c FROM Account WHERE Id IN :setIdAcc];
    }
    public static List<ActionCadence> lstConfigByCadences(Set<String> setTaskDevName){
        return [SELECT DeveloperName__c, GeneraContacto__c, RequiereCargaEvidencia__c FROM ACTIONCADENCE WHERE DeveloperName__c IN :setTaskDevName];
    }
}