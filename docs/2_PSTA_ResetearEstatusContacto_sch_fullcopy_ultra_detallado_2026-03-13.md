# PSTA_ResetearEstatusContacto_sch - Analisis ultra detallado
Ambiente: fullcopy | Fecha de elaboracion: 2026-03-13

## 1. Alcance y ejecucion en fullcopy
Este documento describe el flujo completo de `PSTA_ResetearEstatusContacto_sch` en fullcopy. El nivel de detalle cubre scheduler, helper de business hours, batch principal, batch encadenado, metadata, objetos impactados, campos tocados y efectos colaterales por trigger.

A diferencia de `PSTA_SegmentacionClientes_sch`, este scheduler no ejecuta el batch directamente. Usa `ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(...)`, lo que significa que el proceso solo se lanza si la configuracion del batch y el calendario habil lo permiten.

- Schedule Job: `PSTA_ResetearEstatusContacto`
- CronExpression: `0 0 1 ? * 2,3,4,5,6,7`
- TimesTriggered: `1`
- NextFireTime UTC: `2026-03-14T07:00:00.000+0000`
- State: `WAITING`
- Label usado: `PSTA_Reinicio_Estatus_Registros = 200`
- ACT_BatchConfig__mdt: `PSTA_ResetearEstatusContacto -> BusinessHoursName__c = Postventa`

## 2. Resumen ejecutivo del flujo
1. El scheduler lee `ACT_BatchConfig__mdt` para el proceso `PSTA_ResetearEstatusContacto`.
2. `ACT_BusinessHoursHelper_cls` valida si el dia actual es habil segun `BusinessHours Postventa`.
3. Solo si el dia es habil ejecuta `PSTA_ResetearEstatusContacto_bch` con tamano tomado del label `PSTA_Reinicio_Estatus_Registros`.
4. `PSTA_ResetearEstatusContacto_bch.start()` obtiene desde metadata la query `PSTA_Query_Reinicio_Estatus_Contacto`.
5. `PSTA_ResetearEstatusContacto_cls.resetEstatus()` revisa cada cuenta y, cuando `FechaSiguienteContacto__c` ya vencio y el estatus no es `Pendiente`, prepara un update parcial sobre `Account`.
6. Los campos directos que modifica esta clase son exactos: `EstatusContacto__c = 'Pendiente'` y `PriorizacionContacto__c = false`.
7. `finish()` encadena `PSTA_AgrupacionPriorizacionDiaria_bch`, que reconstruye la lista diaria de contacto marcando `PriorizacionContacto__c = true` a un subconjunto controlado por configuracion y por limite de clientes por banquero.

## 3. Diagrama del flujo completo
```text
PSTA_ResetearEstatusContacto_sch.execute(ctx)
  -> ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
         'PSTA_ResetearEstatusContacto',
         new PSTA_ResetearEstatusContacto_bch(),
         Label.PSTA_Reinicio_Estatus_Registros)
  -> helper lee ACT_BatchConfig__mdt
  -> helper obtiene BusinessHours 'Postventa'
  -> helper evalua si hoy es dia habil
  -> si es habil: Database.executeBatch(...)
  -> si no es habil: no ejecuta batch

PSTA_ResetearEstatusContacto_bch.start(bc)
  -> PSTA_SegmentacionClientesSelector_cls.getQueryStatusCuentas()
  -> SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Reinicio_Estatus_Contacto'
  -> QueryLocator de Account

PSTA_ResetearEstatusContacto_bch.execute(bc, scope)
  -> PSTA_ResetearEstatusContacto_cls.resetEstatus(scope)
     -> si FechaSiguienteContacto__c != null
     -> y EstatusContacto__c != 'Pendiente'
     -> y hoy >= FechaSiguienteContacto__c
        prepara Account(Id)
        set EstatusContacto__c = 'Pendiente'
        set PriorizacionContacto__c = false
  -> updateRecords(values, map)
     -> Database.update(records, false)
     -> EventLogger.error(...) si hay errores
     -> dispara AccountTrigger

PSTA_ResetearEstatusContacto_bch.finish(bc)
  -> Database.executeBatch(new PSTA_AgrupacionPriorizacionDiaria_bch())

PSTA_AgrupacionPriorizacionDiaria_bch.start/execute
  -> PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionDiaria()
  -> lee PSTA_Query_Priorizacion_Diaria
  -> PSTA_PriorizacionDiaria_cls.agrupacionBanqueroPorCuentas(...)
     -> por cada cuenta elegible calcula PriorizacionContacto__c
     -> respeta limite ClientesContactarPorDia__c por segmento y banquero
  -> Database.update(records, false)
  -> dispara AccountTrigger
```

