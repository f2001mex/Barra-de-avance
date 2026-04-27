/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Gallegos Alan
* Project           :   Post Venta
* Clase test		:   
* Description       :   Clase para el reseteo del estatus de contacto
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         16-Jun-2025       Gallegos Alan              Creación
* 2.0         15-Jul-2025       Gallegos Alan          Se agrega el reset de las banderas de contacto diario
*--------------------------------------------------------------------------
*******************************************************************************/
public without sharing class PSTA_ResetearEstatusContacto_cls {

    //Método para resetear el estatus a 'Pendiente'
    public static Map<Id,Account> resetEstatus(List<Account> lstCuentas) {

        Map<Id,Account> mapCuentasParaActualizar = new Map<Id, Account>();

        for(Account cuenta : lstCuentas) {
            if(cuenta.FechaSiguienteContacto__c != null && cuenta.EstatusContacto__c != 'Pendiente'){

                Boolean resetStatus =  System.today() >= cuenta.FechaSiguienteContacto__c  ?  true : false; 

                if(resetStatus) {

                    Account cuentaActualizada = mapCuentasParaActualizar.get(cuenta.Id);

                    if(cuentaActualizada == null) {
                        cuentaActualizada = new Account(Id = cuenta.Id);
                        mapCuentasParaActualizar.put(cuenta.Id,cuentaActualizada);
                    }
                    cuentaActualizada.EstatusContacto__c = 'Pendiente';
                    cuentaActualizada.PriorizacionContacto__c = false;
                }
            }
        }

        return mapCuentasParaActualizar;

    }

    //Método para ejecutar el update de los registros de cuenta
    public static void updateRecords(List<SObject> lstRecords, Map<Id, Account> mapRecords){
        Map<String, String> mapErrors = new Map<String, String>();
        Database.SaveResult[] updateList = Database.update(lstRecords, false);
        for(Database.SaveResult saveResult : updateList){
            if(!saveResult.isSuccess()){
                mapErrors = new Map<String, String>();
                Integer intCount = 0;
                for(Database.Error error : saveResult.getErrors()){
                    mapErrors.put('Error' + intCount, error.getMessage());
                    mapErrors.put('Registro', mapRecords.get(saveResult.getId()).Name);
                    intCount++;
                }
                if(!mapErrors.isEmpty()){
                    saveLogError(mapErrors, 'Error durante Actualizacion de segmento de cuenta', 'ERROR_BATCH_SEGMENTACION_001', '');
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