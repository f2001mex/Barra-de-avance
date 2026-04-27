# PSTA_SegmentacionClientes_sch - Analisis ultra detallado
Ambiente: fullcopy | Fecha de elaboracion: 2026-03-13

## 1. Alcance y ejecucion en fullcopy
Este documento describe el flujo completo de `PSTA_SegmentacionClientes_sch` en fullcopy con el mayor nivel de detalle funcional y tecnico. El objetivo es explicar que hace cada clase, batch y metodo relevante, como consulta metadata/configuracion, que objetos toca, que campos modifica y que efectos indirectos produce por trigger.

En fullcopy este scheduler sigue ejecutando el batch directamente con `Database.executeBatch`; no usa `ACT_BusinessHoursHelper_cls`. Por lo tanto, el criterio de ejecucion depende solo del cron del Scheduled Job y no de una validacion previa de dia habil.

- Schedule Job: `PSTA_SegmentacionClientes`
- CronExpression: `0 0 0 1 */1 ?`
- TimesTriggered: `2`
- NextFireTime UTC: `2026-04-01T06:00:00.000+0000`
- State: `WAITING`
- Label usado: `PSTA_Segmentacion_Registros_Batch = 200`

## 2. Resumen ejecutivo del flujo
1. `PSTA_SegmentacionClientes_sch` ejecuta `PSTA_SegmentacionClientes_bch` con el tamano de lote tomado del Custom Label `PSTA_Segmentacion_Registros_Batch`.
2. `PSTA_SegmentacionClientes_bch.start()` obtiene la query base desde `PSTA_Consultas__mdt` usando `DeveloperName = PSTA_Query_Segmentacion`.
3. `execute()` toma el scope, vuelve a consultar `Account` con subquery de `Contract` y delega el calculo a `PSTA_SegmentacionClientes_cls`.
4. `PSTA_SegmentacionClientes_cls` usa `PSTA_FechaPrimerContacto_cls` y `PSTA_Segmentacion_cls` para calcular segmento, saldo integral, antiguedad y fechas base de contacto/visita.
5. La actualizacion se hace con `Database.update(records, false)`, por lo que el proceso admite errores parciales.
6. Cada `update Account` dispara `AccountTrigger` en `before update`, agregando impactos indirectos sobre fechas siguientes, record type, owner, banquero y otros campos derivados.
7. `finish()` encadena `PSTA_AgrupacionPriorizacionMensual_bch`, que reconstruye `ContactoPriorizadoEsteMes__c` y `PriorizacionVisita__c`.

## 3. Diagrama del flujo completo
```text
PSTA_SegmentacionClientes_sch.execute(ctx)
  -> lee Label.PSTA_Segmentacion_Registros_Batch
  -> Database.executeBatch(new PSTA_SegmentacionClientes_bch(), batchSize)

PSTA_SegmentacionClientes_bch.start(bc)
  -> PSTA_SegmentacionClientesSelector_cls.getQueryString()
  -> SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Segmentacion'
  -> Database.getQueryLocator(query)

PSTA_SegmentacionClientes_bch.execute(bc, scope)
  -> recolecta Ids del scope
  -> PSTA_SegmentacionClientesSelector_cls.getContractAccounts(ids)
  -> consulta Account + subquery Contracts
  -> PSTA_SegmentacionClientes_cls.segmentacionClientes(accounts)
      -> PSTA_FechaPrimerContacto_cls.agregaDatosSegmentacion(...)
         -> PSTA_Segmentacion_cls.getSegmentByBanker(...)
         -> PSTA_SegmentacionClientesSelector_cls.getConfigContracts()
         -> usa ConfiguracionActinver__c para tipos/estatus de contrato
         -> calcula Segmento__c, SaldoIntegral__c, FechaAntiguedad__c
         -> si faltan fechas de ultimo contacto/visita, usa contrato valido mas antiguo
         -> resetea ContactoPriorizadoEsteMes__c y PriorizacionVisita__c a false
      -> updateRecords(accounts)
         -> Database.update(accounts, false)
         -> EventLogger.error(...) si hay errores
         -> dispara AccountTrigger

AccountTrigger (before update)
  -> OD_Account_thr
  -> PSTA_Account_thr
      -> PSTA_ListadoClientes_cls.actualizarFechasSiguienteContacto(...)
      -> PSTA_Segmentacion_cls.getSegmentByBanker(...)
  -> AccountRecordTypeAssigner

PSTA_SegmentacionClientes_bch.finish(bc)
  -> Database.executeBatch(new PSTA_AgrupacionPriorizacionMensual_bch(), batchSize)

PSTA_AgrupacionPriorizacionMensual_bch.start/execute
  -> PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionMensual(...)
  -> lee PSTA_Query_Priorizacion_Mensual y ConfiguracionActinver__c ContactoPostventa
  -> PSTA_PriorizacionMensual_cls.agruparPriorizacionMensual(...)
  -> update Account con ContactoPriorizadoEsteMes__c y PriorizacionVisita__c
  -> AccountTrigger vuelve a ejecutarse
```