## 4. Detalle por clase y metodo
### 4.1 PSTA_ResetearEstatusContacto_sch
1. Implementa `Schedulable`.
2. `execute(SchedulableContext sc)` no ejecuta el batch directamente.
3. Invoca `ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay('PSTA_ResetearEstatusContacto', new PSTA_ResetearEstatusContacto_bch(), Integer.valueOf(System.Label.PSTA_Reinicio_Estatus_Registros))`.
4. Su unica responsabilidad es delegar al helper la validacion de dia habil y el disparo del batch.

### 4.2 ACT_BusinessHoursHelper_cls en este flujo
1. `getConfiguredBusinessHoursName(configDeveloperName)` consulta `ACT_BatchConfig__mdt` y obtiene `BusinessHoursName__c`.
2. `getConfiguredBusinessHoursId(configDeveloperName)` consulta `BusinessHours` por nombre.
3. `isConfiguredBusinessDay(configDeveloperName)` toma `System.now().date()`, crea el inicio del dia y usa `BusinessHours.nextStartDate(bhId, startOfDay)`.
4. La regla exacta es: el proceso corre si el siguiente inicio habil cae en la misma fecha actual.
5. `executeBatchIfConfiguredBusinessDay(...)` solo llama `Database.executeBatch(...)` si la validacion anterior regresa `true`.
6. En este scheduler la configuracion encontrada en fullcopy es `BusinessHoursName__c = Postventa`.

### 4.3 PSTA_ResetearEstatusContacto_bch
1. Implementa `Database.Batchable<SObject>`.
2. `start()` retorna `Database.getQueryLocator(PSTA_SegmentacionClientesSelector_cls.getQueryStatusCuentas())`.
3. `execute()` castea el scope a `List<Account>`.
4. Llama `PSTA_ResetearEstatusContacto_cls.resetEstatus(lstClientes)`.
5. Si el mapa de cuentas a actualizar no esta vacio, llama `PSTA_ResetearEstatusContacto_cls.updateRecords(...)`.
6. `finish()` escribe un debug y ejecuta `Database.executeBatch(new PSTA_AgrupacionPriorizacionDiaria_bch())` sin tamano explicito, por lo que usa el default de Salesforce para batches.

### 4.4 PSTA_ResetearEstatusContacto_cls
1. `resetEstatus(List<Account> lstCuentas)` crea un `Map<Id, Account>` con updates parciales.
2. Para cada cuenta evalua tres condiciones exactas:
3. `cuenta.FechaSiguienteContacto__c != null`.
4. `cuenta.EstatusContacto__c != 'Pendiente'`.
5. `System.today() >= cuenta.FechaSiguienteContacto__c`.
6. Si todas se cumplen, construye `new Account(Id = cuenta.Id)`.
7. Asigna exactamente dos campos: `EstatusContacto__c = 'Pendiente'` y `PriorizacionContacto__c = false`.
8. No toca `FechaSiguienteContacto__c`, `FechaUltimoContacto__c` ni `FechaNoRequiereSerContacto__c` de manera directa.
9. `updateRecords(List<SObject> lstRecords, Map<Id, Account> mapRecords)` ejecuta `Database.update(lstRecords, false)`.
10. En error arma `mapErrors` con el mensaje y el nombre del registro fallido.
11. `saveLogError(...)` llama `EventLogger.error(...)`, que inserta `WebServiceTrackingLog__c`.
### 4.5 PSTA_AgrupacionPriorizacionDiaria_bch
1. Implementa `Database.Batchable<SObject>, Database.Stateful`.
2. En el constructor inicializa `mapAsesorPorNumCuentas` y `mapConfigPorSegmento`.
3. `mapConfigPorSegmento` viene de `PSTA_PriorizacionDiaria_cls.obtenerSegmentoPorConfig()`.
4. `start()` retorna `Database.getQueryLocator(PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionDiaria())`.
5. `execute()` llama `PSTA_PriorizacionDiaria_cls.agrupacionBanqueroPorCuentas(lstClientes, this.mapConfigPorSegmento, this.mapAsesorPorNumCuentas)`.
6. El metodo devuelve dos cosas: `lstCuentasParaActualizar` y el mapa stateful de numero de cuentas ya asignadas por asesor.
7. Si la lista a actualizar no esta vacia, llama `PSTA_PriorizacionDiaria_cls.updateRecords(lstClientesActualizar)`.
8. `finish()` solo deja trazas de debug.

