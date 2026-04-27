/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Clase test		:   
* Description       :   Clase para la segmentacion de clientes
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         09-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public without sharing class PSTA_SegmentacionClientes_cls {

    public static List<Account> segmentacionClientes(List<Account> lstClientes) {

        List<Account> lstClientesParaActualizar        =  PSTA_FechaPrimerContacto_cls.procesarFechas(lstClientes);

        return lstClientesParaActualizar;

    }

    public static void updateRecords(List<SObject> lstRecords){
        Map<String, String> mapErrors = new Map<String, String>();
        Database.SaveResult[] updateList = Database.update(lstRecords, false);
        for(Database.SaveResult saveResult : updateList){
            if(!saveResult.isSuccess()){
                mapErrors = new Map<String, String>();
                Integer intCount = 0;
                for(Database.Error error : saveResult.getErrors()){
                    mapErrors.put('Numero de errores: ' + intCount, error.getMessage());
                    intCount++;
                }
            }
        }
        if(!mapErrors.isEmpty()){
            saveLogError(mapErrors, 'Error durante Actualizacion de segmento de cuenta', 'ERROR_BATCH_SEGMENTACION_001', '');
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