## 4. Detalle por clase y metodo
### 4.1 PSTA_SegmentacionClientes_sch
1. Implementa `Schedulable`.
2. `execute(SchedulableContext sc)` toma `System.Label.PSTA_Segmentacion_Registros_Batch`.
3. Convierte el valor a `Integer`.
4. Ejecuta `Database.executeBatch(new PSTA_SegmentacionClientes_bch(), batchSize)`.
5. No consulta `ACT_BatchConfig__mdt` ni `BusinessHours`.
6. No hace DML directo sobre objetos funcionales.

### 4.2 PSTA_SegmentacionClientes_bch
1. Implementa `Database.Batchable<SObject>`.
2. `start()` llama `PSTA_SegmentacionClientesSelector_cls.getQueryString()`.
3. Ese selector consulta `PSTA_Consultas__mdt` y regresa la `Consulta__c` del registro `PSTA_Query_Segmentacion`.
4. `execute()` castea el scope a `List<Account>`, toma sus Ids y consulta las cuentas detalladas con sus contratos.
5. El recalculo funcional no se hace aqui; se delega a `PSTA_SegmentacionClientes_cls.segmentacionClientes()`.
6. `finish()` encadena `PSTA_AgrupacionPriorizacionMensual_bch` usando el mismo label de tamano de lote.

### 4.3 PSTA_SegmentacionClientesSelector_cls
1. Centraliza las lecturas del flujo.
2. `getQueryString()` consulta `PSTA_Consultas__mdt` y devuelve `Consulta__c` de `PSTA_Query_Segmentacion`.
3. `getContractAccounts(Set<Id>)` consulta `Account` con la subquery `Contracts` para las cuentas del scope.
4. `getConfigContracts()` consulta `ConfiguracionActinver__c` del record type `PSTA_ConfiguracionContratosPostventa`.
5. De esa configuracion obtiene `TipoContratos__c = 01;02;03;08` y `EstatusContrato__c = C05;CC05`.
6. La misma clase tambien expone metodos reutilizados por otros procesos, por ejemplo `getQueryStatusCuentas()` y `getQueryAllBBM()`.

### 4.4 PSTA_SegmentacionClientes_cls
1. `segmentacionClientes(List<Account>)` actua como orquestador.
2. No hace todos los calculos por si mismo; delega la transformacion a `PSTA_FechaPrimerContacto_cls`.
3. `updateRecords(List<Account>)` ejecuta `Database.update(records, false)`.
4. Recorre `SaveResult[]` para detectar errores parciales.
5. Si algun registro falla, llama `EventLogger.error(...)` y termina insertando `WebServiceTrackingLog__c`.
6. No hace `insert`, `upsert` ni `delete` sobre `Account` o `Contract`; solo `update Account`.