### 4.6 PSTA_PriorizacionDiaria_cls
1. Tiene `defaultBusinessHoursId = PSTA_PriorizacionSelector_cls.getDiasLaborales()`.
2. Tiene `hoy = Date.today()`.
3. `obtenerSegmentoPorConfig()` consulta `ConfiguracionActinver__c` desde `PSTA_PriorizacionSelector_cls.getConfiguracionContacto()` y mapea por `Segmento__c`.
4. `agrupacionBanqueroPorCuentas(...)` recorre cuentas, localiza la configuracion del segmento y toma `ClientesContactarPorDia__c` como limite por asesor.
5. Solo procesa cuentas donde `BanqueroAsignado__r.BusinessUnitMember` sea instancia de `Banker`.
6. Si el asesor aun no rebasa su limite, calcula `cuenta.PriorizacionContacto__c = debePriorizarContacto(cuenta.FechaSiguienteContacto__c, Integer.valueOf(config.FrecuenciaContacto__c), hoy)`.
7. El metodo `debePriorizarContacto(...)` usa `PSTA_UtilityClass.obtenerDiasLaboralesEntreFechas(FechaInicio, hoy, defaultBusinessHoursId)`.
8. La regla exacta actual es `lngDiasEntreFechas >= 0`; el parametro `intFrecuencia` se recibe pero no se usa en la condicion final.
9. Si `PriorizacionContacto__c` resulta `true`, agrega la cuenta a update y aumenta el contador del asesor.
10. `updateRecords()` hace `Database.update(records, false)` y registra errores via `EventLogger.error(...)`.

### 4.7 PSTA_PriorizacionSelector_cls en este flujo
1. `getQueryCuentasPriorizacionDiaria()` consulta `PSTA_Consultas__mdt` con `DeveloperName = PSTA_Query_Priorizacion_Diaria`.
2. `getConfiguracionContacto()` consulta `ConfiguracionActinver__c` record type `ContactoPostventa` y lee: `Segmento__c`, `RangoMontoMaximo__c`, `RangoMontoMinimo__c`, `FrecReinicioNoReqContacto__c`, `Rol__c`, `FrecuenciaContacto__c`, `FrecuenciaVisita__c`, `ClientesContactarPorDia__c`.
3. `getDiasLaborales()` consulta `BusinessHours` donde `Name = 'Postventa'`.

### 4.8 AccountTrigger y efectos indirectos
1. El update directo de `EstatusContacto__c` y `PriorizacionContacto__c` dispara `AccountTrigger`.
2. El segundo update de priorizacion diaria tambien dispara `AccountTrigger`.
3. Por ello el impacto final puede incluir cambios indirectos en `FechaSiguienteContacto__c`, `FechaSiguienteVisita__c`, `Segmento__c`, `RecordTypeId`, `OwnerId`, `BanqueroAsignado__c` y derivados, segun la logica activa del trigger.
4. El batch principal no toca esos campos de forma explicita, pero el trigger si puede hacerlo en la misma transaccion.

## 5. Como consulta metadata y como la utiliza
### 5.1 ACT_BatchConfig__mdt
1. El scheduler usa el nombre logico `PSTA_ResetearEstatusContacto`.
2. `ACT_BusinessHoursHelper_cls` consulta ese registro en `ACT_BatchConfig__mdt`.
3. En fullcopy el valor recuperado es `BusinessHoursName__c = Postventa`.
4. Ese dato decide si el batch corre o se inhibe en la fecha actual.

### 5.2 PSTA_Consultas__mdt
1. El batch principal obtiene `PSTA_Query_Reinicio_Estatus_Contacto`.
2. El batch encadenado obtiene `PSTA_Query_Priorizacion_Diaria`.
3. La query de reinicio filtra cuentas con `FechaSiguienteContacto__c <= TODAY` y otras condiciones funcionales definidas en metadata.
4. La query diaria filtra cuentas con `ContactoPriorizadoEsteMes__c = true`, `PriorizacionContacto__c = false`, `EstatusContacto__c = 'Pendiente'` y otras condiciones del universo de postventa.

```sql
SELECT Consulta__c
FROM PSTA_Consultas__mdt
WHERE DeveloperName = 'PSTA_Query_Reinicio_Estatus_Contacto'

SELECT Consulta__c
FROM PSTA_Consultas__mdt
WHERE DeveloperName = 'PSTA_Query_Priorizacion_Diaria'
```

### 5.3 ConfiguracionActinver__c
1. `PSTA_PriorizacionDiaria_cls` usa la configuracion `ContactoPostventa`.
2. Por segmento toma el limite `ClientesContactarPorDia__c`.
3. Tambien lee `FrecuenciaContacto__c`, aunque hoy el metodo `debePriorizarContacto()` no la aplica en su condicion final.
4. Este hallazgo es importante: la frecuencia se transporta por codigo pero no restringe la decision diaria en la implementacion actual.

### 5.4 Custom Labels
1. `PSTA_Reinicio_Estatus_Registros = 200` controla el tamano del batch principal.
2. El batch encadenado no recibe tamano explicito en `finish()`.

