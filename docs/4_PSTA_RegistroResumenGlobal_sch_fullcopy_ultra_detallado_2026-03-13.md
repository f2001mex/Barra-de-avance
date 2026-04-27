# PSTA_RegistroResumenGlobal_sch - Analisis ultra detallado
Ambiente: fullcopy | Fecha de elaboracion: 2026-03-13

## 1. Alcance y ejecucion en fullcopy
Este documento describe el flujo de `PSTA_RegistroResumenGlobal_sch` en fullcopy. El proceso construye o actualiza un resumen global por banquero/miembro de negocio a partir de `BranchUnitBusinessMember`, cuentas priorizadas y reglas de dias habiles. Su impacto principal es sobre `ResumenGlobalPostventa__c`.

- Schedule Job: `PSTA_RegistroResumenGlobal`
- CronExpression: `0 0 4 ? * 2,3,4,5,6,7`
- TimesTriggered: `1`
- NextFireTime UTC: `2026-03-14T10:00:00.000+0000`
- State: `WAITING`
- Label usado: `PSTA_Resumen_Global_Registros = 200`
- ACT_BatchConfig__mdt: `PSTA_RegistroResumenGlobal -> BusinessHoursName__c = Postventa`

## 2. Resumen ejecutivo del flujo
1. El scheduler consulta `ACT_BatchConfig__mdt` para `PSTA_RegistroResumenGlobal`.
2. Si `ACT_BusinessHoursHelper_cls` determina que el dia es habil segun `BusinessHours Postventa`, ejecuta `PSTA_RegistroResumenGlobal_bch`.
3. El batch obtiene desde `PSTA_Consultas__mdt` la query `PSTA_Query_Registro_Resumen_Global` para consultar `BranchUnitBusinessMember`.
4. Por cada `BranchUnitBusinessMember`, el codigo castea `BusinessUnitMember` a `Banker` y toma `ExternalId__c`.
5. `PSTA_RegistroResumenGlobal_cls.getMetaByAccount()` cuenta cuentas `Account` por asesor donde `ContactoPriorizadoEsteMes__c = true`, `PriorizacionContacto__c = true` y `EstatusContacto__c = 'Pendiente'`.
6. `PSTA_RegistroResumenGlobal_cls.getUserIds()` mapea `Banker.ExternalId__c` a `User.Id` activo usando `User.ID_ASESOR__c`.
7. El batch construye `ResumenGlobalPostventa__c` con `Name`, `Fecha__c`, `Banker__c`, `OwnerId`, `ExternalId_Nomina__c`, `Contactados__c = 0` y `Meta__c`.
8. La persistencia se hace con `Database.upsert(lstRecords, ResumenGlobalPostventa__c.ExternalId_Nomina__c, false)`.
9. Existe una lectura adicional de `getResumenesActuales()`, pero el mapa retornado no se usa despues dentro del flujo observado.

## 3. Diagrama del flujo completo
```text
PSTA_RegistroResumenGlobal_sch.execute(ctx)
  -> ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
         'PSTA_RegistroResumenGlobal',
         new PSTA_RegistroResumenGlobal_bch(),
         Label.PSTA_Resumen_Global_Registros)

PSTA_RegistroResumenGlobal_bch.start(bc)
  -> si Test.isRunningTest(): query hardcodeada
  -> si no: PSTA_SegmentacionClientesSelector_cls.getQueryAllBBM()
  -> SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Registro_Resumen_Global'
  -> Database.query(query)

PSTA_RegistroResumenGlobal_bch.execute(bc, scope)
  -> scope = List<BranchUnitBusinessMember>
  -> obtiene lista de ExternalId__c de banker
  -> PSTA_RegistroResumenGlobal_cls.getMetaByAccount(lstBanqueros)
     -> Aggregate sobre Account agrupando por ID_Asesor__c
  -> PSTA_RegistroResumenGlobal_cls.getResumenesActuales()
     -> SELECT Id, ExternalId_Nomina__c, Meta__c, Contactados__c FROM ResumenGlobalPostventa__c
     -> mapa no usado despues
  -> PSTA_RegistroResumenGlobal_cls.getUserIds()
     -> Banker.ExternalId__c -> User.ID_ASESOR__c -> User.Id
  -> por cada BBM crea ResumenGlobalPostventa__c
     -> Name = banker.Name
     -> Fecha__c = hoy
     -> Banker__c = BranchUnitBusinessMember.Id
     -> OwnerId = User.Id mapeado
     -> ExternalId_Nomina__c = banker.ExternalId__c
     -> Contactados__c = 0
     -> Meta__c = conteo de cuentas pendientes/priorizadas
  -> PSTA_RegistroResumenGlobal_cls.upsertRecords(lstResumenesUpsert)
     -> Database.upsert(lstRecords, ExternalId_Nomina__c, false)
     -> EventLogger.error(...) si hay errores
```