### 4.5 PSTA_FechaPrimerContacto_cls
1. Recorre cada `Account` con sus `Contracts` relacionados.
2. Filtra contratos validos usando la configuracion de `TipoContratos__c` y `EstatusContrato__c`.
3. Calcula `SaldoIntegral__c` a partir de los contratos validos.
4. Determina `FechaAntiguedad__c` usando el contrato valido mas antiguo.
5. Si `FechaUltimoContacto__c` o `FechaUltimaVisita__c` estan vacias, usa la fecha del contrato valido mas antiguo como baseline.
6. Invoca `PSTA_Segmentacion_cls` para resolver `Segmento__c`.
7. Resetea `ContactoPriorizadoEsteMes__c = false`.
8. Resetea `PriorizacionVisita__c = false`.
9. Devuelve la lista preparada para persistencia.
### 4.6 PSTA_Segmentacion_cls
1. Resuelve el segmento de negocio a partir del banker asignado.
2. Lee atributos de `Banker`, en especial `Division__c`, `Rol__c` y `ExternalId__c`.
3. Mapea la division a segmentos funcionales como `Privada`, `Patrimonial` y `Wealth Management`.
4. Aplica la excepcion de `Patrimonial reactivo` cuando la configuracion de `ConfiguracionActinver__c` indica `Rol__c = CONSULTOR/A FARMER DIGITAL`.
5. Esta clase tambien se reutiliza desde trigger para recalcular `Segmento__c` cuando cambia owner o banquero.

### 4.7 PSTA_AgrupacionPriorizacionMensual_bch
1. Es el batch encadenado al final del de segmentacion.
2. `start()` toma la query base `PSTA_Query_Priorizacion_Mensual` desde `PSTA_Consultas__mdt`.
3. Esa query contiene un placeholder `{0}`.
4. El batch arma dinamicamente las condiciones por segmento y reemplaza `{0}` con base en la configuracion `ContactoPostventa`.
5. `execute()` consulta las cuentas elegibles y delega el calculo a `PSTA_PriorizacionMensual_cls`.
6. Su objetivo es reconstruir las banderas mensuales despues del reseteo hecho por `PSTA_FechaPrimerContacto_cls`.

### 4.8 PSTA_PriorizacionMensual_cls
1. Lee `ConfiguracionActinver__c` del record type `ContactoPostventa`.
2. De ahi toma `FrecuenciaContacto__c`, `FrecuenciaVisita__c`, `ClientesContactarPorDia__c`, `Segmento__c` y `Rol__c`.
3. Consulta `BusinessHours` con `Name = Postventa` a traves del selector.
4. Calcula dias habiles entre fechas usando utilerias y `BusinessHours`.
5. Marca `ContactoPriorizadoEsteMes__c = true` cuando la cuenta debe entrar a la lista de contacto del mes.
6. Marca `PriorizacionVisita__c = true` cuando ya requiere visita por frecuencia.
7. Persiste con `Database.update(records, false)`.
8. Registra errores con `EventLogger.error(...)`.

### 4.9 PSTA_PriorizacionSelector_cls
1. `getQueryCuentasPriorizacionMensual(String strConditionsBySegment)` consulta `PSTA_Consultas__mdt` con `DeveloperName = PSTA_Query_Priorizacion_Mensual`.
2. Usa `String.format(baseQuery, new List<String>{strConditionsBySegment})` para insertar el filtro dinamico por segmento.
3. `getQueryCuentasPriorizacionDiaria()` tambien lee metadata, aunque corresponde al batch diario y no al mensual de este scheduler.
4. `getConfiguracionContacto()` consulta `ConfiguracionActinver__c` con record type `ContactoPostventa`.
5. `getDiasLaborales()` consulta `BusinessHours` donde `Name = Postventa`.

### 4.10 AccountTrigger y clases indirectas
1. Cada `update Account` del batch dispara `AccountTrigger` porque `Trigger_Management__mdt` indica `AccountTrigger = true`.
2. `OD_Account_thr` y `OD_Account_cls` ejecutan reglas generales de cuenta relacionadas con owner, banquero, mapeos y validaciones.
3. `PSTA_Account_thr` llama `PSTA_ListadoClientes_cls` para recalcular `FechaSiguienteContacto__c`, `FechaSiguienteVisita__c` y reglas de reinicio de contacto.
4. `PSTA_Account_thr` tambien reutiliza `PSTA_Segmentacion_cls` para recalcular `Segmento__c` si hay cambios relevantes.
5. `AccountRecordTypeAssigner` puede reasignar `RecordTypeId` segun owner, division, metadata y configuracion del modelo operativo.
6. El impacto real sobre `Account` es mayor que el update directo visible desde el batch.

