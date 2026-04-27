/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Yesica Navarro
* Project           :   Org. de Datos
* Clase test		:   
* Description       :   Clase exclusiva para procesar por lotes la eliminación de Cuentas sin Contratos.
*--------------------------------------------------------------------------
* No.            Date              Author             Description
* 1.0         09-Dic-2024       Yesica Navarro          Creación
*--------------------------------------------------------------------------
*******************************************************************************/

global class OD_EliminarCuentasSinContrato_bch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Obtén la consulta desde la etiqueta personalizada
        String query = !Test.isRunningTest() ?  Label.Batch_Account_Query : Label.OD_QueryEliminarContratosTest ;
        System.debug('Query ejecutada: ' + query); 

        // Devuelve el QueryLocator basado en la etiqueta personalizada
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        System.debug('Ejecutando lote con ' + scope.size() + ' registros.');
        // Mapa para almacenar errores
        Map<String, String> mapErrors = new Map<String, String>();
        Database.DeleteResult[] updateList = Database.delete(scope, false);

        // Manejo de errores durante la eliminación
        for (Database.DeleteResult saveResult : updateList) {
            if (!saveResult.isSuccess()) {
                mapErrors = new Map<String, String>();
                Integer intCount = 0;
                for (Database.Error error : saveResult.getErrors()) {
                    mapErrors.put('Error' + intCount, error.getMessage());
                    mapErrors.put('Registro', saveResult.getId());
                    intCount++;
                }
                if (!mapErrors.isEmpty()) {
                    saveLogError(mapErrors, 
                                 'Error en eliminación de cuentas sin contrato', 
                                 'ERROR_BATCH_ELIMINAR_ACCOUNT_001', 
                                 '');
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('Batch finalizado.');
    }
    
    public static void saveLogError(Map<String, String> mapErrors, String message, String errorCode, String type) {
        // Lógica para registrar errores
        EventLogger.error(new Map<String, String>{
            'contextId' => null,
            'type' => '',
            'errorCode' => errorCode,
            'message'   => message,
            'request'   => JSON.serializePretty(mapErrors)
        });
    }
}