## 4. Detalle por clase y metodo
### 4.1 PSTA_RegistroResumenGlobal_sch
1. Implementa `Schedulable`.
2. `execute()` delega a `ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay('PSTA_RegistroResumenGlobal', new PSTA_RegistroResumenGlobal_bch(), Integer.valueOf(System.Label.PSTA_Resumen_Global_Registros))`.
3. No hace DML directo.

### 4.2 ACT_BusinessHoursHelper_cls en este flujo
1. Lee `ACT_BatchConfig__mdt` con `DeveloperName = PSTA_RegistroResumenGlobal`.
2. Recupera `BusinessHoursName__c = Postventa`.
3. Resuelve el `BusinessHours.Id`.
4. Valida si la fecha actual es dia habil con `BusinessHours.nextStartDate(...)`.
5. Solo si la validacion es positiva ejecuta el batch.

### 4.3 PSTA_RegistroResumenGlobal_bch
1. Implementa `Database.Batchable<SObject>`.
2. `start()` usa una query hardcodeada solo cuando `Test.isRunningTest()`.
3. En runtime real usa `PSTA_SegmentacionClientesSelector_cls.getQueryAllBBM()`.
4. `execute()` castea el scope a `List<BranchUnitBusinessMember>`.
5. Recorre el scope y extrae `Banker.ExternalId__c` desde `BusinessUnitMember`.
6. Llama tres metodos de servicio:
7. `getMetaByAccount(lstBanqueros)`.
8. `getResumenesActuales()`.
9. `getUserIds()`.
10. Luego construye la lista `lstResumenesUpsert`.
11. Finalmente llama `PSTA_RegistroResumenGlobal_cls.upsertRecords(lstResumenesUpsert)`.
12. `finish()` solo deja debug.

### 4.4 PSTA_RegistroResumenGlobal_cls
1. `getResumenesActuales()` consulta todos los `ResumenGlobalPostventa__c` con campos `Id`, `ExternalId_Nomina__c`, `Meta__c`, `Contactados__c`.
2. Crea un mapa `ExternalId_Nomina__c -> SObject`.
3. En la version fullcopy analizada, ese mapa no se reutiliza despues dentro de `execute()`. Es una lectura redundante o reservada para futura logica.
4. `getMetaByAccount(List<String> lstAsesores)` hace un `AggregateResult` sobre `Account` agrupando por `ID_Asesor__c`.
5. La condicion exacta del aggregate es:
6. `ID_Asesor__c IN :lstAsesores`.
7. `ID_Asesor__c != null`.
8. `ContactoPriorizadoEsteMes__c = true`.
9. `PriorizacionContacto__c = true`.
10. `EstatusContacto__c = 'Pendiente'`.
11. El valor resultante se guarda como `Meta__c` del resumen.
12. `getAllDivisions()` consulta `ConfiguracionActinver__c` donde `ClientesContactarPorDia__c != null` y arma un mapa `Segmento__c -> ClientesContactarPorDia__c`; en el flujo observado este metodo no es usado por el batch.
13. `getUserIds()` consulta todos los `Banker` con `ExternalId__c != null`, arma un set de external ids y luego consulta `User` activos donde `ID_ASESOR__c IN :externalIdsBankers`.
14. El resultado final es un mapa `ExternalId__c -> User.Id`.
15. `upsertRecords(List<SObject>)` ejecuta `Database.upsert(lstRecords, ResumenGlobalPostventa__c.ExternalId_Nomina__c, false)`.
16. Si algun registro falla, registra el error con `EventLogger.error(...)`.
### 4.5 PSTA_SegmentacionClientesSelector_cls en este flujo
1. Aunque su nombre refiere segmentacion, la clase expone `getQueryAllBBM()`.
2. Ese metodo consulta `PSTA_Consultas__mdt` con `DeveloperName = PSTA_Query_Registro_Resumen_Global`.
3. La query recuperada en fullcopy usa `TYPEOF BusinessUnitMember WHEN Banker THEN Division__c, Cargo__c, ExternalId__c, Id, Name END`.
4. Esa estructura permite leer atributos propios del `Banker` dentro de la consulta de `BranchUnitBusinessMember`.