## 5. Como consulta metadata y como la utiliza
### 5.1 PSTA_Consultas__mdt
1. `PSTA_SegmentacionClientesSelector_cls.getQueryString()` consulta `PSTA_Consultas__mdt`.
2. Usa `DeveloperName = PSTA_Query_Segmentacion`.
3. El valor recuperado en fullcopy filtra `Account` por `BanqueroAsignado__c != null`, `Person_Type__c = 'FISICA'` e `ID_Asesor__c IN (...)`.
4. La query esta fuera del codigo, por lo que cambiar metadata cambia el universo procesado sin despliegue.

```sql
SELECT Consulta__c
FROM PSTA_Consultas__mdt
WHERE DeveloperName = 'PSTA_Query_Segmentacion'
```

### 5.2 ConfiguracionActinver__c para contratos
1. Se consulta el record type `PSTA_ConfiguracionContratosPostventa`.
2. `TipoContratos__c` define que tipos de contrato se consideran en saldo y antiguedad.
3. `EstatusContrato__c` define que estatus de contrato entran al calculo.
4. En fullcopy los valores recuperados son `01;02;03;08` y `C05;CC05`.

### 5.3 ConfiguracionActinver__c para contacto postventa
1. Se consulta el record type `ContactoPostventa`.
2. La metadata trae parametros por segmento: `FrecuenciaContacto__c`, `FrecuenciaVisita__c`, `FrecReinicioNoReqContacto__c`, `ClientesContactarPorDia__c`, `RangoMontoMinimo__c`, `RangoMontoMaximo__c` y `Rol__c`.
3. La clase de segmentacion usa `Rol__c` para detectar `Patrimonial reactivo`.
4. La clase de priorizacion mensual usa las frecuencias y volumen diario para definir que cuentas entran al mes y cuales requieren visita.

### 5.4 Custom Labels
1. `PSTA_Segmentacion_Registros_Batch = 200` define el tamano del batch principal.
2. El mismo tamano se reutiliza para el batch mensual encadenado.
3. El tamano no esta hardcodeado; se toma en runtime.

## 6. Matriz exacta clase -> objeto -> operacion -> campos
- `PSTA_SegmentacionClientes_sch` -> Ninguno -> Sin DML -> lee `PSTA_Segmentacion_Registros_Batch`.
- `PSTA_SegmentacionClientes_bch` -> `Account` -> Read -> Ids del scope y recarga detallada.
- `PSTA_SegmentacionClientesSelector_cls` -> `PSTA_Consultas__mdt` -> Read -> `Consulta__c`.
- `PSTA_SegmentacionClientesSelector_cls` -> `ConfiguracionActinver__c` -> Read -> `TipoContratos__c`, `EstatusContrato__c`.
- `PSTA_SegmentacionClientesSelector_cls` -> `Account` -> Read -> campos de cuenta usados para segmentacion y fechas.
- `PSTA_SegmentacionClientesSelector_cls` -> `Contract` -> Read -> campos del contrato usados para saldo y antiguedad.
- `PSTA_FechaPrimerContacto_cls` -> `Account` -> Prepare update -> `Segmento__c`, `SaldoIntegral__c`, `FechaAntiguedad__c`, `FechaUltimoContacto__c`, `FechaUltimaVisita__c`, `ContactoPriorizadoEsteMes__c`, `PriorizacionVisita__c`.
- `PSTA_Segmentacion_cls` -> `Banker` -> Read -> `Division__c`, `Rol__c`, `ExternalId__c`.
- `PSTA_SegmentacionClientes_cls` -> `Account` -> Update -> campos preparados por `PSTA_FechaPrimerContacto_cls`.
- `EventLogger` -> `WebServiceTrackingLog__c` -> Insert solo en error -> detalle tecnico del fallo.
- `PSTA_AgrupacionPriorizacionMensual_bch` -> `PSTA_Consultas__mdt` -> Read -> `PSTA_Query_Priorizacion_Mensual`.
- `PSTA_PriorizacionSelector_cls` -> `ConfiguracionActinver__c` -> Read -> frecuencias y volumen por segmento.
- `PSTA_PriorizacionSelector_cls` -> `BusinessHours` -> Read -> `Name = Postventa`.
- `PSTA_PriorizacionMensual_cls` -> `Account` -> Update -> `ContactoPriorizadoEsteMes__c`, `PriorizacionVisita__c`.
- `AccountTrigger` y clases relacionadas -> `Account` -> Before update indirecto -> `FechaSiguienteContacto__c`, `FechaSiguienteVisita__c`, `FechaNoRequiereSerContacto__c`, `Segmento__c`, `OwnerId`, `BanqueroAsignado__c`, `RecordTypeId` y otros derivados.

