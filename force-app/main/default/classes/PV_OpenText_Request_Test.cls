@isTest
public class PV_OpenText_Request_Test {
    @isTest
    static void testSerializeRequestBody() {
        // Arrange: crear instancia del wrapper
        PV_OpenText_Request request = new PV_OpenText_Request();
        request.contractNumber = '123456';
        request.bankingArea = 'BANCA PATRIMONIAL';
        request.extension = 'pdf';
        request.fileName = 'documento_test.pdf';
        request.file = 'BASE64ENCODEDSTRING==';
        request.instruction = 'MPV';

        // Act: serializar usando el método de la clase
        String jsonOutput = request.serializeRequestBody(request);

        // Assert: validar que el JSON contiene los campos esperados
        System.assertNotEquals(null, jsonOutput, 'El JSON serializado no debe ser null');
        System.assert(jsonOutput.contains('123456'), 'Debe contener el contractNumber');
        System.assert(jsonOutput.contains('BANCA PATRIMONIAL'), 'Debe contener bankingArea');
        System.assert(jsonOutput.contains('pdf'), 'Debe contener extension');
        System.assert(jsonOutput.contains('documento_test.pdf'), 'Debe contener fileName');
        System.assert(jsonOutput.contains('BASE64ENCODEDSTRING=='), 'Debe contener file');
        System.assert(jsonOutput.contains('MPV'), 'Debe contener instruction');
    }
}