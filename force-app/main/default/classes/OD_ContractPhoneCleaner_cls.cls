/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Clase test		:   OD_ContractPhoneCleaner_tst
* Description       :   Clase para la validacion del telefono de los registros de tipo Telefono_de_Contrato.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         21-Nov-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public with sharing class OD_ContractPhoneCleaner_cls {
   
    /**
    * @description Valida si el telefono de contrato tiene un contrato relacionado
    * @param objCorreoDeContrato Registro de tipo de correo de contrato a validar
    * @return Boolean Devuelve true si el correo de contrato tiene un contrato relacionado , false en caso contrario
    **/
    public static Boolean ValidateExistingRelatedContract(Telefono_de_Contrato__c objTelefonoDeContrato){

        return String.isNotBlank(objTelefonoDeContrato.IDSap__c); 
        
    }

    /**
    * @description Metodo para validar y actualizar los telefonos de contrato
    * @param lstTelefonosDeContrato Lista de registros de telefonos a validar.
    * @return List<Telefono_de_Contrato__c> Lista de registros de telefonos actualizados.
    **/
    public static List<Telefono_de_Contrato__c> ValidateAndUpdateRecords(List<Telefono_de_Contrato__c> lstTelefonosDeContrato){

        List<Telefono_de_Contrato__c> lstTelefonosToUpdate = new List<Telefono_de_Contrato__c>();

        Map<String,ConfiguracionTelefonicaRegional__mdt> mapLadasByConfig = getLadasMap();
        Map<String,Integer> mapCodigoAreaByLadaConfigMap = getPaisByTotalDigitosMap();
       
        ConfiguracionTelefonicaRegional__mdt config;
        Integer intAreaCodeDigits;
        Boolean blnNeedsUpdate;
        
        for(Telefono_de_Contrato__c telefono : lstTelefonosDeContrato){

            blnNeedsUpdate = false;

            if(!ValidateExistingRelatedContract(telefono)){
                telefono.DatoContactoNoValido__c = true;
                blnNeedsUpdate = true;
            }

            if (String.isBlank(telefono.Area_Code__c)) {
                telefono.DatoCodigoAreaNoValido__c = true;
                blnNeedsUpdate = true;
            }

            if(String.isBlank(telefono.Lada__c)){
                telefono.DatoLadaNoValida__c = true;
                blnNeedsUpdate = true;
            }

            if(String.isBlank(telefono.Phone__c)){
                telefono.DatoTelefonoNoValido__c = true;
                blnNeedsUpdate = true;
            }

            if (!mapCodigoAreaByLadaConfigMap.containsKey(telefono.Area_Code__c)) {
                telefono.DatoCodigoAreaNoValido__c = true;
                blnNeedsUpdate = true;

                intAreaCodeDigits = VerifyAreaCodeStringInKeyMap(mapCodigoAreaByLadaConfigMap, telefono.Area_Code__c);

                if(intAreaCodeDigits != null){
                    telefono.AreaCodeBackup__c = telefono.Area_Code__c;
                    telefono.Area_Code__c = telefono.Area_Code__c.right(intAreaCodeDigits);
                    
                }

            }



            if(!mapLadasByConfig.containsKey(telefono.Lada__c)){
                
                telefono.DatoLadaNoValida__c = true;
                blnNeedsUpdate = true;
                config = VerifyLadaStringInKeyMap(mapLadasByConfig, telefono.Lada__c);

                if (config != null) {

                    telefono.LadaBackup__c = telefono.Lada__c;
                    telefono.Lada__c = telefono.Lada__c.right(config.TotalDigitosLada__c.intValue());

                    if (telefono.Phone__c.length() != config.TotalDigitosNumericos__c) {
                        telefono.PhoneBackup__c = telefono.Phone__c;
                        telefono.Phone__c = telefono.Phone__c.right(config.TotalDigitosNumericos__c.intValue());

                        telefono.DatoTelefonoNoValido__c = !VerifyPhoneStructure(config.ConfiguracionExpresionRegular__r.Regex__c, telefono.Phone__c);
                    }else{
                        telefono.DatoTelefonoNoValido__c = !VerifyPhoneStructure(config.ConfiguracionExpresionRegular__r.Regex__c, telefono.Phone__c);
                    }
                    
                }else{
                    telefono.DatoTelefonoNoValido__c = true;
                }

            }else {
                config = mapLadasByConfig.get(telefono.Lada__c);

                if (telefono.Phone__c.length() != config.TotalDigitosNumericos__c) {
                    blnNeedsUpdate = true;
                    telefono.PhoneBackup__c = telefono.Phone__c;
                    telefono.Phone__c = telefono.Phone__c.right(config.TotalDigitosNumericos__c.intValue());
                    telefono.DatoTelefonoNoValido__c = !VerifyPhoneStructure(config.ConfiguracionExpresionRegular__r.Regex__c, telefono.Phone__c);
                }else{
                    blnNeedsUpdate = true;
                    telefono.DatoTelefonoNoValido__c = !VerifyPhoneStructure(config.ConfiguracionExpresionRegular__r.Regex__c , telefono.Phone__c);
                }
            }

            if (blnNeedsUpdate) {
                lstTelefonosToUpdate.add(telefono);
            }

        }        

        return lstTelefonosToUpdate;
    }




    /**
    * @description Metodo que genera un mapa de codigos de lada con su respectiva cantidad de digitos y configuracion telefonica.
    * @return Map<String, ConfiguracionTelefonicaRegional__mdt> Mapa de ladas con su respectiva cantidad de digitos y configuracion telefonica
    **/
    public static Map<String,ConfiguracionTelefonicaRegional__mdt> getLadasMap(){
        Map<String, ConfiguracionTelefonicaRegional__mdt> mapLadasByLadaConfig = new Map<String, ConfiguracionTelefonicaRegional__mdt>();

        // Obtener todos los registros del Custom Metadata
        List<ConfiguracionTelefonicaRegional__mdt> lstConfifuracionTelefonica = [SELECT Id, CodigoPais__c, Lada__c, TotalDigitos__c, TotalDigitosCodigoPais__c, TotalDigitosLada__c, TotalDigitosNumericos__c, ConfiguracionExpresionRegular__r.Regex__c FROM ConfiguracionTelefonicaRegional__mdt];
        
        // Poblar el mapa con la clave y los registros
        for (ConfiguracionTelefonicaRegional__mdt record : lstConfifuracionTelefonica) {
            if (String.isNotBlank(record.Lada__c)) {
                String strLadaKey = record.Lada__c;
                mapLadasByLadaConfig.put(strLadaKey, record); 
            }
        }
        
        return mapLadasByLadaConfig;

    }

    /**
    * @description Metodo que genera un mapa de codigos de pais con su respectiva cantidad de digitos.
    * @return Map<String, Integer> Mapa de codigos de pais con su respectiva cantidad de digitos
    **/
    public static Map<String, Integer> getPaisByTotalDigitosMap() {

        Map<String, Integer> mapCodigoPaisByTotalDigitos = new Map<String, Integer>();
    
        List<ConfiguracionTelefonicaRegional__mdt> lstConfiguracionTelefonica = [
            SELECT CodigoPais__c, TotalDigitosCodigoPais__c 
            FROM ConfiguracionTelefonicaRegional__mdt
        ];
    
        for (ConfiguracionTelefonicaRegional__mdt record : lstConfiguracionTelefonica) {
            if (String.isNotBlank(record.CodigoPais__c)) {
                String strKey = record.CodigoPais__c;
    
                if (!mapCodigoPaisByTotalDigitos.containsKey(strKey)) {
                    mapCodigoPaisByTotalDigitos.put(strKey, record.TotalDigitosCodigoPais__c.intValue());
                }
            }
        }
    
        return mapCodigoPaisByTotalDigitos;
    }

    /**
    * @description Verifica la existencia de una cadena de texto (Lada) dentro de un mapa.
    * @param mapKeyStringMap Mapa que contiene las ladas por su configuracion telefonica
    * @param strCadenaConLlave Cadena de texto a encontrar en el mapa.
    * @return ConfiguracionTelefonicaRegional__mdt Registro de la metadata con la informacion sobre la configuracion telefonica
    **/
    public static ConfiguracionTelefonicaRegional__mdt VerifyLadaStringInKeyMap(Map<String,ConfiguracionTelefonicaRegional__mdt> mapKeyStringMap, String strCadenaConLlave){
        
        if (String.isBlank(strCadenaConLlave)) {
            return null; 
        }

        for (String key : mapKeyStringMap.keySet()) {
            if (strCadenaConLlave.contains(key)) {
                return mapKeyStringMap.get(key);
            }
        }

        // Si no se encuentra coincidencia, devolver null
        return null;
    }

    /**
    * @description Metodo que devuelve la cantidad de digitos de una codigo de pais.
    * @param mapKeyStringMap Mapa de llaves de la metadata de codigos de paises.
    * @param strCadenaConLlave Cadena de texto que contiene o no al codigo de pais a encontrar en el mapa.
    * @return Integer Cantidad de digitos del codigo de area
    **/
    public static Integer VerifyAreaCodeStringInKeyMap(Map<String,Integer> mapKeyStringMap, String strCadenaConLlave){
        
        if (String.isBlank(strCadenaConLlave)) {
            return null; 
        }

        for (String key : mapKeyStringMap.keySet()) {
            if (strCadenaConLlave.contains(key)) {
                return mapKeyStringMap.get(key);
            }
        }

        return null;
    }

    /**
    * @description Metodo que compara una cadena de texto con una expresion regular de telefonos.
    * @param strRegex Cadena de texto con la expresion regular.
    * @param strPhone Cadena de texto con el telefono.
    * @return Boolean Devuelve true si contiene un formato valido, false en caso contrario.
    **/
    public static Boolean VerifyPhoneStructure(String strRegex, String strPhone) {
        return Pattern.matches(strRegex, strPhone);
    }

    
}