## 6. Matriz exacta clase -> objeto -> operacion -> campos
- `PSTA_ResetearEstatusContacto_sch` -> `ACT_BatchConfig__mdt` -> Read -> `BusinessHoursName__c` via helper.
- `ACT_BusinessHoursHelper_cls` -> `BusinessHours` -> Read -> `Name = Postventa`, `Id`.
- `PSTA_ResetearEstatusContacto_bch` -> `PSTA_Consultas__mdt` -> Read -> `PSTA_Query_Reinicio_Estatus_Contacto`.
- `PSTA_ResetearEstatusContacto_cls` -> `Account` -> Update -> `EstatusContacto__c = 'Pendiente'`, `PriorizacionContacto__c = false`.
- `EventLogger` -> `WebServiceTrackingLog__c` -> Insert solo en error -> detalle tecnico del fallo.
- `PSTA_AgrupacionPriorizacionDiaria_bch` -> `PSTA_Consultas__mdt` -> Read -> `PSTA_Query_Priorizacion_Diaria`.
- `PSTA_PriorizacionDiaria_cls` -> `ConfiguracionActinver__c` -> Read -> `ClientesContactarPorDia__c`, `FrecuenciaContacto__c`, `Segmento__c` y demas parametros.
- `PSTA_PriorizacionDiaria_cls` -> `BusinessHours` -> Read -> `Postventa`.
- `PSTA_PriorizacionDiaria_cls` -> `Account` -> Update -> `PriorizacionContacto__c`.
- `AccountTrigger` y clases relacionadas -> `Account` -> Before update indirecto -> `FechaSiguienteContacto__c`, `FechaSiguienteVisita__c`, `Segmento__c`, `RecordTypeId` y derivados.

## 7. Registros creados, actualizados o no modificados
1. Actualiza `Account` en el batch de reinicio de estatus.
2. Actualiza `Account` nuevamente en el batch encadenado de priorizacion diaria.
3. Inserta `WebServiceTrackingLog__c` solo en caso de error.
4. No crea `Task`, `Contract` ni `ResumenGlobalPostventa__c` en este flujo.
5. No modifica metadata; solo la consulta.

## 8. Riesgos, observaciones y puntos de auditoria
1. El job programado puede existir y dispararse por cron, pero el helper puede impedir que corra el batch si el dia no es habil.
2. La logica real de elegibilidad depende de queries en metadata; un cambio en `PSTA_Query_Reinicio_Estatus_Contacto` altera el universo procesado sin despliegue.
3. `PSTA_PriorizacionDiaria_cls.debePriorizarContacto()` recibe `intFrecuencia`, pero hoy no lo usa para filtrar; la condicion real es `diasHabiles >= 0`.
4. `finish()` encadena priorizacion diaria sin una segunda validacion de business hours.
5. Al usar `Database.update(..., false)`, la consistencia final exige revisar `WebServiceTrackingLog__c`.

## 9. Complemento con documentacion tecnica del proveedor
1. El documento del proveedor describe este comportamiento de forma funcional cuando habla de `Etapa contacto`, `Fecha de siguiente contacto` y de la lista priorizada diaria de clientes a contactar.
2. En la implementacion real el reinicio no depende de un cambio manual del asesor, sino de un scheduler que reabre cuentas vencidas y luego encadena la priorizacion diaria.
3. Esto conecta directamente con el objetivo del modelo PostVenta descrito por el proveedor: que el asesor siempre tenga una cola activa de clientes pendientes segun segmento y reglas de negocio.
4. La configuracion `ContactoPostventa` listada por el proveedor coincide con el uso observado en `ConfiguracionActinver__c`, especialmente para `FrecuenciaContacto__c`, `FrecuenciaVisita__c`, `ClientesContactarPorDia__c` y `FrecReinicioNoReqContacto__c`.
5. El proveedor presenta la frecuencia de contacto como parametro activo de negocio; la source muestra un hallazgo relevante: hoy la logica diaria recibe ese parametro, pero no lo aplica en la condicion final de priorizacion.
6. Este flujo no interviene en UI de forma directa, pero su resultado es el que sostiene las listas diarias, los indicadores posteriores y la consistencia operativa del seguimiento.
7. En `actidev` se agrego tambien un proceso complementario `PSTA_PostCargaPostventa_*` que puede limpiar `ContactoPriorizadoEsteMes__c`, `PriorizacionContacto__c` y `PriorizacionVisita__c` cuando una cuenta pierde todos sus contratos validos despues de la carga diaria.
8. Ese proceso no reemplaza este scheduler de reinicio ni la priorizacion diaria encadenada; opera como correctivo nocturno para evitar que cuentas invalidas sigan apareciendo en metas mensuales, metas diarias o listas operativas.
9. Para contexto transversal del modelo debe relacionarse este documento con `3_PV_GenerarTareasPeriodicas_sch_fullcopy_ultra_detallado_2026-03-13.md` y con `postventa_documentacion_tecnica_consolidada_2026-03-25.md`.
