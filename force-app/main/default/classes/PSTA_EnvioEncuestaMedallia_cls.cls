/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase PSTA_EnvioEncuestaMedallia_cls
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     09-06-2025      Salvador Ramirez Lopez                    Creación
*******************************************************************************************/
public with sharing class PSTA_EnvioEncuestaMedallia_cls {
    public static void sendSurvey(Set<Id> setIdTask){
        System.debug('Entró a sendSurvey. Set: ' + setIdTask);
        for(Id idTask : setIdTask) {
            System.debug('idTask: ' + idTask);
            PSTA_EnvioEncuestaMedallia_ctr.calloutMedallia(IdTask);
        }
    }
}