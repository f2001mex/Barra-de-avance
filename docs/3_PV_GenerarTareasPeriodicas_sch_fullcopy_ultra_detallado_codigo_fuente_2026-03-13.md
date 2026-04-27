# PV_GenerarTareasPeriodicas_sch - Analisis ultra detallado
Ambiente: fullcopy | Fecha de elaboracion: 2026-03-13

## 1. Alcance y ejecucion en fullcopy
Este documento describe el flujo de `PV_GenerarTareasPeriodicas_sch` en fullcopy. A diferencia de los procesos puramente Apex, este scheduler combina scheduler, helper de business hours, batch, clase de servicio, queueable y un Flow para asignar cadencias comerciales. El impacto funcional no termina en la misma transaccion; parte del efecto ocurre despues, cuando las cadencias generan eventos, trackers y tareas.

- Schedule Job: `PV_GenerarTareasPeriodicas`
- CronExpression: `0 0 2 ? * 2,3,4,5,6,7`
- TimesTriggered: `1`
- NextFireTime UTC: `2026-03-14T08:00:00.000+0000`
- State: `WAITING`
- Label usado: `BatchCadencias_Size_Limit = 200`
- Label adicional: `MesesFiltroTareas = 6`
- ACT_BatchConfig__mdt: `PV_GenerarTareasPeriodicas -> BusinessHoursName__c = Postventa`
- ActionCadence activas en fullcopy: `RemediacionBiometricos`, `FAC`, `PropuestaInversion`, `PlaneacionFinanciera`, `PerspectivaActinver`

## 2. Resumen ejecutivo del flujo
1. El scheduler consulta `ACT_BatchConfig__mdt` y valida `BusinessHours Postventa` antes de arrancar el batch.
2. `PV_GenerarTareasPeriodicas_bch.start()` obtiene desde `PSTA_Consultas__mdt` la query `PSTA_Query_Generar_Tareas` para identificar cuentas elegibles.
3. `PV_GenerarTareasPeriodicas.obtenerCuentasValidas()` descarta cuentas sin cupo de cadencias activas o con contratos marcados como no contactables por tener tres flags de marketing poblados.
4. El batch obtiene las `ActionCadence` activas y construye mapas de referencia entre cuenta, business member y banker.
5. `PV_GenerarTareasPeriodicas.generarRequestCadence()` evalua por cada cadencia si aplica una regla de tarea unica por cuenta, tarea unica por contrato o periodicidad.
6. La salida inmediata no es `insert Task`; es una lista de `PV_GenerarTareasPeriodicas_Request` que se manda a `PV_EjecutarAsignacionCadencias_Queueable`.
7. El Queueable ejecuta el Flow `PV_AsignarCadencesCuentas_Flow`, que usa la accion estandar `assignTargetToSalesCadence` para asignar el target a la cadencia.
8. El efecto posterior puede materializarse en `ActionCadenceStepTracker`, `Task`, eventos de plataforma y actualizaciones de `Account` desde triggers posteriores.

## 3. Diagrama del flujo completo
```text
PV_GenerarTareasPeriodicas_sch.execute(ctx)
  -> ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
         'PV_GenerarTareasPeriodicas',
         new PV_GenerarTareasPeriodicas_bch(),
         Label.BatchCadencias_Size_Limit)

PV_GenerarTareasPeriodicas_bch.start(bc)
  -> PV_GenerarTareasPeriodicasSelector_cls.getQueryAccounts()
  -> SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Generar_Tareas'
  -> QueryLocator de Account

PV_GenerarTareasPeriodicas_bch.execute(bc, scope)
  -> PV_GenerarTareasPeriodicas.obtenerCuentasValidas(scope)
     -> getContactsId(cuentas)
     -> getAccountsWithAvailableCadenceSlot(contactIds)
        -> ActionCadenceTracker WHERE TargetId IN :contactIds AND State = 'Running'
        -> deja cuentas con menos de 5 cadencias activas
     -> getContratosClienteNoContactar(accountIds)
        -> descarta cuentas con contratos donde FLAG_MARKETING__c,
           FLAG_MARKETING_ACTINVER__c y FLAG_EVENTS_INVITATIONS__c estan poblados
  -> getCadence() -> ActionCadence activas
  -> createMapsToReference(lstAccount)
  -> getMapBankerAccount(setBMemberId, mapAccount)
  -> generarRequestCadence(lstCadence, lstAccount, mapBankerAccount)
     -> por cada cadence:
        -> filtrarAccountsConCadencias(...)
        -> validarTareaPorCuenta(...) o validarTareaPorContrato(...) o obtenerCuentasValidasParaAsignarCadencia(...)
        -> generarCadenceItems(...)
     -> System.enqueueJob(new PV_EjecutarAsignacionCadencias_Queueable(inputsList, 0))

PV_EjecutarAsignacionCadencias_Queueable.execute()
  -> procesa chunks de 200 requests
  -> Flow.Interview.PV_AsignarCadencesCuentas_Flow(inputCadenceList = subList)
  -> flow.start()
  -> obtiene errores de salida ErroresAsignacionCadence
  -> PV_GenerarTareasPeriodicas.saveErrorFlow(errores)
  -> si hay mas registros, encola otro queueable

Flow PV_AsignarCadencesCuentas_Flow
  -> loop sobre inputCadenceList
  -> action assignTargetToSalesCadence
     -> input salesCadenceNameOrId
     -> input targetId
     -> input userId
  -> si falla, agrega mensaje a ErroresAsignacionCadence

Efecto posterior de plataforma
  -> Salesforce genera o actualiza ActionCadenceTracker / ActionCadenceStepTracker
  -> al completarse pasos, puede dispararse TriggerActionCadanceStepTracker
  -> PSTA_GestionTareas_Helper actualiza Task y publica PV_FinalizacionCadencia__e
  -> Task_trg puede actualizar Account via PSTA_ChangeAccountInfo_helper
```

## 4. Detalle por clase y metodo
### 4.1 PV_GenerarTareasPeriodicas_sch
1. Implementa `Schedulable`.
2. `execute()` usa `ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay('PV_GenerarTareasPeriodicas', new PV_GenerarTareasPeriodicas_bch(), Integer.valueOf(Label.BatchCadencias_Size_Limit))`.
3. No hace DML directo.

### 4.2 PV_GenerarTareasPeriodicas_bch
1. Implementa `Database.Batchable<SObject>, Database.Stateful`.
2. `start()` obtiene la query base desde `PV_GenerarTareasPeriodicasSelector_cls.getQueryAccounts()`.
3. `execute()` llama `PV_GenerarTareasPeriodicas.obtenerCuentasValidas(scope)`.
4. Si no hay cuentas validas, termina sin procesar.
5. Obtiene `List<ActionCadence>` activas via selector.
6. Construye mapas de referencia entre `BusinessUnitMemberId` y cuentas.
7. Obtiene `mapBankerAccount` para relacionar cuenta con `UserOrContactId` del banker.
8. Llama `PV_GenerarTareasPeriodicas.generarRequestCadence(...)`.
9. `finish()` solo deja debug de cierre.

### 4.3 PV_GenerarTareasPeriodicasSelector_cls
1. `getQueryAccounts()` consulta `PSTA_Consultas__mdt` con `DeveloperName = PSTA_Query_Generar_Tareas`.
2. `getCadence()` consulta `ActionCadence` activas y lee: `Id`, `Name`, `Tipo_de_actividad__c`, `Periodicidad__c`, `DeveloperName__c`, `TareaUnicaPorContrato__c`, `TareaUnicaPorCuenta__c`.
3. `getContratosClienteNoContactar(Set<Id>)` consulta `Contract` con `FLAG_MARKETING__c`, `FLAG_MARKETING_ACTINVER__c`, `FLAG_EVENTS_INVITATIONS__c`.
4. `getBankerByBusinessMemberId(Set<Id>)` consulta `Banker` y recupera `UserOrContactId`, `ExternalId__c`.
5. `validateCadenceActive(Set<Id>, String, Boolean)` consulta `ActionCadenceTracker` en estado `Running` para un `DeveloperName__c` especifico.
6. `getContratosNoPropuestaPlaneacion(Set<Id>)` consulta `Contract` y lee `PlaneacionFinancieraCompletada__c` y `PropuestaInversionCompletada__c`.
7. `getTask(Set<Id>, String)` consulta `Task` por `DeveloperName__c`, `AccountId` y `CreatedDate >= Date.today().addMonths(-MesesFiltroTareas)` ordenando descendente por cuenta y fecha.
8. `getDiasLaborales()` consulta `BusinessHours` con `Name = Postventa`.
### 4.4 PV_GenerarTareasPeriodicas
1. Tiene `businessHoursId = PV_GenerarTareasPeriodicasSelector_cls.getDiasLaborales()`.
2. Declara constantes de developer name para `PlaneacionFinanciera`, `PropuestaInversion`, `Biometricos` y `BancaElectronica`.
3. `obtenerCuentasValidas(List<SObject>)`:
4. Convierte a `List<Account>`.
5. Obtiene `contactIds` con `getContactsId(cuentas)` usando `PersonContactId`.
6. Llama `getAccountsWithAvailableCadenceSlot(contactIds)`.
7. `getAccountsWithAvailableCadenceSlot(...)` consulta `ActionCadenceTracker WHERE TargetId IN :accountIds AND State = 'Running'`.
8. Cuenta cadencias activas por `TargetId` y deja solo cuentas con menos de 5 cadencias activas.
9. Luego consulta `Contract` con `getContratosClienteNoContactar(accountIds)`.
10. Si existen contratos con los tres flags de marketing poblados, marca la cuenta como invalida y la excluye.
11. `createMapsToReference(List<Account>)` arma `mapAccount: BusinessUnitMemberId -> List<AccountId>` y `setBMemberId`.
12. `getMapBankerAccount(...)` consulta `Banker` por business member y construye `AccountId -> UserOrContactId`.
13. `obtenerCuentasValidasParaAsignarCadencia(...)` consulta la ultima `Task` por cuenta y developer name de cadencia.
14. Si no existe tarea previa, la cuenta es valida.
15. Si existe, calcula `fechaTentativa = PSTA_UtilityClass.agregarDiasLaborales(ultimaTarea.CreatedDate.date(), numeroDias, businessHoursId)`.
16. La cuenta solo es valida si `fechaTentativa == hoy`.
17. `validarTareaPorCuenta(...)` aplica reglas exactas para cadencias unicas por cuenta:
18. Si `developerNameCadencia == biometricos`, solo deja cuentas con `EnrolamientoBiometricos__c = '0'` o vacio.
19. Si `developerNameCadencia == bancaElectronica`, solo deja cuentas con `EnrolamientoActivo__c = '0'` o vacio.
20. En otros casos deja pasar la cuenta.
21. `validarTareaPorContrato(...)` aplica reglas exactas para cadencias unicas por contrato:
22. Si la cadencia es `PlaneacionFinanciera`, solo deja contratos donde `PlaneacionFinancieraCompletada__c = false`.
23. Si la cadencia es `PropuestaInversion`, solo deja contratos donde `PropuestaInversionCompletada__c = false`.
24. `filtrarAccountsConCadencias(...)` evita reasignar targets que ya tienen `ActionCadenceTracker` corriendo para la misma cadence.
25. `generarCadenceItems(...)` crea `PV_GenerarTareasPeriodicas_Request(salesCadenceNameOrId, targetId, userId)`.
26. `generarRequestCadence(...)` recorre todas las cadencias activas, aplica las reglas anteriores y encola `PV_EjecutarAsignacionCadencias_Queueable(inputsList, 0)` si hay items.
27. En error usa `saveLogError(...)` y termina en `EventLogger.error(...)`.

