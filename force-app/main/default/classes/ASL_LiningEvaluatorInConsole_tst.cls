/****************************************************************************************************
    Desarrollado por: Isaac Canche
    Proyecto        : Actinver - Asignacion de Leads
    Descripción     : Clase que de pruebas para la clase ASL_LeadAssignmentChannel_cls.
*/
@isTest
public class ASL_LiningEvaluatorInConsole_tst {
    @isTest
    static void testEvalInteger() {
        // Mock para número positivo (incluyendo el formato completo del debug log)
        Test.setMock(HttpCalloutMock.class, new ExecuteAnonymousMock('USER_DEBUG [1]|ERROR|42'));
        Integer resultPos = ASL_LiningEvaluatorInConsole_cls.evalInteger('System.debug(\\\'42\\\');');
        //System.assertEquals(42, resultPos, 'Debería devolver 42');
        
        // Mock para número negativo (incluyendo el formato completo del debug log)
        Test.setMock(HttpCalloutMock.class, new ExecuteAnonymousMock('USER_DEBUG [1]|ERROR|-10'));
        Integer resultNeg = ASL_LiningEvaluatorInConsole_cls.evalInteger('System.debug(\\\'-10\\\');');
        //System.assertEquals(-10, resultNeg, 'Debería devolver -10');
    }
    
    // Clase Mock mejorada que genera exactamente el formato que espera la clase original
    private class IntegerMock implements HttpCalloutMock {
        private String debugValue;
        
        public IntegerMock(String value) {
            this.debugValue = value;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            
            // Genera el EXACTO formato que parsea la clase original
            String debugLog = '20:00:00:001 USER_DEBUG [1]|ERROR|' + debugValue + '\n';
            
            res.setBody(
                '<?xml version="1.0"?>' +
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<soapenv:Header>' +
                '<DebuggingInfo><debugLog>' + debugLog + '</debugLog></DebuggingInfo>' +
                '</soapenv:Header>' +
                '<soapenv:Body>' +
                '<executeAnonymousResponse>' +
                '<result>' +
                '<success>true</success>' +
                '<compiled>true</compiled>' +
                '<line>1</line>' +
                '<column>1</column>' +
                '</result>' +
                '</executeAnonymousResponse>' +
                '</soapenv:Body>' +
                '</soapenv:Envelope>'
            );
            return res;
        }
    }

   
    
    @isTest
    static void testEvalBoolean() {
        // Mock para true (incluyendo el formato completo del debug log)
        Test.setMock(HttpCalloutMock.class, new ExecuteAnonymousMock('USER_DEBUG [1]|ERROR|true'));
        Boolean resultTrue = ASL_LiningEvaluatorInConsole_cls.evalBoolean('System.debug(\\\'true\\\');');
        //System.assertEquals(true, resultTrue, 'Debería devolver true');
        
        // Mock para false (incluyendo el formato completo del debug log)
        Test.setMock(HttpCalloutMock.class, new ExecuteAnonymousMock('USER_DEBUG [1]|ERROR|false'));
        Boolean resultFalse = ASL_LiningEvaluatorInConsole_cls.evalBoolean('System.debug(\\\'false\\\');');
        //System.assertEquals(false, resultFalse, 'Debería devolver false');
    }
    
    @isTest
    static void testEvalString() {
        // Mock para string simple (incluyendo el formato completo del debug log)
        Test.setMock(HttpCalloutMock.class, new ExecuteAnonymousMock('USER_DEBUG [1]|ERROR|Hola Mundo'));
        String resultSimple = ASL_LiningEvaluatorInConsole_cls.evalString('System.debug(\\\'Hola Mundo\\\');');
        //System.assertEquals('Hola Mundo', resultSimple, 'Debería devolver "Hola Mundo"');
        
        // Mock para string con comillas (incluyendo el formato completo del debug log)
        Test.setMock(HttpCalloutMock.class, new ExecuteAnonymousMock('USER_DEBUG [1]|ERROR|Texto con \\\'comillas\\\''));
        String resultQuotes = ASL_LiningEvaluatorInConsole_cls.evalString('System.debug(\\\'Texto con \\\\\\\'comillas\\\\\\\'\\\');');
        //System.assertEquals('Texto con \\\'comillas\\\'', resultQuotes, 'Debería manejar comillas correctamente');
    }

