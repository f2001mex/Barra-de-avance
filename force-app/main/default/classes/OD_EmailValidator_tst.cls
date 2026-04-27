/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Description       :   Clase test de la clase OD_EmailValidator_cls
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         20-Nov-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@IsTest
public class OD_EmailValidator_tst {
    @IsTest
    static void testValidateRestrictedWords() {
        // Verificar que la etiqueta personalizada contiene datos
        List<String> restrictedWords = Label.PalabrasRestringidas.split(',');

        // Crear correos electrónicos de prueba en función del contenido de la etiqueta
        String validEmail = 'user@example.com'; // Siempre válido
        String invalidEmail = restrictedWords.isEmpty() ? 
                              'scam_user@example.com' : 
                              restrictedWords[0] + 'user@example.com'; // Email inválido basado en la primera palabra restringidas

        Boolean result = OD_EmailValidator_cls.ValidateRestrictedWords('PEDO@dominio.com');
        System.assertEquals(false, result, 'Debería detectar palabra restringida en usuario');
        
        Boolean resultInvalidEmail = OD_EmailValidator_cls.ValidateRestrictedWords('nombre@gmail.com');
        System.assertEquals(false, resultInvalidEmail, 'Debería detectar palabra restringida');
        
        Boolean resultInvalid = OD_EmailValidator_cls.ValidateRestrictedWords('usuario@PEDO@dominio.com');
        System.assertEquals(false, resultInvalid, 'debería detectar palabra restringida aunque el formato sea inválido');
        // Validar el email sin palabras restringidas
        Boolean isValid = OD_EmailValidator_cls.ValidateRestrictedWords(validEmail);
        System.assertEquals(true, isValid, 
            'El email válido no debería contener palabras restringidas.');

        // Validar el email con una palabra restringida
        Boolean isInvalid = OD_EmailValidator_cls.ValidateRestrictedWords(invalidEmail);
        System.assertEquals(true, isInvalid, 
            'El email inválido contiene una palabra restringida y debería fallar.');
    }

    @IsTest
    static void testValidateEmailStructure() {
        
        // Patrón de expresión regular para formato de correo electrónico
        String emailRegex = '^[a-z0-9!#$%&\'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&\'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$';

        // Caso válido (email con formato correcto)
        String validEmail = 'user@example.com';
        Boolean isValid = OD_EmailValidator_cls.ValidateEmailStructure(emailRegex, validEmail);
        System.assertEquals(true, isValid, 'El email válido debería cumplir con el formato.');

        // Caso inválido (email con formato incorrecto)
        String invalidEmail = 'userexample.com';
        Boolean isInvalid = OD_EmailValidator_cls.ValidateEmailStructure(emailRegex, invalidEmail);
        System.assertEquals(false, isInvalid, 'El email inválido no debería cumplir con el formato.');

        // Caso vacío (email no proporcionado)
        String emptyEmail = '';
        Boolean isEmpty = OD_EmailValidator_cls.ValidateEmailStructure(emailRegex, emptyEmail);
        System.assertEquals(false, isEmpty, 'Un email vacío no debería ser válido.');
    }
}