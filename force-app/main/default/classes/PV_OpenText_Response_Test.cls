@isTest
public class PV_OpenText_Response_Test {

    @isTest
    static void testDeserializeResponseBody() {
        // Arrange: construir un JSON válido que represente una respuesta
        String jsonResponse = '{' +
            '"status": 200,' +
            '"errorCode": "0",' +
            '"appCode": "APP_OK",' +
            '"messages": ["Documento procesado correctamente"],' +
            '"result": {' +
                '"resultCode": "0",' +
                '"resultType": "Success",' +
                '"resultMessage": "Operación exitosa"' +
            '},' +
            '"payload": {' +
                '"status": "COMPLETED",' +
                '"referenceId": "REF1234567890"' +
            '}' +
        '}';

        // Act: deserializar usando el método de la clase
        PV_OpenText_Response response = (PV_OpenText_Response) new PV_OpenText_Response().deserializeResponseBody(jsonResponse);

        // Assert: validar que los campos fueron correctamente deserializados
        System.assertEquals(200, response.status, 'El status debe ser 200');
        System.assertEquals('0', response.errorCode, 'El errorCode debe ser "0"');
        System.assertEquals('APP_OK', response.appCode, 'El appCode debe ser "APP_OK"');
        System.assertEquals(1, response.messages.size(), 'Debe haber un mensaje');
        System.assertEquals('Documento procesado correctamente', response.messages[0], 'Mensaje incorrecto');

        System.assertNotEquals(null, response.result, 'El campo result no debe ser null');
        System.assertEquals('0', response.result.resultCode, 'resultCode incorrecto');
        System.assertEquals('Success', response.result.resultType, 'resultType incorrecto');
        System.assertEquals('Operación exitosa', response.result.resultMessage, 'resultMessage incorrecto');

        System.assertNotEquals(null, response.payload, 'El campo payload no debe ser null');
        System.assertEquals('COMPLETED', response.payload.status, 'payload.status incorrecto');
        System.assertEquals('REF1234567890', response.payload.referenceId, 'payload.referenceId incorrecto');
    }
}