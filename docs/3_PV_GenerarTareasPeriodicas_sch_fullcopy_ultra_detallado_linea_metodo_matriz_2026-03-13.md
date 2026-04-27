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

## 10. Desglose por metodo con lineas y comportamiento
Esta seccion agrega un inventario metodo por metodo, con lineas de inicio/fin, foco funcional y rastreo de query, DML y side effects.

### classes/PV_GenerarTareasPeriodicas_sch.cls
- Metodo/Elemento: `execute`
- Lineas: `15-22`
- Firma: `global void execute(SchedulableContext sc) {`
- Funcion tecnica: Ejecuta la logica principal del batch/scheduler/queueable sobre el scope o contexto actual.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/ACT_BusinessHoursHelper_cls.cls
- Metodo/Elemento: `getConfiguredBusinessHoursName`
- Lineas: `23-44`
- Firma: `private static String getConfiguredBusinessHoursName(String configDeveloperName) {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: List<SObject> configs = Database.query(; 'SELECT BusinessHoursName__c ' +
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getConfiguredBusinessHoursId`
- Lineas: `46-63`
- Firma: `private static Id getConfiguredBusinessHoursId(String configDeveloperName) {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: SELECT Id
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `isWithinConfiguredBH`
- Lineas: `69-82`
- Firma: `public static Boolean isWithinConfiguredBH(String configDeveloperName) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: return BusinessHours.isWithin(bhId, nowDt);
- Metodo/Elemento: `isConfiguredBusinessDay`
- Lineas: `88-103`
- Firma: `public static Boolean isConfiguredBusinessDay(String configDeveloperName) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: Datetime nextStart = BusinessHours.nextStartDate(bhId, startOfDay);

### classes/PV_GenerarTareasPeriodicas_bch.cls
- Metodo/Elemento: `start`
- Lineas: `14-16`
- Firma: `public Database.QueryLocator start(Database.BatchableContext BC) {`
- Funcion tecnica: Obtiene el universo inicial del proceso; normalmente arma QueryLocator o selecciona registros fuente.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `execute`
- Lineas: `18-50`
- Firma: `public void execute(Database.BatchableContext BC, List<sObject> scope) {`
- Funcion tecnica: Ejecuta la logica principal del batch/scheduler/queueable sobre el scope o contexto actual.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `finish`
- Lineas: `53-56`
- Firma: `public void finish(Database.BatchableContext BC) {`
- Funcion tecnica: Cierra el proceso actual; puede encadenar batches, dejar trazas o completar efectos posteriores.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PV_GenerarTareasPeriodicas.cls
- Metodo/Elemento: `obtenerCuentasValidas`
- Lineas: `17-39`
- Firma: `public static List<Account> obtenerCuentasValidas(List<sObject> cuentasEntrada) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getAccountsWithAvailableCadenceSlot`
- Lineas: `41-72`
- Firma: `public static Set<Id> getAccountsWithAvailableCadenceSlot(Set<Id> accountIds) {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: SELECT Id, TargetId
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `obtenerCuentasValidasParaAsignarCadencia`
- Lineas: `109-154`
- Firma: `public static List<Account> obtenerCuentasValidasParaAsignarCadencia(List<Account> cuentas, String developerNameCadencia, Integer numeroDias) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `validarTareaPorCuenta`
- Lineas: `156-180`
- Firma: `public static List<Account> validarTareaPorCuenta(List<Account> cuentas, String developerNameCadencia) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `validarTareaPorContrato`
- Lineas: `182-214`
- Firma: `public static List<Account> validarTareaPorContrato(List<Account> cuentas, String developerNameCadencia, List<Contract> contratos) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `generarCadenceItems`
- Lineas: `216-230`
- Firma: `public static List<PV_GenerarTareasPeriodicas_Request> generarCadenceItems(Id cadenceId, List<Account> cuentas, Map<Id, Id> mapBankerAccount, String developerNameCadencia) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `filtrarAccountsConCadencias`
- Lineas: `232-243`
- Firma: `public static List<Account> filtrarAccountsConCadencias(List<Account> cuentas, ActionCadence cadence) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `generarRequestCadence`
- Lineas: `245-292`
- Firma: `public static void generarRequestCadence(List<ActionCadence> lstCadence, List<Account> cuentas, Map<Id, Id> mapBankerAccount) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: System.enqueueJob(new PV_EjecutarAsignacionCadencias_Queueable(inputsList,0));
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `obtenerContratos`
- Lineas: `294-298`
- Firma: `public static List<Contract> obtenerContratos(List<Account> cuentas) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getContactsId`
- Lineas: `300-308`
- Firma: `public static Set<Id> getContactsId(List<Account> cuentas) {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `filtrarCuentas`
- Lineas: `310-319`
- Firma: `public static List<Account> filtrarCuentas(List<Account> cuentas, Set<Id> cuentasYaProcesadas, Boolean usarPersonContactId) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `saveLogError`
- Lineas: `321-327`
- Firma: `public static void saveLogError(Map<String, String> mapErrors, String message, String errorCode, String type){`
- Funcion tecnica: Metodo orientado a registro de errores, logging o persistencia auxiliar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: EventLogger.error(new Map<String, String>{'contextId' => null,
- Metodo/Elemento: `saveErrorFlow`
- Lineas: `329-339`
- Firma: `public static void saveErrorFlow(List<String> errores){`
- Funcion tecnica: Metodo orientado a registro de errores, logging o persistencia auxiliar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PV_GenerarTareasPeriodicasSelector_cls.cls
- Metodo/Elemento: `getQueryAccounts`
- Lineas: `16-21`
- Firma: `public static String getQueryAccounts(){`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Generar_Tareas'].Consulta__c ;
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getCadence`
- Lineas: `36-46`
- Firma: `public static List<ActionCadence> getCadence() {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: return [SELECT Id,
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getContratosClienteNoContactar`
- Lineas: `48-56`
- Firma: `public static List<Contract> getContratosClienteNoContactar(Set<Id> accountIds) {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: return [SELECT AccountId, FLAG_MARKETING__c, FLAG_MARKETING_ACTINVER__c, FLAG_EVENTS_INVITATIONS__c
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getBankerByBusinessMemberId`
- Lineas: `58-60`
- Firma: `public static List<Banker> getBankerByBusinessMemberId(Set<Id> setBMemberId){`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: return [SELECT ID, UserOrContactId, ExternalId__c FROM BANKER WHERE ID IN: setBMemberId];
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getDiasLaborales`
- Lineas: `62-64`
- Firma: `public static Id getDiasLaborales(){`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: return [SELECT Id FROM BusinessHours WHERE Name = 'Postventa'].Id;
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `validateCadenceActive`
- Lineas: `66-83`
- Firma: `public static List<ActionCadenceTracker> validateCadenceActive(Set<Id> accountIds, String developerNameCadencia, Boolean cadenciaUnicaPorCuenta) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: String baseQuery = 'SELECT ActionCadence.DeveloperName__c, TargetId ' +; return Database.query(baseQuery);
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getContratosNoPropuestaPlaneacion`
- Lineas: `85-93`
- Firma: `public static List<Contract> getContratosNoPropuestaPlaneacion(Set<Id> accountIds) {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: SELECT Id, AccountId, Account.PersonContactId, PlaneacionFinancieraCompletada__c, PropuestaInversionCompletada__c
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getTask`
- Lineas: `95-113`
- Firma: `public static List<Task> getTask(Set<Id> accountIds, String developerNameCadencia) {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: SELECT AccountId, CreatedDate, DeveloperName__c
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PV_EjecutarAsignacionCadencias_Queueable.cls
- Metodo/Elemento: `PV_EjecutarAsignacionCadencias_Queueable`
- Lineas: `13-16`
- Firma: `public PV_EjecutarAsignacionCadencias_Queueable(List<PV_GenerarTareasPeriodicas_Request> fullList, Integer offset) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `execute`
- Lineas: `18-44`
- Firma: `public void execute(QueueableContext context) {`
- Funcion tecnica: Ejecuta la logica principal del batch/scheduler/queueable sobre el scope o contexto actual.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: System.enqueueJob(new PV_EjecutarAsignacionCadencias_Queueable(fullList, endList));
- Side effects detectados: Flow.Interview.PV_AsignarCadencesCuentas_Flow flow = new Flow.Interview.PV_AsignarCadencesCuentas_Flow(

### classes/PV_GenerarTareasPeriodicas_Request.cls
- Metodo/Elemento: `PV_GenerarTareasPeriodicas_Request`
- Lineas: `19-23`
- Firma: `public PV_GenerarTareasPeriodicas_Request(String cadence, String target, String user) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### flows/PV_AsignarCadencesCuentas_Flow.flow-meta.xml
- Metodo/Elemento: `Asignar_cadencia`
- Lineas: `3-38`
- Firma: `actionCalls:Asignar_cadencia`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: <actionName>assignTargetToSalesCadence</actionName>; <actionType>assignTargetToSalesCadence</actionType>; <nameSegment>assignTargetToSalesCadence</nameSegment>
- Metodo/Elemento: `Almacenar_error`
- Lineas: `41-57`
- Firma: `assignments:Almacenar_error`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `Recorrer_las_cadencias`
- Lineas: `66-76`
- Firma: `loops:Recorrer_las_cadencias`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `start`
- Lineas: `96-102`
- Firma: `start:start`
- Funcion tecnica: Obtiene el universo inicial del proceso; normalmente arma QueryLocator o selecciona registros fuente.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### triggers/TriggerActionCadanceStepTracker.trigger
- Metodo/Elemento: `TriggerActionCadanceStepTracker`
- Lineas: `11-16`
- Firma: `trigger TriggerActionCadanceStepTracker on ActionCadenceStepTrackerChangeEvent (after insert) {`
- Funcion tecnica: Punto de entrada trigger; enruta el evento del objeto/plataforma a la clase manejadora.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: if(Trigger.isInsert && Trigger.isAfter) TriggerActionCadenceStepTracker_thr.onAfterInsert(Trigger.new);

### classes/TriggerActionCadenceStepTracker_thr.cls
- Metodo/Elemento: `onAfterInsert`
- Lineas: `12-14`
- Firma: `public static void onAfterInsert(List<ActionCadenceStepTrackerChangeEvent> lstNewRecords){`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PSTA_GestionTareas_Helper.cls
- Metodo/Elemento: `createTaskWithCloseCadence`
- Lineas: `14-19`
- Firma: `public static void createTaskWithCloseCadence(List<ActionCadenceStepTrackerChangeEvent> lstStepTracker){`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `updateTasksCadence`
- Lineas: `20-31`
- Firma: `public static List<Task> updateTasksCadence( List<ActionCadenceStepTracker> stepTrackers){`
- Funcion tecnica: Metodo orientado a persistencia; aplica DML parcial o total sobre registros preparados previamente.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `createTasks`
- Lineas: `32-39`
- Firma: `public static void createTasks(List<ActionCadenceStepTracker> stepTrackers){`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: if(lstTareas.size() > 0) update lstTareas;
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `generateSetIdContact`
- Lineas: `47-51`
- Firma: `public static Set<Id> generateSetIdContact(List<ActionCadenceStepTracker> stepTrackers){`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `createExternalIdTask`
- Lineas: `64-65`
- Firma: `public static String createExternalIdTask(String strTarea, String ClientBP, String ExternalIdBanquero){ return strTarea + '-' + ClientBP + '-' + ExternalIdBanquero + '-' + ACTINVER_UtilityFactory_utils.formatDate(System.today(), false);`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `publishEvent`
- Lineas: `66-72`
- Firma: `public static void publishEvent(List<Task> lstTask, Map<Id, Contact> mapAccountByContact){`
- Funcion tecnica: Publica eventos de plataforma para propagar el resultado del proceso a consumidores posteriores.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: List<Database.SaveResult> results = EventBus.publish(lstEvent);
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PSTA_GestionTareas_soql.cls
- Metodo/Elemento: `getStepTrackers`
- Lineas: `12-24`
- Firma: `public static List<ActionCadenceStepTracker> getStepTrackers(List<String> recordIds){`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: return [SELECT  Id,
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getAccountsByContactIds`
- Lineas: `25-28`
- Firma: `public static List<Contact> getAccountsByContactIds(Set<Id> setContactId){`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: return [SELECT ID, AccountId, Account.BanqueroAsignado__r.BusinessUnitMemberId, Account.Client_ID__c, Account.Name
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getBankerByBusinessMemberId`
- Lineas: `29-31`
- Firma: `public static List<Banker> getBankerByBusinessMemberId(Set<Id> setBMemberId){`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: return [SELECT ID, UserOrContactId, ExternalId__c FROM BANKER WHERE ID IN: setBMemberId];
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getTaskUsingIdsTracker`
- Lineas: `32-34`
- Firma: `public static List<Task> getTaskUsingIdsTracker(Set<Id> setTrackersId){`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: return [SELECT Id,ActionCadenceStepTrackerId,Account.Client_ID__c,Account.Name, Account.ID_Asesor__c, WhoId, OwnerId FROM Task WHERE ActionCadenceStepTrackerId IN :setTrackersId];
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### triggers/Task_trg.trigger
- Metodo/Elemento: `Task_trg`
- Lineas: `8-17`
- Firma: `trigger Task_trg on Task (after update) {`
- Funcion tecnica: Punto de entrada trigger; enruta el evento del objeto/plataforma a la clase manejadora.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: if(Trigger.isUpdate && Trigger.isAfter){; Task_thr.onAfterUpdate(Trigger.new, Trigger.oldMap);

### classes/Task_thr.cls
- Metodo/Elemento: `onAfterUpdate`
- Lineas: `12-15`
- Firma: `public static void onAfterUpdate(List<Task> newListTask, Map<Id, Task> mapOldTask){`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PSTA_ChangeAccountInfo_ctr.cls
- Metodo/Elemento: `changeContactAndDateStatus`
- Lineas: `13-16`
- Firma: `public static void changeContactAndDateStatus(List<Task> lstTask, Map<Id, Task> mapOldTask){`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PSTA_ChangeAccountInfo_helper.cls
- Metodo/Elemento: `initProcessChangeStatusAccount`
- Lineas: `12-20`
- Firma: `public static void initProcessChangeStatusAccount(List<Task> lstTask, Map<Id, Task> mapOldTask){`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `taskReview`
- Lineas: `49-86`
- Firma: `public static void taskReview(List<Task> lstTask, Map<Id, Task> mapOldTask, Map<Id, Account> mapAccount, Map<String, ActionCadence> mapConfig){`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: if(setTaskUpdate.size() > 0) PSTA_EnvioEncuestaMedallia_cls.sendSurvey(setTaskUpdate);
- Metodo/Elemento: `publicarEvento`
- Lineas: `125-129`
- Firma: `public static void publicarEvento(Id idTask, Id idUser){`
- Funcion tecnica: Publica eventos de plataforma para propagar el resultado del proceso a consumidores posteriores.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: Database.SaveResult sr = EventBus.publish(event);
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PSTA_ChangeAccountInfo_soql.cls
- Metodo/Elemento: `getAccountsInfo`
- Lineas: `12-14`
- Firma: `public static List<Account> getAccountsInfo(Set<Id> setIdAcc){`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: return [SELECT Id, EstatusContacto__c, FechaUltimoContacto__c FROM Account WHERE Id IN :setIdAcc];
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `lstConfigByCadences`
- Lineas: `15-17`
- Firma: `public static List<ActionCadence> lstConfigByCadences(Set<String> setTaskDevName){`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: return [SELECT DeveloperName__c, GeneraContacto__c, RequiereCargaEvidencia__c FROM ACTIONCADENCE WHERE DeveloperName__c IN :setTaskDevName];
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### flows/Flow_Avance_FAC.flow-meta.xml
- Metodo/Elemento: `Aplicables`
- Lineas: `5-34`
- Firma: `assignments:Aplicables`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `BaseSum`
- Lineas: `35-155`
- Firma: `assignments:BaseSum`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `SetResults`
- Lineas: `156-175`
- Firma: `assignments:SetResults`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `start`
- Lineas: `320-329`
- Firma: `start:start`
- Funcion tecnica: Obtiene el universo inicial del proceso; normalmente arma QueryLocator o selecciona registros fuente.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### flows/FAC_Update_Task_Field_Avence.flow-meta.xml
- Metodo/Elemento: `Avance_Percent_Account`
- Lineas: `5-20`
- Firma: `assignments:Avance_Percent_Account`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `Existe_tarea_Postventa`
- Lineas: `21-42`
- Firma: `decisions:Existe_tarea_Postventa`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `Sicontactasi_es_100`
- Lineas: `43-64`
- Firma: `decisions:Sicontactasi_es_100`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `Task_FAC`
- Lineas: `87-131`
- Firma: `recordLookups:Task_FAC`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `Update_contactado`
- Lineas: `132-152`
- Firma: `recordUpdates:Update_contactado`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `Update_Task`
- Lineas: `153-183`
- Firma: `recordUpdates:Update_Task`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `start`
- Lineas: `184-201`
- Firma: `start:start`
- Funcion tecnica: Obtiene el universo inicial del proceso; normalmente arma QueryLocator o selecciona registros fuente.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### flows/FAC_Task_Update_InAccount.flow-meta.xml
- Metodo/Elemento: `Get_Task`
- Lineas: `27-69`
- Firma: `recordLookups:Get_Task`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `UpdateTask`
- Lineas: `70-104`
- Firma: `recordUpdates:UpdateTask`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `start`
- Lineas: `105-122`
- Firma: `start:start`
- Funcion tecnica: Obtiene el universo inicial del proceso; normalmente arma QueryLocator o selecciona registros fuente.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### flows/FAC_Task_Update_InTask.flow-meta.xml
- Metodo/Elemento: `FAC_Avance_100`
- Lineas: `5-33`
- Firma: `decisions:FAC_Avance_100`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `Related_Account`
- Lineas: `56-83`
- Firma: `recordLookups:Related_Account`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `Update_Records_1`
- Lineas: `84-96`
- Firma: `recordUpdates:Update_Records_1`
- Funcion tecnica: Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `start`
- Lineas: `97-121`
- Firma: `start:start`
- Funcion tecnica: Obtiene el universo inicial del proceso; normalmente arma QueryLocator o selecciona registros fuente.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/ACTCompleteCadenceForAccounts.cls
- Metodo/Elemento: `completeForAccounts`
- Lineas: `74-241`
- Firma: `public static List<Response> completeForAccounts(List<Request> requests) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: SELECT Id, AccountId; SELECT Id, State, TargetId, ActionCadenceId
- DML/Ejecucion detectada: List<Database.SaveResult> srList = Database.update(toUpdate, false, AccessLevel.USER_MODE);
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

## 11. Matriz tecnica granular archivo -> metodo -> query -> dml -> side effects
| Archivo | Metodo/Elemento | Lineas | Query/Read | DML/Ejecucion | Side effects |
|---|---|---:|---|---|---|
| classes/PV_GenerarTareasPeriodicas_sch.cls | execute | 15-22 | - | - | - |
| classes/ACT_BusinessHoursHelper_cls.cls | getConfiguredBusinessHoursName | 23-44 | List<SObject> configs = Database.query(<br>'SELECT BusinessHoursName__c ' + | - | - |
| classes/ACT_BusinessHoursHelper_cls.cls | getConfiguredBusinessHoursId | 46-63 | SELECT Id | - | - |
| classes/ACT_BusinessHoursHelper_cls.cls | isWithinConfiguredBH | 69-82 | - | - | return BusinessHours.isWithin(bhId, nowDt); |
| classes/ACT_BusinessHoursHelper_cls.cls | isConfiguredBusinessDay | 88-103 | - | - | Datetime nextStart = BusinessHours.nextStartDate(bhId, startOfDay); |
| classes/PV_GenerarTareasPeriodicas_bch.cls | start | 14-16 | - | - | - |
| classes/PV_GenerarTareasPeriodicas_bch.cls | execute | 18-50 | - | - | - |
| classes/PV_GenerarTareasPeriodicas_bch.cls | finish | 53-56 | - | - | - |
| classes/PV_GenerarTareasPeriodicas.cls | obtenerCuentasValidas | 17-39 | - | - | - |
| classes/PV_GenerarTareasPeriodicas.cls | getAccountsWithAvailableCadenceSlot | 41-72 | SELECT Id, TargetId | - | - |
| classes/PV_GenerarTareasPeriodicas.cls | obtenerCuentasValidasParaAsignarCadencia | 109-154 | - | - | - |
| classes/PV_GenerarTareasPeriodicas.cls | validarTareaPorCuenta | 156-180 | - | - | - |
| classes/PV_GenerarTareasPeriodicas.cls | validarTareaPorContrato | 182-214 | - | - | - |
| classes/PV_GenerarTareasPeriodicas.cls | generarCadenceItems | 216-230 | - | - | - |
| classes/PV_GenerarTareasPeriodicas.cls | filtrarAccountsConCadencias | 232-243 | - | - | - |
| classes/PV_GenerarTareasPeriodicas.cls | generarRequestCadence | 245-292 | - | System.enqueueJob(new PV_EjecutarAsignacionCadencias_Queueable(inputsList,0)); | - |
| classes/PV_GenerarTareasPeriodicas.cls | obtenerContratos | 294-298 | - | - | - |
| classes/PV_GenerarTareasPeriodicas.cls | getContactsId | 300-308 | - | - | - |
| classes/PV_GenerarTareasPeriodicas.cls | filtrarCuentas | 310-319 | - | - | - |
| classes/PV_GenerarTareasPeriodicas.cls | saveLogError | 321-327 | - | - | EventLogger.error(new Map<String, String>{'contextId' => null, |
| classes/PV_GenerarTareasPeriodicas.cls | saveErrorFlow | 329-339 | - | - | - |
| classes/PV_GenerarTareasPeriodicasSelector_cls.cls | getQueryAccounts | 16-21 | String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Generar_Tareas'].Consulta__c ; | - | - |
| classes/PV_GenerarTareasPeriodicasSelector_cls.cls | getCadence | 36-46 | return [SELECT Id, | - | - |
| classes/PV_GenerarTareasPeriodicasSelector_cls.cls | getContratosClienteNoContactar | 48-56 | return [SELECT AccountId, FLAG_MARKETING__c, FLAG_MARKETING_ACTINVER__c, FLAG_EVENTS_INVITATIONS__c | - | - |
| classes/PV_GenerarTareasPeriodicasSelector_cls.cls | getBankerByBusinessMemberId | 58-60 | return [SELECT ID, UserOrContactId, ExternalId__c FROM BANKER WHERE ID IN: setBMemberId]; | - | - |
| classes/PV_GenerarTareasPeriodicasSelector_cls.cls | getDiasLaborales | 62-64 | return [SELECT Id FROM BusinessHours WHERE Name = 'Postventa'].Id; | - | - |
| classes/PV_GenerarTareasPeriodicasSelector_cls.cls | validateCadenceActive | 66-83 | String baseQuery = 'SELECT ActionCadence.DeveloperName__c, TargetId ' +<br>return Database.query(baseQuery); | - | - |
| classes/PV_GenerarTareasPeriodicasSelector_cls.cls | getContratosNoPropuestaPlaneacion | 85-93 | SELECT Id, AccountId, Account.PersonContactId, PlaneacionFinancieraCompletada__c, PropuestaInversionCompletada__c | - | - |
| classes/PV_GenerarTareasPeriodicasSelector_cls.cls | getTask | 95-113 | SELECT AccountId, CreatedDate, DeveloperName__c | - | - |
| classes/PV_EjecutarAsignacionCadencias_Queueable.cls | PV_EjecutarAsignacionCadencias_Queueable | 13-16 | - | - | - |
| classes/PV_EjecutarAsignacionCadencias_Queueable.cls | execute | 18-44 | - | System.enqueueJob(new PV_EjecutarAsignacionCadencias_Queueable(fullList, endList)); | Flow.Interview.PV_AsignarCadencesCuentas_Flow flow = new Flow.Interview.PV_AsignarCadencesCuentas_Flow( |
| classes/PV_GenerarTareasPeriodicas_Request.cls | PV_GenerarTareasPeriodicas_Request | 19-23 | - | - | - |
| flows/PV_AsignarCadencesCuentas_Flow.flow-meta.xml | Asignar_cadencia | 3-38 | - | - | <actionName>assignTargetToSalesCadence</actionName><br><actionType>assignTargetToSalesCadence</actionType><br><nameSegment>assignTargetToSalesCadence</nameSegment> |
| flows/PV_AsignarCadencesCuentas_Flow.flow-meta.xml | Almacenar_error | 41-57 | - | - | - |
| flows/PV_AsignarCadencesCuentas_Flow.flow-meta.xml | Recorrer_las_cadencias | 66-76 | - | - | - |
| flows/PV_AsignarCadencesCuentas_Flow.flow-meta.xml | start | 96-102 | - | - | - |
| triggers/TriggerActionCadanceStepTracker.trigger | TriggerActionCadanceStepTracker | 11-16 | - | - | if(Trigger.isInsert && Trigger.isAfter) TriggerActionCadenceStepTracker_thr.onAfterInsert(Trigger.new); |
| classes/TriggerActionCadenceStepTracker_thr.cls | onAfterInsert | 12-14 | - | - | - |
| classes/PSTA_GestionTareas_Helper.cls | createTaskWithCloseCadence | 14-19 | - | - | - |
| classes/PSTA_GestionTareas_Helper.cls | updateTasksCadence | 20-31 | - | - | - |
| classes/PSTA_GestionTareas_Helper.cls | createTasks | 32-39 | - | if(lstTareas.size() > 0) update lstTareas; | - |
| classes/PSTA_GestionTareas_Helper.cls | generateSetIdContact | 47-51 | - | - | - |
| classes/PSTA_GestionTareas_Helper.cls | createExternalIdTask | 64-65 | - | - | - |
| classes/PSTA_GestionTareas_Helper.cls | publishEvent | 66-72 | - | List<Database.SaveResult> results = EventBus.publish(lstEvent); | - |
| classes/PSTA_GestionTareas_soql.cls | getStepTrackers | 12-24 | return [SELECT  Id, | - | - |
| classes/PSTA_GestionTareas_soql.cls | getAccountsByContactIds | 25-28 | return [SELECT ID, AccountId, Account.BanqueroAsignado__r.BusinessUnitMemberId, Account.Client_ID__c, Account.Name | - | - |
| classes/PSTA_GestionTareas_soql.cls | getBankerByBusinessMemberId | 29-31 | return [SELECT ID, UserOrContactId, ExternalId__c FROM BANKER WHERE ID IN: setBMemberId]; | - | - |
| classes/PSTA_GestionTareas_soql.cls | getTaskUsingIdsTracker | 32-34 | return [SELECT Id,ActionCadenceStepTrackerId,Account.Client_ID__c,Account.Name, Account.ID_Asesor__c, WhoId, OwnerId FROM Task WHERE ActionCadenceStepTrackerId IN :setTrackersId]; | - | - |
| triggers/Task_trg.trigger | Task_trg | 8-17 | - | - | if(Trigger.isUpdate && Trigger.isAfter){<br>Task_thr.onAfterUpdate(Trigger.new, Trigger.oldMap); |
| classes/Task_thr.cls | onAfterUpdate | 12-15 | - | - | - |
| classes/PSTA_ChangeAccountInfo_ctr.cls | changeContactAndDateStatus | 13-16 | - | - | - |
| classes/PSTA_ChangeAccountInfo_helper.cls | initProcessChangeStatusAccount | 12-20 | - | - | - |
| classes/PSTA_ChangeAccountInfo_helper.cls | taskReview | 49-86 | - | - | if(setTaskUpdate.size() > 0) PSTA_EnvioEncuestaMedallia_cls.sendSurvey(setTaskUpdate); |
| classes/PSTA_ChangeAccountInfo_helper.cls | publicarEvento | 125-129 | - | Database.SaveResult sr = EventBus.publish(event); | - |
| classes/PSTA_ChangeAccountInfo_soql.cls | getAccountsInfo | 12-14 | return [SELECT Id, EstatusContacto__c, FechaUltimoContacto__c FROM Account WHERE Id IN :setIdAcc]; | - | - |
| classes/PSTA_ChangeAccountInfo_soql.cls | lstConfigByCadences | 15-17 | return [SELECT DeveloperName__c, GeneraContacto__c, RequiereCargaEvidencia__c FROM ACTIONCADENCE WHERE DeveloperName__c IN :setTaskDevName]; | - | - |
| flows/Flow_Avance_FAC.flow-meta.xml | Aplicables | 5-34 | - | - | - |
| flows/Flow_Avance_FAC.flow-meta.xml | BaseSum | 35-155 | - | - | - |
| flows/Flow_Avance_FAC.flow-meta.xml | SetResults | 156-175 | - | - | - |
| flows/Flow_Avance_FAC.flow-meta.xml | start | 320-329 | - | - | - |
| flows/FAC_Update_Task_Field_Avence.flow-meta.xml | Avance_Percent_Account | 5-20 | - | - | - |
| flows/FAC_Update_Task_Field_Avence.flow-meta.xml | Existe_tarea_Postventa | 21-42 | - | - | - |
| flows/FAC_Update_Task_Field_Avence.flow-meta.xml | Sicontactasi_es_100 | 43-64 | - | - | - |
| flows/FAC_Update_Task_Field_Avence.flow-meta.xml | Task_FAC | 87-131 | - | - | - |
| flows/FAC_Update_Task_Field_Avence.flow-meta.xml | Update_contactado | 132-152 | - | - | - |
| flows/FAC_Update_Task_Field_Avence.flow-meta.xml | Update_Task | 153-183 | - | - | - |
| flows/FAC_Update_Task_Field_Avence.flow-meta.xml | start | 184-201 | - | - | - |
| flows/FAC_Task_Update_InAccount.flow-meta.xml | Get_Task | 27-69 | - | - | - |
| flows/FAC_Task_Update_InAccount.flow-meta.xml | UpdateTask | 70-104 | - | - | - |
| flows/FAC_Task_Update_InAccount.flow-meta.xml | start | 105-122 | - | - | - |
| flows/FAC_Task_Update_InTask.flow-meta.xml | FAC_Avance_100 | 5-33 | - | - | - |
| flows/FAC_Task_Update_InTask.flow-meta.xml | Related_Account | 56-83 | - | - | - |
| flows/FAC_Task_Update_InTask.flow-meta.xml | Update_Records_1 | 84-96 | - | - | - |
| flows/FAC_Task_Update_InTask.flow-meta.xml | start | 97-121 | - | - | - |
| classes/ACTCompleteCadenceForAccounts.cls | completeForAccounts | 74-241 | SELECT Id, AccountId<br>SELECT Id, State, TargetId, ActionCadenceId | List<Database.SaveResult> srList = Database.update(toUpdate, false, AccessLevel.USER_MODE); | - |

## 12. Codigo numerado archivo por archivo
En esta seccion se replica el codigo con numeracion de lineas para facilitar trazabilidad exacta durante la revision tecnica.

### classes/PV_GenerarTareasPeriodicas_sch.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Martín Martínez
0004: * Project           :   Post venta
0005: * Clase test        :   PV_GenerarTareasPeriodicas_sch_tst
0006: * Description       :   Clase exclusiva para la periodicidad de creación de tareas
0007: *-------------------------------------------------------------------------- 
0008: * No.            Date              Author                    Description
0009: * 1.0         19-Jun-2025       Martín Martínez              Creación
0010: * 1.1         20-Jan-2026       Francisco Ortega             Ejecución de BusinessHours vía ACT_PSTA_BusinessHoursHelper_cls
0011: *-------------------------------------------------------------------------- 
0012: *******************************************************************************/
0013: global class PV_GenerarTareasPeriodicas_sch implements Schedulable {
0014: 
0015:     global void execute(SchedulableContext sc) {
0016: 
0017:         ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
0018:             'PV_GenerarTareasPeriodicas',
0019:             new PV_GenerarTareasPeriodicas_bch(),
0020:             Integer.valueOf(Label.BatchCadencias_Size_Limit)
0021:         );
0022:     }
0023: }
```

### classes/ACT_BusinessHoursHelper_cls.cls
```text
0001: /*******************************************************************************
0002: * Developed by      :   Actinver Mexico
0003: * Author            :   Francisco Ortega
0004: * Project           :   Post venta
0005: * Clase test        :   ACT_BusinessHoursHelper_cls_Test
0006: * Description       :   Helper unificado para:
0007: *                       - Leer CMDT ACT_BatchConfig__mdt
0008: *                       - Resolver Business Hours (ej. 'Postventa')
0009: *                       - Evaluar horario habil y dia habil
0010: *                       - Ejecutar batches segun la regla requerida
0011: *--------------------------------------------------------------------------
0012: * No.            Date              Author                Description
0013: * 1.0         18-Nov-2025       Francisco Ortega         Creacion (version PSTA)
0014: * 1.1         20-Jan-2026       Francisco Ortega         Ejecutar Business Hours en una sola clase
0015: * 1.2         11-Mar-2026       Francisco Ortega         Validar dia habil para schedulers nocturnos
0016: *--------------------------------------------------------------------------
0017: *******************************************************************************/
0018: public with sharing class ACT_BusinessHoursHelper_cls {
0019: 
0020:     @TestVisible private static Boolean testOverrideIsWithinConfiguredBH;
0021:     @TestVisible private static Boolean testOverrideIsConfiguredBusinessDay;
0022: 
0023:     private static String getConfiguredBusinessHoursName(String configDeveloperName) {
0024:         if (String.isBlank(configDeveloperName)) {
0025:             return null;
0026:         }
0027: 
0028:         try {
0029:             List<SObject> configs = Database.query(
0030:                 'SELECT BusinessHoursName__c ' +
0031:                 'FROM ACT_BatchConfig__mdt ' +
0032:                 'WHERE DeveloperName = :configDeveloperName ' +
0033:                 'LIMIT 1'
0034:             );
0035: 
0036:             if (!configs.isEmpty()) {
0037:                 return (String)configs[0].get('BusinessHoursName__c');
0038:             }
0039:         } catch (Exception e) {
0040:             return null;
0041:         }
0042: 
0043:         return null;
0044:     }
0045: 
0046:     private static Id getConfiguredBusinessHoursId(String configDeveloperName) {
0047:         String businessHoursName = getConfiguredBusinessHoursName(configDeveloperName);
0048:         if (String.isBlank(businessHoursName)) {
0049:             return null;
0050:         }
0051: 
0052:         try {
0053:             BusinessHours bh = [
0054:                 SELECT Id
0055:                 FROM BusinessHours
0056:                 WHERE Name = :businessHoursName
0057:                 LIMIT 1
0058:             ];
0059:             return bh.Id;
0060:         } catch (Exception e) {
0061:             return null;
0062:         }
0063:     }
0064: 
0065:     /**
0066:      * Valida si System.now() esta dentro del horario habil configurado.
0067:      * Si bhId es null, Salesforce usa el BH default del org.
0068:      */
0069:     public static Boolean isWithinConfiguredBH(String configDeveloperName) {
0070:         if (Test.isRunningTest() && testOverrideIsWithinConfiguredBH != null) {
0071:             return testOverrideIsWithinConfiguredBH;
0072:         }
0073: 
0074:         Datetime nowDt = System.now();
0075:         Id bhId = getConfiguredBusinessHoursId(configDeveloperName);
0076: 
0077:         try {
0078:             return BusinessHours.isWithin(bhId, nowDt);
0079:         } catch (Exception e) {
0080:             return true;
0081:         }
0082:     }
0083: 
0084:     /**
0085:      * Valida si el dia actual es dia habil segun la BH configurada.
0086:      * Ignora la hora actual para permitir ejecuciones de madrugada.
0087:      */
0088:     public static Boolean isConfiguredBusinessDay(String configDeveloperName) {
0089:         if (Test.isRunningTest() && testOverrideIsConfiguredBusinessDay != null) {
0090:             return testOverrideIsConfiguredBusinessDay;
0091:         }
0092: 
0093:         Date currentDate = System.now().date();
0094:         Datetime startOfDay = Datetime.newInstance(currentDate, Time.newInstance(0, 0, 0, 0));
0095:         Id bhId = getConfiguredBusinessHoursId(configDeveloperName);
0096: 
0097:         try {
0098:             Datetime nextStart = BusinessHours.nextStartDate(bhId, startOfDay);
0099:             return nextStart != null && nextStart.date() == currentDate;
0100:         } catch (Exception e) {
0101:             return true;
0102:         }
0103:     }
0104: 
0105:     private static Id executeBatch(
0106:         Database.Batchable<SObject> batchInstance,
0107:         Integer scopeSize
0108:     ) {
0109:         if (scopeSize != null) {
0110:             return Database.executeBatch(batchInstance, scopeSize);
0111:         }
0112:         return Database.executeBatch(batchInstance);
0113:     }
0114: 
0115:     /**
0116:      * Ejecuta batch solo si esta dentro de horario habil (regla estricta por hora).
0117:      */
0118:     public static Id executeBatchIfWithinConfiguredBH(
0119:         String configDeveloperName,
0120:         Database.Batchable<SObject> batchInstance,
0121:         Integer scopeSize
0122:     ) {
0123:         if (!isWithinConfiguredBH(configDeveloperName)) {
0124:             return null;
0125:         }
0126:         return executeBatch(batchInstance, scopeSize);
0127:     }
0128: 
0129:     public static Id executeBatchIfWithinConfiguredBH(
0130:         String configDeveloperName,
0131:         Database.Batchable<SObject> batchInstance
0132:     ) {
0133:         return executeBatchIfWithinConfiguredBH(configDeveloperName, batchInstance, null);
0134:     }
0135: 
0136:     /**
0137:      * Ejecuta batch solo si el dia actual es habil (ignora hora).
0138:      * Esta variante permite jobs nocturnos manteniendo bloqueo en dias inhabiles.
0139:      */
0140:     public static Id executeBatchIfConfiguredBusinessDay(
0141:         String configDeveloperName,
0142:         Database.Batchable<SObject> batchInstance,
0143:         Integer scopeSize
0144:     ) {
0145:         if (!isConfiguredBusinessDay(configDeveloperName)) {
0146:             return null;
0147:         }
0148:         return executeBatch(batchInstance, scopeSize);
0149:     }
0150: 
0151:     public static Id executeBatchIfConfiguredBusinessDay(
0152:         String configDeveloperName,
0153:         Database.Batchable<SObject> batchInstance
0154:     ) {
0155:         return executeBatchIfConfiguredBusinessDay(configDeveloperName, batchInstance, null);
0156:     }
0157: }
```

### classes/PV_GenerarTareasPeriodicas_bch.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Canche Isaac
0004: * Project           :   Post venta
0005: * Clase test    :   PV_GenerarTareasPeriodicas_bch_tst
0006: * Description       :   Batch para crear nuevas tareas por periodicidad.
0007: *--------------------------------------------------------------------------
0008: * No.            Date              Author                Description
0009: * 1.0         19-Jun-2025       Martín Martínez              Creación
0010: *--------------------------------------------------------------------------
0011: *******************************************************************************/
0012: global class PV_GenerarTareasPeriodicas_bch implements Database.Batchable<sObject>, Database.Stateful{
0013:     
0014:     public Database.QueryLocator start(Database.BatchableContext BC) {
0015:         return Database.getQueryLocator(PV_GenerarTareasPeriodicasSelector_cls.getQueryAccounts());
0016:     }
0017: 
0018:     public void execute(Database.BatchableContext BC, List<sObject> scope) {
0019:         // Convertir el scope a lista tipada
0020:         List<Account> lstAccount = PV_GenerarTareasPeriodicas.obtenerCuentasValidas(scope);
0021:         
0022:         if (lstAccount.isEmpty()) {
0023:             System.debug('No se encontraron clientes a procesar para procesar.');
0024:             return;
0025:         }
0026: 
0027:         // Obtener cadencia
0028:         List<ActionCadence> lstCadence = PV_GenerarTareasPeriodicasSelector_cls.getCadence();
0029: 
0030:         if (lstCadence.isEmpty() && !Test.isRunningTest()) {
0031:             System.debug('No se encontraron cadencias para procesar.');
0032:             return;
0033:         }
0034: 
0035:         // Crear mapas de referencia
0036:         Map<String, Object> mapReferences = PV_GenerarTareasPeriodicas.createMapsToReference(lstAccount);
0037: 
0038:         // Obtener mapa de banqueros por cuenta
0039:         Map<Id, Id> mapBankerAccount = PV_GenerarTareasPeriodicas.getMapBankerAccount(
0040:             (Set<Id>) mapReferences.get('setBMemberId'),
0041:             (Map<Id, List<Id>>) mapReferences.get('mapAccount')
0042:         );        
0043: 
0044:         // Generar request a partir de las cadencias y cuentas
0045:         PV_GenerarTareasPeriodicas.generarRequestCadence(
0046:             lstCadence,
0047:             lstAccount,
0048:             mapBankerAccount
0049:         );
0050:     }
0051: 
0052: 
0053:     public void finish(Database.BatchableContext BC) {
0054:         System.debug('Finaliza el batch de tareas.');
0055:         
0056:     }
0057: 
0058: }
```

### classes/PV_GenerarTareasPeriodicas.cls
```text
0001: /**
0002:  * @description       : 
0003:  * @author            : Martin Martinez
0004:  * @group             : 
0005:  * @last modified on  : 09-17-2025
0006:  * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
0007: **/
0008: public class PV_GenerarTareasPeriodicas {
0009: 
0010:     private static Id businessHoursId = PV_GenerarTareasPeriodicasSelector_cls.getDiasLaborales();    
0011:     public static String planeacionFinanciera = PSTA_UtilityClass.DEVELOPERNAME_PLANEACION_FINANCIERA;
0012:     public static String propuestaInversion = PSTA_UtilityClass.DEVELOPERNAME_PROPUESTA_INVERSION;
0013:     public static String biometricos = PSTA_UtilityClass.DEVELOPERNAME_BIOMETRICOS;
0014:     public static String bancaElectronica = PSTA_UtilityClass.DEVELOPERNAME_BANCA_ELECTRONICA;
0015: 
0016: 
0017:     public static List<Account> obtenerCuentasValidas(List<sObject> cuentasEntrada) {
0018:         List<Account> cuentas = (List<Account>) cuentasEntrada;
0019:         Set<Id> accountIds = getAccountsWithAvailableCadenceSlot(getContactsId(cuentas));//new Map<Id, Account>(cuentas).keySet();
0020:         if (accountIds.isEmpty()) {            
0021:             return new List<Account>();
0022:         }
0023:         Set<Id> cuentasInvalidasIds = new Set<Id>();
0024: 
0025:         // Obtener contratos relacionados a las cuentas
0026:         List<Contract> contratos = PV_GenerarTareasPeriodicasSelector_cls.getContratosClienteNoContactar(accountIds);
0027: 
0028:         if (contratos.isEmpty()) {
0029:             return cuentas;
0030:         }
0031: 
0032:         // Validar cuentas con contratos con los tres campos poblados
0033:         for (Contract con : contratos) {
0034:             cuentasInvalidasIds.add(con.AccountId);
0035:         }
0036: 
0037:         // Filtrar cuentas que no estén marcadas como inválidas
0038:         return filtrarCuentas(cuentas, cuentasInvalidasIds, false);
0039:     }
0040: 
0041:     public static Set<Id> getAccountsWithAvailableCadenceSlot(Set<Id> accountIds) {
0042:         if (accountIds.isEmpty()) {
0043:             return new Set<Id>();
0044:         }
0045: 
0046:         // Consultar los targets y contar las cadencias activas por cliente
0047:         Map<Id, Integer> activeCadenceCount = new Map<Id, Integer>();
0048: 
0049:         List<ActionCadenceTracker> targets = [
0050:             SELECT Id, TargetId
0051:             FROM ActionCadenceTracker
0052:             WHERE TargetId IN :accountIds
0053:             AND State = 'Running'
0054:         ];
0055: 
0056:         for (ActionCadenceTracker t : targets) {
0057:             activeCadenceCount.put(
0058:                 t.TargetId,
0059:                 activeCadenceCount.containsKey(t.TargetId) ? activeCadenceCount.get(t.TargetId) + 1 : 1
0060:             );
0061:         }
0062: 
0063:         Set<Id> availableAccounts = new Set<Id>();
0064:         for (Id accId : accountIds) {
0065:             if (!activeCadenceCount.containsKey(accId) || activeCadenceCount.get(accId) < 5) {
0066:                 availableAccounts.add(accId);
0067:             }
0068:         }
0069: 
0070:         System.debug('availableAccounts:' + availableAccounts);
0071:         return availableAccounts;
0072:     }
0073: 
0074:     public static Map<String, Object> createMapsToReference(List<Account> lstAccounts){
0075:         Map<Id, List<Id>> mapAccount = new Map<Id, List<Id>>();
0076:         Set<Id> setBMemberId = new Set<Id>();
0077:         Map<String, Object> mapResult = new Map<String, Object>();
0078:         for (Account ac : lstAccounts) {
0079:             Id memberId = ac.BanqueroAsignado__c != null ? ac.BanqueroAsignado__r.BusinessUnitMemberId : null;
0080:             if (memberId != null) {
0081:                 setBMemberId.add(memberId);
0082: 
0083:                 if (!mapAccount.containsKey(memberId)) {
0084:                     mapAccount.put(memberId, new List<Id>());
0085:                 }
0086:                 mapAccount.get(memberId).add(ac.Id);
0087:             }
0088:         }
0089:         mapResult.put('mapAccount', mapAccount);
0090:         mapResult.put('setBMemberId', setBMemberId);
0091:         return mapResult;
0092:     }
0093: 
0094:     public static Map<Id, Id> getMapBankerAccount(Set<Id> setBMemberId, Map<Id, List<Id>> mapAccount){
0095:         Map<Id, Id> mapBankerAccount = new Map<Id, Id>();
0096:         for(Banker bank : PV_GenerarTareasPeriodicasSelector_cls.getBankerByBusinessMemberId(setBMemberId)){
0097:             if (mapAccount.containsKey(bank.Id)) {
0098:                 List<Id> cuentas = mapAccount.get(bank.Id);
0099:                 for (Id cuentaId : cuentas) {
0100:                     if (!mapBankerAccount.containsKey(cuentaId)) {
0101:                         mapBankerAccount.put(cuentaId, bank.UserOrContactId);
0102:                     }
0103:                 }
0104:             }
0105:         }
0106:         return mapBankerAccount;
0107:     }
0108: 
0109:     public static List<Account> obtenerCuentasValidasParaAsignarCadencia(List<Account> cuentas, String developerNameCadencia, Integer numeroDias) {
0110:         List<Account> cuentasValidas = new List<Account>();
0111:         Set<Id> cuentaIds = new Map<Id, Account>(cuentas).keySet();
0112: 
0113:         if (cuentaIds.isEmpty()) {
0114:             return cuentasValidas;
0115:         }
0116: 
0117:         // Obtener las tareas para esas cuentas con el developerName indicado, ordenadas descendente por CreatedDate
0118:         List<Task> tareas = PV_GenerarTareasPeriodicasSelector_cls.getTask(cuentaIds,developerNameCadencia);
0119: 
0120:         // Map para guardar la última tarea por cuenta
0121:         Map<Id, Task> ultimaTareaPorCuenta = new Map<Id, Task>();
0122:         for (Task t : tareas) {
0123:             if (!ultimaTareaPorCuenta.containsKey(t.AccountId)) {
0124:                 ultimaTareaPorCuenta.put(t.AccountId, t);
0125:             }
0126:         }
0127: 
0128:         Date hoy = Date.today();
0129: 
0130:         for (Account acc : cuentas) {
0131:             Task ultimaTarea = ultimaTareaPorCuenta.get(acc.Id);
0132:             Boolean esValida = false;
0133: 
0134:             if (ultimaTarea == null) {
0135:                 // No tiene tarea -> válido
0136:                 esValida = true;
0137:             } else {
0138:                 Date fechaTentativa = PSTA_UtilityClass.agregarDiasLaborales(
0139:                     ultimaTarea.CreatedDate.date(),
0140:                     numeroDias,
0141:                     businessHoursId
0142:                 );
0143:                 if (fechaTentativa == hoy) {
0144:                     esValida = true;
0145:                 }
0146:             }
0147: 
0148:             if (esValida) {
0149:                 cuentasValidas.add(acc);
0150:             }
0151:         }
0152: 
0153:         return cuentasValidas;
0154:     }   
0155: 
0156:     public static List<Account> validarTareaPorCuenta(List<Account> cuentas, String developerNameCadencia) {
0157:         List<Account> cuentasValidas = new List<Account>();
0158: 
0159:         if (cuentas.isEmpty()) {
0160:             System.debug('No hay cuentas para validar');
0161:             return cuentasValidas;
0162:         }
0163: 
0164:         for (Account acc : cuentas) {
0165:             Boolean agregarCuenta = false;
0166:             if (developerNameCadencia == biometricos) {
0167:                 agregarCuenta = acc.EnrolamientoBiometricos__c == '0' || String.isBlank(acc.EnrolamientoBiometricos__c);
0168:             } else if (developerNameCadencia == bancaElectronica) {
0169:                 agregarCuenta = acc.EnrolamientoActivo__c == '0'|| String.isBlank(acc.EnrolamientoActivo__c);
0170:             } else {
0171:                 agregarCuenta = true;
0172:             }
0173: 
0174:             if (agregarCuenta) {
0175:                 cuentasValidas.add(acc);
0176:             }
0177:         }
0178: 
0179:         return cuentasValidas;
0180:     }
0181: 
0182:     public static List<Account> validarTareaPorContrato(List<Account> cuentas, String developerNameCadencia, List<Contract> contratos) {
0183:         Set<Id> accountContratosValidos = new Set<Id> ();  
0184:         List<Account> cuentasValidas = new List<Account>();
0185: 
0186:         if (contratos.isEmpty()) {
0187:             System.debug('No hay contratos para validar');
0188:             return cuentasValidas;
0189:         }
0190: 
0191:         Set<Id> cuentasConContratos = new Set<Id>();
0192:         for (Contract con : contratos) {
0193:             Boolean agregarCuenta = false;
0194:             if (developerNameCadencia == planeacionFinanciera) {
0195:                 agregarCuenta = !con.PlaneacionFinancieraCompletada__c;
0196:             } else if (developerNameCadencia == propuestaInversion) {
0197:                 agregarCuenta = !con.PropuestaInversionCompletada__c;
0198:             } else {
0199:                 agregarCuenta = true;
0200:             }
0201: 
0202:             if (agregarCuenta) {
0203:                 accountContratosValidos.add(con.AccountId);
0204:             }            
0205:         }
0206: 
0207:         for (Account acc : cuentas) {
0208:             if (accountContratosValidos.contains(acc.Id)) {
0209:                 cuentasValidas.add(acc);
0210:             }
0211:         }
0212: 
0213:         return cuentasValidas;
0214:     }  
0215: 
0216:     public static List<PV_GenerarTareasPeriodicas_Request> generarCadenceItems(Id cadenceId, List<Account> cuentas, Map<Id, Id> mapBankerAccount, String developerNameCadencia) {
0217:         List<PV_GenerarTareasPeriodicas_Request> items = new List<PV_GenerarTareasPeriodicas_Request>();
0218: 
0219:         for (Account acc : cuentas) {
0220:             String userId = mapBankerAccount.get(acc.Id);
0221:             if (userId != null) {
0222:                 items.add(new PV_GenerarTareasPeriodicas_Request(
0223:                     String.valueOf(cadenceId),
0224:                     acc.Id,
0225:                     userId
0226:                 ));
0227:             }
0228:         }
0229:         return items;
0230:     }
0231: 
0232:     public static List<Account> filtrarAccountsConCadencias(List<Account> cuentas, ActionCadence cadence) {
0233:         Set<Id> contactIds = getContactsId(cuentas);
0234:         String developerName = cadence.DeveloperName__c;
0235:         List<ActionCadenceTracker> trackers = PV_GenerarTareasPeriodicasSelector_cls.validateCadenceActive(contactIds,developerName,cadence.TareaUnicaPorCuenta__c);
0236: 
0237:         Set<Id> cuentasCadenceActive = new Set<Id>();
0238:         for (ActionCadenceTracker tracker : trackers) {
0239:             cuentasCadenceActive.add(tracker.TargetId);
0240:         }
0241: 
0242:         return filtrarCuentas(cuentas, cuentasCadenceActive,true);
0243:     }
0244:     
0245:     public static void generarRequestCadence(List<ActionCadence> lstCadence, List<Account> cuentas, Map<Id, Id> mapBankerAccount) {
0246:         try {
0247:             List<PV_GenerarTareasPeriodicas_Request> inputsList = new List<PV_GenerarTareasPeriodicas_Request>();
0248: 
0249:             List<Contract> lstContractClientes = obtenerContratos(cuentas);
0250: 
0251:             for (ActionCadence cadence : lstCadence) {
0252:                 String developerName = cadence.DeveloperName__c;
0253:                 List<Account> cuentasFiltradas = filtrarAccountsConCadencias(cuentas, cadence);
0254:                 List<Account> cuentasValidas = new List<Account>();
0255: 
0256:                 if (cadence.TareaUnicaPorCuenta__c) {
0257:                     System.debug('Validando tareas únicas por cuenta para DeveloperName: ' + developerName);
0258:                     cuentasValidas = validarTareaPorCuenta(cuentasFiltradas, developerName);
0259: 
0260:                 } else if (cadence.TareaUnicaPorContrato__c) {
0261:                     System.debug('Validando tareas únicas por contrato para DeveloperName: ' + developerName);
0262:                     cuentasValidas = validarTareaPorContrato(cuentasFiltradas, developerName, lstContractClientes);
0263: 
0264:                 } else {
0265:                     Integer periodicidad = cadence.Periodicidad__c != null ? cadence.Periodicidad__c.intValue() : 0;
0266:                     System.debug('Validando tareas por periodicidad (' + periodicidad + ') para DeveloperName: ' + developerName);
0267:                     cuentasValidas = obtenerCuentasValidasParaAsignarCadencia(cuentasFiltradas, developerName, periodicidad);
0268:                 }
0269: 
0270:                 System.debug('cuentasValidas.size: ' + cuentasValidas.size() + ' para DeveloperName: ' + developerName);
0271: 
0272:                 if (!cuentasValidas.isEmpty()) {
0273:                     inputsList.addAll(generarCadenceItems(cadence.Id, cuentasValidas, mapBankerAccount, developerName));
0274:                 }
0275:             }
0276: 
0277: 
0278:             if (!inputsList.isEmpty()) {
0279:                 System.debug('inputsList.size: ' + inputsList.size());
0280:                 System.enqueueJob(new PV_EjecutarAsignacionCadencias_Queueable(inputsList,0));                
0281:             }else{
0282:                 System.debug('No hay cadencias para asignar');
0283:             }
0284:         } catch (Exception ex) {
0285:             System.debug('Error: ' + ex.getMessage() + ' - Línea: ' + ex.getLineNumber());
0286:             Map<String, String> mapErrors = new Map<String, String>{
0287:                 'Error' => ex.getMessage(),
0288:                 'Linea' => String.valueOf(ex.getLineNumber())
0289:             };
0290:             saveLogError(mapErrors, 'Error durante Generación de las cadencias', 'ERROR_BATCH_CADENCIAS', '');
0291:         }       
0292:     }
0293: 
0294:     public static List<Contract> obtenerContratos(List<Account> cuentas) {
0295:         Set<Id> accountIds = new Map<Id, Account>(cuentas).keySet(); 
0296:         return PV_GenerarTareasPeriodicasSelector_cls.getContratosNoPropuestaPlaneacion(accountIds);
0297: 
0298:     }
0299: 
0300:     public static Set<Id> getContactsId(List<Account> cuentas) {
0301:         Set<Id> contactIds = new Set<Id>();  
0302:         for (Account acc : cuentas) {
0303:             if (acc.PersonContactId != null) {
0304:                 contactIds.add(acc.PersonContactId);
0305:             }
0306:         } 
0307:         return contactIds;
0308:     }
0309: 
0310:     public static List<Account> filtrarCuentas(List<Account> cuentas, Set<Id> cuentasYaProcesadas, Boolean usarPersonContactId) {
0311:         List<Account> cuentasValidas = new List<Account>();
0312:         for (Account acc : cuentas) {
0313:             Id idEvaluar = usarPersonContactId ? acc.PersonContactId : acc.Id;
0314:             if (idEvaluar != null && !cuentasYaProcesadas.contains(idEvaluar)) {
0315:                 cuentasValidas.add(acc);
0316:             }
0317:         }
0318:         return cuentasValidas;
0319:     }
0320: 
0321:     public static void saveLogError(Map<String, String> mapErrors, String message, String errorCode, String type){
0322:         EventLogger.error(new Map<String, String>{'contextId' => null,
0323:                                                     'type' => '',
0324:                                                     'errorCode' => errorCode,
0325:                                                     'message'   => message,
0326:                                                     'request'   => JSON.serializePretty(mapErrors)});
0327:     }  
0328: 
0329:     public static void saveErrorFlow(List<String> errores){
0330:         if (errores != null && !errores.isEmpty()) {
0331:             Map<String, String> mapErrors = new Map<String, String>();
0332:             Integer intCount = 0;
0333:             for(String error : errores){
0334:                 mapErrors.put('Error ' + intCount, error);
0335:                 intCount++;
0336:             }
0337:             saveLogError(mapErrors, 'Error durante Generación de las cadencias', 'ERROR_BATCH_CADENCIAS', '');
0338:         }
0339:     }
0340: }
```

### classes/PV_GenerarTareasPeriodicasSelector_cls.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Martín Martínez
0004: * Project           :   Post venta
0005: * Clase test		:   
0006: * Description       :   Clase selector que contiene todas las SOQL o DML del batch para crear nuevas tareas por periodicidad.
0007: *--------------------------------------------------------------------------
0008: * No.            Date              Author                Description
0009: * 1.0         19-Jun-2025       Martín Martínez              Creación
0010: *--------------------------------------------------------------------------
0011: *******************************************************************************/
0012: public with sharing class PV_GenerarTareasPeriodicasSelector_cls {
0013: 
0014:     public static final Id idConfigPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ConfiguracionPeriodicidadTareas').getRecordTypeId();
0015: 
0016:     public static String getQueryAccounts(){
0017:         String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Generar_Tareas'].Consulta__c ;
0018:         return consulta;
0019:         
0020:             
0021:     }
0022: 
0023:     /* public static String getQueryAccounts(){
0024:         return 'SELECT Id, Name,' +
0025:                     'FechaUltimoContacto__c, ' +
0026:                     'EnrolamientoBiometricos__c, ' +
0027:                     'EnrolamientoActivo__c, ' +
0028:                     'FichaAfinidadCompletada__c, ' +
0029:                     'PersonContactId, ' +
0030:                     'BanqueroAsignado__r.BusinessUnitMemberId ' +
0031:                 'FROM Account ' +
0032:                 'WHERE CreatedDate = TODAY' +//Id IN (\'001dz0000078XvfAAE\', \'001dz000006wr5JAAQ\', \'001dz000007BDsMAAW\') ';
0033:                 ' AND SaldoIntegral__c != null AND IsPersonAccount = TRUE AND BanqueroAsignado__c != null';
0034:     } */
0035: 
0036:     public static List<ActionCadence> getCadence() {
0037:         return [SELECT Id,
0038:                     Name,
0039:                     Tipo_de_actividad__c,
0040:                     Periodicidad__c,
0041:                     DeveloperName__c,
0042:                     TareaUnicaPorContrato__c, 
0043:                     TareaUnicaPorCuenta__c
0044:                 FROM ActionCadence
0045:                 WHERE State ='Active'];
0046:     }   
0047: 
0048:     public static List<Contract> getContratosClienteNoContactar(Set<Id> accountIds) {
0049:         return [SELECT AccountId, FLAG_MARKETING__c, FLAG_MARKETING_ACTINVER__c, FLAG_EVENTS_INVITATIONS__c
0050:                 FROM Contract
0051:                 WHERE AccountId IN :accountIds
0052:                 AND (FLAG_MARKETING__c != null 
0053:                     AND FLAG_MARKETING_ACTINVER__c != null 
0054:                     AND FLAG_EVENTS_INVITATIONS__c != null)
0055:             ];
0056:     } 
0057: 
0058:     public static List<Banker> getBankerByBusinessMemberId(Set<Id> setBMemberId){
0059:         return [SELECT ID, UserOrContactId, ExternalId__c FROM BANKER WHERE ID IN: setBMemberId];
0060:     }
0061: 
0062:     public static Id getDiasLaborales(){
0063:         return [SELECT Id FROM BusinessHours WHERE Name = 'Postventa'].Id;
0064:     }
0065: 
0066:     public static List<ActionCadenceTracker> validateCadenceActive(Set<Id> accountIds, String developerNameCadencia, Boolean cadenciaUnicaPorCuenta) {
0067:         String baseQuery = 'SELECT ActionCadence.DeveloperName__c, TargetId ' +
0068:                         'FROM ActionCadenceTracker ' +
0069:                         'WHERE ActionCadence.DeveloperName__c = :developerNameCadencia ';
0070: 
0071:         /*Boolean esCadenciaEspecial = 
0072:             developerNameCadencia == PSTA_UtilityClass.DEVELOPERNAME_BIOMETRICOS || 
0073:             developerNameCadencia == PSTA_UtilityClass.DEVELOPERNAME_BANCA_ELECTRONICA;
0074: 
0075:         if (!esCadenciaEspecial || !cadenciaUnicaPorCuenta) {*/
0076:             baseQuery += 'AND State = \'Running\' ';
0077:         //}
0078: 
0079: 
0080:         baseQuery += 'AND TargetId IN :accountIds';
0081: 
0082:         return Database.query(baseQuery);
0083:     }
0084: 
0085:     public static List<Contract> getContratosNoPropuestaPlaneacion(Set<Id> accountIds) {
0086:         return [
0087:             SELECT Id, AccountId, Account.PersonContactId, PlaneacionFinancieraCompletada__c, PropuestaInversionCompletada__c
0088:             FROM Contract
0089:             WHERE AccountId IN :accountIds
0090:             AND (PlaneacionFinancieraCompletada__c = false
0091:             OR PropuestaInversionCompletada__c = false)
0092:         ];
0093:     }
0094: 
0095:     public static List<Task> getTask(Set<Id> accountIds, String developerNameCadencia) {
0096:         Integer mesesFiltro;
0097:         try {
0098:             mesesFiltro = Integer.valueOf(Label.MesesFiltroTareas);
0099:         } catch(Exception e) {
0100:             mesesFiltro = 6;
0101:         }
0102: 
0103:         Date fechaLimite = Date.today().addMonths(-mesesFiltro);
0104:         return [
0105:             SELECT AccountId, CreatedDate, DeveloperName__c
0106:             FROM Task
0107:             WHERE DeveloperName__c = :developerNameCadencia
0108:               AND AccountId IN :accountIds
0109:               AND DeveloperName__c != null
0110:               AND CreatedDate >= :fechaLimite
0111:             ORDER BY AccountId, CreatedDate DESC
0112:         ];
0113:     }
0114: 
0115: }
```

### classes/PV_EjecutarAsignacionCadencias_Queueable.cls
```text
0001: /**
0002:  * @description       : 
0003:  * @author            : Martin Martinez
0004:  * @group             : 
0005:  * @last modified on  : 08-11-2025
0006:  * @last modified by  : Martin Martinez
0007: **/
0008: public class PV_EjecutarAsignacionCadencias_Queueable implements Queueable {
0009: 
0010:     private List<PV_GenerarTareasPeriodicas_Request> fullList;
0011:     private Integer offset;
0012: 
0013:     public PV_EjecutarAsignacionCadencias_Queueable(List<PV_GenerarTareasPeriodicas_Request> fullList, Integer offset) {
0014:         this.fullList = fullList;
0015:         this.offset = offset;
0016:     }
0017: 
0018:     public void execute(QueueableContext context) {
0019:         Integer chunkSize = 200;
0020:         Integer endList = Math.min(offset + chunkSize, fullList.size());
0021: 
0022:         //List<PV_GenerarTareasPeriodicas_Request> subList = fullList.subList(offset, endList);
0023:         List<PV_GenerarTareasPeriodicas_Request> subList = new List<PV_GenerarTareasPeriodicas_Request>();
0024:         for (Integer i = offset; i < endList; i++) {
0025:             subList.add(fullList[i]);
0026:         }
0027: 
0028:         // Ejecuta el flow con el chunk actual
0029:         Flow.Interview.PV_AsignarCadencesCuentas_Flow flow = new Flow.Interview.PV_AsignarCadencesCuentas_Flow(
0030:             new Map<String, Object>{
0031:                 'inputCadenceList' => subList
0032:             }
0033:         );
0034:         flow.start();
0035: 
0036:         // Obtener la variable de errores del flow
0037:         List<String> errores = (List<String>) flow.getVariableValue('ErroresAsignacionCadence');
0038:         PV_GenerarTareasPeriodicas.saveErrorFlow(errores);
0039: 
0040:         // Encola siguiente bloque si hay más registros
0041:         if (endList < fullList.size()) {
0042:             System.enqueueJob(new PV_EjecutarAsignacionCadencias_Queueable(fullList, endList));
0043:         }
0044:     }
0045: }
```

### classes/PV_GenerarTareasPeriodicas_Request.cls
```text
0001: /**
0002:  * @description       : 
0003:  * @author            : Martin Martinez
0004:  * @group             : 
0005:  * @last modified on  : 07-16-2025
0006:  * @last modified by  : Martin Martinez
0007: **/
0008: public class PV_GenerarTareasPeriodicas_Request{
0009: 
0010:     @AuraEnabled @InvocableVariable(required=true)
0011:     public String salesCadenceNameOrId;
0012: 
0013:     @AuraEnabled @InvocableVariable(required=true)
0014:     public String targetId;
0015: 
0016:     @AuraEnabled @InvocableVariable
0017:     public String userId;
0018:     
0019:     public PV_GenerarTareasPeriodicas_Request(String cadence, String target, String user) {
0020:         this.salesCadenceNameOrId = cadence;
0021:         this.targetId = target;
0022:         this.userId = user;
0023:     }
0024: }
```

### flows/PV_AsignarCadencesCuentas_Flow.flow-meta.xml
```text
0001: <?xml version="1.0" encoding="UTF-8"?>
0002: <Flow xmlns="http://soap.sforce.com/2006/04/metadata">
0003:     <actionCalls>
0004:         <name>Asignar_cadencia</name>
0005:         <label>Asignar cadencia</label>
0006:         <locationX>0</locationX>
0007:         <locationY>0</locationY>
0008:         <actionName>assignTargetToSalesCadence</actionName>
0009:         <actionType>assignTargetToSalesCadence</actionType>
0010:         <connector>
0011:             <targetReference>Recorrer_las_cadencias</targetReference>
0012:         </connector>
0013:         <faultConnector>
0014:             <targetReference>Almacenar_error</targetReference>
0015:         </faultConnector>
0016:         <flowTransactionModel>CurrentTransaction</flowTransactionModel>
0017:         <inputParameters>
0018:             <name>salesCadenceNameOrId</name>
0019:             <value>
0020:                 <elementReference>Recorrer_las_cadencias.salesCadenceNameOrId</elementReference>
0021:             </value>
0022:         </inputParameters>
0023:         <inputParameters>
0024:             <name>targetId</name>
0025:             <value>
0026:                 <elementReference>Recorrer_las_cadencias.targetId</elementReference>
0027:             </value>
0028:         </inputParameters>
0029:         <inputParameters>
0030:             <name>userId</name>
0031:             <value>
0032:                 <elementReference>Recorrer_las_cadencias.userId</elementReference>
0033:             </value>
0034:         </inputParameters>
0035:         <nameSegment>assignTargetToSalesCadence</nameSegment>
0036:         <offset>0</offset>
0037:         <storeOutputAutomatically>true</storeOutputAutomatically>
0038:     </actionCalls>
0039:     <apiVersion>64.0</apiVersion>
0040:     <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>
0041:     <assignments>
0042:         <name>Almacenar_error</name>
0043:         <label>Almacenar error</label>
0044:         <locationX>0</locationX>
0045:         <locationY>0</locationY>
0046:         <assignmentItems>
0047:             <assignToReference>ErroresAsignacionCadence</assignToReference>
0048:             <operator>Add</operator>
0049:             <value>
0050:                 <elementReference>ErrorCadencia</elementReference>
0051:             </value>
0052:         </assignmentItems>
0053:         <connector>
0054:             <isGoTo>true</isGoTo>
0055:             <targetReference>Recorrer_las_cadencias</targetReference>
0056:         </connector>
0057:     </assignments>
0058:     <environments>Default</environments>
0059:     <formulas>
0060:         <name>ErrorCadencia</name>
0061:         <dataType>String</dataType>
0062:         <expression>&quot;Target: &quot; &amp; {!Recorrer_las_cadencias.targetId} &amp; &quot; - Error: &quot; &amp; {!$Flow.FaultMessage}</expression>
0063:     </formulas>
0064:     <interviewLabel>PV_AsignarCadencesCuentas_Flow {!$Flow.CurrentDateTime}</interviewLabel>
0065:     <label>PV_AsignarCadencesCuentas_Flow</label>
0066:     <loops>
0067:         <name>Recorrer_las_cadencias</name>
0068:         <label>Recorrer las cadencias</label>
0069:         <locationX>0</locationX>
0070:         <locationY>0</locationY>
0071:         <collectionReference>inputCadenceList</collectionReference>
0072:         <iterationOrder>Asc</iterationOrder>
0073:         <nextValueConnector>
0074:             <targetReference>Asignar_cadencia</targetReference>
0075:         </nextValueConnector>
0076:     </loops>
0077:     <processMetadataValues>
0078:         <name>BuilderType</name>
0079:         <value>
0080:             <stringValue>LightningFlowBuilder</stringValue>
0081:         </value>
0082:     </processMetadataValues>
0083:     <processMetadataValues>
0084:         <name>CanvasMode</name>
0085:         <value>
0086:             <stringValue>AUTO_LAYOUT_CANVAS</stringValue>
0087:         </value>
0088:     </processMetadataValues>
0089:     <processMetadataValues>
0090:         <name>OriginBuilderType</name>
0091:         <value>
0092:             <stringValue>LightningFlowBuilder</stringValue>
0093:         </value>
0094:     </processMetadataValues>
0095:     <processType>AutoLaunchedFlow</processType>
0096:     <start>
0097:         <locationX>0</locationX>
0098:         <locationY>0</locationY>
0099:         <connector>
0100:             <targetReference>Recorrer_las_cadencias</targetReference>
0101:         </connector>
0102:     </start>
0103:     <status>Active</status>
0104:     <variables>
0105:         <name>ErroresAsignacionCadence</name>
0106:         <dataType>String</dataType>
0107:         <isCollection>true</isCollection>
0108:         <isInput>false</isInput>
0109:         <isOutput>true</isOutput>
0110:     </variables>
0111:     <variables>
0112:         <name>inputCadenceList</name>
0113:         <apexClass>PV_GenerarTareasPeriodicas_Request</apexClass>
0114:         <dataType>Apex</dataType>
0115:         <isCollection>true</isCollection>
0116:         <isInput>true</isInput>
0117:         <isOutput>false</isOutput>
0118:     </variables>
0119: </Flow>
```

### triggers/TriggerActionCadanceStepTracker.trigger
```text
0001: /***************************************************************************************
0002: Desarrollado por:        VASS México
0003: Autor:                   Salvador Ramirez Lopez 
0004: Proyecto:                Actinver Postventa
0005: Descripción:             Clase TriggerActionCadanceStepTracker
0006: ------------------------------------------------------------------------------------------
0007: No.        Fecha               Autor                           Descripción
0008: ------  ----------  -----------------------------    -------------------------------------
0009: 1.0     19-06-2025      Salvador Ramirez Lopez                  Creación
0010: *******************************************************************************************/
0011: trigger TriggerActionCadanceStepTracker on ActionCadenceStepTrackerChangeEvent (after insert) {
0012:     Trigger_Management__mdt  triggerIsActive = Trigger_Management__mdt.getInstance(System.label.CadenceStepTracker);
0013:     if (triggerIsActive != null && triggerIsActive.IsActive__c){
0014:         if(Trigger.isInsert && Trigger.isAfter) TriggerActionCadenceStepTracker_thr.onAfterInsert(Trigger.new);
0015:     }
0016: }
```

### classes/TriggerActionCadenceStepTracker_thr.cls
```text
0001: /***************************************************************************************
0002: Desarrollado por:        VASS México
0003: Autor:                   Salvador Ramirez Lopez 
0004: Proyecto:                Actinver Postventa
0005: Descripción:             Clase TriggerActionCadenceStepTracker_thr
0006: ------------------------------------------------------------------------------------------
0007: No.        Fecha               Autor                           Descripción
0008: ------  ----------  -----------------------------    -------------------------------------
0009: 1.0     19-06-2025      Salvador Ramirez Lopez                  Creación
0010: *******************************************************************************************/
0011: public class TriggerActionCadenceStepTracker_thr {
0012:     public static void onAfterInsert(List<ActionCadenceStepTrackerChangeEvent> lstNewRecords){
0013:         PSTA_GestionTareas_Helper.createTaskWithCloseCadence(lstNewRecords);
0014:     }
0015: }
```

### classes/PSTA_GestionTareas_Helper.cls
```text
0001: /***************************************************************************************
0002: Desarrollado por:        VASS México
0003: Autor:                   Salvador Ramirez Lopez 
0004: Proyecto:                Actinver Postventa
0005: Descripción:             Clase PSTA_GestionTareas_Helper
0006: ------------------------------------------------------------------------------------------
0007: No.        Fecha               Autor                           Descripción
0008: ------  ----------  -----------------------------    -------------------------------------
0009: 1.0     19-06-2025      Salvador Ramirez Lopez                  Creación
0010: 1.1     11-08-2025      Salvador Ramírez López                  Modificación para hacer un update sobre la tarea generada desde la cadencia y no generar nuevas tareas.
0011: *******************************************************************************************/
0012: public class PSTA_GestionTareas_Helper {
0013:     public static Boolean bypassTriggerExecution = false;
0014:     public static void createTaskWithCloseCadence(List<ActionCadenceStepTrackerChangeEvent> lstStepTracker){
0015:         if (bypassTriggerExecution) return; List<String> recordIds = new List<String>();
0016:         for(ActionCadenceStepTrackerChangeEvent event : lstStepTracker){ EventBus.ChangeEventHeader header = event.ChangeEventHeader; recordIds.addAll(header.getRecordIds());
0017:         }
0018:         List<ActionCadenceStepTracker> stepTrackers = PSTA_GestionTareas_soql.getStepTrackers(recordIds); if(stepTrackers.size() > 0 && stepTrackers != null) createTasks(stepTrackers);
0019:     }
0020:     public static List<Task> updateTasksCadence( List<ActionCadenceStepTracker> stepTrackers){
0021:         Map<Id,ActionCadenceStepTracker> mapActionCadence = new Map<Id,ActionCadenceStepTracker>();
0022:         for(ActionCadenceStepTracker objActionCadenceStepTracker :stepTrackers) mapActionCadence.put(objActionCadenceStepTracker.Id,objActionCadenceStepTracker);
0023:         Task[] tasks = PSTA_GestionTareas_soql.getTaskUsingIdsTracker(mapActionCadence.keySet());
0024:         for(Task objTask : tasks){
0025:             ActionCadenceStepTracker stepTracker = mapActionCadence.get(objTask.ActionCadenceStepTrackerId); objTask.Subject = stepTracker.ActionCadenceName; objTask.Status = 'Completado'; objTask.Type = stepTracker.ActionCadence.Tipo_de_actividad__c;
0026:             objTask.DeveloperName__c = stepTracker.ActionCadence.DeveloperName__c; objTask.Description = 'Contacto efectivo ' + stepTracker.ActionCadence.Name + ' ' + objTask.Account.Client_ID__c + ' ' + objTask.Account.Name;
0027:             objTask.PV_ExternalID__c = createExternalIdTask(stepTracker.ActionCadence.DeveloperName__c, objTask.Account.Client_ID__c, objTask.Account.ID_Asesor__c); objTask.RecordTypeId = ACTINVER_UtilityFactory_utils.getRecodType('Task', 'Postventa');
0028: 
0029:         }
0030:         return tasks;
0031:     }
0032:     public static void createTasks(List<ActionCadenceStepTracker> stepTrackers){
0033:         Set<Id> setContactId = generateSetIdContact(stepTrackers);
0034:         Map<String, Object> mapReferences = createMapsToReference(setContactId);
0035:         Map<Id, Banker> mapBankerAccount = getMapBankerAccount((Set<Id>)mapReferences.get('setBMemberId'), (Map<Id, Contact>)mapReferences.get('mapContact'));
0036:         List<Task> lstTareas = updateTasksCadence(stepTrackers);
0037:         if(lstTareas.size() > 0) update lstTareas;
0038:         publishEvent(lstTareas, (Map<Id, Contact>)mapReferences.get('mapAccountByContact'));
0039:     }
0040:     public static Map<Id, Banker> getMapBankerAccount(Set<Id> setBMemberId, Map<Id, Contact> mapContact){
0041:         Map<Id, Banker> mapBankerAccount = new Map<Id, Banker>();
0042:         if(!Test.isRunningTest()){for(Banker bank : PSTA_GestionTareas_soql.getBankerByBusinessMemberId(setBMemberId)){if(mapContact.containsKey(bank.Id)) if(!mapBankerAccount.containsKey(mapContact.get(bank.Id).Id)) mapBankerAccount.put(mapContact.get(bank.Id).Id, bank);
0043:             }   
0044:         }
0045:         return mapBankerAccount;
0046:     }
0047:     public static Set<Id> generateSetIdContact(List<ActionCadenceStepTracker> stepTrackers){
0048:         Set<Id> setContactId = new Set<Id>();
0049:         for(ActionCadenceStepTracker stepTracker : stepTrackers) setContactId.add(stepTracker.TargetId);
0050:         return setContactId;
0051:     }
0052:     public static Map<String, Object> createMapsToReference(Set<Id> setContactId){
0053:         Map<Id, Contact> mapContact = new Map<Id, Contact>();
0054:         Map<Id, Contact> mapAccountByContact = new Map<Id, Contact>();
0055:         Set<Id> setBMemberId = new Set<Id>();
0056:         Map<String, Object> mapResult = new Map<String, Object>();
0057:         for(Contact con : PSTA_GestionTareas_soql.getAccountsByContactIds(setContactId)){setBMemberId.add(con.Account.BanqueroAsignado__r.BusinessUnitMemberId);if(!mapContact.containsKey(con.Account.BanqueroAsignado__r.BusinessUnitMemberId)) mapContact.put(con.Account.BanqueroAsignado__r.BusinessUnitMemberId, con);if(!mapAccountByContact.containsKey(con.Id)) mapAccountByContact.put(con.Id, con);
0058:         }
0059:         mapResult.put('mapContact', mapContact);
0060:         mapResult.put('setBMemberId', setBMemberId);
0061:         mapResult.put('mapAccountByContact', mapAccountByContact);
0062:         return mapResult;
0063:     }
0064:     public static String createExternalIdTask(String strTarea, String ClientBP, String ExternalIdBanquero){ return strTarea + '-' + ClientBP + '-' + ExternalIdBanquero + '-' + ACTINVER_UtilityFactory_utils.formatDate(System.today(), false);
0065:     }
0066:     public static void publishEvent(List<Task> lstTask, Map<Id, Contact> mapAccountByContact){
0067:         List<PV_FinalizacionCadencia__e> lstEvent = new List<PV_FinalizacionCadencia__e>();
0068:         for(Task objTask : lstTask){PV_FinalizacionCadencia__e event = new PV_FinalizacionCadencia__e(); event.TaskId__c = objTask.Id; event.AccountId__c = mapAccountByContact.get(objTask.WhoId).Account.Id;event.UserId__c = objTask.OwnerId;lstEvent.add(event);
0069:         }
0070:         List<Database.SaveResult> results = EventBus.publish(lstEvent);
0071:         System.debug('Resultado publish: ' + results);
0072:     }
0073: }
```

### classes/PSTA_GestionTareas_soql.cls
```text
0001: /***************************************************************************************
0002: Desarrollado por:        VASS México
0003: Autor:                   Salvador Ramirez Lopez 
0004: Proyecto:                Actinver Postventa
0005: Descripción:             Clase PSTA_GestionTareas_soql
0006: ------------------------------------------------------------------------------------------
0007: No.        Fecha               Autor                           Descripción
0008: ------  ----------  -----------------------------    -------------------------------------
0009: 1.0     16-06-2025      Salvador Ramirez Lopez                  Creación
0010: *******************************************************************************************/
0011: public  class PSTA_GestionTareas_soql {
0012:     public static List<ActionCadenceStepTracker> getStepTrackers(List<String> recordIds){
0013:         return [SELECT  Id,
0014:                         ActionCadenceStepId,
0015:                         ActionCadenceName,
0016:                         TargetId,
0017:                         StepType,
0018:                         StepTitle,
0019:                         ActionCadence.Tipo_de_actividad__c,
0020:                         ActionCadence.DeveloperName__c,
0021:                         ActionCadence.Name
0022:                 FROM ActionCadenceStepTracker
0023:                 WHERE Id IN :recordIds AND State = 'Completed'  AND ActionCadenceTracker.State = 'Complete'];
0024:     }
0025:     public static List<Contact> getAccountsByContactIds(Set<Id> setContactId){
0026:         return [SELECT ID, AccountId, Account.BanqueroAsignado__r.BusinessUnitMemberId, Account.Client_ID__c, Account.Name
0027:                 FROM CONTACT WHERE Id IN :setContactId AND AccountId != NULL];
0028:     }
0029:     public static List<Banker> getBankerByBusinessMemberId(Set<Id> setBMemberId){
0030:         return [SELECT ID, UserOrContactId, ExternalId__c FROM BANKER WHERE ID IN: setBMemberId];
0031:     }
0032:     public static List<Task> getTaskUsingIdsTracker(Set<Id> setTrackersId){
0033:         return [SELECT Id,ActionCadenceStepTrackerId,Account.Client_ID__c,Account.Name, Account.ID_Asesor__c, WhoId, OwnerId FROM Task WHERE ActionCadenceStepTrackerId IN :setTrackersId];
0034:     }
0035: }
```

### triggers/Task_trg.trigger
```text
0001: /**
0002:  * @description       : 
0003:  * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
0004:  * @group             : 
0005:  * @last modified on  : 06-25-2025
0006:  * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
0007: **/
0008: trigger Task_trg on Task (after update) {
0009:     System.debug('*******Va a iniciar trigger');
0010:     Trigger_Management__mdt  triggerIsActive = Trigger_Management__mdt.getInstance(System.label.TaskTrigger);
0011:     if(triggerIsActive != null && triggerIsActive.IsActive__c){
0012:         System.debug('******Trigger activo, inicia');
0013:         if(Trigger.isUpdate && Trigger.isAfter){
0014:             Task_thr.onAfterUpdate(Trigger.new, Trigger.oldMap);
0015:         }
0016:     }
0017: }
```

### classes/Task_thr.cls
```text
0001: /***************************************************************************************
0002: Desarrollado por:        VASS México
0003: Autor:                   Salvador Ramirez Lopez 
0004: Proyecto:                Actinver Postventa
0005: Descripción:             Clase Task_thr
0006: ------------------------------------------------------------------------------------------
0007: No.        Fecha               Autor                           Descripción
0008: ------  ----------  -----------------------------    -------------------------------------
0009: 1.0     18-06-2025      Salvador Ramirez Lopez                  Creación
0010: *******************************************************************************************/
0011: public class Task_thr {
0012:     public static void onAfterUpdate(List<Task> newListTask, Map<Id, Task> mapOldTask){
0013:         PSTA_ChangeAccountInfo_ctr.changeContactAndDateStatus(newListTask, mapOldTask);
0014:         Task_Helper.publishEventToComponent(newListTask, mapOldTask);
0015:     }
0016: }
```

### classes/PSTA_ChangeAccountInfo_ctr.cls
```text
0001: /***************************************************************************************
0002: Desarrollado por:        VASS México
0003: Autor:                   Salvador Ramirez Lopez 
0004: Proyecto:                Actinver Postventa
0005: Descripción:             Clase PSTA_ChangeAccountInfo_ctr
0006: ------------------------------------------------------------------------------------------
0007: No.        Fecha               Autor                           Descripción
0008: ------  ----------  -----------------------------    -------------------------------------
0009: 1.0     16-06-2025      Salvador Ramirez Lopez                  Creación
0010: *******************************************************************************************/
0011: public with sharing class PSTA_ChangeAccountInfo_ctr {
0012:     public static boolean byPassTriggerExecution = false;
0013:     public static void changeContactAndDateStatus(List<Task> lstTask, Map<Id, Task> mapOldTask){
0014:         if (bypassTriggerExecution) return;
0015:         PSTA_ChangeAccountInfo_helper.initProcessChangeStatusAccount(lstTask, mapOldTask);
0016:     }
0017: }
```

### classes/PSTA_ChangeAccountInfo_helper.cls
```text
0001: /***************************************************************************************
0002: Desarrollado por:        VASS México
0003: Autor:                   Salvador Ramirez Lopez 
0004: Proyecto:                Actinver Postventa
0005: Descripción:             Clase PSTA_ChangeAccountInfo_helper
0006: ------------------------------------------------------------------------------------------
0007: No.        Fecha               Autor                      Descripción
0008: ------  ----------  -----------------------------    -------------------------------------
0009: 1.0     16-06-2025      Salvador Ramirez Lopez        Clase PSTA_ChangeAccountInfo_helper
0010: *******************************************************************************************/
0011: public class PSTA_ChangeAccountInfo_helper {
0012:     public static void initProcessChangeStatusAccount(List<Task> lstTask, Map<Id, Task> mapOldTask){
0013:         System.debug('**********function initPracess');
0014:         Map<String, Object> mapSets = generateSets(lstTask);
0015:         Set<Id> setIdAcc = (Set<Id>) mapSets.get('setIdAcc');
0016:         Set<String> setDevName = (Set<String>) mapSets.get('setDevName');
0017:         Map<Id, Account> mapAccount = new Map<Id, Account>(PSTA_ChangeAccountInfo_soql.getAccountsInfo(setIdAcc));
0018:         Map<String, ActionCadence> mapConfig = createMapWithConfigs(PSTA_ChangeAccountInfo_soql.lstConfigByCadences(setDevName));
0019:         TaskReview(lstTask, mapOldTask, mapAccount, mapConfig);
0020:     }
0021:     public static Map<String, Object> changeContacAndDatetStatus(Task objTask, Task objOldTask, ActionCadence objConfig, Account objAcc){
0022:         System.debug('**************** changeContactAndDateStatus');
0023:         Map<String, Object> mapResult = new Map<String, Object>();
0024:         try{
0025:             if( objTask.El_cliente_fue_contactado__c != null && objTask.El_cliente_fue_contactado__c != objOldTask.El_cliente_fue_contactado__c && objTask.Status == 'Completado' && (objConfig != null && objConfig.GeneraContacto__c) || (objTask.WhatId != null && String.valueOf(objTask.WhatId).startsWith('006'))){
0026:                 System.debug('Entró');
0027:                 if(objConfig != null && objConfig.RequiereCargaEvidencia__c && objTask.RefenciaOpenText__c == null){
0028:                     objTask.addError('No es posible cambiar el estatus de contacto a cliente ya que no se ha cargado evidencia.');
0029:                 } else {
0030:                     objAcc.FechaUltimoContacto__c = System.today();
0031:                     if(objTask.ClienteNoQuiereSerContactado__c){
0032:                         objAcc.FechaNoRequiereSerContacto__c = System.today();
0033:                         objAcc.EstatusContacto__c = 'Cliente no quiere ser contactado';
0034:                     } else {
0035:                         objAcc.EstatusContacto__c = objTask.El_cliente_fue_contactado__c == 'Si' ? 'Contacto efectivo exitoso' : 'Contacto no exitoso';
0036:                     }
0037:                     mapResult.put('Account', objAcc);
0038:                 }
0039:             }
0040:             /*if(objTask.ClienteNoQuiereSerContactado__c && objTask.ClienteNoQuiereSerContactado__c != objOldTask.ClienteNoQuiereSerContactado__c){
0041:                 publicarEvento(objTask.Id, System.UserInfo.getUserId());
0042:             }*/
0043:         } catch(Exception e){
0044:             System.debug('Error al actualizar cuenta desde trigger: ' + e.getMessage() + '. Línea: ' + e.getLineNumber());
0045:             mapResult.put('Error', 'Error al actualizar la cuenta: ' + e.getMessage());
0046:         }
0047:         return mapResult;
0048:     }
0049:     public static void taskReview(List<Task> lstTask, Map<Id, Task> mapOldTask, Map<Id, Account> mapAccount, Map<String, ActionCadence> mapConfig){
0050:         System.debug('********* funcion taskreview');
0051:         List<Account> lstAccToUpdate = new List<Account>();
0052:         Set<Id> setTaskUpdate = new Set<Id>();
0053:         Set<Id> setIdTasksWithErrors = new Set<Id>();
0054:         Map<Id, Id> mapTaskByAccount = new Map<Id, Id>();
0055:         try{
0056:             System.debug('********* Lista de tareas: ' + lstTask.size());
0057:             for(Task objTask : lstTask){
0058:                 System.debug('********* Entra a la lista de tareas');
0059:                 System.debug('********* Objeto tarea: ' + objTask);
0060:                 if(objTask.AccountId != null && mapAccount.containsKey(objTask.AccountId)){
0061:                     System.debug('******* Mapa de configuración: ' + mapConfig);
0062:                     Map<String, Object> mapResult = changeContacAndDatetStatus(objTask, mapOldTask.get(objTask.Id), mapConfig.get(objTask.DeveloperName__c), mapAccount.get(objTask.AccountId));
0063:                     if(mapResult.containsKey('Account')){
0064:                         Account objAcc = (Account)mapResult.get('Account');
0065:                         lstAccToUpdate.add(objAcc);
0066:                         if(!mapTaskByAccount.containsKey(objAcc.Id)) mapTaskByAccount.put(objAcc.Id, objTask.Id);
0067:                     } else {
0068:                         if(mapResult.containsKey('Error')) objTask.addError((String)mapResult.get('Error'));
0069:                     }
0070:                 }
0071:             }
0072:             System.debug('********* Finaliza recorrido de tareas');
0073:             Map<String, Object> mapResult = updateAccountAndGetTasks(lstAccToUpdate, mapTaskByAccount);
0074:             setTaskUpdate = (Set<Id>) mapResult.get('success');
0075:             setIdTasksWithErrors = (Set<Id>) mapResult.get('Errors');
0076:             Map<Id, String> mapErrors = (Map<Id, String>) mapResult.get('ErrorMsgs');
0077:             if(setIdTasksWithErrors.size() > 0){
0078:                 for(Task objTask : lstTask){
0079:                     if(setIdTasksWithErrors.contains(objTask.Id)) objTask.addError('Error al actualizar la información del cliente: ' + mapErrors.get(objTask.Id));
0080:                 }
0081:             }
0082:             if(setTaskUpdate.size() > 0) PSTA_EnvioEncuestaMedallia_cls.sendSurvey(setTaskUpdate);
0083:         } catch (Exception e){
0084:             System.debug('************ Error al actualizar en taskreview: ' + e.getMessage() + '. Línea: ' + e.getLineNumber());
0085:         }
0086:     }
0087:     public static Map<String, Object> generateSets(List<Task> lstTask){
0088:         Set<Id> setIdAcc = new Set<Id>();
0089:         Set<String> setDevName = new Set<String>();
0090:         for(Task objTask : lstTask){
0091:             if(objTask.AccountId != null) setIdAcc.add(objTask.AccountId);
0092:             if(objTask.DeveloperName__c != null) setDevName.add(objTask.DeveloperName__c);
0093:         }
0094:         return new Map<String, Object>{'setIdAcc' => setIdAcc, 'setDevName' => setDevName};
0095:     }
0096:     public static Map<String, Object> updateAccountAndGetTasks(List<Account> lstAccToUpdate, Map<Id, Id> mapTaskByAccount){
0097:         OD_Account_cls.bypassTriggerExecution = true;
0098:         Set<Id> setIdTasks = new Set<Id>();
0099:         Set<Id> setIdTasksWithErrors = new Set<Id>();
0100:         String strError = '';
0101:         Map<String, Object> mapResult = new Map<String, Object>();
0102:         Map<Id, String> mapErrors = new Map<Id, String>();
0103:         List<Database.SaveResult> saveResult = Database.update(lstAccToUpdate, false);
0104:         for(Database.SaveResult result : saveResult){
0105:             if(result.isSuccess()) setIdTasks.add(mapTaskByAccount.get(result.getId())); else {
0106:                 for(Database.Error error : result.getErrors()){
0107:                     strError += error.getMessage() + '; ';
0108:                     setIdTasksWithErrors.add(mapTaskByAccount.get(result.getId()));
0109:                 }
0110:                 if(!mapErrors.containsKey(mapTaskByAccount.get(result.getId()))) mapErrors.put(mapTaskByAccount.get(result.getId()), strError);
0111:             }
0112:         }
0113:         mapResult.put('Errors', setIdTasksWithErrors);
0114:         mapResult.put('success', setIdTasks);
0115:         mapResult.put('ErrorMsgs', mapErrors);
0116:         return mapResult;
0117:     }
0118:     public static Map<String, ActionCadence> createMapWithConfigs(List<ActionCadence> lstConfig){
0119:         Map<String, ActionCadence> mapConfig = new Map<String, ActionCadence>();
0120:         for(ActionCadence objConfig : lstConfig){
0121:             mapConfig.put(objConfig.DeveloperName__c, objConfig);
0122:         }
0123:         return mapConfig;
0124:     }
0125:     public static void publicarEvento(Id idTask, Id idUser){
0126:         EventoComponente__e event = new EventoComponente__e(TaskId__c = idTask, UserId__c = idUser);
0127:         Database.SaveResult sr = EventBus.publish(event);
0128:         System.debug('*******Resultado de publicación: ' + sr.isSuccess());
0129:     }
0130: }
```

### classes/PSTA_ChangeAccountInfo_soql.cls
```text
0001: /***************************************************************************************
0002: Desarrollado por:        VASS México
0003: Autor:                   Salvador Ramirez Lopez 
0004: Proyecto:                Actinver Postventa
0005: Descripción:             Clase PSTA_ChangeAccountInfo_soql
0006: ------------------------------------------------------------------------------------------
0007: No.        Fecha               Autor                            Descripción
0008: ------  ----------  -----------------------------    -------------------------------------
0009: 1.0     18-06-2025      Salvador Ramirez Lopez                   Creación
0010: *******************************************************************************************/
0011: public class PSTA_ChangeAccountInfo_soql {
0012:     public static List<Account> getAccountsInfo(Set<Id> setIdAcc){
0013:         return [SELECT Id, EstatusContacto__c, FechaUltimoContacto__c FROM Account WHERE Id IN :setIdAcc];
0014:     }
0015:     public static List<ActionCadence> lstConfigByCadences(Set<String> setTaskDevName){
0016:         return [SELECT DeveloperName__c, GeneraContacto__c, RequiereCargaEvidencia__c FROM ACTIONCADENCE WHERE DeveloperName__c IN :setTaskDevName];
0017:     }
0018: }
```

### flows/Flow_Avance_FAC.flow-meta.xml
```text
0001: ﻿<?xml version="1.0" encoding="UTF-8"?>
0002: <Flow xmlns="http://soap.sforce.com/2006/04/metadata">
0003:     <apiVersion>66.0</apiVersion>
0004:     <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>
0005:     <assignments>
0006:         <name>Aplicables</name>
0007:         <label>Aplicables</label>
0008:         <locationX>0</locationX>
0009:         <locationY>0</locationY>
0010:         <assignmentItems>
0011:             <assignToReference>vAplicables</assignToReference>
0012:             <operator>Assign</operator>
0013:             <value>
0014:                 <numberValue>0.0</numberValue>
0015:             </value>
0016:         </assignmentItems>
0017:         <assignmentItems>
0018:             <assignToReference>vLlenos</assignToReference>
0019:             <operator>Assign</operator>
0020:             <value>
0021:                 <numberValue>0.0</numberValue>
0022:             </value>
0023:         </assignmentItems>
0024:         <assignmentItems>
0025:             <assignToReference>vAplicables</assignToReference>
0026:             <operator>Add</operator>
0027:             <value>
0028:                 <numberValue>16.0</numberValue>
0029:             </value>
0030:         </assignmentItems>
0031:         <connector>
0032:             <targetReference>BaseSum</targetReference>
0033:         </connector>
0034:     </assignments>
0035:     <assignments>
0036:         <name>BaseSum</name>
0037:         <label>BaseSum</label>
0038:         <locationX>0</locationX>
0039:         <locationY>0</locationY>
0040:         <assignmentItems>
0041:             <assignToReference>vLlenos</assignToReference>
0042:             <operator>Add</operator>
0043:             <value>
0044:                 <elementReference>f_Pasatiempo</elementReference>
0045:             </value>
0046:         </assignmentItems>
0047:         <assignmentItems>
0048:             <assignToReference>vLlenos</assignToReference>
0049:             <operator>Add</operator>
0050:             <value>
0051:                 <elementReference>f_Viajas</elementReference>
0052:             </value>
0053:         </assignmentItems>
0054:         <assignmentItems>
0055:             <assignToReference>vLlenos</assignToReference>
0056:             <operator>Add</operator>
0057:             <value>
0058:                 <elementReference>f_Frecuencia</elementReference>
0059:             </value>
0060:         </assignmentItems>
0061:         <assignmentItems>
0062:             <assignToReference>vLlenos</assignToReference>
0063:             <operator>Add</operator>
0064:             <value>
0065:                 <elementReference>f_Hijos</elementReference>
0066:             </value>
0067:         </assignmentItems>
0068:         <assignmentItems>
0069:             <assignToReference>vLlenos</assignToReference>
0070:             <operator>Add</operator>
0071:             <value>
0072:                 <elementReference>f_EstudiaFuera</elementReference>
0073:             </value>
0074:         </assignmentItems>
0075:         <assignmentItems>
0076:             <assignToReference>vLlenos</assignToReference>
0077:             <operator>Add</operator>
0078:             <value>
0079:                 <elementReference>f_Institucion</elementReference>
0080:             </value>
0081:         </assignmentItems>
0082:         <assignmentItems>
0083:             <assignToReference>vLlenos</assignToReference>
0084:             <operator>Add</operator>
0085:             <value>
0086:                 <elementReference>f_Porque</elementReference>
0087:             </value>
0088:         </assignmentItems>
0089:         <assignmentItems>
0090:             <assignToReference>vLlenos</assignToReference>
0091:             <operator>Add</operator>
0092:             <value>
0093:                 <elementReference>f_OtrosProd</elementReference>
0094:             </value>
0095:         </assignmentItems>
0096:         <assignmentItems>
0097:             <assignToReference>vLlenos</assignToReference>
0098:             <operator>Add</operator>
0099:             <value>
0100:                 <elementReference>f_TipoSeguros</elementReference>
0101:             </value>
0102:         </assignmentItems>
0103:         <assignmentItems>
0104:             <assignToReference>vLlenos</assignToReference>
0105:             <operator>Add</operator>
0106:             <value>
0107:                 <elementReference>f_MedioPreferido</elementReference>
0108:             </value>
0109:         </assignmentItems>
0110:         <assignmentItems>
0111:             <assignToReference>vLlenos</assignToReference>
0112:             <operator>Add</operator>
0113:             <value>
0114:                 <elementReference>f_Influye</elementReference>
0115:             </value>
0116:         </assignmentItems>
0117:         <assignmentItems>
0118:             <assignToReference>vLlenos</assignToReference>
0119:             <operator>Add</operator>
0120:             <value>
0121:                 <elementReference>f_Ingreso</elementReference>
0122:             </value>
0123:         </assignmentItems>
0124:         <assignmentItems>
0125:             <assignToReference>vLlenos</assignToReference>
0126:             <operator>Add</operator>
0127:             <value>
0128:                 <elementReference>f_Gastos</elementReference>
0129:             </value>
0130:         </assignmentItems>
0131:         <assignmentItems>
0132:             <assignToReference>vLlenos</assignToReference>
0133:             <operator>Add</operator>
0134:             <value>
0135:                 <elementReference>f_PatrimonioAct</elementReference>
0136:             </value>
0137:         </assignmentItems>
0138:         <assignmentItems>
0139:             <assignToReference>vLlenos</assignToReference>
0140:             <operator>Add</operator>
0141:             <value>
0142:                 <elementReference>f_PrincipalAct</elementReference>
0143:             </value>
0144:         </assignmentItems>
0145:         <assignmentItems>
0146:             <assignToReference>vLlenos</assignToReference>
0147:             <operator>Add</operator>
0148:             <value>
0149:                 <elementReference>f_MesPreferente</elementReference>
0150:             </value>
0151:         </assignmentItems>
0152:         <connector>
0153:             <targetReference>SetResults</targetReference>
0154:         </connector>
0155:     </assignments>
0156:     <assignments>
0157:         <name>SetResults</name>
0158:         <label>SetResults</label>
0159:         <locationX>0</locationX>
0160:         <locationY>0</locationY>
0161:         <assignmentItems>
0162:             <assignToReference>$Record.AvanceNum1FAC__c</assignToReference>
0163:             <operator>Assign</operator>
0164:             <value>
0165:                 <elementReference>vAplicables</elementReference>
0166:             </value>
0167:         </assignmentItems>
0168:         <assignmentItems>
0169:             <assignToReference>$Record.AvanceNum2FAC__c</assignToReference>
0170:             <operator>Assign</operator>
0171:             <value>
0172:                 <elementReference>vLlenos</elementReference>
0173:             </value>
0174:         </assignmentItems>
0175:     </assignments>
0176:     <description>Flojo que ayuda a el cÃ¡lculo de avance de llenado de Ficha de Afinidad del Cliente</description>
0177:     <environments>Default</environments>
0178:     <formulas>
0179:         <name>f_EstudiaFuera</name>
0180:         <dataType>Number</dataType>
0181:         <expression>IF( ISBLANK(TEXT({!$Record.Estudiaoestudianfueradelpais__c})), 0, 1 )</expression>
0182:         <scale>0</scale>
0183:     </formulas>
0184:     <formulas>
0185:         <name>f_Frecuencia</name>
0186:         <dataType>Number</dataType>
0187:         <expression>IF(
0188:   OR(
0189:     ISBLANK(TEXT({!$Record.Frecuencia_para_ser_contactado__c})),
0190:     TEXT({!$Record.Frecuencia_para_ser_contactado__c})=&quot;--None--&quot;
0191:   ),
0192:   0, 1
0193: )</expression>
0194:         <scale>0</scale>
0195:     </formulas>
0196:     <formulas>
0197:         <name>f_Gastos</name>
0198:         <dataType>Number</dataType>
0199:         <expression>IF( ISBLANK({!$Record.Gastos_mensuales__c}), 0, 1 )</expression>
0200:         <scale>0</scale>
0201:     </formulas>
0202:     <formulas>
0203:         <name>f_Hijos</name>
0204:         <dataType>Number</dataType>
0205:         <expression>IF( ISBLANK(TEXT({!$Record.Cuantos_hijos_tienes__c})), 0, 1 )</expression>
0206:         <scale>0</scale>
0207:     </formulas>
0208:     <formulas>
0209:         <name>f_Influye</name>
0210:         <dataType>Number</dataType>
0211:         <expression>IF( ISBLANK({!$Record.Alguien_InfluyeEnTuPatrimonio__c}), 0, 1 )</expression>
0212:         <scale>0</scale>
0213:     </formulas>
0214:     <formulas>
0215:         <name>f_Ingreso</name>
0216:         <dataType>Number</dataType>
0217:         <expression>IF( ISBLANK({!$Record.Ingreso_mensual_despu_s_de_impuestos__c}), 0, 1 )</expression>
0218:         <scale>0</scale>
0219:     </formulas>
0220:     <formulas>
0221:         <name>f_Institucion</name>
0222:         <dataType>Number</dataType>
0223:         <expression>IF(
0224:   OR(
0225:     ISBLANK(TEXT({!$Record.InstitucionFinancieraPrincipal__c})),
0226:     TEXT({!$Record.InstitucionFinancieraPrincipal__c}) = &quot;--None--&quot;
0227:   ),
0228:   0,
0229:   1
0230: )</expression>
0231:         <scale>0</scale>
0232:     </formulas>
0233:     <formulas>
0234:         <name>f_MedioPreferido</name>
0235:         <dataType>Number</dataType>
0236:         <expression>IF( ISBLANK({!$Record.MedioPreferidoContacto__c}), 0, 1 )</expression>
0237:         <scale>0</scale>
0238:     </formulas>
0239:     <formulas>
0240:         <name>f_MesPreferente</name>
0241:         <dataType>Number</dataType>
0242:         <expression>IF( ISBLANK({!$Record.MesPreferenteInversion_o_ahorrar__c}), 0, 1 )</expression>
0243:         <scale>0</scale>
0244:     </formulas>
0245:     <formulas>
0246:         <name>f_OtrosProd</name>
0247:         <dataType>Number</dataType>
0248:         <expression>IF( ISBLANK({!$Record.Otrosproductosfinancierosteinteresan__c}), 0, 1 )</expression>
0249:         <scale>0</scale>
0250:     </formulas>
0251:     <formulas>
0252:         <name>f_Pasatiempo</name>
0253:         <dataType>Number</dataType>
0254:         <expression>IF(
0255:   OR(
0256:     ISBLANK(TEXT({!$Record.Pasatiempo__c})),
0257:     TEXT({!$Record.Pasatiempo__c})=&quot;--None--&quot;
0258:   ),
0259:   0, 1
0260: )</expression>
0261:         <scale>0</scale>
0262:     </formulas>
0263:     <formulas>
0264:         <name>f_PatrimonioAct</name>
0265:         <dataType>Number</dataType>
0266:         <expression>IF( ISBLANK({!$Record.depatrimoniofinancierototalenActinver__c}), 0, 1 )</expression>
0267:         <scale>0</scale>
0268:     </formulas>
0269:     <formulas>
0270:         <name>f_Porque</name>
0271:         <dataType>Number</dataType>
0272:         <expression>IF( ISBLANK({!$Record.PorqueIndentInteres__c}), 0, 1 )</expression>
0273:         <scale>0</scale>
0274:     </formulas>
0275:     <formulas>
0276:         <name>f_PrincipalAct</name>
0277:         <dataType>Number</dataType>
0278:         <expression>IF(
0279:   OR(
0280:     ISBLANK(TEXT({!$Record.PrincipalActividadProfesional__c})),
0281:     TEXT({!$Record.PrincipalActividadProfesional__c})=&quot;--None--&quot;
0282:   ),
0283:   0, 1
0284: )</expression>
0285:         <scale>0</scale>
0286:     </formulas>
0287:     <formulas>
0288:         <name>f_TipoSeguros</name>
0289:         <dataType>Number</dataType>
0290:         <expression>IF( ISBLANK({!$Record.Conquetipodeseguroscuentas__c}), 0, 1 )</expression>
0291:         <scale>0</scale>
0292:     </formulas>
0293:     <formulas>
0294:         <name>f_Viajas</name>
0295:         <dataType>Number</dataType>
0296:         <expression>IF( ISBLANK(TEXT({!$Record.Viajas_recurrentemente__c})), 0, 1 )</expression>
0297:         <scale>0</scale>
0298:     </formulas>
0299:     <interviewLabel>Flow_Avance_FAC {!$Flow.CurrentDateTime}</interviewLabel>
0300:     <label>Flow_Avance_FAC</label>
0301:     <processMetadataValues>
0302:         <name>BuilderType</name>
0303:         <value>
0304:             <stringValue>LightningFlowBuilder</stringValue>
0305:         </value>
0306:     </processMetadataValues>
0307:     <processMetadataValues>
0308:         <name>CanvasMode</name>
0309:         <value>
0310:             <stringValue>AUTO_LAYOUT_CANVAS</stringValue>
0311:         </value>
0312:     </processMetadataValues>
0313:     <processMetadataValues>
0314:         <name>OriginBuilderType</name>
0315:         <value>
0316:             <stringValue>LightningFlowBuilder</stringValue>
0317:         </value>
0318:     </processMetadataValues>
0319:     <processType>AutoLaunchedFlow</processType>
0320:     <start>
0321:         <locationX>0</locationX>
0322:         <locationY>0</locationY>
0323:         <connector>
0324:             <targetReference>Aplicables</targetReference>
0325:         </connector>
0326:         <object>Account</object>
0327:         <recordTriggerType>CreateAndUpdate</recordTriggerType>
0328:         <triggerType>RecordBeforeSave</triggerType>
0329:     </start>
0330:     <status>Active</status>
0331:     <variables>
0332:         <name>vAplicables</name>
0333:         <dataType>Number</dataType>
0334:         <isCollection>false</isCollection>
0335:         <isInput>false</isInput>
0336:         <isOutput>false</isOutput>
0337:         <scale>0</scale>
0338:     </variables>
0339:     <variables>
0340:         <name>vLlenos</name>
0341:         <dataType>Number</dataType>
0342:         <isCollection>false</isCollection>
0343:         <isInput>false</isInput>
0344:         <isOutput>false</isOutput>
0345:         <scale>0</scale>
0346:     </variables>
0347: </Flow>
0348: 
```

### flows/FAC_Update_Task_Field_Avence.flow-meta.xml
```text
0001: <?xml version="1.0" encoding="UTF-8"?>
0002: <Flow xmlns="http://soap.sforce.com/2006/04/metadata">
0003:     <apiVersion>66.0</apiVersion>
0004:     <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>
0005:     <assignments>
0006:         <name>Avance_Percent_Account</name>
0007:         <label>Avance_Percent_Account</label>
0008:         <locationX>0</locationX>
0009:         <locationY>0</locationY>
0010:         <assignmentItems>
0011:             <assignToReference>FACavancefield</assignToReference>
0012:             <operator>Assign</operator>
0013:             <value>
0014:                 <elementReference>$Record.Avance_FAC__c</elementReference>
0015:             </value>
0016:         </assignmentItems>
0017:         <connector>
0018:             <targetReference>Task_FAC</targetReference>
0019:         </connector>
0020:     </assignments>
0021:     <decisions>
0022:         <name>Existe_tarea_Postventa</name>
0023:         <label>Existe tarea Postventa</label>
0024:         <locationX>0</locationX>
0025:         <locationY>0</locationY>
0026:         <defaultConnectorLabel>Default Outcome</defaultConnectorLabel>
0027:         <rules>
0028:             <name>Si</name>
0029:             <conditionLogic>and</conditionLogic>
0030:             <conditions>
0031:                 <leftValueReference>Task_FAC.Id</leftValueReference>
0032:                 <operator>IsNull</operator>
0033:                 <rightValue>
0034:                     <booleanValue>false</booleanValue>
0035:                 </rightValue>
0036:             </conditions>
0037:             <connector>
0038:                 <targetReference>Update_Task</targetReference>
0039:             </connector>
0040:             <label>Si</label>
0041:         </rules>
0042:     </decisions>
0043:     <decisions>
0044:         <name>Sicontactasi_es_100</name>
0045:         <label>Sicontactasi es 100</label>
0046:         <locationX>0</locationX>
0047:         <locationY>0</locationY>
0048:         <defaultConnectorLabel>Default Outcome</defaultConnectorLabel>
0049:         <rules>
0050:             <name>Es_100</name>
0051:             <conditionLogic>and</conditionLogic>
0052:             <conditions>
0053:                 <leftValueReference>Task_FAC.Avance_FAC_Validacion__c</leftValueReference>
0054:                 <operator>EqualTo</operator>
0055:                 <rightValue>
0056:                     <numberValue>100.0</numberValue>
0057:                 </rightValue>
0058:             </conditions>
0059:             <connector>
0060:                 <targetReference>Update_contactado</targetReference>
0061:             </connector>
0062:             <label>Es 100</label>
0063:         </rules>
0064:     </decisions>
0065:     <environments>Default</environments>
0066:     <interviewLabel>FAC_Update_Task Field_Avence {!$Flow.CurrentDateTime}</interviewLabel>
0067:     <label>FAC_Update_Task Field_Avence</label>
0068:     <processMetadataValues>
0069:         <name>BuilderType</name>
0070:         <value>
0071:             <stringValue>LightningFlowBuilder</stringValue>
0072:         </value>
0073:     </processMetadataValues>
0074:     <processMetadataValues>
0075:         <name>CanvasMode</name>
0076:         <value>
0077:             <stringValue>AUTO_LAYOUT_CANVAS</stringValue>
0078:         </value>
0079:     </processMetadataValues>
0080:     <processMetadataValues>
0081:         <name>OriginBuilderType</name>
0082:         <value>
0083:             <stringValue>LightningFlowBuilder</stringValue>
0084:         </value>
0085:     </processMetadataValues>
0086:     <processType>AutoLaunchedFlow</processType>
0087:     <recordLookups>
0088:         <name>Task_FAC</name>
0089:         <label>Task FAC</label>
0090:         <locationX>0</locationX>
0091:         <locationY>0</locationY>
0092:         <assignNullValuesIfNoRecordsFound>false</assignNullValuesIfNoRecordsFound>
0093:         <connector>
0094:             <targetReference>Existe_tarea_Postventa</targetReference>
0095:         </connector>
0096:         <filterLogic>and</filterLogic>
0097:         <filters>
0098:             <field>RecordTypeId</field>
0099:             <operator>EqualTo</operator>
0100:             <value>
0101:                 <stringValue>012WP000000peoIYAQ</stringValue>
0102:             </value>
0103:         </filters>
0104:         <filters>
0105:             <field>WhatId</field>
0106:             <operator>EqualTo</operator>
0107:             <value>
0108:                 <elementReference>$Record.Id</elementReference>
0109:             </value>
0110:         </filters>
0111:         <filters>
0112:             <field>Subject</field>
0113:             <operator>Contains</operator>
0114:             <value>
0115:                 <stringValue>Ficha de afinidad con el cliente</stringValue>
0116:             </value>
0117:         </filters>
0118:         <filters>
0119:             <field>El_cliente_fue_contactado__c</field>
0120:             <operator>IsNull</operator>
0121:             <value>
0122:                 <booleanValue>true</booleanValue>
0123:             </value>
0124:         </filters>
0125:         <getFirstRecordOnly>true</getFirstRecordOnly>
0126:         <object>Task</object>
0127:         <queriedFields>Id</queriedFields>
0128:         <queriedFields>Avance_FAC_Validacion__c</queriedFields>
0129:         <queriedFields>El_cliente_fue_contactado__c</queriedFields>
0130:         <storeOutputAutomatically>true</storeOutputAutomatically>
0131:     </recordLookups>
0132:     <recordUpdates>
0133:         <name>Update_contactado</name>
0134:         <label>Update contactado</label>
0135:         <locationX>0</locationX>
0136:         <locationY>0</locationY>
0137:         <filterLogic>and</filterLogic>
0138:         <filters>
0139:             <field>Avance_FAC_Validacion__c</field>
0140:             <operator>EqualTo</operator>
0141:             <value>
0142:                 <numberValue>100.0</numberValue>
0143:             </value>
0144:         </filters>
0145:         <inputAssignments>
0146:             <field>El_cliente_fue_contactado__c</field>
0147:             <value>
0148:                 <stringValue>Si</stringValue>
0149:             </value>
0150:         </inputAssignments>
0151:         <object>Task</object>
0152:     </recordUpdates>
0153:     <recordUpdates>
0154:         <name>Update_Task</name>
0155:         <label>Update Task</label>
0156:         <locationX>0</locationX>
0157:         <locationY>0</locationY>
0158:         <connector>
0159:             <targetReference>Sicontactasi_es_100</targetReference>
0160:         </connector>
0161:         <filterLogic>and</filterLogic>
0162:         <filters>
0163:             <field>Subject</field>
0164:             <operator>Contains</operator>
0165:             <value>
0166:                 <stringValue>Ficha de afinidad con el cliente</stringValue>
0167:             </value>
0168:         </filters>
0169:         <filters>
0170:             <field>AccountId</field>
0171:             <operator>EqualTo</operator>
0172:             <value>
0173:                 <elementReference>$Record.Id</elementReference>
0174:             </value>
0175:         </filters>
0176:         <inputAssignments>
0177:             <field>Avance_FAC_Validacion__c</field>
0178:             <value>
0179:                 <elementReference>$Record.Avance_FAC__c</elementReference>
0180:             </value>
0181:         </inputAssignments>
0182:         <object>Task</object>
0183:     </recordUpdates>
0184:     <start>
0185:         <locationX>0</locationX>
0186:         <locationY>0</locationY>
0187:         <connector>
0188:             <targetReference>Avance_Percent_Account</targetReference>
0189:         </connector>
0190:         <filterLogic>or</filterLogic>
0191:         <filters>
0192:             <field>Avance_FAC__c</field>
0193:             <operator>IsChanged</operator>
0194:             <value>
0195:                 <booleanValue>true</booleanValue>
0196:             </value>
0197:         </filters>
0198:         <object>Account</object>
0199:         <recordTriggerType>Update</recordTriggerType>
0200:         <triggerType>RecordAfterSave</triggerType>
0201:     </start>
0202:     <status>Active</status>
0203:     <variables>
0204:         <name>FACavancefield</name>
0205:         <dataType>Number</dataType>
0206:         <isCollection>false</isCollection>
0207:         <isInput>false</isInput>
0208:         <isOutput>false</isOutput>
0209:         <scale>0</scale>
0210:     </variables>
0211: </Flow>
```

### flows/FAC_Task_Update_InAccount.flow-meta.xml
```text
0001: <?xml version="1.0" encoding="UTF-8"?>
0002: <Flow xmlns="http://soap.sforce.com/2006/04/metadata">
0003:     <apiVersion>66.0</apiVersion>
0004:     <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>
0005:     <environments>Default</environments>
0006:     <interviewLabel>FAC_Task_Update_InAccount {!$Flow.CurrentDateTime}</interviewLabel>
0007:     <label>FAC_Task_Update_InAccount</label>
0008:     <processMetadataValues>
0009:         <name>BuilderType</name>
0010:         <value>
0011:             <stringValue>LightningFlowBuilder</stringValue>
0012:         </value>
0013:     </processMetadataValues>
0014:     <processMetadataValues>
0015:         <name>CanvasMode</name>
0016:         <value>
0017:             <stringValue>AUTO_LAYOUT_CANVAS</stringValue>
0018:         </value>
0019:     </processMetadataValues>
0020:     <processMetadataValues>
0021:         <name>OriginBuilderType</name>
0022:         <value>
0023:             <stringValue>LightningFlowBuilder</stringValue>
0024:         </value>
0025:     </processMetadataValues>
0026:     <processType>AutoLaunchedFlow</processType>
0027:     <recordLookups>
0028:         <name>Get_Task</name>
0029:         <label>Get Task</label>
0030:         <locationX>0</locationX>
0031:         <locationY>0</locationY>
0032:         <assignNullValuesIfNoRecordsFound>false</assignNullValuesIfNoRecordsFound>
0033:         <connector>
0034:             <targetReference>UpdateTask</targetReference>
0035:         </connector>
0036:         <filterLogic>and</filterLogic>
0037:         <filters>
0038:             <field>WhatId</field>
0039:             <operator>EqualTo</operator>
0040:             <value>
0041:                 <elementReference>$Record.Id</elementReference>
0042:             </value>
0043:         </filters>
0044:         <filters>
0045:             <field>RecordTypeId</field>
0046:             <operator>EqualTo</operator>
0047:             <value>
0048:                 <stringValue>012WP000000peoIYAQ</stringValue>
0049:             </value>
0050:         </filters>
0051:         <filters>
0052:             <field>Subject</field>
0053:             <operator>Contains</operator>
0054:             <value>
0055:                 <stringValue>Ficha de afinidad con el cliente</stringValue>
0056:             </value>
0057:         </filters>
0058:         <object>Task</object>
0059:         <outputAssignments>
0060:             <assignToReference>recordId</assignToReference>
0061:             <field>Id</field>
0062:         </outputAssignments>
0063:         <outputAssignments>
0064:             <assignToReference>RelatedTo</assignToReference>
0065:             <field>WhatId</field>
0066:         </outputAssignments>
0067:         <sortField>LastModifiedDate</sortField>
0068:         <sortOrder>Desc</sortOrder>
0069:     </recordLookups>
0070:     <recordUpdates>
0071:         <name>UpdateTask</name>
0072:         <label>UpdateTask</label>
0073:         <locationX>0</locationX>
0074:         <locationY>0</locationY>
0075:         <filterLogic>and</filterLogic>
0076:         <filters>
0077:             <field>WhatId</field>
0078:             <operator>EqualTo</operator>
0079:             <value>
0080:                 <elementReference>$Record.Id</elementReference>
0081:             </value>
0082:         </filters>
0083:         <filters>
0084:             <field>Id</field>
0085:             <operator>EqualTo</operator>
0086:             <value>
0087:                 <elementReference>recordId</elementReference>
0088:             </value>
0089:         </filters>
0090:         <filters>
0091:             <field>Subject</field>
0092:             <operator>EqualTo</operator>
0093:             <value>
0094:                 <stringValue>Ficha de afinidad con el cliente</stringValue>
0095:             </value>
0096:         </filters>
0097:         <inputAssignments>
0098:             <field>El_cliente_fue_contactado__c</field>
0099:             <value>
0100:                 <stringValue>Si</stringValue>
0101:             </value>
0102:         </inputAssignments>
0103:         <object>Task</object>
0104:     </recordUpdates>
0105:     <start>
0106:         <locationX>0</locationX>
0107:         <locationY>0</locationY>
0108:         <connector>
0109:             <targetReference>Get_Task</targetReference>
0110:         </connector>
0111:         <filterLogic>and</filterLogic>
0112:         <filters>
0113:             <field>Avance_FAC__c</field>
0114:             <operator>EqualTo</operator>
0115:             <value>
0116:                 <numberValue>100.0</numberValue>
0117:             </value>
0118:         </filters>
0119:         <object>Account</object>
0120:         <recordTriggerType>Update</recordTriggerType>
0121:         <triggerType>RecordAfterSave</triggerType>
0122:     </start>
0123:     <status>Active</status>
0124:     <variables>
0125:         <name>recordId</name>
0126:         <dataType>String</dataType>
0127:         <isCollection>false</isCollection>
0128:         <isInput>true</isInput>
0129:         <isOutput>false</isOutput>
0130:     </variables>
0131:     <variables>
0132:         <name>RelatedTo</name>
0133:         <dataType>String</dataType>
0134:         <isCollection>false</isCollection>
0135:         <isInput>true</isInput>
0136:         <isOutput>false</isOutput>
0137:     </variables>
0138: </Flow>
```

### flows/FAC_Task_Update_InTask.flow-meta.xml
```text
0001: <?xml version="1.0" encoding="UTF-8"?>
0002: <Flow xmlns="http://soap.sforce.com/2006/04/metadata">
0003:     <apiVersion>66.0</apiVersion>
0004:     <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>
0005:     <decisions>
0006:         <name>FAC_Avance_100</name>
0007:         <label>FAC Avance 100</label>
0008:         <locationX>0</locationX>
0009:         <locationY>0</locationY>
0010:         <defaultConnectorLabel>Default Outcome</defaultConnectorLabel>
0011:         <rules>
0012:             <name>Es_100</name>
0013:             <conditionLogic>and</conditionLogic>
0014:             <conditions>
0015:                 <leftValueReference>Related_Account.Avance_FAC__c</leftValueReference>
0016:                 <operator>EqualTo</operator>
0017:                 <rightValue>
0018:                     <numberValue>100.0</numberValue>
0019:                 </rightValue>
0020:             </conditions>
0021:             <conditions>
0022:                 <leftValueReference>$Record.WhatId</leftValueReference>
0023:                 <operator>EqualTo</operator>
0024:                 <rightValue>
0025:                     <elementReference>Related_Account.Id</elementReference>
0026:                 </rightValue>
0027:             </conditions>
0028:             <connector>
0029:                 <targetReference>Update_Records_1</targetReference>
0030:             </connector>
0031:             <label>Es 100</label>
0032:         </rules>
0033:     </decisions>
0034:     <environments>Default</environments>
0035:     <interviewLabel>FAC_Task_Update {!$Flow.CurrentDateTime}</interviewLabel>
0036:     <label>FAC_Task_Update_InTask</label>
0037:     <processMetadataValues>
0038:         <name>BuilderType</name>
0039:         <value>
0040:             <stringValue>LightningFlowBuilder</stringValue>
0041:         </value>
0042:     </processMetadataValues>
0043:     <processMetadataValues>
0044:         <name>CanvasMode</name>
0045:         <value>
0046:             <stringValue>AUTO_LAYOUT_CANVAS</stringValue>
0047:         </value>
0048:     </processMetadataValues>
0049:     <processMetadataValues>
0050:         <name>OriginBuilderType</name>
0051:         <value>
0052:             <stringValue>LightningFlowBuilder</stringValue>
0053:         </value>
0054:     </processMetadataValues>
0055:     <processType>AutoLaunchedFlow</processType>
0056:     <recordLookups>
0057:         <name>Related_Account</name>
0058:         <label>Related Account</label>
0059:         <locationX>0</locationX>
0060:         <locationY>0</locationY>
0061:         <assignNullValuesIfNoRecordsFound>false</assignNullValuesIfNoRecordsFound>
0062:         <connector>
0063:             <targetReference>FAC_Avance_100</targetReference>
0064:         </connector>
0065:         <filterLogic>and</filterLogic>
0066:         <filters>
0067:             <field>Id</field>
0068:             <operator>EqualTo</operator>
0069:             <value>
0070:                 <elementReference>$Record.WhatId</elementReference>
0071:             </value>
0072:         </filters>
0073:         <filters>
0074:             <field>Avance_FAC__c</field>
0075:             <operator>EqualTo</operator>
0076:             <value>
0077:                 <numberValue>100.0</numberValue>
0078:             </value>
0079:         </filters>
0080:         <getFirstRecordOnly>true</getFirstRecordOnly>
0081:         <object>Account</object>
0082:         <storeOutputAutomatically>true</storeOutputAutomatically>
0083:     </recordLookups>
0084:     <recordUpdates>
0085:         <name>Update_Records_1</name>
0086:         <label>Update Records 1</label>
0087:         <locationX>0</locationX>
0088:         <locationY>0</locationY>
0089:         <inputAssignments>
0090:             <field>El_cliente_fue_contactado__c</field>
0091:             <value>
0092:                 <stringValue>Si</stringValue>
0093:             </value>
0094:         </inputAssignments>
0095:         <inputReference>$Record</inputReference>
0096:     </recordUpdates>
0097:     <start>
0098:         <locationX>0</locationX>
0099:         <locationY>0</locationY>
0100:         <connector>
0101:             <targetReference>Related_Account</targetReference>
0102:         </connector>
0103:         <filterLogic>and</filterLogic>
0104:         <filters>
0105:             <field>RecordTypeId</field>
0106:             <operator>EqualTo</operator>
0107:             <value>
0108:                 <stringValue>012WP000000peoIYAQ</stringValue>
0109:             </value>
0110:         </filters>
0111:         <filters>
0112:             <field>Subject</field>
0113:             <operator>Contains</operator>
0114:             <value>
0115:                 <stringValue>Ficha de afinidad con el cliente</stringValue>
0116:             </value>
0117:         </filters>
0118:         <object>Task</object>
0119:         <recordTriggerType>Create</recordTriggerType>
0120:         <triggerType>RecordAfterSave</triggerType>
0121:     </start>
0122:     <status>Active</status>
0123: </Flow>
```

### classes/ACTCompleteCadenceForAccounts.cls
```text
0001: /**
0002:  * ACTCompleteCadenceForAccounts
0003:  * Invocable Apex to complete ActionCadenceTracker records for Contacts under given Account Ids
0004:  * when business rules require setting State = 'Complete' for a specific ActionCadenceId.
0005:  *
0006:  * Specs confirmed by user:
0007:  * - Object: standard ActionCadenceTracker (not __c)
0008:  * - Fields: State (picklist), TargetId (lookup to Contact)
0009:  * - Filter: only trackers with ActionCadenceId = '77Cdp0000000L7hEAE'
0010:  * - Update rule: for the Account whose Avance_FAC__c reached 100 (handled by Flow),
0011:  *                complete all trackers with State != 'Complete' for Contacts of that Account.
0012:  * - Invocation: from a Record-Triggered Flow on Account (After Save), passing Account Ids
0013:  *
0014:  * Design:
0015:  * - Bulkified processing
0016:  * - with sharing to respect sharing rules
0017:  * - SOQL with WITH SECURITY_ENFORCED
0018:  * - DML using Database.update with AccessLevel.USER_MODE
0019:  * - No SOQL/DML in loops; use collections
0020:  * - Clear per-account summary suitable for Flow consumption
0021:  */
0022: public with sharing class ACTCompleteCadenceForAccounts {
0023: 
0024:     // CONSTANTS
0025:     public static final String TARGET_ACTION_CADENCE_ID = '77Cdp0000000L7hEAE';
0026:     public static final String STATE_COMPLETE = 'Complete';
0027: 
0028:     // Invocable input
0029:     public class Request {
0030:         @InvocableVariable(required=true)
0031:         public Id accountId;
0032:     }
0033: 
0034:     // Per-account aggregated outcome for Flow visibility
0035:     public class PerAccountResult {
0036:         @InvocableVariable
0037:         public Id accountId;
0038: 
0039:         @InvocableVariable
0040:         public Integer trackersFound;
0041: 
0042:         @InvocableVariable
0043:         public Integer updatedToComplete;
0044: 
0045:         @InvocableVariable
0046:         public Integer alreadyComplete;
0047: 
0048:         @InvocableVariable
0049:         public String errorMessage;
0050:     }
0051: 
0052:     // Top-level response (single element list returned to Flow)
0053:     public class Response {
0054:         @InvocableVariable
0055:         public List<PerAccountResult> perAccountResults;
0056: 
0057:         @InvocableVariable
0058:         public Integer totalFound;
0059: 
0060:         @InvocableVariable
0061:         public Integer totalUpdated;
0062: 
0063:         @InvocableVariable
0064:         public Integer totalAlreadyComplete;
0065: 
0066:         @InvocableVariable
0067:         public String errorMessage;
0068:     }
0069: 
0070:     @InvocableMethod(
0071:         label='Complete Ficha de Afinidad Cadence for Accounts'
0072:         description='For provided Account Ids, completes ActionCadenceTracker records (State = "Complete") tied to Contacts under those Accounts where ActionCadenceId = TARGET and State != "Complete".'
0073:     )
0074:     public static List<Response> completeForAccounts(List<Request> requests) {
0075:         List<Response> out = new List<Response>();
0076:         Response summary = new Response();
0077:         summary.perAccountResults = new List<PerAccountResult>();
0078:         summary.totalFound = 0;
0079:         summary.totalUpdated = 0;
0080:         summary.totalAlreadyComplete = 0;
0081: 
0082:         // Validate input
0083:         if (requests == null || requests.isEmpty()) {
0084:             out.add(summary);
0085:             return out;
0086:         }
0087: 
0088:         // Collect Account Ids
0089:         Set<Id> accountIds = new Set<Id>();
0090:         for (Request r : requests) {
0091:             if (r != null && r.accountId != null) {
0092:                 accountIds.add(r.accountId);
0093:             }
0094:         }
0095:         if (accountIds.isEmpty()) {
0096:             summary.errorMessage = 'No valid Account Ids provided.';
0097:             out.add(summary);
0098:             return out;
0099:         }
0100: 
0101:         // Fetch Contacts for the Accounts
0102:         // SECURITY: enforce FLS/sharing
0103:         Map<Id, List<Id>> contactIdsByAccount = new Map<Id, List<Id>>();
0104:         for (Contact c : [
0105:             SELECT Id, AccountId
0106:             FROM Contact
0107:             WHERE AccountId IN :accountIds
0108:             WITH SECURITY_ENFORCED
0109:         ]) {
0110:             if (c.AccountId == null) continue;
0111:             List<Id> bucket = contactIdsByAccount.get(c.AccountId);
0112:             if (bucket == null) {
0113:                 bucket = new List<Id>();
0114:                 contactIdsByAccount.put(c.AccountId, bucket);
0115:             }
0116:             bucket.add(c.Id);
0117:         }
0118: 
0119:         // Build a flat set of all contact Ids
0120:         Set<Id> allContactIds = new Set<Id>();
0121:         for (List<Id> ids : contactIdsByAccount.values()) {
0122:             allContactIds.addAll(ids);
0123:         }
0124: 
0125:         if (allContactIds.isEmpty()) {
0126:             // No contacts, so no trackers to complete
0127:             for (Id accId : accountIds) {
0128:                 PerAccountResult par = new PerAccountResult();
0129:                 par.accountId = accId;
0130:                 par.trackersFound = 0;
0131:                 par.updatedToComplete = 0;
0132:                 par.alreadyComplete = 0;
0133:                 summary.perAccountResults.add(par);
0134:             }
0135:             out.add(summary);
0136:             return out;
0137:         }
0138: 
0139:         // Query relevant ActionCadenceTracker records for those Contacts and target Cadence
0140:         // Note: Standard object API names and fields per user confirmation:
0141:         // - Object: ActionCadenceTracker
0142:         // - Fields: State, TargetId (points to Contact), ActionCadenceId
0143:         List<ActionCadenceTracker> trackers = [
0144:             SELECT Id, State, TargetId, ActionCadenceId
0145:             FROM ActionCadenceTracker
0146:             WHERE TargetId IN :allContactIds
0147:               AND ActionCadenceId = :TARGET_ACTION_CADENCE_ID
0148:             WITH SECURITY_ENFORCED
0149:         ];
0150: 
0151:         // Group trackers by Account via TargetId(Contact.AccountId)
0152:         Map<Id, List<ActionCadenceTracker>> trackersByAccount = new Map<Id, List<ActionCadenceTracker>>();
0153:         if (!trackers.isEmpty()) {
0154:             // Preload Contact.AccountId for mapping without extra SOQL:
0155:             // We'll query a minimal map ContactId -> AccountId for the subset of TargetIds found
0156:             Set<Id> trackerContactIds = new Set<Id>();
0157:             for (ActionCadenceTracker t : trackers) {
0158:                 if (t.TargetId != null) trackerContactIds.add(t.TargetId);
0159:             }
0160:             Map<Id, Id> contactToAccount = new Map<Id, Id>();
0161:             if (!trackerContactIds.isEmpty()) {
0162:                 for (Contact c2 : [
0163:                     SELECT Id, AccountId
0164:                     FROM Contact
0165:                     WHERE Id IN :trackerContactIds
0166:                     WITH SECURITY_ENFORCED
0167:                 ]) {
0168:                     contactToAccount.put(c2.Id, c2.AccountId);
0169:                 }
0170:             }
0171: 
0172:             for (ActionCadenceTracker t : trackers) {
0173:                 Id accId = contactToAccount.get(t.TargetId);
0174:                 if (accId == null) continue;
0175:                 List<ActionCadenceTracker> bucket = trackersByAccount.get(accId);
0176:                 if (bucket == null) {
0177:                     bucket = new List<ActionCadenceTracker>();
0178:                     trackersByAccount.put(accId, bucket);
0179:                 }
0180:                 bucket.add(t);
0181:             }
0182:         }
0183: 
0184:         // Prepare updates and per-account tallies
0185:         List<ActionCadenceTracker> toUpdate = new List<ActionCadenceTracker>();
0186:         for (Id accId : accountIds) {
0187:             PerAccountResult par = new PerAccountResult();
0188:             par.accountId = accId;
0189:             par.trackersFound = 0;
0190:             par.updatedToComplete = 0;
0191:             par.alreadyComplete = 0;
0192: 
0193:             List<ActionCadenceTracker> accTrackers = trackersByAccount.get(accId);
0194:             if (accTrackers != null && !accTrackers.isEmpty()) {
0195:                 par.trackersFound = accTrackers.size();
0196:                 for (ActionCadenceTracker t : accTrackers) {
0197:                     if (t.State == STATE_COMPLETE) {
0198:                         par.alreadyComplete++;
0199:                     } else {
0200:                         ActionCadenceTracker upd = new ActionCadenceTracker(
0201:                             Id = t.Id,
0202:                             State = STATE_COMPLETE
0203:                         );
0204:                         toUpdate.add(upd);
0205:                         par.updatedToComplete++;
0206:                     }
0207:                 }
0208:             }
0209: 
0210:             summary.perAccountResults.add(par);
0211:         }
0212: 
0213:         // DML in USER_MODE with partial success handling
0214:         if (!toUpdate.isEmpty()) {
0215:             try {
0216:                 List<Database.SaveResult> srList = Database.update(toUpdate, false, AccessLevel.USER_MODE);
0217:                 Integer failures = 0;
0218:                 for (Database.SaveResult sr : srList) {
0219:                     if (!sr.isSuccess()) failures++;
0220:                 }
0221:                 Integer successes = srList.size() - failures;
0222:                 summary.totalUpdated += successes;
0223:                 if (failures > 0) {
0224:                     summary.errorMessage = 'Some trackers failed to update. Failures: ' + String.valueOf(failures);
0225:                 }
0226:             } catch (Exception e) {
0227:                 summary.errorMessage = 'Update failed: ' + e.getMessage();
0228:                 out.add(summary);
0229:                 return out;
0230:             }
0231:         }
0232: 
0233:         // Global counters
0234:         for (PerAccountResult par : summary.perAccountResults) {
0235:             summary.totalFound += (par.trackersFound == null ? 0 : par.trackersFound);
0236:             summary.totalAlreadyComplete += (par.alreadyComplete == null ? 0 : par.alreadyComplete);
0237:         }
0238: 
0239:         out.add(summary);
0240:         return out;
0241:     }
0242: }
```
