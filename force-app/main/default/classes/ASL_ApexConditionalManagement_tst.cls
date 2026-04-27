/****************************************************************************************************
    Desarrollado por: Gerardo Bautista
    Proyecto        : Actinver - Corrección de Asignacion de Leads
    Descripción     : Clase que de pruebas para la clase ASL_ApexConditionalManagement_cls.
*/
@IsTest
public class ASL_ApexConditionalManagement_tst {

    @IsTest
    static void testApplyLogicReplacements_TwoDigitIndex10() {
        // Arrange: simula el mapa de condiciones ya “traducidas” a expresiones Apex
        Map<String, String> mapTernary = new Map<String, String>{
            '1'  => 'A == B',
            '2'  => 'C == D',
            '10' => 'X.contains(Y)'
        };

        // Lógica real como la que tienes en tu JSON: "10 AND (1 OR 2)"
        String logic = '10 AND (1 OR 2)';

        // Act
        String out = ASL_ApexConditionalManagement_cls.applyLogicReplacements(logic, mapTernary);

        // Assert: operadores normalizados
        System.assert(out.contains('&&'), 'Debe convertir AND a &&');
        System.assert(out.contains('||'), 'Debe convertir OR a ||');

        // Assert: debe reemplazar 10 completo (no "1" + "0")
        System.assert(out.contains('(X.contains(Y))'), 'Debe reemplazar el índice 10 como token completo');
        System.assert(out.contains('(A == B)'), 'Debe reemplazar el índice 1');
        System.assert(out.contains('(C == D)'), 'Debe reemplazar el índice 2');

        // El síntoma del bug: que quede un "0" colgando pegado a algo.
        // No es perfecto, pero detecta el caso típico que viste: "...strResultadoXXXXX0"
        System.assertEquals(false, out.contains(')0'), 'No debe quedar un "0" colgando tras un reemplazo incorrecto');
    }

    @IsTest
    static void testApplyLogicReplacements_MissingIndexBecomesFalse() {
        // Arrange: falta el índice 10
        Map<String, String> mapTernary = new Map<String, String>{
            '1' => 'TRUE'
        };

        String logic = '1 AND 10';

        // Act
        String out = ASL_ApexConditionalManagement_cls.applyLogicReplacements(logic, mapTernary);

        // Assert
        System.assert(out.contains('(TRUE)'), 'Debe reemplazar el índice existente');
        System.assert(out.contains('false'), 'Índices no encontrados deben volverse false para no tronar');
    }

    @IsTest
    static void testApplyLogicReplacements_EmptyLogic() {
        Map<String, String> mapTernary = new Map<String, String>();
        System.assertEquals(null, ASL_ApexConditionalManagement_cls.applyLogicReplacements(null, mapTernary));
        System.assertEquals('', ASL_ApexConditionalManagement_cls.applyLogicReplacements('', mapTernary));
    }
    @IsTest
    static void testValidateFiltersAssignment_basic() {

        // Crear Lead de prueba
        Lead l = new Lead(
            FirstName = 'QA',
            LastName  = 'Test',
            Company   = 'Test Company',
            Email     = 'qa.test@example.com',
            Phone     = '5555555555'
        );


        insert l;

        List<Lead> leads = [SELECT Id, LastName FROM Lead WHERE Id = :l.Id];

        Test.startTest();

        Map<String,Object> result =
            ASL_ApexConditionalManagement_cls.validateFiltersAssignment(
                leads,
                false,
                false,
                'TEST'
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
    }
}