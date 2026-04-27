/**
 * @description       : 
 * @author            : Martin Martinez
 * @group             : 
 * @last modified on  : 09-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class PV_GenerarTareasPeriodicas {

    private static Id businessHoursId = PV_GenerarTareasPeriodicasSelector_cls.getDiasLaborales();    
    @TestVisible private static Set<Id> testValidContractAccountIdsOverride;
    @TestVisible private static Boolean testUseValidContractFilter = false;
    public static String planeacionFinanciera = PSTA_UtilityClass.DEVELOPERNAME_PLANEACION_FINANCIERA;
    public static String propuestaInversion = PSTA_UtilityClass.DEVELOPERNAME_PROPUESTA_INVERSION;
    public static String biometricos = PSTA_UtilityClass.DEVELOPERNAME_BIOMETRICOS;
    public static String bancaElectronica = PSTA_UtilityClass.DEVELOPERNAME_BANCA_ELECTRONICA;


    public static List<Account> obtenerCuentasValidas(List<sObject> cuentasEntrada) {
        List<Account> cuentas = (List<Account>) cuentasEntrada;
        Set<Id> availableContactIds = getAccountsWithAvailableCadenceSlot(getContactsId(cuentas));//new Map<Id, Account>(cuentas).keySet();
        if (availableContactIds.isEmpty()) {
            return new List<Account>();
        }
        cuentas = filtrarCuentas(cuentas, availableContactIds, true);
        if (cuentas.isEmpty()) {
            return new List<Account>();
        }

        Set<Id> accountIds = getAccountsWithValidContracts(new Map<Id, Account>(cuentas).keySet());
        if (accountIds.isEmpty()) {
            return new List<Account>();
        }

        cuentas = filtrarCuentas(cuentas, accountIds, false);
        if (cuentas.isEmpty()) {
            return new List<Account>();
        }

        accountIds = new Map<Id, Account>(cuentas).keySet();
        Set<Id> cuentasInvalidasIds = new Set<Id>();

        // Obtener contratos relacionados a las cuentas
        List<Contract> contratos = PV_GenerarTareasPeriodicasSelector_cls.getContratosClienteNoContactar(accountIds);

        if (contratos.isEmpty()) {
            return cuentas;
        }

        // Validar cuentas con contratos con los tres campos poblados
        for (Contract con : contratos) {
            cuentasInvalidasIds.add(con.AccountId);
        }

        // Filtrar cuentas que no estén marcadas como inválidas
        return filtrarCuentas(cuentas, cuentasInvalidasIds, false);
    }

    public static Set<Id> getAccountsWithValidContracts(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new Set<Id>();
        }

        if (Test.isRunningTest()) {
            if (testValidContractAccountIdsOverride != null) {
                return new Set<Id>(testValidContractAccountIdsOverride);
            }

            if (!testUseValidContractFilter) {
                return accountIds;
            }
        }

        try {
            ConfiguracionActinver__c contractConfig = PSTA_SegmentacionClientesSelector_cls.getConfiguracionContratosPostventa();
            Set<String> validContractTypes = PSTA_UtilityClass.splitValuesMultiPickList(contractConfig.TipoContratos__c);
            Set<String> validContractStatuses = PSTA_UtilityClass.splitValuesMultiPickList(contractConfig.EstatusContrato__c);

            if (validContractTypes.isEmpty() || validContractStatuses.isEmpty()) {
                return accountIds;
            }

            return PV_GenerarTareasPeriodicasSelector_cls.getAccountsWithValidContracts(
                accountIds,
                validContractTypes,
                validContractStatuses
            );
        } catch (Exception ex) {
            System.debug('No fue posible obtener la configuracion de contratos Postventa: ' + ex.getMessage());
            return accountIds;
        }
    }

    public static Set<Id> getAccountsWithAvailableCadenceSlot(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return new Set<Id>();
        }

        if (Test.isRunningTest()) {
            return accountIds;
        }

        // Consultar los targets y contar las cadencias activas por cliente
        Map<Id, Integer> activeCadenceCount = new Map<Id, Integer>();

        List<ActionCadenceTracker> targets = [
            SELECT Id, TargetId
            FROM ActionCadenceTracker
            WHERE TargetId IN :accountIds
            AND State = 'Running'
        ];

        for (ActionCadenceTracker t : targets) {
            activeCadenceCount.put(
                t.TargetId,
                activeCadenceCount.containsKey(t.TargetId) ? activeCadenceCount.get(t.TargetId) + 1 : 1
            );
        }

        Set<Id> availableAccounts = new Set<Id>();
        for (Id accId : accountIds) {
            if (!activeCadenceCount.containsKey(accId) || activeCadenceCount.get(accId) < 5) {
                availableAccounts.add(accId);
            }
        }

        System.debug('availableAccounts:' + availableAccounts);
        return availableAccounts;
    }

    public static Map<String, Object> createMapsToReference(List<Account> lstAccounts){
        Map<Id, List<Id>> mapAccount = new Map<Id, List<Id>>();
        Set<Id> setBMemberId = new Set<Id>();
        Map<String, Object> mapResult = new Map<String, Object>();
        for (Account ac : lstAccounts) {
            Id memberId = ac.BanqueroAsignado__c != null ? ac.BanqueroAsignado__r.BusinessUnitMemberId : null;
            if (memberId != null) {
                setBMemberId.add(memberId);

                if (!mapAccount.containsKey(memberId)) {
                    mapAccount.put(memberId, new List<Id>());
                }
                mapAccount.get(memberId).add(ac.Id);
            }
        }
        mapResult.put('mapAccount', mapAccount);
        mapResult.put('setBMemberId', setBMemberId);
        return mapResult;
    }

    public static Map<Id, Id> getMapBankerAccount(Set<Id> setBMemberId, Map<Id, List<Id>> mapAccount){
        Map<Id, Id> mapBankerAccount = new Map<Id, Id>();
        for(Banker bank : PV_GenerarTareasPeriodicasSelector_cls.getBankerByBusinessMemberId(setBMemberId)){
            if (mapAccount.containsKey(bank.Id)) {
                List<Id> cuentas = mapAccount.get(bank.Id);
                for (Id cuentaId : cuentas) {
                    if (!mapBankerAccount.containsKey(cuentaId)) {
                        mapBankerAccount.put(cuentaId, bank.UserOrContactId);
                    }
                }
            }
        }
        return mapBankerAccount;
    }

    public static List<Account> obtenerCuentasValidasParaAsignarCadencia(List<Account> cuentas, String developerNameCadencia, Integer numeroDias) {
        List<Account> cuentasValidas = new List<Account>();
        Set<Id> cuentaIds = new Map<Id, Account>(cuentas).keySet();

        if (cuentaIds.isEmpty()) {
            return cuentasValidas;
        }

        // Obtener las tareas para esas cuentas con el developerName indicado, ordenadas descendente por CreatedDate
        List<Task> tareas = PV_GenerarTareasPeriodicasSelector_cls.getTask(cuentaIds,developerNameCadencia);

        // Map para guardar la última tarea por cuenta
        Map<Id, Task> ultimaTareaPorCuenta = new Map<Id, Task>();
        for (Task t : tareas) {
            if (!ultimaTareaPorCuenta.containsKey(t.AccountId)) {
                ultimaTareaPorCuenta.put(t.AccountId, t);
            }
        }

        Date hoy = Date.today();

        for (Account acc : cuentas) {
            Task ultimaTarea = ultimaTareaPorCuenta.get(acc.Id);
            Boolean esValida = false;

            if (ultimaTarea == null) {
                // No tiene tarea -> válido
                esValida = true;
            } else {
                Date fechaTentativa = PSTA_UtilityClass.agregarDiasLaborales(
                    ultimaTarea.CreatedDate.date(),
                    numeroDias,
                    businessHoursId
                );
                if (fechaTentativa == hoy) {
                    esValida = true;
                }
            }

            if (esValida) {
                cuentasValidas.add(acc);
            }
        }

        return cuentasValidas;
    }   

    public static List<Account> validarTareaPorCuenta(List<Account> cuentas, String developerNameCadencia) {
        List<Account> cuentasValidas = new List<Account>();

        if (cuentas.isEmpty()) {
            System.debug('No hay cuentas para validar');
            return cuentasValidas;
        }

        for (Account acc : cuentas) {
            Boolean agregarCuenta = false;
            if (developerNameCadencia == biometricos) {
                agregarCuenta = acc.EnrolamientoBiometricos__c == '0' || String.isBlank(acc.EnrolamientoBiometricos__c);
            } else if (developerNameCadencia == bancaElectronica) {
                agregarCuenta = acc.EnrolamientoActivo__c == '0'|| String.isBlank(acc.EnrolamientoActivo__c);
            } else {
                agregarCuenta = true;
            }

            if (agregarCuenta) {
                cuentasValidas.add(acc);
            }
        }

        return cuentasValidas;
    }

    public static List<Account> validarTareaPorContrato(List<Account> cuentas, String developerNameCadencia, List<Contract> contratos) {
        Set<Id> accountContratosValidos = new Set<Id> ();  
        List<Account> cuentasValidas = new List<Account>();

        if (contratos.isEmpty()) {
            System.debug('No hay contratos para validar');
            return cuentasValidas;
        }

        Set<Id> cuentasConContratos = new Set<Id>();
        for (Contract con : contratos) {
            Boolean agregarCuenta = false;
            if (developerNameCadencia == planeacionFinanciera) {
                agregarCuenta = !con.PlaneacionFinancieraCompletada__c;
            } else if (developerNameCadencia == propuestaInversion) {
                agregarCuenta = !con.PropuestaInversionCompletada__c;
            } else {
                agregarCuenta = true;
            }

            if (agregarCuenta) {
                accountContratosValidos.add(con.AccountId);
            }            
        }

        for (Account acc : cuentas) {
            if (accountContratosValidos.contains(acc.Id)) {
                cuentasValidas.add(acc);
            }
        }

        return cuentasValidas;
    }  

    public static List<PV_GenerarTareasPeriodicas_Request> generarCadenceItems(Id cadenceId, List<Account> cuentas, Map<Id, Id> mapBankerAccount, String developerNameCadencia) {
        List<PV_GenerarTareasPeriodicas_Request> items = new List<PV_GenerarTareasPeriodicas_Request>();

        for (Account acc : cuentas) {
            String userId = mapBankerAccount.get(acc.Id);
            if (userId != null) {
                items.add(new PV_GenerarTareasPeriodicas_Request(
                    String.valueOf(cadenceId),
                    acc.Id,
                    userId
                ));
            }
        }
        return items;
    }

    public static List<Account> filtrarAccountsConCadencias(List<Account> cuentas, ActionCadence cadence) {
        Set<Id> contactIds = getContactsId(cuentas);
        String developerName = cadence.DeveloperName__c;
        List<ActionCadenceTracker> trackers = PV_GenerarTareasPeriodicasSelector_cls.validateCadenceActive(contactIds,developerName,cadence.TareaUnicaPorCuenta__c);

        Set<Id> cuentasCadenceActive = new Set<Id>();
        for (ActionCadenceTracker tracker : trackers) {
            cuentasCadenceActive.add(tracker.TargetId);
        }

        return filtrarCuentas(cuentas, cuentasCadenceActive,true);
    }
    
    public static void generarRequestCadence(List<ActionCadence> lstCadence, List<Account> cuentas, Map<Id, Id> mapBankerAccount) {
        try {
            List<PV_GenerarTareasPeriodicas_Request> inputsList = new List<PV_GenerarTareasPeriodicas_Request>();

            List<Contract> lstContractClientes = obtenerContratos(cuentas);

            for (ActionCadence cadence : lstCadence) {
                String developerName = cadence.DeveloperName__c;
                List<Account> cuentasFiltradas = filtrarAccountsConCadencias(cuentas, cadence);
                List<Account> cuentasValidas = new List<Account>();

                if (cadence.TareaUnicaPorCuenta__c) {
                    System.debug('Validando tareas únicas por cuenta para DeveloperName: ' + developerName);
                    cuentasValidas = validarTareaPorCuenta(cuentasFiltradas, developerName);

                } else if (cadence.TareaUnicaPorContrato__c) {
                    System.debug('Validando tareas únicas por contrato para DeveloperName: ' + developerName);
                    cuentasValidas = validarTareaPorContrato(cuentasFiltradas, developerName, lstContractClientes);

                } else {
                    Integer periodicidad = cadence.Periodicidad__c != null ? cadence.Periodicidad__c.intValue() : 0;
                    System.debug('Validando tareas por periodicidad (' + periodicidad + ') para DeveloperName: ' + developerName);
                    cuentasValidas = obtenerCuentasValidasParaAsignarCadencia(cuentasFiltradas, developerName, periodicidad);
                }

                System.debug('cuentasValidas.size: ' + cuentasValidas.size() + ' para DeveloperName: ' + developerName);

                if (!cuentasValidas.isEmpty()) {
                    inputsList.addAll(generarCadenceItems(cadence.Id, cuentasValidas, mapBankerAccount, developerName));
                }
            }


            if (!inputsList.isEmpty()) {
                System.debug('inputsList.size: ' + inputsList.size());
                System.enqueueJob(new PV_EjecutarAsignacionCadencias_Queueable(inputsList,0));                
            }else{
                System.debug('No hay cadencias para asignar');
            }
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage() + ' - Línea: ' + ex.getLineNumber());
            Map<String, String> mapErrors = new Map<String, String>{
                'Error' => ex.getMessage(),
                'Linea' => String.valueOf(ex.getLineNumber())
            };
            saveLogError(mapErrors, 'Error durante Generación de las cadencias', 'ERROR_BATCH_CADENCIAS', '');
        }       
    }

    public static List<Contract> obtenerContratos(List<Account> cuentas) {
        Set<Id> accountIds = new Map<Id, Account>(cuentas).keySet(); 
        return PV_GenerarTareasPeriodicasSelector_cls.getContratosNoPropuestaPlaneacion(accountIds);

    }

    public static Set<Id> getContactsId(List<Account> cuentas) {
        Set<Id> contactIds = new Set<Id>();  
        for (Account acc : cuentas) {
            if (acc.PersonContactId != null) {
                contactIds.add(acc.PersonContactId);
            }
        } 
        return contactIds;
    }

    public static List<Account> filtrarCuentas(List<Account> cuentas, Set<Id> cuentasYaProcesadas, Boolean usarPersonContactId) {
        List<Account> cuentasValidas = new List<Account>();
        for (Account acc : cuentas) {
            Id idEvaluar = usarPersonContactId ? acc.PersonContactId : acc.Id;
            if (idEvaluar != null && !cuentasYaProcesadas.contains(idEvaluar)) {
                cuentasValidas.add(acc);
            }
        }
        return cuentasValidas;
    }

    public static void saveLogError(Map<String, String> mapErrors, String message, String errorCode, String type){
        EventLogger.error(new Map<String, String>{'contextId' => null,
                                                    'type' => '',
                                                    'errorCode' => errorCode,
                                                    'message'   => message,
                                                    'request'   => JSON.serializePretty(mapErrors)});
    }  

    public static void saveErrorFlow(List<String> errores){
        if (errores != null && !errores.isEmpty()) {
            Map<String, String> mapErrors = new Map<String, String>();
            Integer intCount = 0;
            for(String error : errores){
                mapErrors.put('Error ' + intCount, error);
                intCount++;
            }
            saveLogError(mapErrors, 'Error durante Generación de las cadencias', 'ERROR_BATCH_CADENCIAS', '');
        }
    }
}