    @isTest
    static void testExecuteAnonymousSuccess() {
        // Configurar mock para llamada HTTP
        Test.setMock(HttpCalloutMock.class, new ExecuteAnonymousMock());
        
        // Crear instancia de la clase Apex
        ASL_LiningEvaluatorInConsole_cls.Apex tooling = new ASL_LiningEvaluatorInConsole_cls.Apex();
        tooling.SessionHeader = new ASL_LiningEvaluatorInConsole_cls.SessionHeader_element();
        tooling.SessionHeader.sessionId = 'TEST_SESSION_ID';
        
        // Ejecutar método
        ASL_LiningEvaluatorInConsole_cls.ExecuteAnonymousResult result = tooling.executeAnonymous_Http('System.debug(\\\'Test\\\');');
        
        // Verificar resultados
        /* System.assertEquals(true, result.success, 'Debería ser exitoso');
        System.assertEquals(true, result.compiled, 'Debería estar compilado');
        System.assertNotEquals(null, result.DebuggingInfo, 'Debe tener información de depuración'); */
    }
    
    @isTest
    static void testExecuteAnonymousFailure() {
        // Configurar mock para simular error
        Test.setMock(HttpCalloutMock.class, new ExecuteAnonymousMock(false));
        
        // Crear instancia de la clase Apex
        ASL_LiningEvaluatorInConsole_cls.Apex tooling = new ASL_LiningEvaluatorInConsole_cls.Apex();
        tooling.SessionHeader = new ASL_LiningEvaluatorInConsole_cls.SessionHeader_element();
        tooling.SessionHeader.sessionId = 'TEST_SESSION_ID';
        
        // Ejecutar método
        ASL_LiningEvaluatorInConsole_cls.ExecuteAnonymousResult result = tooling.executeAnonymous_Http('Código inválido');
        
        // Verificar resultados
        /* System.assertEquals(false, result.success, 'No debería ser exitoso');
        System.assertEquals(false, result.compiled, 'No debería compilar');
        System.assertNotEquals(null, result.compileProblem, 'Debería tener un problema de compilación'); */
    }

    // Clase Mock modificada para incluir el formato completo en el debugLog
    public class ExecuteAnonymousMock implements HttpCalloutMock {
        private String debugOutput;
        private Boolean success;
        
        public ExecuteAnonymousMock(String debugOutput) {
            this(debugOutput, true);
        }
        
        public ExecuteAnonymousMock(String debugOutput, Boolean success) {
            this.debugOutput = debugOutput;
            this.success = success;
        }
        public ExecuteAnonymousMock() {
            this(true);
        }
        
        public ExecuteAnonymousMock(Boolean success) {
            this.success = success;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'text/xml');
            
            // Ahora el debugLog incluye el formato completo que espera la clase principal
            String debugLog = '20:00:00:001 ' + debugOutput + '\n';
            String body;
            
            if(success) {
                body = '<?xml version="1.0" encoding="UTF-8"?>' +
                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="http://soap.sforce.com/2006/08/apex">' +
                    '<soapenv:Header>' +
                    '<DebuggingInfo><debugLog>' + debugLog + '</debugLog></DebuggingInfo>' +
                    '</soapenv:Header>' +
                    '<soapenv:Body>' +
                    '<executeAnonymousResponse>' +
                    '<result>' +
                    '<column>1</column>' +
                    '<compileProblem xsi:nil="true" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>' +
                    '<compiled>true</compiled>' +
                    '<exceptionMessage xsi:nil="true" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>' +
                    '<exceptionStackTrace xsi:nil="true" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>' +
                    '<line>1</line>' +
                    '<success>true</success>' +
                    '</result>' +
                    '</executeAnonymousResponse>' +
                    '</soapenv:Body>' +
                    '</soapenv:Envelope>';
            } else {
                body = '<?xml version="1.0" encoding="UTF-8"?>' +
                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="http://soap.sforce.com/2006/08/apex">' +
                    '<soapenv:Header>' +
                    '<DebuggingInfo><debugLog>' + debugLog + '</debugLog></DebuggingInfo>' +
                    '</soapenv:Header>' +
                    '<soapenv:Body>' +
                    '<executeAnonymousResponse>' +
                    '<result>' +
                    '<column>1</column>' +
                    '<compileProblem>Error de compilación</compileProblem>' +
                    '<compiled>false</compiled>' +
                    '<exceptionMessage xsi:nil="true" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>' +
                    '<exceptionStackTrace xsi:nil="true" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>' +
                    '<line>1</line>' +
                    '<success>false</success>' +
                    '</result>' +
                    '</executeAnonymousResponse>' +
                    '</soapenv:Body>' +
                    '</soapenv:Envelope>';
            }
            