## 5. Como consulta metadata y como la utiliza
### 5.1 ACT_BatchConfig__mdt
1. El scheduler usa la clave `PSTA_RegistroResumenGlobal`.
2. El helper recupera `BusinessHoursName__c = Postventa`.
3. Ese valor controla si el batch corre o se inhibe.

### 5.2 PSTA_Consultas__mdt
1. `getQueryAllBBM()` obtiene `PSTA_Query_Registro_Resumen_Global`.
2. La query trabaja sobre `BranchUnitBusinessMember` y usa `TYPEOF BusinessUnitMember` para traer datos del `Banker`.
3. Cambiar esa metadata cambia el universo de miembros de negocio procesados sin despliegue.

```sql
SELECT Consulta__c
FROM PSTA_Consultas__mdt
WHERE DeveloperName = 'PSTA_Query_Registro_Resumen_Global'
```

### 5.3 ConfiguracionActinver__c
1. En este flujo no es necesaria para crear el resumen principal.
2. Existe `getAllDivisions()` que la consulta por `ClientesContactarPorDia__c`, pero el batch actual no la usa.
3. Por lo tanto, `ConfiguracionActinver__c` es una dependencia disponible en la clase, no una dependencia efectiva del flujo ejecutado por el scheduler.

### 5.4 Custom Labels
1. `PSTA_Resumen_Global_Registros = 200` controla el tamano del batch.

## 6. Matriz exacta clase -> objeto -> operacion -> campos
- `PSTA_RegistroResumenGlobal_sch` -> `ACT_BatchConfig__mdt` -> Read -> `BusinessHoursName__c` via helper.
- `ACT_BusinessHoursHelper_cls` -> `BusinessHours` -> Read -> `Name = Postventa`, `Id`.
- `PSTA_SegmentacionClientesSelector_cls.getQueryAllBBM` -> `PSTA_Consultas__mdt` -> Read -> `PSTA_Query_Registro_Resumen_Global`.
- `PSTA_RegistroResumenGlobal_bch` -> `BranchUnitBusinessMember` -> Read -> `Id`, `BusinessUnitMemberId`, `TYPEOF BusinessUnitMember`.
- `PSTA_RegistroResumenGlobal_cls.getMetaByAccount` -> `Account` -> Aggregate Read -> `ID_Asesor__c`, conteo de cuentas con `ContactoPriorizadoEsteMes__c = true`, `PriorizacionContacto__c = true`, `EstatusContacto__c = 'Pendiente'`.
- `PSTA_RegistroResumenGlobal_cls.getResumenesActuales` -> `ResumenGlobalPostventa__c` -> Read -> `Id`, `ExternalId_Nomina__c`, `Meta__c`, `Contactados__c`.
- `PSTA_RegistroResumenGlobal_cls.getUserIds` -> `Banker` -> Read -> `ExternalId__c`, `Division__c`, `Cargo__c`.
- `PSTA_RegistroResumenGlobal_cls.getUserIds` -> `User` -> Read -> `Id`, `Name`, `ID_ASESOR__c`, `IsActive`.
- `PSTA_RegistroResumenGlobal_bch` -> `ResumenGlobalPostventa__c` -> Prepare upsert -> `Name`, `Fecha__c`, `Banker__c`, `OwnerId`, `ExternalId_Nomina__c`, `Contactados__c`, `Meta__c`.
- `PSTA_RegistroResumenGlobal_cls` -> `ResumenGlobalPostventa__c` -> Upsert -> llave externa `ExternalId_Nomina__c`.
- `EventLogger` -> `WebServiceTrackingLog__c` -> Insert solo en error -> detalle tecnico del fallo.

