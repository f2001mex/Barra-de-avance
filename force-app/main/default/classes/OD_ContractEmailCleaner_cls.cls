/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Clase test		:   OD_ContractEmailCleaner_tst
* Description       :   clase para la validacion del contrato y estructura de los correos de los registros de tipo Correo_de_Contrato.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         20-Nov-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public without sharing class OD_ContractEmailCleaner_cls {


    /**
    * @description Valida si el correo de contrato tiene un contrato relacionado
    * @param objCorreoDeContrato Registro de tipo de correo de contrato a validar
    * @return Boolean Devuelve true si el correo de contrato tiene un contrato relacionado , false en caso contrario
    **/
    public static Boolean ValidateExistingRelatedContract(Correo_de_Contrato__c objCorreoDeContrato){

        return String.isNotBlank(objCorreoDeContrato.NUM_CONTRATO__c); 
        
    }

    /**
    * @description Valida una lista de correos de contrato para verificar si estan relacionados a un contrato, que tengan una estructura correcta y que no contengan palabras restringidas
    * @param lstCorreosDeContrato Lista de correos de contrato a validar
    * @return List<Correo_de_Contrato__c> Lista de contratos actualizados 
    **/
    public static List<Correo_de_Contrato__c> ValidateAndUpdateRecords(List<Correo_de_Contrato__c> lstCorreosDeContrato) {
        // Obtenemos el patrón de expresión regular desde el Custom Metadata
        String strRegex = ConfiguracionExpresionesRegulares__mdt.getInstance('OD_EstructuraCorreo').Regex__c;
        
        List<Correo_de_Contrato__c> lstCorreosToUpdate = new List<Correo_de_Contrato__c>();
        
        for (Correo_de_Contrato__c correo : lstCorreosDeContrato) {
            Boolean blnNeedsUpdate = false;
            
            // Validar existencia de contrato relacionado
            if (!ValidateExistingRelatedContract(correo) || !OD_EmailValidator_cls.ValidateEmailStructure(strRegex, correo.Contract_email__c)) {
                correo.DatoContactoNoValido__c = true;
                blnNeedsUpdate = true;
            }

            // Validar palabras restringidas
            if (!OD_EmailValidator_cls.ValidateRestrictedWords(correo.Contract_email__c)) {
                correo.DatoPalabraRestringida__c = true;
                blnNeedsUpdate = true;
            }
            
            if (blnNeedsUpdate) {
                lstCorreosToUpdate.add(correo);
            }

        }

        return lstCorreosToUpdate;
       
    }
    
}