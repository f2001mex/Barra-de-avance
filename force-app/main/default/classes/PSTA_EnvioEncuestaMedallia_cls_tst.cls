/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para PSTA_EnvioEncuestaMedallia_cls
------------------------------------------------------------------------------------------
No.        Fecha               Autor                            Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     14-07-2025        Jessica Salazar                        Creación
*******************************************************************************************/
@IsTest
public class PSTA_EnvioEncuestaMedallia_cls_tst {

        @isTest
        static void test_sendSurvey_withMock() {
        Task task = new Task(
            Subject = 'Llamada de prueba',
            Status = 'Completado',
            Priority = 'Alta'
        );
        insert task;

        Test.setMock(HttpCalloutMock.class, new PSTA_EnvioEncuestaMedallia_Mockup());

        Test.startTest();
        PSTA_EnvioEncuestaMedallia_cls.sendSurvey(new Set<Id>{task.Id});
        Test.stopTest();
    }

    @isTest
    static void test_sendSurvey_emptySet() {
        Set<Id> emptySet = new Set<Id>();

        Test.startTest();
        PSTA_EnvioEncuestaMedallia_cls.sendSurvey(emptySet);
        Test.stopTest();
    }
}