## 7. Registros creados, actualizados o no modificados
1. Inserta `ResumenGlobalPostventa__c` si no existe un registro con la misma `ExternalId_Nomina__c`.
2. Actualiza `ResumenGlobalPostventa__c` si ya existe un registro con esa llave externa.
3. No actualiza `Account`, `Contract` ni `BranchUnitBusinessMember` en el flujo principal observado.
4. Inserta `WebServiceTrackingLog__c` solo en caso de error.
5. `getResumenesActuales()` realiza lectura de `ResumenGlobalPostventa__c`, pero esa lectura hoy no cambia el comportamiento observable del upsert.

## 8. Riesgos, observaciones y puntos de auditoria
1. `getResumenesActuales()` es un hallazgo tecnico: hoy consulta datos que luego no utiliza el batch.
2. La llave externa `ExternalId_Nomina__c` es critica. Si hay mala calidad de datos, el upsert puede insertar duplicados funcionales o actualizar el resumen equivocado.
3. La meta (`Meta__c`) no viene de metadata sino de un conteo vivo sobre `Account`; por eso el resultado depende del estado real de priorizacion al momento de correr el batch.
4. El helper de business hours puede impedir la ejecucion real aunque el job exista en `CronTrigger`.
5. La query base esta en metadata; cambios en `PSTA_Query_Registro_Resumen_Global` alteran el conjunto de banqueros procesados sin despliegue.

## 9. Complemento con documentacion tecnica del proveedor
1. Este flujo corresponde directamente a la entidad `Resumen global postventa` descrita por el proveedor como base para control, avance y reporteo por asesor o banquero.
2. La descripcion de campos del proveedor coincide con la estructura observada en el batch: `Banker__c`, `Contactados__c`, `ExternalId_Nomina__c`, `Fecha__c`, `Meta__c` y el porcentaje derivado.
3. La relacion con tableros y reportes tambien es consistente con el documento del proveedor, aunque en esta linea base no se recupero la metadata de `reports` ni `dashboards`.
4. El proveedor lista un flow `PV_ActualizaResumenPostventa` para incrementar `Contactados__c` cuando una tarea se marca como contacto exitoso; ese comportamiento no se pudo verificar en esta extraccion del repo, por lo que debe tratarse como inventario documental no confirmado aqui.
5. Lo que si esta confirmado es que este scheduler prepara la base diaria del resumen usando cuentas priorizadas y pendientes, y hace `upsert` por `ExternalId_Nomina__c`.
6. El resultado funcional de este scheduler depende del estado previo que dejan la segmentacion, la priorizacion mensual, la priorizacion diaria y las tareas completadas por los asesores.
7. En `actidev` el proceso complementario `PSTA_PostCargaPostventa_*` ya refresca `Meta__c` en `ResumenGlobalPostventa__c` para los asesores impactados por cambios detectados en `AccountHistory` y `ContractHistory`.
8. Eso permite corregir la meta operativa sin esperar a que vuelva a correr el scheduler principal del resumen, especialmente cuando una cuenta sale de PostVenta despues de la carga diaria por quedarse sin contratos validos.
9. Para una lectura cerrada del modelo este documento debe enlazarse con `3_PV_GenerarTareasPeriodicas_sch_fullcopy_ultra_detallado_2026-03-13.md` y con `postventa_documentacion_tecnica_consolidada_2026-03-25.md`.