## 7. Registros creados, actualizados o no modificados
1. Actualiza `Account` de manera directa en `PSTA_SegmentacionClientes_cls.updateRecords(...)`.
2. Actualiza `Account` nuevamente en `PSTA_PriorizacionMensual_cls.updateRecords(...)`.
3. Inserta `WebServiceTrackingLog__c` solo cuando hay error de DML.
4. No inserta `Account` nuevas.
5. No actualiza `Contract`.
6. El `before update` de `AccountTrigger` puede ampliar el conjunto de campos modificados en la misma cuenta.

## 8. Riesgos, observaciones y puntos de auditoria
1. El scheduler no valida dia habil. Si el cron dispara en un dia no operativo, el proceso corre de todos modos.
2. La query dinamica vive en metadata; cambios en `PSTA_Consultas__mdt` cambian el universo de cuentas sin despliegue.
3. `Database.update(..., false)` permite avance parcial. Para auditoria es obligatorio revisar `WebServiceTrackingLog__c`.
4. El impacto final depende tambien de `AccountTrigger`, no solo del batch.
5. El batch mensual encadenado asume que las banderas fueron reseteadas correctamente por el batch principal; si `finish()` no corre, la priorizacion puede quedar inconsistente.

## 9. Complemento con documentacion tecnica del proveedor
1. El documento tecnico del proveedor ubica este proceso dentro de la base del modelo PostVenta porque de aqui salen la segmentacion del cliente, el calculo de cartera y varias fechas operativas usadas despues por priorizacion, cadencias, tareas y reportes.
2. La seccion de `Configuracion Actinver` del proveedor coincide con la implementacion observada: este flujo depende de parametros por segmento y de la configuracion de contratos validos para construir el universo funcional correcto.
3. La lista amplia de campos de `Account` descrita por el proveedor es compatible con la responsabilidad de este scheduler, aunque en esta linea base no se recupero toda la metadata declarativa del objeto.
4. Este proceso no crea tareas ni asigna cadencias directamente, pero prepara los datos de cuenta que luego consumen `PSTA_ResetearEstatusContacto`, `PV_GenerarTareasPeriodicas` y `PSTA_RegistroResumenGlobal`.
5. Las Lightning Pages de cuenta descritas por el proveedor quedan funcionalmente alimentadas por este scheduler, en especial las que muestran avance, segmento o widgets relacionados con gestion PostVenta.
6. El proveedor presenta la segmentacion como una sola capacidad funcional; la source confirma que en realidad esta distribuida entre scheduler, batch, selector, clase de calculo, helper de fechas, priorizacion mensual y trigger de cuenta.
7. En `actidev` ya existe un proceso complementario `PSTA_PostCargaPostventa_*` que no sustituye esta segmentacion mensual, pero si reevalua cuentas despues de la carga diaria cuando detecta cambios de owner o cambios de estatus en contratos por `AccountHistory` y `ContractHistory`.
8. Ese proceso post-carga reutiliza la misma logica base de contratos validos documentada aqui para decidir si una cuenta debe mantenerse o salir del circuito de PostVenta.
9. Para el panorama completo del modelo debe leerse este documento junto con `postventa_documentacion_tecnica_consolidada_2026-03-25.md`.
