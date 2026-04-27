/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Gallegos Alan
* Project           :   Post Venta
* Clase test		:   
* Description       :   Clase para la creación y actualización del objeto Resumen
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         24-Jun-2025       Gallegos Alan              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public without sharing class PSTA_RegistroResumenGlobal_cls {
     
    public static Map<String,SObject> getResumenesActuales() {

        List<SObject> lstResumenes = [SELECT Id,ExternalId_Nomina__c,Meta__c,Contactados__c FROM ResumenGlobalPostventa__c];
        Map<String,SObject> mapResumenesPorActualizar =  new Map<String,SObject>();

        for(SObject objectAux : lstResumenes){
            mapResumenesPorActualizar.put(String.valueOf( objectAux.get('ExternalId_Nomina__c') ), objectAux);
        }

        return mapResumenesPorActualizar;

    }

    public static Map<String,Integer> getMetaByAccount(List<String> lstAsesores) {
        Map<String,Integer> mapAsesorByMeta = new Map<String,Integer>();

        List<AggregateResult> resultados = [
            SELECT ID_Asesor__c asesorId, COUNT(Id) totalCuentas
            FROM Account 
            WHERE ID_Asesor__c IN :lstAsesores
                AND ID_Asesor__c != null 
                AND ContactoPriorizadoEsteMes__c = true 
                AND PriorizacionContacto__c = true 
                AND EstatusContacto__c = 'Pendiente'
            GROUP BY ID_Asesor__c
        ];

        for (AggregateResult ar : resultados) {
            String asesorId = (String)ar.get('asesorId');
            Integer totalCuentas = (Integer)ar.get('totalCuentas');
            mapAsesorByMeta.put(asesorId, totalCuentas);
        }

        return mapAsesorByMeta;
    }

    public static Map<String,Integer> getAllDivisions() {

        Map<String,Integer> mapaDivisionesMeta = new Map<String,Integer>();

        List<ConfiguracionActinver__c> lstMetasPorDia = [SELECT Id, Name, Segmento__c, ClientesContactarPorDia__c
                                                        FROM ConfiguracionActinver__c   
                                                        WHERE ClientesContactarPorDia__c != null];
        
        for(ConfiguracionActinver__c aux : lstMetasPorDia){
            mapaDivisionesMeta.put(aux.Segmento__c,Integer.valueOf( aux.ClientesContactarPorDia__c) );
        }
                                                  
        return mapaDivisionesMeta;

    }


    public static Map<String,String> getUserIds() {

        Map<String,String> mapIdAsesorIdUser = new Map<String,String>();
        Set<String> lstExternalIdsBankers = new Set<String>();

        List<Banker> lstBankers = [SELECT Id, Division__c, Cargo__c, ExternalId__c
                                  FROM Banker   
                                  WHERE ExternalId__c != null];

        for(Banker aux : lstBankers){
            lstExternalIdsBankers.add(aux.ExternalId__c);
        }
        
        
        // List<String> bnkIds = new List<Id>(new Map<Id, Banker>(lstBankers).keySet());

        List<User> listaUsers = [SELECT Id, Name, ID_ASESOR__c
                                FROM User WHERE ID_ASESOR__c IN :lstExternalIdsBankers AND IsActive = true];
        
        for(User aux : listaUsers){
            mapIdAsesorIdUser.put(aux.ID_ASESOR__c, aux.Id );
        }
                                                  
        return mapIdAsesorIdUser;

    }

    public static void upsertRecords(List<SObject> lstRecords){
        Map<String, String> mapErrors = new Map<String, String>();
        Database.UpsertResult[] upsertList = Database.upsert(lstRecords,ResumenGlobalPostventa__c.ExternalId_Nomina__c, false);
        for(Database.UpsertResult saveResult : upsertList){
            if(!saveResult.isSuccess()){
                mapErrors = new Map<String, String>();
                Integer intCount = 0;
                for(Database.Error error : saveResult.getErrors()){
                    mapErrors.put('Error' + intCount, error.getMessage());
                    mapErrors.put('Registro', saveResult.getId());
                    intCount++;
                }
                if(!mapErrors.isEmpty()){
                    saveLogError(mapErrors, 'Error durante la creacion del resumen global de contacto de asesor', 'ERROR_BATCH_RESUMENES_001', '');
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