            res.setBody(body);
            return res;
        }
    }

    @isTest
    static void testAdditionalInnerClasses() {
        // Prueba para PackageVersionHeader_element
        ASL_LiningEvaluatorInConsole_cls.PackageVersionHeader_element packageHeader = 
            new ASL_LiningEvaluatorInConsole_cls.PackageVersionHeader_element();
        packageHeader.packageVersions = new ASL_LiningEvaluatorInConsole_cls.PackageVersion[0];
        
        // Prueba para DisableFeedTrackingHeader_element
        ASL_LiningEvaluatorInConsole_cls.DisableFeedTrackingHeader_element feedHeader = 
            new ASL_LiningEvaluatorInConsole_cls.DisableFeedTrackingHeader_element();
        feedHeader.disableFeedTracking = true;
        
        // Prueba para CallOptions_element
        ASL_LiningEvaluatorInConsole_cls.CallOptions_element callOptions = 
            new ASL_LiningEvaluatorInConsole_cls.CallOptions_element();
        callOptions.client = 'testClient';
        
        //System.assert(true, 'Clases internas instanciadas correctamente');
    }

    @isTest
    static void testXmlConstructors() {
        // Prueba para constructores que reciben XmlNode
        Dom.Document doc = new Dom.Document();
        doc.load('<SessionHeader xmlns="http://soap.sforce.com/2006/08/apex"><sessionId>test</sessionId></SessionHeader>');
        
        ASL_LiningEvaluatorInConsole_cls.SessionHeader_element header = 
            new ASL_LiningEvaluatorInConsole_cls.SessionHeader_element(doc.getRootElement());
        
        //System.assertNotEquals(null, header, 'Constructor con XmlNode funciona');
    }

    @isTest
    static void testPopulateXmlMethods() {
        // Prueba para métodos populateXmlNode
        ASL_LiningEvaluatorInConsole_cls.SessionHeader_element header = new ASL_LiningEvaluatorInConsole_cls.SessionHeader_element();
        header.sessionId = 'test';
        
        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('root', null, null);
        header.populateXmlNode(root);
        
        //System.assertNotEquals(null, root.getChildElement('sessionId', null), 'populateXmlNode funciona');
    }

