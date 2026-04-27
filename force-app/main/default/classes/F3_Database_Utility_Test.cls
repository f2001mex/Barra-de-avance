@isTest
public class F3_Database_Utility_Test {
    @isTest
    static void testUpsertRecordsWithStadistics() {
        // Crear datos de prueba
        Account acc1 = new Account(Name = 'Test Account 1');
        Account acc2 = new Account(Name = 'Test Account 2');

        List<SObject> accounts = new List<SObject>{ acc1, acc2 };

        Test.startTest();
        // Llamar a upsertRecords con estadísticas
        Object result = F3_Database_Utility.upsertRecords(accounts, null, true, true);
        Test.stopTest();

        // Validaciones
        System.assert(result instanceof Map<String, Map<String, String>>, 'El resultado debe ser un Map con estadísticas.');
        Map<String, Map<String, String>> resultMap = (Map<String, Map<String, String>>) result;
        System.assert(resultMap.containsKey('Stadistics'), 'El resultado debe contener estadísticas.');
    }
    
    @IsTest
    static void testUpsertRecords_CatchBlock() {
        // Crear un registro inválido
        List<SObject> invalidRecords = new List<SObject>{
            new Account(Name = null) // Nombre es obligatorio para Account
        };

        // Llamar al método y capturar el resultado
        Object result = F3_Database_Utility.upsertRecords(
            invalidRecords, // Lista inválida
            null, // Sin campo de ID externo
            true, // allOrNone activado
            false // Sin estadísticas
        );

        // Validar que el resultado corresponde al bloque catch
        System.assert(result instanceof Map<String, Map<String, String>>, 'El resultado debe ser un mapa de errores');
        Map<String, Map<String, String>> errorMap = (Map<String, Map<String, String>>) result;
        System.assertEquals('1', errorMap.get('Errors AllOrNone').get('Errors AllOrNone'), 'Debe registrar un error');
        System.assertNotEquals(null, errorMap.get('Errors AllOrNone').get('Error Description'), 'Debe contener una descripción del error');
    }

    @isTest
    static void testInsertRecordsWithStadistics() {
        // Crear datos de prueba
        Account acc1 = new Account(Name = 'Test Insert 1');
        Account acc2 = new Account(Name = 'Test Insert 2');

        List<SObject> accounts = new List<SObject>{ acc1, acc2 };

        Test.startTest();
        // Llamar a insertRecords con estadísticas
        Object result = F3_Database_Utility.insertRecords(accounts, true, true);
        Test.stopTest();

        // Validaciones
        System.assert(result instanceof Map<String, Map<String, String>>, 'El resultado debe ser un Map con estadísticas.');
        Map<String, Map<String, String>> resultMap = (Map<String, Map<String, String>>) result;
        System.assert(resultMap.containsKey('Stadistics'), 'El resultado debe contener estadísticas.');
    }
    
    @IsTest
    static void testInsertRecords_CatchBlock() {
        // Crear un registro inválido
        List<SObject> invalidRecords = new List<SObject>{
            new Account(Name = null) // Nombre es obligatorio para Account
        };

        // Llamar al método y capturar el resultado
        Object result = F3_Database_Utility.insertRecords(
            invalidRecords, // Lista inválida
            true, // allOrNone activado
            false // Sin estadísticas
        );

        // Validar que el resultado corresponde al bloque catch
        System.assert(result instanceof Map<String, Map<String, String>>, 'El resultado debe ser un mapa de errores');
        Map<String, Map<String, String>> errorMap = (Map<String, Map<String, String>>) result;
        System.assertEquals('1', errorMap.get('Errors AllOrNone').get('Errors AllOrNone'), 'Debe registrar un error');
    }

    @isTest
    static void testUpdateRecordsWithStadistics() {
        // Crear y actualizar datos de prueba
        Account acc = new Account(Name = 'Test Update');
        insert acc;

        acc.Name = 'Updated Test';
        List<SObject> accounts = new List<SObject>{ acc };

        Test.startTest();
        // Llamar a updateRecords con estadísticas
        Object result = F3_Database_Utility.updateRecords(accounts, true, true);
        Test.stopTest();

        // Validaciones
        System.assert(result instanceof Map<String, Map<String, String>>, 'El resultado debe ser un Map con estadísticas.');
        Map<String, Map<String, String>> resultMap = (Map<String, Map<String, String>>) result;
        System.assert(resultMap.containsKey('Stadistics'), 'El resultado debe contener estadísticas.');
    }
    
    @IsTest
    static void testUpdateRecords_CatchBlock() {
        // Crear un registro inválido que no pueda ser actualizado correctamente
        Account acc = new Account(Name = 'Test Account');
        insert acc; // Insertar el registro

        // Intentar actualizar un campo de solo lectura o un campo incorrecto
        acc.Name = null; // 'Name' no puede ser nulo, esto debería generar un error al intentar actualizar
        List<SObject> invalidRecords = new List<SObject>{ acc };

        // Llamar al método y capturar el resultado
        Object result = F3_Database_Utility.updateRecords(
            invalidRecords, // Lista con el registro inválido
            true, // allOrNone activado
            false // Sin estadísticas
        );

        // Validar que el resultado corresponde al bloque catch
        System.assert(result instanceof Map<String, Map<String, String>>, 'El resultado debe ser un mapa de errores');
        Map<String, Map<String, String>> errorMap = (Map<String, Map<String, String>>) result;
        System.assertEquals('1', errorMap.get('Errors AllOrNone').get('Errors AllOrNone'), 'Debe registrar un error');
    }

    @isTest
    static void testCreateDMLStadistics() {
        // Crear datos de prueba
        Account acc1 = new Account(Name = 'Test Account 1');
        Account acc2 = new Account(Name = 'Test Account 2');
        Account accError = new Account(); // Sin nombre, causará error

        List<Account> accounts = new List<Account>{ acc1, acc2, accError };

        Test.startTest();
        // Insertar cuentas con errores simulados
        List<Database.SaveResult> results = Database.insert(accounts, false);
        Test.stopTest();

        // Llamar a createDMLStadistics
        Map<String, Map<String, String>> stadistics = F3_Database_Utility.createDMLStadistics(results);

        // Validaciones
        System.assert(stadistics.containsKey('Stadistics'), 'El mapa debe contener estadísticas.');
        System.assertEquals('1', stadistics.get('Stadistics').get('Errors'), 'Debe haber un error reportado.');
    }
    
    
}