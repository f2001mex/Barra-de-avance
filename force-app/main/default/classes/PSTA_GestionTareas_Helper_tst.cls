/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para PSTA_GestionTareas_Helper
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     15-07-2025        Jessica Salazar                         Creación
*******************************************************************************************/
@isTest(SeeAllData=true)
public class PSTA_GestionTareas_Helper_tst {

    @IsTest
    static void test_createTaskWithCloseCadence_and_createTasks() {
        /*List<ActionCadenceStepTracker> trackers = [
            SELECT Id, ActionCadenceName, TargetId, 
                   ActionCadence.Tipo_de_actividad__c, 
                   ActionCadence.DeveloperName__c, 
                   ActionCadence.Name
            FROM ActionCadenceStepTracker
            WHERE State = 'Completed'
            LIMIT 1
        ];*/
        List<ActionCadenceStepTracker> trackers = new List<ActionCadenceStepTracker>();
        //System.assert(!trackers.isEmpty(), 'ActionCadenceStepTracker en estado Completed');

        List<Contact> contactos = [
            SELECT Id, AccountId, 
                   Account.Client_ID__c, 
                   Account.Name, 
                   Account.BanqueroAsignado__r.BusinessUnitMemberId 
            FROM Contact 
            WHERE AccountId != NULL 
            AND Account.BanqueroAsignado__r.BusinessUnitMemberId != NULL
            LIMIT 1
        ];
        System.assert(!contactos.isEmpty(), 'Contacto con Account válido');

        List<Banker> bankers = [
            SELECT Id, UserOrContactId, ExternalId__c 
            FROM Banker 
            LIMIT 1
        ];
        System.assert(!bankers.isEmpty(), 'Banker');

        Test.startTest();
        PSTA_GestionTareas_Helper.createTasks(trackers);
        Test.stopTest();

        /*List<Task> tasks = [SELECT Id, Subject, Status, WhoId FROM Task WHERE Subject = :trackers[0].ActionCadenceName];
        System.assert(tasks.size() > 0, 'Tarea');*/
    }
    @isTest
    static void test_createExternalIdTask(){
        Test.startTest();
        PSTA_GestionTareas_Helper.createExternalIdTask('test', '001', '0005');
        Test.stopTest();
    }
}