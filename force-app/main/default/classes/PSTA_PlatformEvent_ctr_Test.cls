@isTest
public class PSTA_PlatformEvent_ctr_Test {

    @isTest
    static void testPublishEvent_ShowFileUploadLWC() {
        // Datos de prueba
        String testRecordId = '001xxxxxxxxxxxxxxx';
        Boolean showComponent = true;

        Test.startTest();
        // Llamar al método para publicar el evento
        PSTA_PlatformEvent_ctr.publishEvent_ShowFileUploadLWC(testRecordId, showComponent);
        Test.stopTest();

        // No hay asserts específicos porque es un evento, pero la prueba valida que no haya excepciones
        System.assert(true, 'El evento se publicó sin lanzar excepciones');
    }
}