### 4.5 PV_GenerarTareasPeriodicas_Request
1. Es un DTO/Wrapper para el Flow.
2. Expone como `@InvocableVariable`: `salesCadenceNameOrId`, `targetId`, `userId`.
3. No hace consultas ni DML.

### 4.6 PV_EjecutarAsignacionCadencias_Queueable
1. Implementa `Queueable`.
2. Recibe la lista completa y un `offset`.
3. `execute()` procesa chunks de 200 requests.
4. Construye un `subList` manualmente entre `offset` y `endList`.
5. Instancia `Flow.Interview.PV_AsignarCadencesCuentas_Flow` con `inputCadenceList = subList`.
6. Ejecuta `flow.start()`.
7. Recupera la salida `ErroresAsignacionCadence`.
8. Llama `PV_GenerarTareasPeriodicas.saveErrorFlow(errores)` para registrar errores del Flow.
9. Si faltan registros, encola otro `PV_EjecutarAsignacionCadencias_Queueable(fullList, endList)`.

### 4.7 Flow PV_AsignarCadencesCuentas_Flow
1. Es un `AutoLaunchedFlow` activo.
2. Recibe la variable de entrada `inputCadenceList` de tipo `PV_GenerarTareasPeriodicas_Request[]`.
3. Itera sobre la coleccion con el loop `Recorrer_las_cadencias`.
4. En cada iteracion invoca la accion estandar `assignTargetToSalesCadence`.
5. Los inputs exactos de la accion son `salesCadenceNameOrId`, `targetId` y `userId`.
6. Si la accion falla, el `faultConnector` lleva a `Almacenar_error`.
7. La formula `ErrorCadencia` concatena `Target: <targetId> - Error: <$Flow.FaultMessage>`.
8. El Flow devuelve `ErroresAsignacionCadence` como salida para que Apex los loguee.
9. La accion estandar realiza un efecto de plataforma; el DML interno sobre objetos de cadencias no es visible en el Apex recuperado.

### 4.8 Impacto posterior: TriggerActionCadanceStepTracker, Task y Account
1. `TriggerActionCadanceStepTracker` corre `after insert` sobre `ActionCadenceStepTrackerChangeEvent` si `Trigger_Management__mdt` indica `CadenceStepTracker = true`.
2. `TriggerActionCadenceStepTracker_thr.onAfterInsert()` llama `PSTA_GestionTareas_Helper.createTaskWithCloseCadence(...)`.
3. `PSTA_GestionTareas_Helper.updateTasksCadence(...)` consulta `Task` por `ActionCadenceStepTrackerId` y actualiza exactamente:
4. `Task.Subject = stepTracker.ActionCadenceName`.
5. `Task.Status = 'Completado'`.
6. `Task.Type = stepTracker.ActionCadence.Tipo_de_actividad__c`.
7. `Task.DeveloperName__c = stepTracker.ActionCadence.DeveloperName__c`.
8. `Task.Description = 'Contacto efectivo ' + cadence.Name + Client_ID__c + Account.Name`.
9. `Task.PV_ExternalID__c = developerName + '-' + Client_ID__c + '-' + ID_Asesor__c + '-' + fecha`.
10. `Task.RecordTypeId = RecordType('Task', 'Postventa')`.
11. Luego publica `PV_FinalizacionCadencia__e` con `TaskId__c`, `AccountId__c`, `UserId__c`.
12. `Task_trg` esta activo `after update` si `Trigger_Management__mdt` indica `TaskTrigger = true`.
13. `Task_thr.onAfterUpdate()` llama `PSTA_ChangeAccountInfo_ctr.changeContactAndDateStatus(...)`.
14. `PSTA_ChangeAccountInfo_helper.changeContacAndDatetStatus(...)` puede actualizar `Account` cuando cambia `El_cliente_fue_contactado__c`, la tarea queda `Completado`, la cadencia `GeneraContacto__c = true`, o la tarea referencia una oportunidad (`WhatId` inicia con `006`).
15. Los campos exactos que puede tocar en `Account` son:
16. `FechaUltimoContacto__c = System.today()`.
17. Si `ClienteNoQuiereSerContactado__c = true`, tambien `FechaNoRequiereSerContacto__c = System.today()` y `EstatusContacto__c = 'Cliente no quiere ser contactado'`.
18. En otro caso, `EstatusContacto__c = 'Contacto efectivo exitoso'` si `El_cliente_fue_contactado__c = 'Si'`, de lo contrario `EstatusContacto__c = 'Contacto no exitoso'`.
19. El helper actualiza `Account` con `Database.update(lstAccToUpdate, false)` y puede disparar encuestas via `PSTA_EnvioEncuestaMedallia_cls.sendSurvey(setTaskUpdate)`.

## 5. Como consulta metadata y como la utiliza
### 5.1 ACT_BatchConfig__mdt y BusinessHours
1. El scheduler usa la clave `PV_GenerarTareasPeriodicas`.
2. El helper lee `BusinessHoursName__c = Postventa`.
3. Con eso resuelve el `BusinessHours.Id` y valida si el dia es habil.

### 5.2 PSTA_Consultas__mdt
1. `PV_GenerarTareasPeriodicasSelector_cls.getQueryAccounts()` consulta `PSTA_Consultas__mdt` con `DeveloperName = PSTA_Query_Generar_Tareas`.
2. La query recuperada en fullcopy trae estos campos base: `Id`, `FechaUltimoContacto__c`, `EnrolamientoBiometricos__c`, `EnrolamientoActivo__c`, `FichaAfinidadCompletada__c`, `PersonContactId`, `BanqueroAsignado__r.BusinessUnitMemberId`.
3. Los filtros observados incluyen `SaldoIntegral__c != null`, `IsPersonAccount = TRUE`, `BanqueroAsignado__c != null`, `ID_Asesor__c IN (...)`.

```sql
SELECT Consulta__c
FROM PSTA_Consultas__mdt
WHERE DeveloperName = 'PSTA_Query_Generar_Tareas'
```

### 5.3 ActionCadence y Labels
1. `getCadence()` toma todas las `ActionCadence` con `State = 'Active'`.
2. `MesesFiltroTareas` controla la ventana historica para buscar tareas previas del mismo `DeveloperName__c`.
3. `BatchCadencias_Size_Limit = 200` controla el tamano del batch inicial.

## 6. Matriz exacta clase -> objeto -> operacion -> campos
- `PV_GenerarTareasPeriodicas_sch` -> `ACT_BatchConfig__mdt` -> Read -> `BusinessHoursName__c` via helper.
- `ACT_BusinessHoursHelper_cls` -> `BusinessHours` -> Read -> `Name = Postventa`, `Id`.
- `PV_GenerarTareasPeriodicasSelector_cls` -> `PSTA_Consultas__mdt` -> Read -> `PSTA_Query_Generar_Tareas`.
- `PV_GenerarTareasPeriodicas_bch` -> `Account` -> Read -> campos del scope.
- `PV_GenerarTareasPeriodicas` -> `ActionCadenceTracker` -> Read -> `TargetId`, `State`.
- `PV_GenerarTareasPeriodicas` -> `Contract` -> Read -> `FLAG_MARKETING__c`, `FLAG_MARKETING_ACTINVER__c`, `FLAG_EVENTS_INVITATIONS__c`, `PlaneacionFinancieraCompletada__c`, `PropuestaInversionCompletada__c`.
- `PV_GenerarTareasPeriodicas` -> `Task` -> Read -> `AccountId`, `CreatedDate`, `DeveloperName__c`.
- `PV_GenerarTareasPeriodicas` -> `Banker` -> Read -> `UserOrContactId`, `ExternalId__c`.
- `PV_GenerarTareasPeriodicas` -> Sin DML directo -> crea requests y encola Queueable.
- `PV_EjecutarAsignacionCadencias_Queueable` -> `Flow` -> Invoke -> `PV_AsignarCadencesCuentas_Flow`.
- `PV_AsignarCadencesCuentas_Flow` -> Sales Cadence assignment -> DML inferido de plataforma -> `assignTargetToSalesCadence`.
- `TriggerActionCadanceStepTracker` / `PSTA_GestionTareas_Helper` -> `Task` -> Update posterior -> `Subject`, `Status`, `Type`, `DeveloperName__c`, `Description`, `PV_ExternalID__c`, `RecordTypeId`.
- `PSTA_GestionTareas_Helper` -> `PV_FinalizacionCadencia__e` -> Publish -> `TaskId__c`, `AccountId__c`, `UserId__c`.
- `Task_trg` / `PSTA_ChangeAccountInfo_helper` -> `Account` -> Update posterior -> `FechaUltimoContacto__c`, `FechaNoRequiereSerContacto__c`, `EstatusContacto__c`.
- `EventLogger` -> `WebServiceTrackingLog__c` -> Insert solo en error -> detalle tecnico del fallo.

## 7. Registros creados, actualizados o no modificados
1. Impacto inmediato visible: lectura de `Account`, `Contract`, `ActionCadence`, `ActionCadenceTracker`, `Task` y encolado de `Queueable`.
2. Impacto inmediato inferido por Flow/accion estandar: asignacion de target a `ActionCadence` activa.
3. Impacto posterior probable: creacion o actualizacion de `ActionCadenceTracker` y `ActionCadenceStepTracker`.
4. Impacto posterior visible por Apex recuperado: actualizacion de `Task` cuando se completa la cadencia.
5. Impacto posterior visible por Apex recuperado: actualizacion de `Account` a partir del `TaskTrigger`.
6. No se observo `insert Task` directo en el Apex del scheduler; si ocurre, seria por plataforma o procesos posteriores.

## 8. Riesgos, observaciones y puntos de auditoria
1. El proceso es multipaso y asincrono. Auditar solo el batch no explica el resultado funcional final.
2. Parte del DML real pertenece a la accion estandar `assignTargetToSalesCadence`; por eso el impacto sobre objetos de cadencia se documenta como inferido, no como DML Apex observable.
3. La activacion o desactivacion de `ActionCadence` cambia el comportamiento sin despliegue.
4. `getAccountsWithAvailableCadenceSlot()` limita a menos de 5 cadencias activas por target; esa restriccion es funcional y debe considerarse en auditoria.
5. `getContratosClienteNoContactar()` descarta cuentas con tres flags poblados, lo que puede sacar clientes del proceso aunque cumplan otros criterios.
6. El helper de business hours puede impedir la ejecucion del batch aun cuando `CronTrigger` muestre proxima corrida.

## 9. Anexo de codigo fuente completo
Esta seccion agrega el codigo fuente completo de todos los artefactos que participan en el proceso analizado.

