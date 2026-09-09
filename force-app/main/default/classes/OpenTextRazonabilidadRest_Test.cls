@IsTest
private class OpenTextRazonabilidadRest_Test {
    @IsTest
    static void rechazaSolicitudSinCamposObligatorios() {
        RestContext.request = buildRequest('{"bpCliente":"92160118"}');
        RestContext.response = new RestResponse();

        Test.startTest();
        OpenTextRazonabilidadRest.Response response = OpenTextRazonabilidadRest.procesar();
        Test.stopTest();

        System.assertEquals(false, response.success);
        System.assertEquals('DATOS_INVALIDOS', response.codigo);
        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(response.errores.contains('contrato es obligatorio.'));
        System.assert(response.errores.contains('areaBancaria es obligatorio.'));
        System.assert(response.errores.contains('idAsesor es obligatorio.'));
        System.assert(response.errores.contains('fechaGeneracion es obligatorio.'));
        System.assert(response.errores.contains('idOpenText es obligatorio.'));
    }

    @IsTest
    static void respondeCadenciaNoEncontradaCuandoNoExisteCliente() {
        OpenTextRazonabilidadRest.testAdvisorUserId = UserInfo.getUserId();

        RestContext.request = buildRequest(
            '{"bpCliente":"BP-INEXISTENTE","contrato":"12345","areaBancaria":"Privada",' +
            '"idAsesor":"62847","fechaGeneracion":"2026-08-03","idOpenText":"OT-123"}'
        );
        RestContext.response = new RestResponse();

        Test.startTest();
        OpenTextRazonabilidadRest.Response response = OpenTextRazonabilidadRest.procesar();
        Test.stopTest();

        System.assertEquals(false, response.success);
        System.assertEquals('BP_NO_ENCONTRADO', response.codigo);
        System.assertEquals('BP no encontrado', response.mensaje);
        System.assert(response.errores.contains('No se encontro cliente con el bpCliente recibido.'));
        System.assertEquals(404, RestContext.response.statusCode);
    }

    @IsTest
    static void respondeErrorConJsonInvalido() {
        RestContext.request = buildRequest('{json-invalido');
        RestContext.response = new RestResponse();

        Test.startTest();
        OpenTextRazonabilidadRest.Response response = OpenTextRazonabilidadRest.procesar();
        Test.stopTest();

        System.assertEquals(false, response.success);
        System.assertEquals('ERROR_ACTUALIZAR_TAREA', response.codigo);
        System.assertEquals(500, RestContext.response.statusCode);
        System.assert(!response.errores.isEmpty());
    }

    @IsTest
    static void rechazaSolicitudConBodyVacio() {
        RestContext.request = buildRequest('');
        RestContext.response = new RestResponse();

        Test.startTest();
        OpenTextRazonabilidadRest.Response response = OpenTextRazonabilidadRest.procesar();
        Test.stopTest();

        System.assertEquals(false, response.success);
        System.assertEquals('DATOS_INVALIDOS', response.codigo);
        System.assert(response.errores.contains('El body de la solicitud es obligatorio.'));
    }

    @IsTest
    static void respondeCadenciaNoEncontradaCuandoNoExisteObjetoCadencia() {
        OpenTextRazonabilidadRest.testAccount = new Account(
            Id = '001000000000002AAA',
            OwnerId = UserInfo.getUserId()
        );
        OpenTextRazonabilidadRest.testContactId = '003000000000002AAA';
        OpenTextRazonabilidadRest.testAdvisorUserId = UserInfo.getUserId();

        RestContext.request = buildRequest(
            '{"bpCliente":"BP-POC-002","contrato":"CON-002","areaBancaria":"Privada",' +
            '"idAsesor":"62847","fechaGeneracion":"2026-08-03","idOpenText":"OT-002"}'
        );
        RestContext.response = new RestResponse();

        Test.startTest();
        OpenTextRazonabilidadRest.Response response = OpenTextRazonabilidadRest.procesar();
        Test.stopTest();

        System.assertEquals(false, response.success);
        System.assertEquals('CADENCIA_NO_ENCONTRADA', response.codigo);
        System.assertEquals(404, RestContext.response.statusCode);
    }

    @IsTest
    static void respondeErrorCuandoNoExisteTareaRelacionada() {
        OpenTextRazonabilidadRest.testAccount = new Account(
            Id = '001000000000003AAA',
            OwnerId = UserInfo.getUserId()
        );
        OpenTextRazonabilidadRest.testContactId = '003000000000003AAA';
        OpenTextRazonabilidadRest.testCadenceStep =
            new OpenTextRazonabilidadRest.CadenceStepInfo('8HF000000000003AAA', '0qB000000000003AAA', 'Active');
        OpenTextRazonabilidadRest.testAdvisorUserId = UserInfo.getUserId();
        OpenTextRazonabilidadRest.skipCadenceActionsForTest = true;

        RestContext.request = buildRequest(
            '{"bpCliente":"BP-POC-003","contrato":"CON-003","areaBancaria":"Privada",' +
            '"idAsesor":"62847","fechaGeneracion":"2026-08-03","idOpenText":"OT-003"}'
        );
        RestContext.response = new RestResponse();

        Test.startTest();
        OpenTextRazonabilidadRest.Response response = OpenTextRazonabilidadRest.procesar();
        Test.stopTest();

        System.assertEquals(false, response.success);
        System.assertEquals('ERROR_ACTUALIZAR_TAREA', response.codigo);
        System.assertEquals(500, RestContext.response.statusCode);
    }

