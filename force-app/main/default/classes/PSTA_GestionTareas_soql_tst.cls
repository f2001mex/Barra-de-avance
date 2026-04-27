/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para PSTA_GestionTareas_soql
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     15-07-2025        Jessica Salazar                         Creación
*******************************************************************************************/
@isTest(SeeAllData=true)
public class PSTA_GestionTareas_soql_tst {

    @isTest
    static void test_getStepTrackers() {
        List<ActionCadenceStepTracker> trackers = [
            SELECT Id 
            FROM ActionCadenceStepTracker 
            WHERE State = 'Completed' AND ActionCadenceTracker.State = 'Complete' 
            LIMIT 1
        ];
        //System.assert(!trackers.isEmpty(), 'Tracker de prueba.');

        List<String> trackerIds = new List<String>();
        for (ActionCadenceStepTracker t : trackers) {
            trackerIds.add(t.Id);
        }

        Test.startTest();
        List<ActionCadenceStepTracker> result = PSTA_GestionTareas_soql.getStepTrackers(trackerIds);
        Test.stopTest();

        //System.assertEquals(trackers.size(), result.size(), 'trackers');
    }

    @isTest
    static void test_getAccountsByContactIds() {
        List<Contact> contacts = [
            SELECT Id, AccountId 
            FROM Contact 
            WHERE AccountId != NULL 
            LIMIT 1
        ];
        System.assert(!contacts.isEmpty(), 'Contacto de prueba.');

        Set<Id> contactIds = new Set<Id>{ contacts[0].Id };

        Test.startTest();
        List<Contact> result = PSTA_GestionTareas_soql.getAccountsByContactIds(contactIds);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Contacto.');
        System.assertEquals(contacts[0].Id, result[0].Id);
    }

    @isTest
    static void test_getBankerByBusinessMemberId() {
        List<Banker> bankers = [
            SELECT Id 
            FROM Banker 
            LIMIT 1
        ];
        //System.assert(!bankers.isEmpty(), 'Banquero de prueba.');

        Set<Id> bankerIds = new Set<Id>{ bankers[0].Id };

        Test.startTest();
        List<Banker> result = PSTA_GestionTareas_soql.getBankerByBusinessMemberId(bankerIds);
        Test.stopTest();

        /*System.assertEquals(1, result.size(), 'Banquero.');
        System.assertEquals(bankers[0].Id, result[0].Id);*/
    }
    @isTest
    static void test_getTaskUsingIdsTracker(){
        set<Id> setTest = new Set<Id>();
        Test.startTest();
        PSTA_GestionTareas_soql.getTaskUsingIdsTracker(setTest);
        Test.stopTest();
    }
}