/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Clase test		:   OD_ContractEmail_tgr_tst
* Description       :   Trigger para el objeto de correo de contrato
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         21-Nov-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public without sharing class OD_EmailValidator_cls {

    //Etiqueta personalizada que contiene todo el mundo de palabras restringidas separadas por comas.
    public static final List<String> lstRestrictedWords = Label.PalabrasRestringidas.split(',');

    private static final Set<String> restrictedWordsSet = new Set<String>();
    static {
        if(String.isNotBlank(Label.PalabrasRestringidas)) {
            for(String word : Label.PalabrasRestringidas.split(',')) {
                restrictedWordsSet.add(word.toLowerCase());
            }
        }
    }

    /**
    * @description Valida si el email proporcionado contiene palabras restringidas
    * @param strEmail Email a ser validado.
    * @return Boolean Devuelve true si no contiene palabras restringidas, false en caso contrario.
    **/
    public static Boolean ValidateRestrictedWords(String strEmail) {
        
        String strEmailContentLowerCase = strEmail.toLowerCase();

        if(restrictedWordsSet.contains(strEmail)) {
            return false;
        }
        
        List<String> segments = strEmail.split('\\.|_|-|\\+|@');
        
        for(String segment : segments) {
            if(restrictedWordsSet.contains(segment.toLowerCase())) return false;
        }

        return true;
    }

    /**
    * @description Valida si el email proporcionado contiene un formato valido
    * @param strEmail Email a ser validado.
    * @return Boolean Devuelve true si contiene un formato valido, false en caso contrario.
    **/
    public static Boolean ValidateEmailStructure(String strRegex, String strEmail){

        return Pattern.matches(strRegex, strEmail);
    }

}