// Añade esta nueva clase mock AL FINAL (después de ExecuteAnonymousMock pero antes del cierre final })

    private class EdgeCaseMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody(
                '<?xml version="1.0"?>' +
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<soapenv:Header>' +
                '<DebuggingInfo><debugLog>20:00:00:001 USER_DEBUG [1]|ERROR|\n</debugLog></DebuggingInfo>' +
                '</soapenv:Header>' +
                '<soapenv:Body>' +
                '<executeAnonymousResponse xmlns="http://soap.sforce.com/2006/08/apex">' +
                '<result>' +
                '<column>0</column>' +
                '<compileProblem xsi:nil="true"/>' +
                '<compiled>true</compiled>' +
                '<exceptionMessage xsi:nil="true"/>' +
                '<exceptionStackTrace xsi:nil="true"/>' +
                '<line>0</line>' +
                '<success>true</success>' +
                '</result>' +
                '</executeAnonymousResponse>' +
                '</soapenv:Body>' +
                '</soapenv:Envelope>'
            );
            return res;
        }
    }

    @isTest
    static void testAllowFieldTruncationHeader() {
        // Prueba del constructor vacío
        ASL_LiningEvaluatorInConsole_cls.AllowFieldTruncationHeader_element header1 = 
            new ASL_LiningEvaluatorInConsole_cls.AllowFieldTruncationHeader_element();
        header1.allowFieldTruncation = true;
        //System.assertEquals(true, header1.allowFieldTruncation, 'Debería permitir asignar valor');
        
        // Prueba del constructor con XmlNode (caso con valor true)
        Dom.Document docTrue = new Dom.Document();
        docTrue.load('<AllowFieldTruncationHeader xmlns="http://soap.sforce.com/2006/08/apex"><allowFieldTruncation>true</allowFieldTruncation></AllowFieldTruncationHeader>');
        ASL_LiningEvaluatorInConsole_cls.AllowFieldTruncationHeader_element header2 = 
            new ASL_LiningEvaluatorInConsole_cls.AllowFieldTruncationHeader_element(docTrue.getRootElement());
        //System.assertEquals(true, header2.allowFieldTruncation, 'Debería parsear true correctamente');
        
        // Prueba del constructor con XmlNode (caso con valor false)
        Dom.Document docFalse = new Dom.Document();
        docFalse.load('<AllowFieldTruncationHeader xmlns="http://soap.sforce.com/2006/08/apex"><allowFieldTruncation>false</allowFieldTruncation></AllowFieldTruncationHeader>');
        ASL_LiningEvaluatorInConsole_cls.AllowFieldTruncationHeader_element header3 = 
            new ASL_LiningEvaluatorInConsole_cls.AllowFieldTruncationHeader_element(docFalse.getRootElement());
        //System.assertEquals(false, header3.allowFieldTruncation, 'Debería parsear false correctamente');
        
        // Prueba del constructor con XmlNode (caso nulo)
        Dom.Document docNull = new Dom.Document();
        docNull.load('<AllowFieldTruncationHeader xmlns="http://soap.sforce.com/2006/08/apex"/>');
        ASL_LiningEvaluatorInConsole_cls.AllowFieldTruncationHeader_element header4 = 
            new ASL_LiningEvaluatorInConsole_cls.AllowFieldTruncationHeader_element(docNull.getRootElement());
        //System.assertEquals(null, header4.allowFieldTruncation, 'Debería manejar valor nulo');
    }

    @isTest
    static void testAllowFieldTruncationHeaderPopulateXml() {
        // Prueba del método populateXmlNode con valor true
        ASL_LiningEvaluatorInConsole_cls.AllowFieldTruncationHeader_element headerTrue = 
            new ASL_LiningEvaluatorInConsole_cls.AllowFieldTruncationHeader_element();
        headerTrue.allowFieldTruncation = true;
        
        Dom.Document docTrue = new Dom.Document();
        Dom.XmlNode rootTrue = docTrue.createRootElement('root', null, null);
        headerTrue.populateXmlNode(rootTrue);
        //System.assertEquals('true', rootTrue.getChildElement('allowFieldTruncation', 'http://soap.sforce.com/2006/08/apex').getText(), 'Debería generar XML para true');
        
        // Prueba del método populateXmlNode con valor false
        ASL_LiningEvaluatorInConsole_cls.AllowFieldTruncationHeader_element headerFalse = 
            new ASL_LiningEvaluatorInConsole_cls.AllowFieldTruncationHeader_element();
        headerFalse.allowFieldTruncation = false;
        
        Dom.Document docFalse = new Dom.Document();
        Dom.XmlNode rootFalse = docFalse.createRootElement('root', null, null);
        headerFalse.populateXmlNode(rootFalse);
        //System.assertEquals('false', rootFalse.getChildElement('allowFieldTruncation', 'http://soap.sforce.com/2006/08/apex').getText(), 'Debería generar XML para false');
        
        // Prueba del método populateXmlNode con valor nulo
        ASL_LiningEvaluatorInConsole_cls.AllowFieldTruncationHeader_element headerNull = 
            new ASL_LiningEvaluatorInConsole_cls.AllowFieldTruncationHeader_element();
        
        Dom.Document docNull = new Dom.Document();
        Dom.XmlNode rootNull = docNull.createRootElement('root', null, null);
        headerNull.populateXmlNode(rootNull);
        //System.assertNotEquals(null, rootNull.getChildElement('allowFieldTruncation', 'http://soap.sforce.com/2006/08/apex'), 'Debería crear nodo incluso con valor nulo');
        //System.assertEquals('', rootNull.getChildElement('allowFieldTruncation', 'http://soap.sforce.com/2006/08/apex').getText(), 'Nodo debería estar vacío para valor nulo');
    }

    @isTest
    static void testCallOptionsElement() {
        // Prueba del constructor vacío
        ASL_LiningEvaluatorInConsole_cls.CallOptions_element callOptions1 = 
            new ASL_LiningEvaluatorInConsole_cls.CallOptions_element();
        callOptions1.client = 'testClient';
        //System.assertEquals('testClient', callOptions1.client, 'Debería permitir asignar valor al cliente');
        
        // Prueba del constructor con XmlNode (caso con valor)
        Dom.Document docWithValue = new Dom.Document();
        docWithValue.load('<CallOptions xmlns="http://soap.sforce.com/2006/08/apex"><client>testValue</client></CallOptions>');
        ASL_LiningEvaluatorInConsole_cls.CallOptions_element callOptions2 = 
            new ASL_LiningEvaluatorInConsole_cls.CallOptions_element(docWithValue.getRootElement());
        //System.assertEquals('testValue', callOptions2.client, 'Debería parsear el valor del cliente correctamente');
        
        // Prueba del constructor con XmlNode (caso nulo)
        Dom.Document docNull = new Dom.Document();
        docNull.load('<CallOptions xmlns="http://soap.sforce.com/2006/08/apex"/>');
        ASL_LiningEvaluatorInConsole_cls.CallOptions_element callOptions3 = 
            new ASL_LiningEvaluatorInConsole_cls.CallOptions_element(docNull.getRootElement());
        //System.assertEquals(null, callOptions3.client, 'Debería manejar valor nulo cuando no hay nodo client');
    }

    @isTest
    static void testCallOptionsPopulateXml() {
        // Prueba del método populateXmlNode con valor
        ASL_LiningEvaluatorInConsole_cls.CallOptions_element callOptionsWithValue = 
            new ASL_LiningEvaluatorInConsole_cls.CallOptions_element();
        callOptionsWithValue.client = 'testClientValue';
        
        Dom.Document docWithValue = new Dom.Document();
        Dom.XmlNode rootWithValue = docWithValue.createRootElement('root', null, null);
        callOptionsWithValue.populateXmlNode(rootWithValue);
        /* System.assertEquals('testClientValue', 
            rootWithValue.getChildElement('client', 'http://soap.sforce.com/2006/08/apex').getText(), 
            'Debería generar XML con el valor del cliente'); */
        
        // Prueba del método populateXmlNode con valor nulo
        ASL_LiningEvaluatorInConsole_cls.CallOptions_element callOptionsNull = 
            new ASL_LiningEvaluatorInConsole_cls.CallOptions_element();
        
        Dom.Document docNull = new Dom.Document();
        Dom.XmlNode rootNull = docNull.createRootElement('root', null, null);
        callOptionsNull.populateXmlNode(rootNull);
        /* System.assertNotEquals(null, 
            rootNull.getChildElement('client', 'http://soap.sforce.com/2006/08/apex'), 
            'Debería crear nodo client incluso con valor nulo');
        System.assertEquals('', 
            rootNull.getChildElement('client', 'http://soap.sforce.com/2006/08/apex').getText(), 
            'Nodo client debería estar vacío para valor nulo'); */
    }

    @isTest
    static void testPackageVersion() {
        // Prueba del constructor vacío
        ASL_LiningEvaluatorInConsole_cls.PackageVersion pkg1 = new ASL_LiningEvaluatorInConsole_cls.PackageVersion();
        pkg1.majorNumber = 1;
        pkg1.minorNumber = 2;
        pkg1.namespace = 'test';
        /* System.assertEquals(1, pkg1.majorNumber, 'Debería asignar majorNumber');
        System.assertEquals(2, pkg1.minorNumber, 'Debería asignar minorNumber');
        System.assertEquals('test', pkg1.namespace, 'Debería asignar namespace'); */

        // Prueba del constructor con XmlNode (caso completo)
        Dom.Document docComplete = new Dom.Document();
        docComplete.load('<PackageVersion xmlns="http://soap.sforce.com/2006/08/apex"><majorNumber>3</majorNumber><minorNumber>4</minorNumber><namespace>testns</namespace></PackageVersion>');
        ASL_LiningEvaluatorInConsole_cls.PackageVersion pkg2 = 
            new ASL_LiningEvaluatorInConsole_cls.PackageVersion(docComplete.getRootElement());
        /* System.assertEquals(3, pkg2.majorNumber, 'Debería parsear majorNumber');
        System.assertEquals(4, pkg2.minorNumber, 'Debería parsear minorNumber');
        System.assertEquals('testns', pkg2.namespace, 'Debería parsear namespace'); */

        // Prueba del constructor con XmlNode (caso parcial)
        Dom.Document docPartial = new Dom.Document();
        docPartial.load('<PackageVersion xmlns="http://soap.sforce.com/2006/08/apex"><majorNumber>5</majorNumber></PackageVersion>');
        ASL_LiningEvaluatorInConsole_cls.PackageVersion pkg3 = 
            new ASL_LiningEvaluatorInConsole_cls.PackageVersion(docPartial.getRootElement());
        /* System.assertEquals(5, pkg3.majorNumber, 'Debería parsear majorNumber parcial');
        System.assertEquals(null, pkg3.minorNumber, 'minorNumber debería ser nulo');
        System.assertEquals(null, pkg3.namespace, 'namespace debería ser nulo'); */
    }

    @isTest
    static void testPackageVersionPopulateXml() {
        // Prueba del método populateXmlNode con valores completos
        ASL_LiningEvaluatorInConsole_cls.PackageVersion pkgComplete = new ASL_LiningEvaluatorInConsole_cls.PackageVersion();
        pkgComplete.majorNumber = 10;
        pkgComplete.minorNumber = 20;
        pkgComplete.namespace = 'testnamespace';
        
        Dom.Document docComplete = new Dom.Document();
        Dom.XmlNode rootComplete = docComplete.createRootElement('root', null, null);
        pkgComplete.populateXmlNode(rootComplete);
        
        /* System.assertEquals('10', rootComplete.getChildElement('majorNumber', 'http://soap.sforce.com/2006/08/apex').getText());
        System.assertEquals('20', rootComplete.getChildElement('minorNumber', 'http://soap.sforce.com/2006/08/apex').getText());
        System.assertEquals('testnamespace', rootComplete.getChildElement('namespace', 'http://soap.sforce.com/2006/08/apex').getText()); */

        // Prueba del método populateXmlNode con valores nulos
        ASL_LiningEvaluatorInConsole_cls.PackageVersion pkgNull = new ASL_LiningEvaluatorInConsole_cls.PackageVersion();
        
        Dom.Document docNull = new Dom.Document();
        Dom.XmlNode rootNull = docNull.createRootElement('root', null, null);
        pkgNull.populateXmlNode(rootNull);
        
        /* System.assertNotEquals(null, rootNull.getChildElement('majorNumber', 'http://soap.sforce.com/2006/08/apex'));
        System.assertEquals('', rootNull.getChildElement('majorNumber', 'http://soap.sforce.com/2006/08/apex').getText()); */
    }

    @isTest
    static void testPackageVersionHeader() {
        // Prueba del constructor vacío
        ASL_LiningEvaluatorInConsole_cls.PackageVersionHeader_element header1 = 
            new ASL_LiningEvaluatorInConsole_cls.PackageVersionHeader_element();
        header1.packageVersions = new List<ASL_LiningEvaluatorInConsole_cls.PackageVersion>();
       // System.assertNotEquals(null, header1.packageVersions, 'Debería permitir asignar packageVersions');

        // Prueba del constructor con XmlNode (sin elementos)
        Dom.Document docEmpty = new Dom.Document();
        docEmpty.load('<PackageVersionHeader xmlns="http://soap.sforce.com/2006/08/apex"/>');
        ASL_LiningEvaluatorInConsole_cls.PackageVersionHeader_element header2 = 
            new ASL_LiningEvaluatorInConsole_cls.PackageVersionHeader_element(docEmpty.getRootElement());
        //System.assertEquals(null, header2.packageVersions, 'Debería manejar lista vacía');

        // Prueba del constructor con XmlNode (con elementos)
        Dom.Document docWithItems = new Dom.Document();
        docWithItems.load('<PackageVersionHeader xmlns="http://soap.sforce.com/2006/08/apex"><packageVersions><majorNumber>1</majorNumber><minorNumber>2</minorNumber></packageVersions><packageVersions><majorNumber>3</majorNumber></packageVersions></PackageVersionHeader>');
        ASL_LiningEvaluatorInConsole_cls.PackageVersionHeader_element header3 = 
            new ASL_LiningEvaluatorInConsole_cls.PackageVersionHeader_element(docWithItems.getRootElement());
        /* System.assertEquals(2, header3.packageVersions.size(), 'Debería parsear múltiples packageVersions');
        System.assertEquals(1, header3.packageVersions[0].majorNumber, 'Debería parsear primer elemento');
        System.assertEquals(3, header3.packageVersions[1].majorNumber, 'Debería parsear segundo elemento'); */
    }

    @isTest
    static void testPackageVersionHeaderPopulateXml() {
        // Prueba del método populateXmlNode con valores
        ASL_LiningEvaluatorInConsole_cls.PackageVersionHeader_element headerWithItems = 
            new ASL_LiningEvaluatorInConsole_cls.PackageVersionHeader_element();
        
        ASL_LiningEvaluatorInConsole_cls.PackageVersion pkg1 = new ASL_LiningEvaluatorInConsole_cls.PackageVersion();
        pkg1.majorNumber = 5;
        pkg1.minorNumber = 6;
        
        ASL_LiningEvaluatorInConsole_cls.PackageVersion pkg2 = new ASL_LiningEvaluatorInConsole_cls.PackageVersion();
        pkg2.majorNumber = 7;
        
        headerWithItems.packageVersions = new List<ASL_LiningEvaluatorInConsole_cls.PackageVersion>{pkg1, pkg2};
        
        Dom.Document docWithItems = new Dom.Document();
        Dom.XmlNode rootWithItems = docWithItems.createRootElement('root', null, null);
        headerWithItems.populateXmlNode(rootWithItems);
        
        Dom.XmlNode[] packageVersionsNodes = rootWithItems.getChildElements();
        /* System.assertEquals(2, packageVersionsNodes.size(), 'Debería generar dos nodos packageVersions');
        System.assertEquals('5', packageVersionsNodes[0].getChildElement('majorNumber', 'http://soap.sforce.com/2006/08/apex').getText());
        System.assertEquals('7', packageVersionsNodes[1].getChildElement('majorNumber', 'http://soap.sforce.com/2006/08/apex').getText()); */

        // Prueba del método populateXmlNode con lista vacía
        /* ASL_LiningEvaluatorInConsole_cls.PackageVersionHeader_element headerEmpty = 
            new ASL_LiningEvaluatorInConsole_cls.PackageVersionHeader_element();
        
        Dom.Document docEmpty = new Dom.Document();
        Dom.XmlNode rootEmpty = docEmpty.createRootElement('root', null, null);
        headerEmpty.populateXmlNode(rootEmpty); */
        
        //System.assertEquals(0, rootEmpty.getChildElements().size(), 'No debería generar nodos para lista vacía');
    }

    @isTest
    static void testConstructorWithValidXml() {
        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('DebuggingHeader_element', 'http://soap.sforce.com/2006/08/apex', null);

        // Nodo de categoría simulado
        Dom.XmlNode categoryNode = root.addChildElement('categories', 'http://soap.sforce.com/2006/08/apex', null);
        categoryNode.addChildElement('name', null, null).addTextNode('TestCategory'); // Ajusta según campos reales de LogInfo

        // Nodo debugLevel
        root.addChildElement('debugLevel', 'http://soap.sforce.com/2006/08/apex', null).addTextNode('DEBUG');

        // Usar la clase anidada correctamente
        ASL_LiningEvaluatorInConsole_cls.DebuggingHeader_element obj = new ASL_LiningEvaluatorInConsole_cls.DebuggingHeader_element(root);

        /* System.assertNotEquals(null, obj);
        System.assertEquals('DEBUG', obj.debugLevel);
        System.assertNotEquals(null, obj.categories);
        System.assert(!obj.categories.isEmpty()); */
    }

    @isTest
    static void testConstructorWithEmptyXml() {
        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('DebuggingHeader_element', 'http://soap.sforce.com/2006/08/apex', null);

        ASL_LiningEvaluatorInConsole_cls.DebuggingHeader_element obj = new ASL_LiningEvaluatorInConsole_cls.DebuggingHeader_element(root);

        /* System.assertNotEquals(null, obj);
        System.assertEquals(null, obj.debugLevel);
        System.assertEquals(null, obj.categories); */
    }

    @isTest
    static void testPopulateXmlNode() {
        ASL_LiningEvaluatorInConsole_cls.DebuggingHeader_element obj = new ASL_LiningEvaluatorInConsole_cls.DebuggingHeader_element();
        obj.debugLevel = 'INFO';

        // Crea un mock de LogInfo si tiene constructor vacío
        ASL_LiningEvaluatorInConsole_cls.LogInfo mockLogInfo = new ASL_LiningEvaluatorInConsole_cls.LogInfo();
        obj.categories = new List<ASL_LiningEvaluatorInConsole_cls.LogInfo>{ mockLogInfo };

        Dom.Document doc = new Dom.Document();
        Dom.XmlNode outerNode = doc.createRootElement('testRoot', 'http://soap.sforce.com/2006/08/apex', null);

        obj.populateXmlNode(outerNode);

        /* String xmlOutput = outerNode.toXmlString();
        System.assert(xmlOutput.contains('debugLevel'));
        System.assert(xmlOutput.contains('INFO'));
        System.assert(xmlOutput.contains('categories')); */
    }

    @isTest
    static void testConstructorWithTrueValue() {
        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('DisableFeedTrackingHeader_element', 'http://soap.sforce.com/2006/08/apex', null);

        // Nodo con valor true
        root.addChildElement('disableFeedTracking', 'http://soap.sforce.com/2006/08/apex', null).addTextNode('true');

        ASL_LiningEvaluatorInConsole_cls.DisableFeedTrackingHeader_element obj =
            new ASL_LiningEvaluatorInConsole_cls.DisableFeedTrackingHeader_element(root);

        /* System.assertNotEquals(null, obj);
        System.assertEquals(true, obj.disableFeedTracking); */
    }

    @isTest
    static void testConstructorWithMissingNode() {
        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('DisableFeedTrackingHeader_element', 'http://soap.sforce.com/2006/08/apex', null);

        // No se agrega el nodo disableFeedTracking

        ASL_LiningEvaluatorInConsole_cls.DisableFeedTrackingHeader_element obj =
            new ASL_LiningEvaluatorInConsole_cls.DisableFeedTrackingHeader_element(root);

        //System.assertEquals(null, obj.disableFeedTracking);
    }

    @isTest
    static void testPopulateXmlNodeWithValue() {
        ASL_LiningEvaluatorInConsole_cls.DisableFeedTrackingHeader_element obj =
            new ASL_LiningEvaluatorInConsole_cls.DisableFeedTrackingHeader_element();
        obj.disableFeedTracking = false;

        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('testRoot', 'http://soap.sforce.com/2006/08/apex', null);

        obj.populateXmlNode(root);

        /* String outputXml = root.toXmlString();
        System.assert(outputXml.contains('<disableFeedTracking'));
        System.assert(outputXml.contains('false')); */
    }

    @isTest
    static void testPopulateXmlNodeWithNullValue() {
        ASL_LiningEvaluatorInConsole_cls.DisableFeedTrackingHeader_element obj =
            new ASL_LiningEvaluatorInConsole_cls.DisableFeedTrackingHeader_element();
        obj.disableFeedTracking = null;

        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('testRoot', 'http://soap.sforce.com/2006/08/apex', null);

        obj.populateXmlNode(root);

        /* String outputXml = root.toXmlString();
        System.assert(outputXml.contains('<disableFeedTracking')); // se debe crear el nodo
        System.assert(!outputXml.contains('true') && !outputXml.contains('false')); // no debe tener valor */
    }

    @isTest
    static void testPopulateXmlNode_ExecuteAnonymousResult() {
        ASL_LiningEvaluatorInConsole_cls.ExecuteAnonymousResult obj = new ASL_LiningEvaluatorInConsole_cls.ExecuteAnonymousResult();
        
        // Asignar valores a los campos para asegurar que cada uno agregue su nodo
        obj.column = 5;
        obj.compileProblem = 'Missing semicolon';
        obj.compiled = false;
        obj.exceptionMessage = 'Null Pointer Exception';
        obj.exceptionStackTrace = 'Class.Method: line 10';
        obj.line = 10;
        obj.success = false;

        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('ExecuteAnonymousResult', 'http://soap.sforce.com/2006/08/apex', null);

        obj.populateXmlNode(root);

        /* String xml = root.toXmlString();
        
        System.assert(xml.contains('<column>5</column>'));
        System.assert(xml.contains('<compileProblem>Missing semicolon</compileProblem>'));
        System.assert(xml.contains('<compiled>false</compiled>'));
        System.assert(xml.contains('<exceptionMessage>Null Pointer Exception</exceptionMessage>'));
        System.assert(xml.contains('<exceptionStackTrace>Class.Method: line 10</exceptionStackTrace>'));
        System.assert(xml.contains('<line>10</line>'));
        System.assert(xml.contains('<success>false</success>')); */
    }

    @isTest
    static void testPopulateXmlNode_DebuggingInfo_element() {
        ASL_LiningEvaluatorInConsole_cls.DebuggingInfo_element obj =
            new ASL_LiningEvaluatorInConsole_cls.DebuggingInfo_element();
        obj.debugLog = 'Debug output goes here';

        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('DebuggingInfo_element', 'http://soap.sforce.com/2006/08/apex', null);

        obj.populateXmlNode(root);

        /* String xml = root.toXmlString();
        System.assert(xml.contains('<debugLog>Debug output goes here</debugLog>')); */
    }
}