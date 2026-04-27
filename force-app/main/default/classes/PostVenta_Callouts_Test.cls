@isTest
public class PostVenta_Callouts_Test {

    // Test para el método buildErrorMessage (TestVisible)
    @isTest static void testBuildErrorMessage() {
        // Código de error 400-499
        String msg1 = PostVenta_Callouts_cls.buildErrorMessage(404);
        System.assertEquals('Datos erróneos, favor de intentarlo nuevamente.', msg1);

        // Código de error >= 500
        String msg2 = PostVenta_Callouts_cls.buildErrorMessage(500);
        System.assertEquals('Error al obtener la información del servidor.', msg2);

        // Código de error menor a 400
        String msg3 = PostVenta_Callouts_cls.buildErrorMessage(300);
        System.assertEquals('Error al obtener la información del servidor.', msg3);
    }

    // Test para PV_OpenText_WebService.manageErrorStatus()
    @isTest static void testPV_OpenText_WebService_manageErrorStatus() {
        Test.startTest();
        PostVenta_Callouts_cls.PV_OpenText_WebService service = new PostVenta_Callouts_cls.PV_OpenText_WebService();

        // Crear HttpResponse simulado con error
        HttpResponse response = new HttpResponse();
        response.setStatusCode(500);
        response.setBody('Internal Server Error');
        response.setStatus('Internal Server Error');

        try {
            service.manageErrorStatus(response);
            System.assert(false, 'Se esperaba una excepción ServiceException');
        } catch (Exception e) {
            System.assert(e instanceof ServiceException, 'Se esperaba ServiceException');
            System.assert(e.getMessage().contains('There was a problem calling the HOST service'), 'Mensaje de error esperado');
        }
        Test.stopTest();
    }

    // Test para PV_EnvioEncuestaMedallia.manageErrorStatus()
    @isTest static void testPV_EnvioEncuestaMedallia_manageErrorStatus() {
        Test.startTest();
        PostVenta_Callouts_cls.PV_EnvioEncuestaMedallia service = new PostVenta_Callouts_cls.PV_EnvioEncuestaMedallia();

        // Crear HttpResponse simulado con error 404
        HttpResponse response = new HttpResponse();
        response.setStatusCode(404);
        response.setBody('Not Found');
        response.setStatus('Not Found');

        try {
            service.manageErrorStatus(response);
            System.assert(false, 'Se esperaba una excepción ServiceException');
        } catch (Exception e) {
            System.assert(e instanceof ServiceException, 'Se esperaba ServiceException');
            System.assertEquals('Datos erróneos, favor de intentarlo nuevamente.', e.getMessage());
        }
        Test.stopTest();
    }
}