### classes/PV_GenerarTareasPeriodicas_sch.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PV_GenerarTareasPeriodicas_sch.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Martín Martínez
* Project           :   Post venta
* Clase test        :   PV_GenerarTareasPeriodicas_sch_tst
* Description       :   Clase exclusiva para la periodicidad de creación de tareas
*-------------------------------------------------------------------------- 
* No.            Date              Author                    Description
* 1.0         19-Jun-2025       Martín Martínez              Creación
* 1.1         20-Jan-2026       Francisco Ortega             Ejecución de BusinessHours vía ACT_PSTA_BusinessHoursHelper_cls
*-------------------------------------------------------------------------- 
*******************************************************************************/
global class PV_GenerarTareasPeriodicas_sch implements Schedulable {

    global void execute(SchedulableContext sc) {

        ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
            'PV_GenerarTareasPeriodicas',
            new PV_GenerarTareasPeriodicas_bch(),
            Integer.valueOf(Label.BatchCadencias_Size_Limit)
        );
    }
}
```

### classes/ACT_BusinessHoursHelper_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\ACT_BusinessHoursHelper_cls.cls
```text
/*******************************************************************************
* Developed by      :   Actinver Mexico
* Author            :   Francisco Ortega
* Project           :   Post venta
* Clase test        :   ACT_BusinessHoursHelper_cls_Test
* Description       :   Helper unificado para:
*                       - Leer CMDT ACT_BatchConfig__mdt
*                       - Resolver Business Hours (ej. 'Postventa')
*                       - Evaluar horario habil y dia habil
*                       - Ejecutar batches segun la regla requerida
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         18-Nov-2025       Francisco Ortega         Creacion (version PSTA)
* 1.1         20-Jan-2026       Francisco Ortega         Ejecutar Business Hours en una sola clase
* 1.2         11-Mar-2026       Francisco Ortega         Validar dia habil para schedulers nocturnos
*--------------------------------------------------------------------------
*******************************************************************************/
public with sharing class ACT_BusinessHoursHelper_cls {

    @TestVisible private static Boolean testOverrideIsWithinConfiguredBH;
    @TestVisible private static Boolean testOverrideIsConfiguredBusinessDay;

    private static String getConfiguredBusinessHoursName(String configDeveloperName) {
        if (String.isBlank(configDeveloperName)) {
            return null;
        }

        try {
            List<SObject> configs = Database.query(
                'SELECT BusinessHoursName__c ' +
                'FROM ACT_BatchConfig__mdt ' +
                'WHERE DeveloperName = :configDeveloperName ' +
                'LIMIT 1'
            );

            if (!configs.isEmpty()) {
                return (String)configs[0].get('BusinessHoursName__c');
            }
        } catch (Exception e) {
            return null;
        }

        return null;
    }

    private static Id getConfiguredBusinessHoursId(String configDeveloperName) {
        String businessHoursName = getConfiguredBusinessHoursName(configDeveloperName);
        if (String.isBlank(businessHoursName)) {
            return null;
        }

        try {
            BusinessHours bh = [
                SELECT Id
                FROM BusinessHours
                WHERE Name = :businessHoursName
                LIMIT 1
            ];
            return bh.Id;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Valida si System.now() esta dentro del horario habil configurado.
     * Si bhId es null, Salesforce usa el BH default del org.
     */
    public static Boolean isWithinConfiguredBH(String configDeveloperName) {
        if (Test.isRunningTest() && testOverrideIsWithinConfiguredBH != null) {
            return testOverrideIsWithinConfiguredBH;
        }

        Datetime nowDt = System.now();
        Id bhId = getConfiguredBusinessHoursId(configDeveloperName);

        try {
            return BusinessHours.isWithin(bhId, nowDt);
        } catch (Exception e) {
            return true;
        }
    }

    /**
     * Valida si el dia actual es dia habil segun la BH configurada.
     * Ignora la hora actual para permitir ejecuciones de madrugada.
     */
    public static Boolean isConfiguredBusinessDay(String configDeveloperName) {
        if (Test.isRunningTest() && testOverrideIsConfiguredBusinessDay != null) {
            return testOverrideIsConfiguredBusinessDay;
        }

        Date currentDate = System.now().date();
        Datetime startOfDay = Datetime.newInstance(currentDate, Time.newInstance(0, 0, 0, 0));
        Id bhId = getConfiguredBusinessHoursId(configDeveloperName);

        try {
            Datetime nextStart = BusinessHours.nextStartDate(bhId, startOfDay);
            return nextStart != null && nextStart.date() == currentDate;
        } catch (Exception e) {
            return true;
        }
    }

    private static Id executeBatch(
        Database.Batchable<SObject> batchInstance,
        Integer scopeSize
    ) {
        if (scopeSize != null) {
            return Database.executeBatch(batchInstance, scopeSize);
        }
        return Database.executeBatch(batchInstance);
    }

    /**
     * Ejecuta batch solo si esta dentro de horario habil (regla estricta por hora).
     */
    public static Id executeBatchIfWithinConfiguredBH(
        String configDeveloperName,
        Database.Batchable<SObject> batchInstance,
        Integer scopeSize
    ) {
        if (!isWithinConfiguredBH(configDeveloperName)) {
            return null;
        }
        return executeBatch(batchInstance, scopeSize);
    }

    public static Id executeBatchIfWithinConfiguredBH(
        String configDeveloperName,
        Database.Batchable<SObject> batchInstance
    ) {
        return executeBatchIfWithinConfiguredBH(configDeveloperName, batchInstance, null);
    }

    /**
     * Ejecuta batch solo si el dia actual es habil (ignora hora).
     * Esta variante permite jobs nocturnos manteniendo bloqueo en dias inhabiles.
     */
    public static Id executeBatchIfConfiguredBusinessDay(
        String configDeveloperName,
        Database.Batchable<SObject> batchInstance,
        Integer scopeSize
    ) {
        if (!isConfiguredBusinessDay(configDeveloperName)) {
            return null;
        }
        return executeBatch(batchInstance, scopeSize);
    }

    public static Id executeBatchIfConfiguredBusinessDay(
        String configDeveloperName,
        Database.Batchable<SObject> batchInstance
    ) {
        return executeBatchIfConfiguredBusinessDay(configDeveloperName, batchInstance, null);
    }
}
```

### classes/PV_GenerarTareasPeriodicas_bch.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PV_GenerarTareasPeriodicas_bch.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test    :   PV_GenerarTareasPeriodicas_bch_tst
* Description       :   Batch para crear nuevas tareas por periodicidad.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         19-Jun-2025       Martín Martínez              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
global class PV_GenerarTareasPeriodicas_bch implements Database.Batchable<sObject>, Database.Stateful{
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(PV_GenerarTareasPeriodicasSelector_cls.getQueryAccounts());
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        // Convertir el scope a lista tipada
        List<Account> lstAccount = PV_GenerarTareasPeriodicas.obtenerCuentasValidas(scope);
        
        if (lstAccount.isEmpty()) {
            System.debug('No se encontraron clientes a procesar para procesar.');
            return;
        }

        // Obtener cadencia
        List<ActionCadence> lstCadence = PV_GenerarTareasPeriodicasSelector_cls.getCadence();

        if (lstCadence.isEmpty() && !Test.isRunningTest()) {
            System.debug('No se encontraron cadencias para procesar.');
            return;
        }

        // Crear mapas de referencia
        Map<String, Object> mapReferences = PV_GenerarTareasPeriodicas.createMapsToReference(lstAccount);

        // Obtener mapa de banqueros por cuenta
        Map<Id, Id> mapBankerAccount = PV_GenerarTareasPeriodicas.getMapBankerAccount(
            (Set<Id>) mapReferences.get('setBMemberId'),
            (Map<Id, List<Id>>) mapReferences.get('mapAccount')
        );        

        // Generar request a partir de las cadencias y cuentas
        PV_GenerarTareasPeriodicas.generarRequestCadence(
            lstCadence,
            lstAccount,
            mapBankerAccount
        );
    }


    public void finish(Database.BatchableContext BC) {
        System.debug('Finaliza el batch de tareas.');
        
    }

}
```

### classes/PV_GenerarTareasPeriodicas.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PV_GenerarTareasPeriodicas.cls
```text
/**
 * @description       : 
 * @author            : Martin Martinez
 * @group             : 
 * @last modified on  : 09-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class PV_GenerarTareasPeriodicas {

    private static Id businessHoursId = PV_GenerarTareasPeriodicasSelector_cls.getDiasLaborales();    
    public static String planeacionFinanciera = PSTA_UtilityClass.DEVELOPERNAME_PLANEACION_FINANCIERA;
    public static String propuestaInversion = PSTA_UtilityClass.DEVELOPERNAME_PROPUESTA_INVERSION;
    public static String biometricos = PSTA_UtilityClass.DEVELOPERNAME_BIOMETRICOS;
    public static String bancaElectronica = PSTA_UtilityClass.DEVELOPERNAME_BANCA_ELECTRONICA;


    public static List<Account> obtenerCuentasValidas(List<sObject> cuentasEntrada) {
        List<Account> cuentas = (List<Account>) cuentasEntrada;
        Set<Id> accountIds = getAccountsWithAvailableCadenceSlot(getContactsId(cuentas));//new Map<Id, Account>(cuentas).keySet();
        if (accountIds.isEmpty()) {            
            return new List<Account>();
        }
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

    public static Set<Id> getAccountsWithAvailableCadenceSlot(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return new Set<Id>();
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
```

### classes/PV_GenerarTareasPeriodicasSelector_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PV_GenerarTareasPeriodicasSelector_cls.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Martín Martínez
* Project           :   Post venta
* Clase test		:   
* Description       :   Clase selector que contiene todas las SOQL o DML del batch para crear nuevas tareas por periodicidad.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         19-Jun-2025       Martín Martínez              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public with sharing class PV_GenerarTareasPeriodicasSelector_cls {

    public static final Id idConfigPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ConfiguracionPeriodicidadTareas').getRecordTypeId();

    public static String getQueryAccounts(){
        String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Generar_Tareas'].Consulta__c ;
        return consulta;
        
            
    }

    /* public static String getQueryAccounts(){
        return 'SELECT Id, Name,' +
                    'FechaUltimoContacto__c, ' +
                    'EnrolamientoBiometricos__c, ' +
                    'EnrolamientoActivo__c, ' +
                    'FichaAfinidadCompletada__c, ' +
                    'PersonContactId, ' +
                    'BanqueroAsignado__r.BusinessUnitMemberId ' +
                'FROM Account ' +
                'WHERE CreatedDate = TODAY' +//Id IN (\'001dz0000078XvfAAE\', \'001dz000006wr5JAAQ\', \'001dz000007BDsMAAW\') ';
                ' AND SaldoIntegral__c != null AND IsPersonAccount = TRUE AND BanqueroAsignado__c != null';
    } */

    public static List<ActionCadence> getCadence() {
        return [SELECT Id,
                    Name,
                    Tipo_de_actividad__c,
                    Periodicidad__c,
                    DeveloperName__c,
                    TareaUnicaPorContrato__c, 
                    TareaUnicaPorCuenta__c
                FROM ActionCadence
                WHERE State ='Active'];
    }   

    public static List<Contract> getContratosClienteNoContactar(Set<Id> accountIds) {
        return [SELECT AccountId, FLAG_MARKETING__c, FLAG_MARKETING_ACTINVER__c, FLAG_EVENTS_INVITATIONS__c
                FROM Contract
                WHERE AccountId IN :accountIds
                AND (FLAG_MARKETING__c != null 
                    AND FLAG_MARKETING_ACTINVER__c != null 
                    AND FLAG_EVENTS_INVITATIONS__c != null)
            ];
    } 

    public static List<Banker> getBankerByBusinessMemberId(Set<Id> setBMemberId){
        return [SELECT ID, UserOrContactId, ExternalId__c FROM BANKER WHERE ID IN: setBMemberId];
    }

    public static Id getDiasLaborales(){
        return [SELECT Id FROM BusinessHours WHERE Name = 'Postventa'].Id;
    }

    public static List<ActionCadenceTracker> validateCadenceActive(Set<Id> accountIds, String developerNameCadencia, Boolean cadenciaUnicaPorCuenta) {
        String baseQuery = 'SELECT ActionCadence.DeveloperName__c, TargetId ' +
                        'FROM ActionCadenceTracker ' +
                        'WHERE ActionCadence.DeveloperName__c = :developerNameCadencia ';

        /*Boolean esCadenciaEspecial = 
            developerNameCadencia == PSTA_UtilityClass.DEVELOPERNAME_BIOMETRICOS || 
            developerNameCadencia == PSTA_UtilityClass.DEVELOPERNAME_BANCA_ELECTRONICA;

        if (!esCadenciaEspecial || !cadenciaUnicaPorCuenta) {*/
            baseQuery += 'AND State = \'Running\' ';
        //}


        baseQuery += 'AND TargetId IN :accountIds';

        return Database.query(baseQuery);
    }

    public static List<Contract> getContratosNoPropuestaPlaneacion(Set<Id> accountIds) {
        return [
            SELECT Id, AccountId, Account.PersonContactId, PlaneacionFinancieraCompletada__c, PropuestaInversionCompletada__c
            FROM Contract
            WHERE AccountId IN :accountIds
            AND (PlaneacionFinancieraCompletada__c = false
            OR PropuestaInversionCompletada__c = false)
        ];
    }

    public static List<Task> getTask(Set<Id> accountIds, String developerNameCadencia) {
        Integer mesesFiltro;
        try {
            mesesFiltro = Integer.valueOf(Label.MesesFiltroTareas);
        } catch(Exception e) {
            mesesFiltro = 6;
        }

        Date fechaLimite = Date.today().addMonths(-mesesFiltro);
        return [
            SELECT AccountId, CreatedDate, DeveloperName__c
            FROM Task
            WHERE DeveloperName__c = :developerNameCadencia
              AND AccountId IN :accountIds
              AND DeveloperName__c != null
              AND CreatedDate >= :fechaLimite
            ORDER BY AccountId, CreatedDate DESC
        ];
    }

}
```

### classes/PV_EjecutarAsignacionCadencias_Queueable.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PV_EjecutarAsignacionCadencias_Queueable.cls
```text
/**
 * @description       : 
 * @author            : Martin Martinez
 * @group             : 
 * @last modified on  : 08-11-2025
 * @last modified by  : Martin Martinez
**/
public class PV_EjecutarAsignacionCadencias_Queueable implements Queueable {

    private List<PV_GenerarTareasPeriodicas_Request> fullList;
    private Integer offset;

    public PV_EjecutarAsignacionCadencias_Queueable(List<PV_GenerarTareasPeriodicas_Request> fullList, Integer offset) {
        this.fullList = fullList;
        this.offset = offset;
    }

    public void execute(QueueableContext context) {
        Integer chunkSize = 200;
        Integer endList = Math.min(offset + chunkSize, fullList.size());

        //List<PV_GenerarTareasPeriodicas_Request> subList = fullList.subList(offset, endList);
        List<PV_GenerarTareasPeriodicas_Request> subList = new List<PV_GenerarTareasPeriodicas_Request>();
        for (Integer i = offset; i < endList; i++) {
            subList.add(fullList[i]);
        }

        // Ejecuta el flow con el chunk actual
        Flow.Interview.PV_AsignarCadencesCuentas_Flow flow = new Flow.Interview.PV_AsignarCadencesCuentas_Flow(
            new Map<String, Object>{
                'inputCadenceList' => subList
            }
        );
        flow.start();

        // Obtener la variable de errores del flow
        List<String> errores = (List<String>) flow.getVariableValue('ErroresAsignacionCadence');
        PV_GenerarTareasPeriodicas.saveErrorFlow(errores);

        // Encola siguiente bloque si hay más registros
        if (endList < fullList.size()) {
            System.enqueueJob(new PV_EjecutarAsignacionCadencias_Queueable(fullList, endList));
        }
    }
}
```

### classes/PV_GenerarTareasPeriodicas_Request.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PV_GenerarTareasPeriodicas_Request.cls
```text
/**
 * @description       : 
 * @author            : Martin Martinez
 * @group             : 
 * @last modified on  : 07-16-2025
 * @last modified by  : Martin Martinez
**/
public class PV_GenerarTareasPeriodicas_Request{

    @AuraEnabled @InvocableVariable(required=true)
    public String salesCadenceNameOrId;

    @AuraEnabled @InvocableVariable(required=true)
    public String targetId;

    @AuraEnabled @InvocableVariable
    public String userId;
    
    public PV_GenerarTareasPeriodicas_Request(String cadence, String target, String user) {
        this.salesCadenceNameOrId = cadence;
        this.targetId = target;
        this.userId = user;
    }
}
```

### flows/PV_AsignarCadencesCuentas_Flow.flow-meta.xml
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\flows\PV_AsignarCadencesCuentas_Flow.flow-meta.xml
```text
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <actionCalls>
        <name>Asignar_cadencia</name>
        <label>Asignar cadencia</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <actionName>assignTargetToSalesCadence</actionName>
        <actionType>assignTargetToSalesCadence</actionType>
        <connector>
            <targetReference>Recorrer_las_cadencias</targetReference>
        </connector>
        <faultConnector>
            <targetReference>Almacenar_error</targetReference>
        </faultConnector>
        <flowTransactionModel>CurrentTransaction</flowTransactionModel>
        <inputParameters>
            <name>salesCadenceNameOrId</name>
            <value>
                <elementReference>Recorrer_las_cadencias.salesCadenceNameOrId</elementReference>
            </value>
        </inputParameters>
        <inputParameters>
            <name>targetId</name>
            <value>
                <elementReference>Recorrer_las_cadencias.targetId</elementReference>
            </value>
        </inputParameters>
        <inputParameters>
            <name>userId</name>
            <value>
                <elementReference>Recorrer_las_cadencias.userId</elementReference>
            </value>
        </inputParameters>
        <nameSegment>assignTargetToSalesCadence</nameSegment>
        <offset>0</offset>
        <storeOutputAutomatically>true</storeOutputAutomatically>
    </actionCalls>
    <apiVersion>64.0</apiVersion>
    <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>
    <assignments>
        <name>Almacenar_error</name>
        <label>Almacenar error</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <assignmentItems>
            <assignToReference>ErroresAsignacionCadence</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>ErrorCadencia</elementReference>
            </value>
        </assignmentItems>
        <connector>
            <isGoTo>true</isGoTo>
            <targetReference>Recorrer_las_cadencias</targetReference>
        </connector>
    </assignments>
    <environments>Default</environments>
    <formulas>
        <name>ErrorCadencia</name>
        <dataType>String</dataType>
        <expression>&quot;Target: &quot; &amp; {!Recorrer_las_cadencias.targetId} &amp; &quot; - Error: &quot; &amp; {!$Flow.FaultMessage}</expression>
    </formulas>
    <interviewLabel>PV_AsignarCadencesCuentas_Flow {!$Flow.CurrentDateTime}</interviewLabel>
    <label>PV_AsignarCadencesCuentas_Flow</label>
    <loops>
        <name>Recorrer_las_cadencias</name>
        <label>Recorrer las cadencias</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <collectionReference>inputCadenceList</collectionReference>
        <iterationOrder>Asc</iterationOrder>
        <nextValueConnector>
            <targetReference>Asignar_cadencia</targetReference>
        </nextValueConnector>
    </loops>
    <processMetadataValues>
        <name>BuilderType</name>
        <value>
            <stringValue>LightningFlowBuilder</stringValue>
        </value>
    </processMetadataValues>
    <processMetadataValues>
        <name>CanvasMode</name>
        <value>
            <stringValue>AUTO_LAYOUT_CANVAS</stringValue>
        </value>
    </processMetadataValues>
    <processMetadataValues>
        <name>OriginBuilderType</name>
        <value>
            <stringValue>LightningFlowBuilder</stringValue>
        </value>
    </processMetadataValues>
    <processType>AutoLaunchedFlow</processType>
    <start>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>Recorrer_las_cadencias</targetReference>
        </connector>
    </start>
    <status>Active</status>
    <variables>
        <name>ErroresAsignacionCadence</name>
        <dataType>String</dataType>
        <isCollection>true</isCollection>
        <isInput>false</isInput>
        <isOutput>true</isOutput>
    </variables>
    <variables>
        <name>inputCadenceList</name>
        <apexClass>PV_GenerarTareasPeriodicas_Request</apexClass>
        <dataType>Apex</dataType>
        <isCollection>true</isCollection>
        <isInput>true</isInput>
        <isOutput>false</isOutput>
    </variables>
</Flow>
```

### triggers/TriggerActionCadanceStepTracker.trigger
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\triggers\TriggerActionCadanceStepTracker.trigger
```text
/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase TriggerActionCadanceStepTracker
------------------------------------------------------------------------------------------
No.        Fecha               Autor                           Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     19-06-2025      Salvador Ramirez Lopez                  Creación
*******************************************************************************************/
trigger TriggerActionCadanceStepTracker on ActionCadenceStepTrackerChangeEvent (after insert) {
    Trigger_Management__mdt  triggerIsActive = Trigger_Management__mdt.getInstance(System.label.CadenceStepTracker);
    if (triggerIsActive != null && triggerIsActive.IsActive__c){
        if(Trigger.isInsert && Trigger.isAfter) TriggerActionCadenceStepTracker_thr.onAfterInsert(Trigger.new);
    }
}
```

### classes/TriggerActionCadenceStepTracker_thr.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\TriggerActionCadenceStepTracker_thr.cls
```text
/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase TriggerActionCadenceStepTracker_thr
------------------------------------------------------------------------------------------
No.        Fecha               Autor                           Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     19-06-2025      Salvador Ramirez Lopez                  Creación
*******************************************************************************************/
public class TriggerActionCadenceStepTracker_thr {
    public static void onAfterInsert(List<ActionCadenceStepTrackerChangeEvent> lstNewRecords){
        PSTA_GestionTareas_Helper.createTaskWithCloseCadence(lstNewRecords);
    }
}
```

### classes/PSTA_GestionTareas_Helper.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_GestionTareas_Helper.cls
```text
/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase PSTA_GestionTareas_Helper
------------------------------------------------------------------------------------------
No.        Fecha               Autor                           Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     19-06-2025      Salvador Ramirez Lopez                  Creación
1.1     11-08-2025      Salvador Ramírez López                  Modificación para hacer un update sobre la tarea generada desde la cadencia y no generar nuevas tareas.
*******************************************************************************************/
public class PSTA_GestionTareas_Helper {
    public static Boolean bypassTriggerExecution = false;
    public static void createTaskWithCloseCadence(List<ActionCadenceStepTrackerChangeEvent> lstStepTracker){
        if (bypassTriggerExecution) return; List<String> recordIds = new List<String>();
        for(ActionCadenceStepTrackerChangeEvent event : lstStepTracker){ EventBus.ChangeEventHeader header = event.ChangeEventHeader; recordIds.addAll(header.getRecordIds());
        }
        List<ActionCadenceStepTracker> stepTrackers = PSTA_GestionTareas_soql.getStepTrackers(recordIds); if(stepTrackers.size() > 0 && stepTrackers != null) createTasks(stepTrackers);
    }
    public static List<Task> updateTasksCadence( List<ActionCadenceStepTracker> stepTrackers){
        Map<Id,ActionCadenceStepTracker> mapActionCadence = new Map<Id,ActionCadenceStepTracker>();
        for(ActionCadenceStepTracker objActionCadenceStepTracker :stepTrackers) mapActionCadence.put(objActionCadenceStepTracker.Id,objActionCadenceStepTracker);
        Task[] tasks = PSTA_GestionTareas_soql.getTaskUsingIdsTracker(mapActionCadence.keySet());
        for(Task objTask : tasks){
            ActionCadenceStepTracker stepTracker = mapActionCadence.get(objTask.ActionCadenceStepTrackerId); objTask.Subject = stepTracker.ActionCadenceName; objTask.Status = 'Completado'; objTask.Type = stepTracker.ActionCadence.Tipo_de_actividad__c;
            objTask.DeveloperName__c = stepTracker.ActionCadence.DeveloperName__c; objTask.Description = 'Contacto efectivo ' + stepTracker.ActionCadence.Name + ' ' + objTask.Account.Client_ID__c + ' ' + objTask.Account.Name;
            objTask.PV_ExternalID__c = createExternalIdTask(stepTracker.ActionCadence.DeveloperName__c, objTask.Account.Client_ID__c, objTask.Account.ID_Asesor__c); objTask.RecordTypeId = ACTINVER_UtilityFactory_utils.getRecodType('Task', 'Postventa');

        }
        return tasks;
    }
    public static void createTasks(List<ActionCadenceStepTracker> stepTrackers){
        Set<Id> setContactId = generateSetIdContact(stepTrackers);
        Map<String, Object> mapReferences = createMapsToReference(setContactId);
        Map<Id, Banker> mapBankerAccount = getMapBankerAccount((Set<Id>)mapReferences.get('setBMemberId'), (Map<Id, Contact>)mapReferences.get('mapContact'));
        List<Task> lstTareas = updateTasksCadence(stepTrackers);
        if(lstTareas.size() > 0) update lstTareas;
        publishEvent(lstTareas, (Map<Id, Contact>)mapReferences.get('mapAccountByContact'));
    }
    public static Map<Id, Banker> getMapBankerAccount(Set<Id> setBMemberId, Map<Id, Contact> mapContact){
        Map<Id, Banker> mapBankerAccount = new Map<Id, Banker>();
        if(!Test.isRunningTest()){for(Banker bank : PSTA_GestionTareas_soql.getBankerByBusinessMemberId(setBMemberId)){if(mapContact.containsKey(bank.Id)) if(!mapBankerAccount.containsKey(mapContact.get(bank.Id).Id)) mapBankerAccount.put(mapContact.get(bank.Id).Id, bank);
            }   
        }
        return mapBankerAccount;
    }
    public static Set<Id> generateSetIdContact(List<ActionCadenceStepTracker> stepTrackers){
        Set<Id> setContactId = new Set<Id>();
        for(ActionCadenceStepTracker stepTracker : stepTrackers) setContactId.add(stepTracker.TargetId);
        return setContactId;
    }
    public static Map<String, Object> createMapsToReference(Set<Id> setContactId){
        Map<Id, Contact> mapContact = new Map<Id, Contact>();
        Map<Id, Contact> mapAccountByContact = new Map<Id, Contact>();
        Set<Id> setBMemberId = new Set<Id>();
        Map<String, Object> mapResult = new Map<String, Object>();
        for(Contact con : PSTA_GestionTareas_soql.getAccountsByContactIds(setContactId)){setBMemberId.add(con.Account.BanqueroAsignado__r.BusinessUnitMemberId);if(!mapContact.containsKey(con.Account.BanqueroAsignado__r.BusinessUnitMemberId)) mapContact.put(con.Account.BanqueroAsignado__r.BusinessUnitMemberId, con);if(!mapAccountByContact.containsKey(con.Id)) mapAccountByContact.put(con.Id, con);
        }
        mapResult.put('mapContact', mapContact);
        mapResult.put('setBMemberId', setBMemberId);
        mapResult.put('mapAccountByContact', mapAccountByContact);
        return mapResult;
    }
    public static String createExternalIdTask(String strTarea, String ClientBP, String ExternalIdBanquero){ return strTarea + '-' + ClientBP + '-' + ExternalIdBanquero + '-' + ACTINVER_UtilityFactory_utils.formatDate(System.today(), false);
    }
    public static void publishEvent(List<Task> lstTask, Map<Id, Contact> mapAccountByContact){
        List<PV_FinalizacionCadencia__e> lstEvent = new List<PV_FinalizacionCadencia__e>();
        for(Task objTask : lstTask){PV_FinalizacionCadencia__e event = new PV_FinalizacionCadencia__e(); event.TaskId__c = objTask.Id; event.AccountId__c = mapAccountByContact.get(objTask.WhoId).Account.Id;event.UserId__c = objTask.OwnerId;lstEvent.add(event);
        }
        List<Database.SaveResult> results = EventBus.publish(lstEvent);
        System.debug('Resultado publish: ' + results);
    }
}
```

### classes/PSTA_GestionTareas_soql.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_GestionTareas_soql.cls
```text
/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase PSTA_GestionTareas_soql
------------------------------------------------------------------------------------------
No.        Fecha               Autor                           Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     16-06-2025      Salvador Ramirez Lopez                  Creación
*******************************************************************************************/
public  class PSTA_GestionTareas_soql {
    public static List<ActionCadenceStepTracker> getStepTrackers(List<String> recordIds){
        return [SELECT  Id,
                        ActionCadenceStepId,
                        ActionCadenceName,
                        TargetId,
                        StepType,
                        StepTitle,
                        ActionCadence.Tipo_de_actividad__c,
                        ActionCadence.DeveloperName__c,
                        ActionCadence.Name
                FROM ActionCadenceStepTracker
                WHERE Id IN :recordIds AND State = 'Completed'  AND ActionCadenceTracker.State = 'Complete'];
    }
    public static List<Contact> getAccountsByContactIds(Set<Id> setContactId){
        return [SELECT ID, AccountId, Account.BanqueroAsignado__r.BusinessUnitMemberId, Account.Client_ID__c, Account.Name
                FROM CONTACT WHERE Id IN :setContactId AND AccountId != NULL];
    }
    public static List<Banker> getBankerByBusinessMemberId(Set<Id> setBMemberId){
        return [SELECT ID, UserOrContactId, ExternalId__c FROM BANKER WHERE ID IN: setBMemberId];
    }
    public static List<Task> getTaskUsingIdsTracker(Set<Id> setTrackersId){
        return [SELECT Id,ActionCadenceStepTrackerId,Account.Client_ID__c,Account.Name, Account.ID_Asesor__c, WhoId, OwnerId FROM Task WHERE ActionCadenceStepTrackerId IN :setTrackersId];
    }
}
```

### triggers/Task_trg.trigger
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\triggers\Task_trg.trigger
```text
/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-25-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger Task_trg on Task (after update) {
    System.debug('*******Va a iniciar trigger');
    Trigger_Management__mdt  triggerIsActive = Trigger_Management__mdt.getInstance(System.label.TaskTrigger);
    if(triggerIsActive != null && triggerIsActive.IsActive__c){
        System.debug('******Trigger activo, inicia');
        if(Trigger.isUpdate && Trigger.isAfter){
            Task_thr.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
```

### classes/Task_thr.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\Task_thr.cls
```text
/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase Task_thr
------------------------------------------------------------------------------------------
No.        Fecha               Autor                           Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     18-06-2025      Salvador Ramirez Lopez                  Creación
*******************************************************************************************/
public class Task_thr {
    public static void onAfterUpdate(List<Task> newListTask, Map<Id, Task> mapOldTask){
        PSTA_ChangeAccountInfo_ctr.changeContactAndDateStatus(newListTask, mapOldTask);
        Task_Helper.publishEventToComponent(newListTask, mapOldTask);
    }
}
```

### classes/PSTA_ChangeAccountInfo_ctr.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_ChangeAccountInfo_ctr.cls
```text
/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase PSTA_ChangeAccountInfo_ctr
------------------------------------------------------------------------------------------
No.        Fecha               Autor                           Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     16-06-2025      Salvador Ramirez Lopez                  Creación
*******************************************************************************************/
public with sharing class PSTA_ChangeAccountInfo_ctr {
    public static boolean byPassTriggerExecution = false;
    public static void changeContactAndDateStatus(List<Task> lstTask, Map<Id, Task> mapOldTask){
        if (bypassTriggerExecution) return;
        PSTA_ChangeAccountInfo_helper.initProcessChangeStatusAccount(lstTask, mapOldTask);
    }
}
```

### classes/PSTA_ChangeAccountInfo_helper.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_ChangeAccountInfo_helper.cls
```text
/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase PSTA_ChangeAccountInfo_helper
------------------------------------------------------------------------------------------
No.        Fecha               Autor                      Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     16-06-2025      Salvador Ramirez Lopez        Clase PSTA_ChangeAccountInfo_helper
*******************************************************************************************/
public class PSTA_ChangeAccountInfo_helper {
    public static void initProcessChangeStatusAccount(List<Task> lstTask, Map<Id, Task> mapOldTask){
        System.debug('**********function initPracess');
        Map<String, Object> mapSets = generateSets(lstTask);
        Set<Id> setIdAcc = (Set<Id>) mapSets.get('setIdAcc');
        Set<String> setDevName = (Set<String>) mapSets.get('setDevName');
        Map<Id, Account> mapAccount = new Map<Id, Account>(PSTA_ChangeAccountInfo_soql.getAccountsInfo(setIdAcc));
        Map<String, ActionCadence> mapConfig = createMapWithConfigs(PSTA_ChangeAccountInfo_soql.lstConfigByCadences(setDevName));
        TaskReview(lstTask, mapOldTask, mapAccount, mapConfig);
    }
    public static Map<String, Object> changeContacAndDatetStatus(Task objTask, Task objOldTask, ActionCadence objConfig, Account objAcc){
        System.debug('**************** changeContactAndDateStatus');
        Map<String, Object> mapResult = new Map<String, Object>();
        try{
            if( objTask.El_cliente_fue_contactado__c != null && objTask.El_cliente_fue_contactado__c != objOldTask.El_cliente_fue_contactado__c && objTask.Status == 'Completado' && (objConfig != null && objConfig.GeneraContacto__c) || (objTask.WhatId != null && String.valueOf(objTask.WhatId).startsWith('006'))){
                System.debug('Entró');
                if(objConfig != null && objConfig.RequiereCargaEvidencia__c && objTask.RefenciaOpenText__c == null){
                    objTask.addError('No es posible cambiar el estatus de contacto a cliente ya que no se ha cargado evidencia.');
                } else {
                    objAcc.FechaUltimoContacto__c = System.today();
                    if(objTask.ClienteNoQuiereSerContactado__c){
                        objAcc.FechaNoRequiereSerContacto__c = System.today();
                        objAcc.EstatusContacto__c = 'Cliente no quiere ser contactado';
                    } else {
                        objAcc.EstatusContacto__c = objTask.El_cliente_fue_contactado__c == 'Si' ? 'Contacto efectivo exitoso' : 'Contacto no exitoso';
                    }
                    mapResult.put('Account', objAcc);
                }
            }
            /*if(objTask.ClienteNoQuiereSerContactado__c && objTask.ClienteNoQuiereSerContactado__c != objOldTask.ClienteNoQuiereSerContactado__c){
                publicarEvento(objTask.Id, System.UserInfo.getUserId());
            }*/
        } catch(Exception e){
            System.debug('Error al actualizar cuenta desde trigger: ' + e.getMessage() + '. Línea: ' + e.getLineNumber());
            mapResult.put('Error', 'Error al actualizar la cuenta: ' + e.getMessage());
        }
        return mapResult;
    }
    public static void taskReview(List<Task> lstTask, Map<Id, Task> mapOldTask, Map<Id, Account> mapAccount, Map<String, ActionCadence> mapConfig){
        System.debug('********* funcion taskreview');
        List<Account> lstAccToUpdate = new List<Account>();
        Set<Id> setTaskUpdate = new Set<Id>();
        Set<Id> setIdTasksWithErrors = new Set<Id>();
        Map<Id, Id> mapTaskByAccount = new Map<Id, Id>();
        try{
            System.debug('********* Lista de tareas: ' + lstTask.size());
            for(Task objTask : lstTask){
                System.debug('********* Entra a la lista de tareas');
                System.debug('********* Objeto tarea: ' + objTask);
                if(objTask.AccountId != null && mapAccount.containsKey(objTask.AccountId)){
                    System.debug('******* Mapa de configuración: ' + mapConfig);
                    Map<String, Object> mapResult = changeContacAndDatetStatus(objTask, mapOldTask.get(objTask.Id), mapConfig.get(objTask.DeveloperName__c), mapAccount.get(objTask.AccountId));
                    if(mapResult.containsKey('Account')){
                        Account objAcc = (Account)mapResult.get('Account');
                        lstAccToUpdate.add(objAcc);
                        if(!mapTaskByAccount.containsKey(objAcc.Id)) mapTaskByAccount.put(objAcc.Id, objTask.Id);
                    } else {
                        if(mapResult.containsKey('Error')) objTask.addError((String)mapResult.get('Error'));
                    }
                }
            }
            System.debug('********* Finaliza recorrido de tareas');
            Map<String, Object> mapResult = updateAccountAndGetTasks(lstAccToUpdate, mapTaskByAccount);
            setTaskUpdate = (Set<Id>) mapResult.get('success');
            setIdTasksWithErrors = (Set<Id>) mapResult.get('Errors');
            Map<Id, String> mapErrors = (Map<Id, String>) mapResult.get('ErrorMsgs');
            if(setIdTasksWithErrors.size() > 0){
                for(Task objTask : lstTask){
                    if(setIdTasksWithErrors.contains(objTask.Id)) objTask.addError('Error al actualizar la información del cliente: ' + mapErrors.get(objTask.Id));
                }
            }
            if(setTaskUpdate.size() > 0) PSTA_EnvioEncuestaMedallia_cls.sendSurvey(setTaskUpdate);
        } catch (Exception e){
            System.debug('************ Error al actualizar en taskreview: ' + e.getMessage() + '. Línea: ' + e.getLineNumber());
        }
    }
    public static Map<String, Object> generateSets(List<Task> lstTask){
        Set<Id> setIdAcc = new Set<Id>();
        Set<String> setDevName = new Set<String>();
        for(Task objTask : lstTask){
            if(objTask.AccountId != null) setIdAcc.add(objTask.AccountId);
            if(objTask.DeveloperName__c != null) setDevName.add(objTask.DeveloperName__c);
        }
        return new Map<String, Object>{'setIdAcc' => setIdAcc, 'setDevName' => setDevName};
    }
    public static Map<String, Object> updateAccountAndGetTasks(List<Account> lstAccToUpdate, Map<Id, Id> mapTaskByAccount){
        OD_Account_cls.bypassTriggerExecution = true;
        Set<Id> setIdTasks = new Set<Id>();
        Set<Id> setIdTasksWithErrors = new Set<Id>();
        String strError = '';
        Map<String, Object> mapResult = new Map<String, Object>();
        Map<Id, String> mapErrors = new Map<Id, String>();
        List<Database.SaveResult> saveResult = Database.update(lstAccToUpdate, false);
        for(Database.SaveResult result : saveResult){
            if(result.isSuccess()) setIdTasks.add(mapTaskByAccount.get(result.getId())); else {
                for(Database.Error error : result.getErrors()){
                    strError += error.getMessage() + '; ';
                    setIdTasksWithErrors.add(mapTaskByAccount.get(result.getId()));
                }
                if(!mapErrors.containsKey(mapTaskByAccount.get(result.getId()))) mapErrors.put(mapTaskByAccount.get(result.getId()), strError);
            }
        }
        mapResult.put('Errors', setIdTasksWithErrors);
        mapResult.put('success', setIdTasks);
        mapResult.put('ErrorMsgs', mapErrors);
        return mapResult;
    }
    public static Map<String, ActionCadence> createMapWithConfigs(List<ActionCadence> lstConfig){
        Map<String, ActionCadence> mapConfig = new Map<String, ActionCadence>();
        for(ActionCadence objConfig : lstConfig){
            mapConfig.put(objConfig.DeveloperName__c, objConfig);
        }
        return mapConfig;
    }
    public static void publicarEvento(Id idTask, Id idUser){
        EventoComponente__e event = new EventoComponente__e(TaskId__c = idTask, UserId__c = idUser);
        Database.SaveResult sr = EventBus.publish(event);
        System.debug('*******Resultado de publicación: ' + sr.isSuccess());
    }
}
```

### classes/PSTA_ChangeAccountInfo_soql.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_ChangeAccountInfo_soql.cls
```text
/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase PSTA_ChangeAccountInfo_soql
------------------------------------------------------------------------------------------
No.        Fecha               Autor                            Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     18-06-2025      Salvador Ramirez Lopez                   Creación
*******************************************************************************************/
public class PSTA_ChangeAccountInfo_soql {
    public static List<Account> getAccountsInfo(Set<Id> setIdAcc){
        return [SELECT Id, EstatusContacto__c, FechaUltimoContacto__c FROM Account WHERE Id IN :setIdAcc];
    }
    public static List<ActionCadence> lstConfigByCadences(Set<String> setTaskDevName){
        return [SELECT DeveloperName__c, GeneraContacto__c, RequiereCargaEvidencia__c FROM ACTIONCADENCE WHERE DeveloperName__c IN :setTaskDevName];
    }
}
```

### flows/Flow_Avance_FAC.flow-meta.xml
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\flows\Flow_Avance_FAC.flow-meta.xml
```text
﻿<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>
    <assignments>
        <name>Aplicables</name>
        <label>Aplicables</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <assignmentItems>
            <assignToReference>vAplicables</assignToReference>
            <operator>Assign</operator>
            <value>
                <numberValue>0.0</numberValue>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Assign</operator>
            <value>
                <numberValue>0.0</numberValue>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vAplicables</assignToReference>
            <operator>Add</operator>
            <value>
                <numberValue>16.0</numberValue>
            </value>
        </assignmentItems>
        <connector>
            <targetReference>BaseSum</targetReference>
        </connector>
    </assignments>
    <assignments>
        <name>BaseSum</name>
        <label>BaseSum</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_Pasatiempo</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_Viajas</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_Frecuencia</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_Hijos</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_EstudiaFuera</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_Institucion</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_Porque</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_OtrosProd</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_TipoSeguros</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_MedioPreferido</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_Influye</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_Ingreso</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_Gastos</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_PatrimonioAct</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_PrincipalAct</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>vLlenos</assignToReference>
            <operator>Add</operator>
            <value>
                <elementReference>f_MesPreferente</elementReference>
            </value>
        </assignmentItems>
        <connector>
            <targetReference>SetResults</targetReference>
        </connector>
    </assignments>
    <assignments>
        <name>SetResults</name>
        <label>SetResults</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <assignmentItems>
            <assignToReference>$Record.AvanceNum1FAC__c</assignToReference>
            <operator>Assign</operator>
            <value>
                <elementReference>vAplicables</elementReference>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>$Record.AvanceNum2FAC__c</assignToReference>
            <operator>Assign</operator>
            <value>
                <elementReference>vLlenos</elementReference>
            </value>
        </assignmentItems>
    </assignments>
    <description>Flojo que ayuda a el cÃ¡lculo de avance de llenado de Ficha de Afinidad del Cliente</description>
    <environments>Default</environments>
    <formulas>
        <name>f_EstudiaFuera</name>
        <dataType>Number</dataType>
        <expression>IF( ISBLANK(TEXT({!$Record.Estudiaoestudianfueradelpais__c})), 0, 1 )</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_Frecuencia</name>
        <dataType>Number</dataType>
        <expression>IF(
  OR(
    ISBLANK(TEXT({!$Record.Frecuencia_para_ser_contactado__c})),
    TEXT({!$Record.Frecuencia_para_ser_contactado__c})=&quot;--None--&quot;
  ),
  0, 1
)</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_Gastos</name>
        <dataType>Number</dataType>
        <expression>IF( ISBLANK({!$Record.Gastos_mensuales__c}), 0, 1 )</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_Hijos</name>
        <dataType>Number</dataType>
        <expression>IF( ISBLANK(TEXT({!$Record.Cuantos_hijos_tienes__c})), 0, 1 )</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_Influye</name>
        <dataType>Number</dataType>
        <expression>IF( ISBLANK({!$Record.Alguien_InfluyeEnTuPatrimonio__c}), 0, 1 )</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_Ingreso</name>
        <dataType>Number</dataType>
        <expression>IF( ISBLANK({!$Record.Ingreso_mensual_despu_s_de_impuestos__c}), 0, 1 )</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_Institucion</name>
        <dataType>Number</dataType>
        <expression>IF(
  OR(
    ISBLANK(TEXT({!$Record.InstitucionFinancieraPrincipal__c})),
    TEXT({!$Record.InstitucionFinancieraPrincipal__c}) = &quot;--None--&quot;
  ),
  0,
  1
)</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_MedioPreferido</name>
        <dataType>Number</dataType>
        <expression>IF( ISBLANK({!$Record.MedioPreferidoContacto__c}), 0, 1 )</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_MesPreferente</name>
        <dataType>Number</dataType>
        <expression>IF( ISBLANK({!$Record.MesPreferenteInversion_o_ahorrar__c}), 0, 1 )</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_OtrosProd</name>
        <dataType>Number</dataType>
        <expression>IF( ISBLANK({!$Record.Otrosproductosfinancierosteinteresan__c}), 0, 1 )</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_Pasatiempo</name>
        <dataType>Number</dataType>
        <expression>IF(
  OR(
    ISBLANK(TEXT({!$Record.Pasatiempo__c})),
    TEXT({!$Record.Pasatiempo__c})=&quot;--None--&quot;
  ),
  0, 1
)</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_PatrimonioAct</name>
        <dataType>Number</dataType>
        <expression>IF( ISBLANK({!$Record.depatrimoniofinancierototalenActinver__c}), 0, 1 )</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_Porque</name>
        <dataType>Number</dataType>
        <expression>IF( ISBLANK({!$Record.PorqueIndentInteres__c}), 0, 1 )</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_PrincipalAct</name>
        <dataType>Number</dataType>
        <expression>IF(
  OR(
    ISBLANK(TEXT({!$Record.PrincipalActividadProfesional__c})),
    TEXT({!$Record.PrincipalActividadProfesional__c})=&quot;--None--&quot;
  ),
  0, 1
)</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_TipoSeguros</name>
        <dataType>Number</dataType>
        <expression>IF( ISBLANK({!$Record.Conquetipodeseguroscuentas__c}), 0, 1 )</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>f_Viajas</name>
        <dataType>Number</dataType>
        <expression>IF( ISBLANK(TEXT({!$Record.Viajas_recurrentemente__c})), 0, 1 )</expression>
        <scale>0</scale>
    </formulas>
    <interviewLabel>Flow_Avance_FAC {!$Flow.CurrentDateTime}</interviewLabel>
    <label>Flow_Avance_FAC</label>
    <processMetadataValues>
        <name>BuilderType</name>
        <value>
            <stringValue>LightningFlowBuilder</stringValue>
        </value>
    </processMetadataValues>
    <processMetadataValues>
        <name>CanvasMode</name>
        <value>
            <stringValue>AUTO_LAYOUT_CANVAS</stringValue>
        </value>
    </processMetadataValues>
    <processMetadataValues>
        <name>OriginBuilderType</name>
        <value>
            <stringValue>LightningFlowBuilder</stringValue>
        </value>
    </processMetadataValues>
    <processType>AutoLaunchedFlow</processType>
    <start>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>Aplicables</targetReference>
        </connector>
        <object>Account</object>
        <recordTriggerType>CreateAndUpdate</recordTriggerType>
        <triggerType>RecordBeforeSave</triggerType>
    </start>
    <status>Active</status>
    <variables>
        <name>vAplicables</name>
        <dataType>Number</dataType>
        <isCollection>false</isCollection>
        <isInput>false</isInput>
        <isOutput>false</isOutput>
        <scale>0</scale>
    </variables>
    <variables>
        <name>vLlenos</name>
        <dataType>Number</dataType>
        <isCollection>false</isCollection>
        <isInput>false</isInput>
        <isOutput>false</isOutput>
        <scale>0</scale>
    </variables>
</Flow>
```

### flows/FAC_Update_Task_Field_Avence.flow-meta.xml
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\flows\FAC_Update_Task_Field_Avence.flow-meta.xml
```text
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>
    <assignments>
        <name>Avance_Percent_Account</name>
        <label>Avance_Percent_Account</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <assignmentItems>
            <assignToReference>FACavancefield</assignToReference>
            <operator>Assign</operator>
            <value>
                <elementReference>$Record.Avance_FAC__c</elementReference>
            </value>
        </assignmentItems>
        <connector>
            <targetReference>Task_FAC</targetReference>
        </connector>
    </assignments>
    <decisions>
        <name>Existe_tarea_Postventa</name>
        <label>Existe tarea Postventa</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <defaultConnectorLabel>Default Outcome</defaultConnectorLabel>
        <rules>
            <name>Si</name>
            <conditionLogic>and</conditionLogic>
            <conditions>
                <leftValueReference>Task_FAC.Id</leftValueReference>
                <operator>IsNull</operator>
                <rightValue>
                    <booleanValue>false</booleanValue>
                </rightValue>
            </conditions>
            <connector>
                <targetReference>Update_Task</targetReference>
            </connector>
            <label>Si</label>
        </rules>
    </decisions>
    <decisions>
        <name>Sicontactasi_es_100</name>
        <label>Sicontactasi es 100</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <defaultConnectorLabel>Default Outcome</defaultConnectorLabel>
        <rules>
            <name>Es_100</name>
            <conditionLogic>and</conditionLogic>
            <conditions>
                <leftValueReference>Task_FAC.Avance_FAC_Validacion__c</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue>
                    <numberValue>100.0</numberValue>
                </rightValue>
            </conditions>
            <connector>
                <targetReference>Update_contactado</targetReference>
            </connector>
            <label>Es 100</label>
        </rules>
    </decisions>
    <environments>Default</environments>
    <interviewLabel>FAC_Update_Task Field_Avence {!$Flow.CurrentDateTime}</interviewLabel>
    <label>FAC_Update_Task Field_Avence</label>
    <processMetadataValues>
        <name>BuilderType</name>
        <value>
            <stringValue>LightningFlowBuilder</stringValue>
        </value>
    </processMetadataValues>
    <processMetadataValues>
        <name>CanvasMode</name>
        <value>
            <stringValue>AUTO_LAYOUT_CANVAS</stringValue>
        </value>
    </processMetadataValues>
    <processMetadataValues>
        <name>OriginBuilderType</name>
        <value>
            <stringValue>LightningFlowBuilder</stringValue>
        </value>
    </processMetadataValues>
    <processType>AutoLaunchedFlow</processType>
    <recordLookups>
        <name>Task_FAC</name>
        <label>Task FAC</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <assignNullValuesIfNoRecordsFound>false</assignNullValuesIfNoRecordsFound>
        <connector>
            <targetReference>Existe_tarea_Postventa</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>RecordTypeId</field>
            <operator>EqualTo</operator>
            <value>
                <stringValue>012WP000000peoIYAQ</stringValue>
            </value>
        </filters>
        <filters>
            <field>WhatId</field>
            <operator>EqualTo</operator>
            <value>
                <elementReference>$Record.Id</elementReference>
            </value>
        </filters>
        <filters>
            <field>Subject</field>
            <operator>Contains</operator>
            <value>
                <stringValue>Ficha de afinidad con el cliente</stringValue>
            </value>
        </filters>
        <filters>
            <field>El_cliente_fue_contactado__c</field>
            <operator>IsNull</operator>
            <value>
                <booleanValue>true</booleanValue>
            </value>
        </filters>
        <getFirstRecordOnly>true</getFirstRecordOnly>
        <object>Task</object>
        <queriedFields>Id</queriedFields>
        <queriedFields>Avance_FAC_Validacion__c</queriedFields>
        <queriedFields>El_cliente_fue_contactado__c</queriedFields>
        <storeOutputAutomatically>true</storeOutputAutomatically>
    </recordLookups>
    <recordUpdates>
        <name>Update_contactado</name>
        <label>Update contactado</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Avance_FAC_Validacion__c</field>
            <operator>EqualTo</operator>
            <value>
                <numberValue>100.0</numberValue>
            </value>
        </filters>
        <inputAssignments>
            <field>El_cliente_fue_contactado__c</field>
            <value>
                <stringValue>Si</stringValue>
            </value>
        </inputAssignments>
        <object>Task</object>
    </recordUpdates>
    <recordUpdates>
        <name>Update_Task</name>
        <label>Update Task</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>Sicontactasi_es_100</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Subject</field>
            <operator>Contains</operator>
            <value>
                <stringValue>Ficha de afinidad con el cliente</stringValue>
            </value>
        </filters>
        <filters>
            <field>AccountId</field>
            <operator>EqualTo</operator>
            <value>
                <elementReference>$Record.Id</elementReference>
            </value>
        </filters>
        <inputAssignments>
            <field>Avance_FAC_Validacion__c</field>
            <value>
                <elementReference>$Record.Avance_FAC__c</elementReference>
            </value>
        </inputAssignments>
        <object>Task</object>
    </recordUpdates>
    <start>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>Avance_Percent_Account</targetReference>
        </connector>
        <filterLogic>or</filterLogic>
        <filters>
            <field>Avance_FAC__c</field>
            <operator>IsChanged</operator>
            <value>
                <booleanValue>true</booleanValue>
            </value>
        </filters>
        <object>Account</object>
        <recordTriggerType>Update</recordTriggerType>
        <triggerType>RecordAfterSave</triggerType>
    </start>
    <status>Active</status>
    <variables>
        <name>FACavancefield</name>
        <dataType>Number</dataType>
        <isCollection>false</isCollection>
        <isInput>false</isInput>
        <isOutput>false</isOutput>
        <scale>0</scale>
    </variables>
</Flow>
```

### flows/FAC_Task_Update_InAccount.flow-meta.xml
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\flows\FAC_Task_Update_InAccount.flow-meta.xml
```text
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>
    <environments>Default</environments>
    <interviewLabel>FAC_Task_Update_InAccount {!$Flow.CurrentDateTime}</interviewLabel>
    <label>FAC_Task_Update_InAccount</label>
    <processMetadataValues>
        <name>BuilderType</name>
        <value>
            <stringValue>LightningFlowBuilder</stringValue>
        </value>
    </processMetadataValues>
    <processMetadataValues>
        <name>CanvasMode</name>
        <value>
            <stringValue>AUTO_LAYOUT_CANVAS</stringValue>
        </value>
    </processMetadataValues>
    <processMetadataValues>
        <name>OriginBuilderType</name>
        <value>
            <stringValue>LightningFlowBuilder</stringValue>
        </value>
    </processMetadataValues>
    <processType>AutoLaunchedFlow</processType>
    <recordLookups>
        <name>Get_Task</name>
        <label>Get Task</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <assignNullValuesIfNoRecordsFound>false</assignNullValuesIfNoRecordsFound>
        <connector>
            <targetReference>UpdateTask</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>WhatId</field>
            <operator>EqualTo</operator>
            <value>
                <elementReference>$Record.Id</elementReference>
            </value>
        </filters>
        <filters>
            <field>RecordTypeId</field>
            <operator>EqualTo</operator>
            <value>
                <stringValue>012WP000000peoIYAQ</stringValue>
            </value>
        </filters>
        <filters>
            <field>Subject</field>
            <operator>Contains</operator>
            <value>
                <stringValue>Ficha de afinidad con el cliente</stringValue>
            </value>
        </filters>
        <object>Task</object>
        <outputAssignments>
            <assignToReference>recordId</assignToReference>
            <field>Id</field>
        </outputAssignments>
        <outputAssignments>
            <assignToReference>RelatedTo</assignToReference>
            <field>WhatId</field>
        </outputAssignments>
        <sortField>LastModifiedDate</sortField>
        <sortOrder>Desc</sortOrder>
    </recordLookups>
    <recordUpdates>
        <name>UpdateTask</name>
        <label>UpdateTask</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <filterLogic>and</filterLogic>
        <filters>
            <field>WhatId</field>
            <operator>EqualTo</operator>
            <value>
                <elementReference>$Record.Id</elementReference>
            </value>
        </filters>
        <filters>
            <field>Id</field>
            <operator>EqualTo</operator>
            <value>
                <elementReference>recordId</elementReference>
            </value>
        </filters>
        <filters>
            <field>Subject</field>
            <operator>EqualTo</operator>
            <value>
                <stringValue>Ficha de afinidad con el cliente</stringValue>
            </value>
        </filters>
        <inputAssignments>
            <field>El_cliente_fue_contactado__c</field>
            <value>
                <stringValue>Si</stringValue>
            </value>
        </inputAssignments>
        <object>Task</object>
    </recordUpdates>
    <start>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>Get_Task</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Avance_FAC__c</field>
            <operator>EqualTo</operator>
            <value>
                <numberValue>100.0</numberValue>
            </value>
        </filters>
        <object>Account</object>
        <recordTriggerType>Update</recordTriggerType>
        <triggerType>RecordAfterSave</triggerType>
    </start>
    <status>Active</status>
    <variables>
        <name>recordId</name>
        <dataType>String</dataType>
        <isCollection>false</isCollection>
        <isInput>true</isInput>
        <isOutput>false</isOutput>
    </variables>
    <variables>
        <name>RelatedTo</name>
        <dataType>String</dataType>
        <isCollection>false</isCollection>
        <isInput>true</isInput>
        <isOutput>false</isOutput>
    </variables>
</Flow>
```

### flows/FAC_Task_Update_InTask.flow-meta.xml
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\flows\FAC_Task_Update_InTask.flow-meta.xml
```text
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>
    <decisions>
        <name>FAC_Avance_100</name>
        <label>FAC Avance 100</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <defaultConnectorLabel>Default Outcome</defaultConnectorLabel>
        <rules>
            <name>Es_100</name>
            <conditionLogic>and</conditionLogic>
            <conditions>
                <leftValueReference>Related_Account.Avance_FAC__c</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue>
                    <numberValue>100.0</numberValue>
                </rightValue>
            </conditions>
            <conditions>
                <leftValueReference>$Record.WhatId</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue>
                    <elementReference>Related_Account.Id</elementReference>
                </rightValue>
            </conditions>
            <connector>
                <targetReference>Update_Records_1</targetReference>
            </connector>
            <label>Es 100</label>
        </rules>
    </decisions>
    <environments>Default</environments>
    <interviewLabel>FAC_Task_Update {!$Flow.CurrentDateTime}</interviewLabel>
    <label>FAC_Task_Update_InTask</label>
    <processMetadataValues>
        <name>BuilderType</name>
        <value>
            <stringValue>LightningFlowBuilder</stringValue>
        </value>
    </processMetadataValues>
    <processMetadataValues>
        <name>CanvasMode</name>
        <value>
            <stringValue>AUTO_LAYOUT_CANVAS</stringValue>
        </value>
    </processMetadataValues>
    <processMetadataValues>
        <name>OriginBuilderType</name>
        <value>
            <stringValue>LightningFlowBuilder</stringValue>
        </value>
    </processMetadataValues>
    <processType>AutoLaunchedFlow</processType>
    <recordLookups>
        <name>Related_Account</name>
        <label>Related Account</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <assignNullValuesIfNoRecordsFound>false</assignNullValuesIfNoRecordsFound>
        <connector>
            <targetReference>FAC_Avance_100</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Id</field>
            <operator>EqualTo</operator>
            <value>
                <elementReference>$Record.WhatId</elementReference>
            </value>
        </filters>
        <filters>
            <field>Avance_FAC__c</field>
            <operator>EqualTo</operator>
            <value>
                <numberValue>100.0</numberValue>
            </value>
        </filters>
        <getFirstRecordOnly>true</getFirstRecordOnly>
        <object>Account</object>
        <storeOutputAutomatically>true</storeOutputAutomatically>
    </recordLookups>
    <recordUpdates>
        <name>Update_Records_1</name>
        <label>Update Records 1</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <inputAssignments>
            <field>El_cliente_fue_contactado__c</field>
            <value>
                <stringValue>Si</stringValue>
            </value>
        </inputAssignments>
        <inputReference>$Record</inputReference>
    </recordUpdates>
    <start>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>Related_Account</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>RecordTypeId</field>
            <operator>EqualTo</operator>
            <value>
                <stringValue>012WP000000peoIYAQ</stringValue>
            </value>
        </filters>
        <filters>
            <field>Subject</field>
            <operator>Contains</operator>
            <value>
                <stringValue>Ficha de afinidad con el cliente</stringValue>
            </value>
        </filters>
        <object>Task</object>
        <recordTriggerType>Create</recordTriggerType>
        <triggerType>RecordAfterSave</triggerType>
    </start>
    <status>Active</status>
</Flow>
```

### classes/ACTCompleteCadenceForAccounts.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\ACTCompleteCadenceForAccounts.cls
```text
/**
 * ACTCompleteCadenceForAccounts
 * Invocable Apex to complete ActionCadenceTracker records for Contacts under given Account Ids
 * when business rules require setting State = 'Complete' for a specific ActionCadenceId.
 *
 * Specs confirmed by user:
 * - Object: standard ActionCadenceTracker (not __c)
 * - Fields: State (picklist), TargetId (lookup to Contact)
 * - Filter: only trackers with ActionCadenceId = '77Cdp0000000L7hEAE'
 * - Update rule: for the Account whose Avance_FAC__c reached 100 (handled by Flow),
 *                complete all trackers with State != 'Complete' for Contacts of that Account.
 * - Invocation: from a Record-Triggered Flow on Account (After Save), passing Account Ids
 *
 * Design:
 * - Bulkified processing
 * - with sharing to respect sharing rules
 * - SOQL with WITH SECURITY_ENFORCED
 * - DML using Database.update with AccessLevel.USER_MODE
 * - No SOQL/DML in loops; use collections
 * - Clear per-account summary suitable for Flow consumption
 */
public with sharing class ACTCompleteCadenceForAccounts {

    // CONSTANTS
    public static final String TARGET_ACTION_CADENCE_ID = '77Cdp0000000L7hEAE';
    public static final String STATE_COMPLETE = 'Complete';

    // Invocable input
    public class Request {
        @InvocableVariable(required=true)
        public Id accountId;
    }

    // Per-account aggregated outcome for Flow visibility
    public class PerAccountResult {
        @InvocableVariable
        public Id accountId;

        @InvocableVariable
        public Integer trackersFound;

        @InvocableVariable
        public Integer updatedToComplete;

        @InvocableVariable
        public Integer alreadyComplete;

        @InvocableVariable
        public String errorMessage;
    }

    // Top-level response (single element list returned to Flow)
    public class Response {
        @InvocableVariable
        public List<PerAccountResult> perAccountResults;

        @InvocableVariable
        public Integer totalFound;

        @InvocableVariable
        public Integer totalUpdated;

        @InvocableVariable
        public Integer totalAlreadyComplete;

        @InvocableVariable
        public String errorMessage;
    }

    @InvocableMethod(
        label='Complete Ficha de Afinidad Cadence for Accounts'
        description='For provided Account Ids, completes ActionCadenceTracker records (State = "Complete") tied to Contacts under those Accounts where ActionCadenceId = TARGET and State != "Complete".'
    )
    public static List<Response> completeForAccounts(List<Request> requests) {
        List<Response> out = new List<Response>();
        Response summary = new Response();
        summary.perAccountResults = new List<PerAccountResult>();
        summary.totalFound = 0;
        summary.totalUpdated = 0;
        summary.totalAlreadyComplete = 0;

        // Validate input
        if (requests == null || requests.isEmpty()) {
            out.add(summary);
            return out;
        }

        // Collect Account Ids
        Set<Id> accountIds = new Set<Id>();
        for (Request r : requests) {
            if (r != null && r.accountId != null) {
                accountIds.add(r.accountId);
            }
        }
        if (accountIds.isEmpty()) {
            summary.errorMessage = 'No valid Account Ids provided.';
            out.add(summary);
            return out;
        }

        // Fetch Contacts for the Accounts
        // SECURITY: enforce FLS/sharing
        Map<Id, List<Id>> contactIdsByAccount = new Map<Id, List<Id>>();
        for (Contact c : [
            SELECT Id, AccountId
            FROM Contact
            WHERE AccountId IN :accountIds
            WITH SECURITY_ENFORCED
        ]) {
            if (c.AccountId == null) continue;
            List<Id> bucket = contactIdsByAccount.get(c.AccountId);
            if (bucket == null) {
                bucket = new List<Id>();
                contactIdsByAccount.put(c.AccountId, bucket);
            }
            bucket.add(c.Id);
        }

        // Build a flat set of all contact Ids
        Set<Id> allContactIds = new Set<Id>();
        for (List<Id> ids : contactIdsByAccount.values()) {
            allContactIds.addAll(ids);
        }

        if (allContactIds.isEmpty()) {
            // No contacts, so no trackers to complete
            for (Id accId : accountIds) {
                PerAccountResult par = new PerAccountResult();
                par.accountId = accId;
                par.trackersFound = 0;
                par.updatedToComplete = 0;
                par.alreadyComplete = 0;
                summary.perAccountResults.add(par);
            }
            out.add(summary);
            return out;
        }

        // Query relevant ActionCadenceTracker records for those Contacts and target Cadence
        // Note: Standard object API names and fields per user confirmation:
        // - Object: ActionCadenceTracker
        // - Fields: State, TargetId (points to Contact), ActionCadenceId
        List<ActionCadenceTracker> trackers = [
            SELECT Id, State, TargetId, ActionCadenceId
            FROM ActionCadenceTracker
            WHERE TargetId IN :allContactIds
              AND ActionCadenceId = :TARGET_ACTION_CADENCE_ID
            WITH SECURITY_ENFORCED
        ];

        // Group trackers by Account via TargetId(Contact.AccountId)
        Map<Id, List<ActionCadenceTracker>> trackersByAccount = new Map<Id, List<ActionCadenceTracker>>();
        if (!trackers.isEmpty()) {
            // Preload Contact.AccountId for mapping without extra SOQL:
            // We'll query a minimal map ContactId -> AccountId for the subset of TargetIds found
            Set<Id> trackerContactIds = new Set<Id>();
            for (ActionCadenceTracker t : trackers) {
                if (t.TargetId != null) trackerContactIds.add(t.TargetId);
            }
            Map<Id, Id> contactToAccount = new Map<Id, Id>();
            if (!trackerContactIds.isEmpty()) {
                for (Contact c2 : [
                    SELECT Id, AccountId
                    FROM Contact
                    WHERE Id IN :trackerContactIds
                    WITH SECURITY_ENFORCED
                ]) {
                    contactToAccount.put(c2.Id, c2.AccountId);
                }
            }

            for (ActionCadenceTracker t : trackers) {
                Id accId = contactToAccount.get(t.TargetId);
                if (accId == null) continue;
                List<ActionCadenceTracker> bucket = trackersByAccount.get(accId);
                if (bucket == null) {
                    bucket = new List<ActionCadenceTracker>();
                    trackersByAccount.put(accId, bucket);
                }
                bucket.add(t);
            }
        }

        // Prepare updates and per-account tallies
        List<ActionCadenceTracker> toUpdate = new List<ActionCadenceTracker>();
        for (Id accId : accountIds) {
            PerAccountResult par = new PerAccountResult();
            par.accountId = accId;
            par.trackersFound = 0;
            par.updatedToComplete = 0;
            par.alreadyComplete = 0;

            List<ActionCadenceTracker> accTrackers = trackersByAccount.get(accId);
            if (accTrackers != null && !accTrackers.isEmpty()) {
                par.trackersFound = accTrackers.size();
                for (ActionCadenceTracker t : accTrackers) {
                    if (t.State == STATE_COMPLETE) {
                        par.alreadyComplete++;
                    } else {
                        ActionCadenceTracker upd = new ActionCadenceTracker(
                            Id = t.Id,
                            State = STATE_COMPLETE
                        );
                        toUpdate.add(upd);
                        par.updatedToComplete++;
                    }
                }
            }

            summary.perAccountResults.add(par);
        }

        // DML in USER_MODE with partial success handling
        if (!toUpdate.isEmpty()) {
            try {
                List<Database.SaveResult> srList = Database.update(toUpdate, false, AccessLevel.USER_MODE);
                Integer failures = 0;
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) failures++;
                }
                Integer successes = srList.size() - failures;
                summary.totalUpdated += successes;
                if (failures > 0) {
                    summary.errorMessage = 'Some trackers failed to update. Failures: ' + String.valueOf(failures);
                }
            } catch (Exception e) {
                summary.errorMessage = 'Update failed: ' + e.getMessage();
                out.add(summary);
                return out;
            }
        }

        // Global counters
        for (PerAccountResult par : summary.perAccountResults) {
            summary.totalFound += (par.trackersFound == null ? 0 : par.trackersFound);
            summary.totalAlreadyComplete += (par.alreadyComplete == null ? 0 : par.alreadyComplete);
        }

        out.add(summary);
        return out;
    }
}
```
