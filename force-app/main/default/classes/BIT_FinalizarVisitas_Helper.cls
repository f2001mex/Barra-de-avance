/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
* Project           :   Bitácora anfitrión
* Clase test		:   BIT_FinalizarVisitas_Helper_Test
* Description       :   Clase helper de batch para finalización de visitas
*--------------------------------------------------------------------------
* No.            Date              Author             Description
* 1.0         10-Ene-2025       Salvador Ramírez           Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class BIT_FinalizarVisitas_Helper {
    public static List<Servicio__c> getServicios(Set<Id> visitasIds){
        return [
            SELECT Id, Etapa__c, Visita__c, Name
            FROM Servicio__c 
            WHERE Visita__c IN :visitasIds 
            AND Etapa__c != 'Finalizado'
            AND Etapa__c != 'Pre-registro'
        ];
    }
    public static void updateRecords(List<SObject> lstRecords, Map<Id, String> mapRecords){
        Map<String, String> mapErrors = new Map<String, String>();
        Database.SaveResult[] updateList = Database.update(lstRecords, false);
        for(Database.SaveResult saveResult : updateList){
            if(!saveResult.isSuccess()){
                mapErrors = new Map<String, String>();
                Integer intCount = 0;
                for(Database.Error error : saveResult.getErrors()){
                    mapErrors.put('Error' + intCount, error.getMessage());
                    mapErrors.put('Registro', mapRecords.get(saveResult.getId()));
                    intCount++;
                }
                if(!mapErrors.isEmpty()){
                    saveLogError(mapErrors, 'Error durante finalización automática de visitas', 'ERROR_BATCH_FINALIZAR_001', '');
                }
            }
        }
    }
    public static void saveLogError(Map<String, String> mapErrors, String message, String errorCode, String type){
        EventLogger.error(new Map<String, String>{'contextId' => null,
                                                    'type' => '',
                                                    'errorCode' => errorCode,
                                                    'message'   => message,
                                                    'request'   => JSON.serializePretty(mapErrors)});
    }
}