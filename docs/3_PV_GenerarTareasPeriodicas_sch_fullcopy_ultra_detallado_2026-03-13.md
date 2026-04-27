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

## 9. Complemento con documentacion tecnica del proveedor
1. Este es el documento que mas se alinea con la narrativa central del proveedor sobre `Sales Engagement`, `Cadencias`, `Tareas` y el motor de reglas de asignacion de seguimiento PostVenta.
2. La descripcion funcional del proveedor sobre tareas unicas por cuenta, tareas unicas por contrato, periodicidad y parametrizacion en cadencias coincide con el uso real de campos como `TareaUnicaPorCuenta__c`, `TareaUnicaPorContrato__c`, `Periodicidad__c` y `GeneraContacto__c`.
3. El flow `PV_AsignarCadencesCuentas_Flow` listado por el proveedor si esta presente y activo en la source, y efectivamente usa la accion estandar `assignTargetToSalesCadence`.
4. La pagina `Postventa` y el componente `pV_GestionTarea_lwc` aterrizan en UI la parte final de este flujo, porque muestran confirmacion visual cuando la cadencia ya termino y se genero la tarea asociada.
5. El proveedor describe un componente de carga documental para OpenText; en la source esta capacidad aparece por la cadena `pv_FileUpload_LWC` referenciada desde la flexipage y por las clases `PV_FileUpload_*` y `PV_OpenText_*`, aunque no todo el source declarativo vino en esta linea base.
6. Tambien coincide con el documento del proveedor la existencia de un flujo de pantalla `PSTA_NuevoEventoTarea` para reagendar cuando el cliente no fue contactado; este flow esta referenciado desde la pagina `Postventa`.
7. El proveedor presenta la generacion de tareas como resultado de cadencias; la source confirma que esa materializacion no ocurre en el scheduler mismo, sino despues, mediante flow, trigger sobre step tracker, helper de tareas, trigger de task y actualizacion de `Account`.
8. En `actidev` ya existe un proceso complementario `PSTA_PostCargaPostventa_*` que puede remover cadencias `Running` cuando una cuenta pierde todos sus contratos validos y, si la cuenta sigue vigente en PostVenta, reconciliar la cadencia contra el `Account.OwnerId` actual.
9. Ese proceso post-carga no sustituye este scheduler ni la logica de asignacion regular; actua despues de la carga diaria para limpiar o corregir asignaciones ya existentes.
10. La reconciliacion automatica de cadencias ya quedo implementada junto con la limpieza post-carga; la reconciliacion automatica de `Opportunity` sigue siendo un punto a validar con operacion por casos donde un asesor crea oportunidades en cuentas de otro owner.
11. Para la lectura completa del modulo este documento debe consumirse junto con `postventa_documentacion_tecnica_consolidada_2026-03-25.md`.
