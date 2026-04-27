/****************************************************************************************************
Desarrollado por: VASS MÉXICO
Proyecto        : Actinver - Bitácora 
Descripción     : Clase controlador del Lightning Web Component bIT_ProcesoVisita_lwc y subcomponentes relacionados.
 
Cambios (Versiones)
-----------------------------------------------------------------------------------------------------
No.          Fecha            Autor                             Descripción
-----   ----------      --------------------   -----------------------------------------------------
1.0     2024-08-22          VASS MÉXICO                      Creación de la Clase.                                       
*/
public with sharing class BIT_ProcesoVisita_ctr {
    /**
    * @description : obtiene el set de campos deshabilitados de "Servicio__c" a través del Nombre API correspondiente
    * @param   fieldSetName : Nombre API del FieldSet enviado por el LWC
    * @param   objectName : Nombre API del sObject enviado por el LWC
    * @return  String
    **/
    @AuraEnabled
    public static Map<String, Object> getDisabledFields(Map<String, Object> mapParams) {
        Map<String, Object> mapResponse = new Map<String, Object>();
        // · Obtener variables de entrada
        String strFieldsetEnabled    = (String) mapParams.get('strFieldsetEnabled');
        String strFieldsetDisabled   = (String) mapParams.get('strFieldsetDisabled');
        String strObjectApiName   = (String) mapParams.get('strObjectApiName');

        mapResponse.put('disabledFields', ACTINVER_UtilityFactory_utils.getValueFieldSet(strFieldsetDisabled, strObjectApiName));
        mapResponse.put('enabledFields', ACTINVER_UtilityFactory_utils.getValueFieldSet(strFieldsetEnabled, strObjectApiName));
        
        return mapResponse;
    }
    /**
    * @description : obtiene el set de campos deshabilitados de "Servicio__c" a través del Nombre API correspondiente
    * @param   fieldSetName : Nombre API del FieldSet enviado por el LWC
    * @param   objectName : Nombre API del sObject enviado por el LWC
    * @return  String
    **/
    @AuraEnabled
    public static void getFieldsToUpdate(String recordId, Map<String, Object> mapFields) {

        Visita__c recordVisita = new Visita__c();
        recordVisita.id = recordId;
        for (String fieldName : mapFields.keySet()) {
            Object fieldValue = mapFields.get(fieldName);
            
            if (fieldName == 'HoraSalida__c' && fieldValue instanceof String) {
                Datetime dtValue = Datetime.valueOf((String)fieldValue);
                recordVisita.put(fieldName, dtValue);
            } else recordVisita.put(fieldName, fieldValue);
        }
        update recordVisita;
    }
        /**
    * @description : Actualiza la visita a la etapa de "Iniciado"
    * @param   recordId : Id SF de la visita
    * @return  String
    **/
    @AuraEnabled
    public static string changeStageVisitToStart(String recordId) {
        Visita__c recordVisita = new Visita__c();
        recordVisita.id = recordId;
        recordVisita.Etapa__c = 'Iniciado';
        try{
            update recordVisita;
            return 'Success';
        }catch(Exception e){
            return String.valueOf(e.getMessage());
        }
    }
    
}