    @IsTest
    static void actualizaTareaCuandoCadenciaFueLocalizada() {
        Lead lead = new Lead(
            FirstName = 'Cliente',
            LastName = 'POC',
            Company = 'Actinver POC',
            Email = 'cliente.poc@example.com'
        );
        insert lead;

        Task task = new Task(
            Subject = 'Propuesta de inversion',
            WhoId = lead.Id,
            Status = 'Completado',
            Priority = 'Normal'
        );
        insert task;

        OpenTextRazonabilidadRest.testAccount = new Account(
            Id = '001000000000001AAA',
            OwnerId = UserInfo.getUserId()
        );
        OpenTextRazonabilidadRest.testContactId = lead.Id;
        OpenTextRazonabilidadRest.testCadenceStep =
            new OpenTextRazonabilidadRest.CadenceStepInfo('8HF000000000001AAA', '0qB000000000001AAA', 'Completed');
        OpenTextRazonabilidadRest.testAdvisorUserId = UserInfo.getUserId();
        OpenTextRazonabilidadRest.skipCadenceActionsForTest = true;
        String asesorId = UserInfo.getUserId();

        RestContext.request = buildRequest(
            '{"bpCliente":"BP-POC-001","contrato":"CON-001","areaBancaria":"Privada",' +
            '"idAsesor":"62847","fechaGeneracion":"' + String.valueOf(Date.today()) + '","idOpenText":"OT-001"}'
        );
        RestContext.response = new RestResponse();

        Test.startTest();
        OpenTextRazonabilidadRest.Response response = OpenTextRazonabilidadRest.procesar();
        Test.stopTest();

        System.assertEquals(true, response.success);
        System.assertEquals('OK', response.codigo);
        System.assertEquals(200, RestContext.response.statusCode);

        Task updatedTask = [
            SELECT OwnerId, Status, RefenciaOpenText__c, El_cliente_fue_contactado__c, ContratoVinculado__c
            FROM Task
            WHERE Id = :task.Id
            LIMIT 1
        ];

        System.assertEquals(asesorId, updatedTask.OwnerId);
        System.assertEquals('Completado', updatedTask.Status);
        System.assertEquals('OT-001', updatedTask.RefenciaOpenText__c);
        System.assertEquals('Si', updatedTask.El_cliente_fue_contactado__c);
        System.assertEquals('CON-001', updatedTask.ContratoVinculado__c);
    }

    @IsTest
    static void completaCadenciaActivaPorRestYActualizaTarea() {
        Lead lead = new Lead(
            FirstName = 'Cliente',
            LastName = 'Activo',
            Company = 'Actinver POC',
            Email = 'cliente.activo@example.com'
        );
        insert lead;

        Task task = new Task(
            Subject = 'Propuesta de inversion',
            WhoId = lead.Id,
            Status = 'Abierto',
            Priority = 'Normal'
        );
        insert task;

        String asesorId = UserInfo.getUserId();
        OpenTextRazonabilidadRest.testAccount = new Account(
            Id = '001000000000004AAA',
            OwnerId = UserInfo.getUserId()
        );
        OpenTextRazonabilidadRest.testContactId = lead.Id;
        OpenTextRazonabilidadRest.testCadenceStep =
            new OpenTextRazonabilidadRest.CadenceStepInfo('8HF000000000004AAA', '0qB000000000004AAA', 'Active', asesorId);
        OpenTextRazonabilidadRest.testAdvisorUserId = UserInfo.getUserId();
        OpenTextRazonabilidadRest.skipCadenceActionsForTest = false;
        Test.setMock(HttpCalloutMock.class, new CadenceActionSuccessMock());

        RestContext.request = buildRequest(
            '{"bpCliente":"BP-POC-004","contrato":"CON-004","areaBancaria":"Privada",' +
            '"idAsesor":"62847","fechaGeneracion":"' + String.valueOf(Date.today()) + '","idOpenText":"OT-004"}'
        );
        RestContext.response = new RestResponse();

        Test.startTest();
        OpenTextRazonabilidadRest.Response response = OpenTextRazonabilidadRest.procesar();
        Test.stopTest();

        System.assertEquals(true, response.success);
        System.assertEquals('OK', response.codigo);

        Task updatedTask = [
            SELECT OwnerId, Status, RefenciaOpenText__c, El_cliente_fue_contactado__c, ContratoVinculado__c
            FROM Task
            WHERE Id = :task.Id
            LIMIT 1
        ];

        System.assertEquals(asesorId, updatedTask.OwnerId);
        System.assertEquals('Completado', updatedTask.Status);
        System.assertEquals('OT-004', updatedTask.RefenciaOpenText__c);
        System.assertEquals('Si', updatedTask.El_cliente_fue_contactado__c);
        System.assertEquals('CON-004', updatedTask.ContratoVinculado__c);
    }

    @IsTest
    static void generaExpresionCronParaReintentoDeOwner() {
        Datetime scheduledDateTime = Datetime.newInstance(2026, 8, 24, 15, 30, 45);

        String cronExpression = OpenTextRazonabilidadRest.buildCronExpression(scheduledDateTime);

        System.assertEquals('45 30 15 24 8 ? 2026', cronExpression);
    }

    private static RestRequest buildRequest(String body) {
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/opentext/razonabilidad';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(body);
        return request;
    }

    private class CadenceActionSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            Boolean isCadenceAction =
                request.getEndpoint().contains('/services/data/v67.0/actions/standard/sendSalesCadenceEvent') ||
                request.getEndpoint().contains('/services/data/v67.0/actions/standard/changeSalesCadenceTargetAssignee');
            System.assert(isCadenceAction);
            System.assertEquals('POST', request.getMethod());

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('[{"isSuccess":true,"outputValues":{"error":null}}]');
            return response;
        }
    }
}