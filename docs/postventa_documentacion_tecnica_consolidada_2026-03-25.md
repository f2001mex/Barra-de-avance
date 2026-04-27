# PostVenta - Documentacion tecnica consolidada

Fecha de consolidacion: 2026-04-01

## 1. Proposito

Este documento consolida dos fuentes:

- La documentacion tecnica entregada por el proveedor para el proyecto `Modelo postventa`.
- La implementacion realmente disponible en esta linea base del repo.

El objetivo es dejar una referencia maestra de PostVenta que sirva para:

- Entender la arquitectura funcional y tecnica de punta a punta.
- Relacionar los procesos batch, schedulers, triggers, flows y LWC.
- Separar lo que esta documentado por el proveedor de lo que si pudo verificarse en codigo fuente.
- Apoyarse en los analisis profundos ya existentes para los schedulers y Ficha de Afinidad.

## 2. Fuentes base usadas

### 2.1 Documento del proveedor

El documento del proveedor describe estas areas del modelo PostVenta:

- Introduccion, objetivo y audiencia.
- Modelo de datos.
- Personalizacion de objetos.
- Reglas de validacion.
- Lightning Pages.
- Eventos de plataforma.
- Reportes.
- Flujos.
- Apex.
- Lightning Web Components.
- Custom Metadata.
- Global Value Set.
- Permission Sets.
- Public Groups.

### 2.2 Implementacion revisada en el repo

Se verificaron principalmente estos componentes:

- `force-app/main/default/classes`
- `force-app/main/default/triggers`
- `force-app/main/default/flows`
- `force-app/main/default/flexipages`
- `force-app/main/default/lwc`
- `force-app/main/default/objects/Task/validationRules`

Ademas, este documento se apoya en los analisis profundos ya generados en `docs`:

- `1_PSTA_SegmentacionClientes_sch_fullcopy_ultra_detallado_2026-03-13.md`
- `2_PSTA_ResetearEstatusContacto_sch_fullcopy_ultra_detallado_2026-03-13.md`
- `3_PV_GenerarTareasPeriodicas_sch_fullcopy_ultra_detallado_2026-03-13.md`
- `4_PSTA_RegistroResumenGlobal_sch_fullcopy_ultra_detallado_2026-03-13.md`
- `implementacion_actualizacion_ficha_afinidad_2026-03-23.md`

## 3. Lectura recomendada de PostVenta

Para entender PostVenta en orden funcional conviene leerlo asi:

1. Segmentacion y enriquecimiento de cuentas.
2. Reinicio de estatus y priorizacion diaria.
3. Generacion y asignacion de cadencias.
4. Cierre de cadencias y creacion de tareas.
5. Actualizacion de cuenta al completar la tarea.
6. Registro del resumen global diario.
7. Reglas de Ficha de Afinidad.

## 4. Arquitectura consolidada del modelo PostVenta

### 4.1 Capa de negocio

El documento del proveedor describe correctamente el objetivo general del modelo:

- Guiar al asesor en sus tareas de contacto y seguimiento.
- Priorizar clientes por segmento.
- Registrar resultado de contacto.
- Suspender o reprogramar seguimiento segun el resultado.
- Dar visibilidad directiva del avance operativo.

En la implementacion del repo esto se materializa principalmente sobre:

- `Account`
- `Task`
- `Contract`
- `ActionCadence`
- `ActionCadenceTracker`
- `ActionCadenceStepTracker`
- `BranchUnitBusinessMember`
- `Banker`
- `ResumenGlobalPostventa__c`

### 4.2 Cadena principal de procesos programados

La linea base revisada muestra cuatro procesos programados centrales de PostVenta:

1. `PSTA_SegmentacionClientes_sch`
   Recalcula segmento, saldo integral, fechas base y campos de priorizacion mensual.

2. `PSTA_ResetearEstatusContacto_sch`
   Reestablece cuentas vencidas a estatus `Pendiente` y vuelve a preparar la priorizacion diaria.

3. `PV_GenerarTareasPeriodicas_sch`
   Evalua elegibilidad de cuentas, reglas de cadencias y manda la asignacion al flow `PV_AsignarCadencesCuentas_Flow`.

4. `PSTA_RegistroResumenGlobal_sch`
   Construye o actualiza el resumen global por banquero para meta y avance diario.

Cada uno de estos procesos ya tiene su documento tecnico detallado en `docs`.

### 4.3 Proceso complementario post-carga nocturna

Adicionalmente, en `actidev` ya quedo implementado un proceso nuevo de conciliacion post-carga para absorber cambios diarios provenientes del microservicio de actualizacion de clientes y contratos:

1. `PSTA_PostCargaPostventa_sch`
   Scheduler que dispara el batch nocturno.

2. `PSTA_PostCargaPostventa_bch`
   Batch que toma cuentas impactadas durante las ultimas 24 horas, pero no por modificacion general del registro, sino por historial de cambios en campos puntuales.

3. `PSTA_PostCargaPostventa_cls`
   Servicio que:
   - revalua contratos vigentes para PostVenta,
   - saca de priorizacion mensual y diaria a cuentas sin contratos validos,
   - recalcula saldo integral, fecha de antiguedad y segmento para cuentas que siguen vigentes,
   - reconcilia owner de tareas abiertas y oportunidades no cerradas sobre cuentas segmentadas con priorizacion mensual activa,
   - y prepara la limpieza o reasignacion de cadencias activas.

4. `PSTA_PostCargaPostventaCadencias_qbl`
   Queueable que remueve trackers `Running` con `removeTargetFromSalesCadence` y, cuando aplica, vuelve a asignar la cadencia al owner correcto.

5. `PSTA_PostCargaPostventa_soql`
   Selector de cuentas, contratos, tareas, oportunidades, trackers y resumenes.

6. `PSTA_PostCargaPostventa_Request`
   DTO interno para transportar instrucciones de remocion o reasignacion de cadencias.

Este proceso no sustituye a los cuatro schedulers centrales del modelo; funciona como un correctivo nocturno posterior a la carga masiva.

### 4.4 Cadena de tareas y cadencias

La arquitectura real observada para tareas y cadencias es:

1. `PV_GenerarTareasPeriodicas_sch` dispara el batch.
2. `PV_GenerarTareasPeriodicas_bch` construye la lista de requests de asignacion.
3. `PV_EjecutarAsignacionCadencias_Queueable` invoca `Flow.Interview.PV_AsignarCadencesCuentas_Flow`.
4. Salesforce asigna la cadencia al target.
5. `TriggerActionCadanceStepTracker.trigger` y su handler procesan la finalizacion de pasos.
6. `PSTA_GestionTareas_Helper` crea la tarea derivada del cierre de cadencia.
7. Se publica `PV_FinalizacionCadencia__e` para retroalimentar la UI.
8. El usuario completa la tarea.
9. `Task_trg` y `Task_thr` ejecutan `PSTA_ChangeAccountInfo_ctr/helper` para actualizar la cuenta.

### 4.5 Capa de interfaz

Lo verificado en el repo muestra esta capa declarativa de UI:

- `Postventa.flexipage-meta.xml`
- `Account_Privada.flexipage-meta.xml`
- `Account_PatrimonialRP1.flexipage-meta.xml`
- LWC `taskProgressBar`
- LWC `accountProgressBar`
- LWC `pV_GestionTarea_lwc`
- Flow de pantalla `PSTA_NuevoEventoTarea` referenciado desde la pagina `Postventa`

## 5. Matriz de cobertura: documento del proveedor vs repo

| Tema | Estado | Nota consolidada |
| --- | --- | --- |
| Objetivo general del modelo | Verificado | Coincide con la implementacion observada de segmentacion, priorizacion, cadencias y tareas. |
| Modelo de datos conceptual | Parcialmente verificado | La relacion funcional entre cuenta, tarea, contrato, cadencia y tracker si coincide con el codigo; no toda la metadata del modelo fue recuperada en el repo. |
| Campos de Account | Parcialmente verificado | El proveedor lista muchos campos, pero en esta linea base no se recupero la metadata completa de `Account`; su uso si aparece en Apex y flows. |
| Campos de Task | Parcialmente verificado | Se verifican en codigo `El_cliente_fue_contactado__c`, `ClienteNoQuiereSerContactado__c`, `DeveloperName__c`, `Avance_FAC__c`; no todos los field metadata estan en source. |
| Campos de ActionCadence | Parcialmente verificado | El proveedor describe `Periodicidad__c`, `GeneraContacto__c`, `RequiereCargaEvidencia__c`, `TareaUnicaPorCuenta__c`, `TareaUnicaPorContrato__c`; estos campos si son usados por Apex. |
| Configuracion Actinver | Parcialmente verificado | `ConfiguracionActinver__c` es pieza central en segmentacion, priorizacion y reinicios, pero la metadata del objeto no esta en esta linea base. |
| Resumen global postventa | Verificado funcionalmente | La clase `PSTA_RegistroResumenGlobal_cls` si construye y hace upsert sobre `ResumenGlobalPostventa__c`. |
| Reglas de validacion | Parcial | En source solo se verifico `Task.Avance_FAC_Validacion`; las demas reglas listadas por el proveedor no vienen en esta extraccion. |
| Lightning Pages | Parcialmente verificado | Existen `Postventa`, `Account_Privada` y `Account_PatrimonialRP1`; no se encontro `Account wealth record page` en esta linea base. |
| Eventos de plataforma | Parcialmente verificado | `PV_FinalizacionCadencia__e` si esta usado por Apex y LWC; `UpdateTask__c` se describe en el documento pero no aparecio en la source recuperada. |
| Reportes | No verificable en esta linea base | El documento los lista, pero no hay metadata de `reports` recuperada en este repo. |
| Flujos | Verificado con diferencias | Estan en source `Flow_Avance_FAC`, `FAC_Task_Update_InTask`, `FAC_Task_Update_InAccount`, `FAC_Update_Task_Field_Avence`, `PV_AsignarCadencesCuentas_Flow`; dos de ellos estan `Obsolete`. |
| Apex | Verificado en gran parte | La mayoria del inventario principal de PostVenta si esta presente en `classes` y `triggers`. |
| Job nocturno post-carga | Verificado en dev | Ya existe implementacion Apex nueva para depuracion post-carga y reconciliacion de owner en `actidev`; aun no queda programado en el org. |
| LWC | Parcialmente verificado | Existen `accountProgressBar`, `taskProgressBar` y `pV_GestionTarea_lwc`; el componente `pv_FileUpload_LWC` es referenciado por la flexipage pero no vino en esta linea base. |
| Custom Metadata | Parcialmente verificado | `PSTA_Consultas__mdt` y `WebServiceInfo__mdt` si estan referenciados por Apex, pero sus archivos metadata no fueron recuperados aqui. |
| Global Value Set | No verificable en esta linea base | El documento menciona `TipoTarea`, pero no existe carpeta `globalValueSets` en esta extraccion. |
| Permission Sets | No verificable en esta linea base | El documento lista tres permission sets de PostVenta, pero no estan presentes en la source recuperada. |
| Public Groups | No verificable en esta linea base | El documento lista grupos publicos, pero no hay metadata de grupos en esta extraccion. |

## 6. Inventario tecnico consolidado

### 6.1 Flujos verificados

| Flow | Tipo | Estado en source | Uso consolidado |
| --- | --- | --- | --- |
| `Flow_Avance_FAC` | Record-triggered sobre `Account` | `Active` | Calcula base y llenado de Ficha de Afinidad. |
| `FAC_Task_Update_InTask` | Record-triggered sobre `Task` | `Active` | Si la cuenta ya esta al 100%, marca la tarea FAC como contactada al crearla. |
| `FAC_Task_Update_InAccount` | Record-triggered sobre `Account` | `Obsolete` | Permanece en source, pero no es la version activa. |
| `FAC_Update_Task_Field_Avence` | Record-triggered sobre `Account` | `Obsolete` | Flujo historico en source; no debe asumirse como logica vigente. |
| `PV_AsignarCadencesCuentas_Flow` | Autolaunched | `Active` | Usa la accion estandar `assignTargetToSalesCadence`. |

### 6.2 Triggers y clases Apex principales de PostVenta

#### Segmentacion y priorizacion

- `PSTA_SegmentacionClientes_sch`
- `PSTA_SegmentacionClientes_bch`
- `PSTA_SegmentacionClientes_cls`
- `PSTA_SegmentacionClientesSelector_cls`
- `PSTA_FechaPrimerContacto_cls`
- `PSTA_Segmentacion_cls`
- `PSTA_AgrupacionPriorizacionMensual_bch`
- `PSTA_PriorizacionMensual_cls`
- `PSTA_ResetearEstatusContacto_sch`
- `PSTA_ResetearEstatusContacto_bch`
- `PSTA_ResetearEstatusContacto_cls`
- `PSTA_AgrupacionPriorizacionDiaria_bch`
- `PSTA_PriorizacionDiaria_cls`
- `PSTA_PriorizacionSelector_cls`

#### Cadencias, tareas y actualizacion de cuenta

- `PV_GenerarTareasPeriodicas_sch`
- `PV_GenerarTareasPeriodicas_bch`
- `PV_GenerarTareasPeriodicas`
- `PV_GenerarTareasPeriodicasSelector_cls`
- `PV_GenerarTareasPeriodicas_Request`
- `PV_EjecutarAsignacionCadencias_Queueable`
- `TriggerActionCadanceStepTracker.trigger`
- `TriggerActionCadenceStepTracker_thr`
- `PSTA_GestionTareas_Helper`
- `PSTA_GestionTareas_soql`
- `Task_trg`
- `Task_thr`
- `PSTA_ChangeAccountInfo_ctr`
- `PSTA_ChangeAccountInfo_helper`
- `PSTA_ChangeAccountInfo_soql`

#### Resumen global

- `PSTA_RegistroResumenGlobal_sch`
- `PSTA_RegistroResumenGlobal_bch`
- `PSTA_RegistroResumenGlobal_cls`

#### Conciliacion post-carga

- `PSTA_PostCargaPostventa_sch`
- `PSTA_PostCargaPostventa_bch`
- `PSTA_PostCargaPostventa_cls`
- `PSTA_PostCargaPostventa_soql`
- `PSTA_PostCargaPostventaCadencias_qbl`
- `PSTA_PostCargaPostventa_Request`

#### Integraciones y extensiones relacionadas

- `PV_FileUpload_ctr`
- `PV_FileUpload_soql`
- `PV_OpenText_Request`
- `PV_OpenText_Response`
- `PSTA_EnvioEncuestaMedallia_cls`
- `PSTA_EnvioEncuestaMedallia_ctr`
- `PSTA_EnvioEncuestaMedallia_soql`
- `PSTA_EnvioEncuestaMedallia_Mockup`
- `PV_EnvioEncuestaMedallia_Action_cls`
- `PSTA_FACCadenceCompletion_cls`

### 6.3 LWC y paginas

#### Pagina de tarea Postventa

La flexipage `Postventa` muestra:

- `pv_FileUpload_LWC`
- `taskProgressBar`
- flow `PSTA_NuevoEventoTarea`

Notas:

- El flow `PSTA_NuevoEventoTarea` se muestra cuando `El_cliente_fue_contactado__c = No` y `ClienteNoQuiereSerContactado__c = false`.
- `taskProgressBar` expone visualmente `Task.Avance_FAC__c`.
- El componente `pv_FileUpload_LWC` esta referenciado por la pagina, pero su source no viene en esta linea base.

#### Paginas de cuenta

Las flexipages `Account_Privada` y `Account_PatrimonialRP1` si muestran:

- `accountProgressBar`
- `pV_GestionTarea_lwc`

`pV_GestionTarea_lwc` escucha el canal `/event/PV_FinalizacionCadencia__e` y muestra un toast con liga a la tarea creada cuando la cadencia termina para el mismo usuario y la misma cuenta.

### 6.4 Logica del job post-carga implementado en dev

La implementacion nueva en `actidev` trabaja asi:

1. Detecta cuentas impactadas mediante `Field History`, no mediante `LastModifiedDate` general.
2. Consulta `AccountHistory` para los campos:
   - `Owner`
   - `OwnerId`
   - `ID_Asesor__c`
3. Consulta `ContractHistory` para los campos:
   - `Status__c`
   - `Owner`
   - `OwnerId`
   - `ID_ASESOR__c`
4. Reune los `AccountId` afectados en una ventana movil de 24 horas.
5. Reconsulta la cuenta completa con sus contratos.
6. Considera contratos validos solo si cumplen con:
   - `Status__c` dentro de `ConfiguracionActinver__c.EstatusContrato__c`
   - `TypeOfContract__c` dentro de `ConfiguracionActinver__c.TipoContratos__c`
   - `Saldo__c` no nulo
   - `AccountOpeningDate__c` no nula
7. Si una cuenta queda en `0` contratos validos:
   - `ContactoPriorizadoEsteMes__c = false`
   - `PriorizacionContacto__c = false`
   - `PriorizacionVisita__c = false`
   - remueve cadencias activas
8. Si la cuenta conserva contratos validos:
   - recalcula `SaldoIntegral__c`
   - recalcula `FechaAntiguedad__c`
   - recalcula `Segmento__c`
9. Solo si la cuenta sigue valida, tiene `Segmento__c` y `ContactoPriorizadoEsteMes__c = true`, reconcilia:
   - `Task` abiertas contra `Account.OwnerId`
   - `Opportunity` no cerradas contra `Account.OwnerId`
   - `ActionCadenceTracker` `Running` contra `Account.OwnerId`
10. Al finalizar, refresca `Meta__c` de `ResumenGlobalPostventa__c` para los asesores impactados.

Estado actual en dev:

- desplegado satisfactoriamente a `actidev`
- pruebas unitarias `PSTA_PostCargaPostventa_tst` exitosas
- scheduler aun no programado

### 6.5 Reglas y validaciones verificadas

La validacion confirmada en source es:

- `Task.Avance_FAC_Validacion`

Logica observada:

- Aplica a tareas `Postventa`.
- Aplica al asunto `Ficha de afinidad con el cliente`.
- Bloquea guardar `El_cliente_fue_contactado__c = "Si"` si `Avance_FAC__c < 100%`.

Mensaje actual en source:

`La ficha de afinidad no ha sido completada al 100%`

### 6.6 Eventos y mensajeria

#### Verificados en codigo

- `PV_FinalizacionCadencia__e`

Uso real observado:

- Se publica desde `PSTA_GestionTareas_Helper`.
- Tambien es usado por `PSTA_FACCadenceCompletion_cls`.
- Lo consume `pV_GestionTarea_lwc` para mostrar confirmacion al usuario.

#### Referenciados por el proveedor pero no verificados en esta source

- `UpdateTask__c`
- Los grupos publicos de PostVenta.
- Los reportes listados en el documento.

## 7. Ficha de Afinidad dentro del modelo PostVenta

El documento del proveedor la menciona dentro del contexto de tareas, validaciones y UI. En esta linea base la funcionalidad de Ficha de Afinidad ya tiene suficiente evidencia para consolidarla como parte formal del modelo:

- `Flow_Avance_FAC` calcula aplicables y respondidas en `Account`.
- `Task.Avance_FAC__c` refleja el avance en la tarea.
- `taskProgressBar` muestra ese avance en la pagina `Postventa`.
- `FAC_Task_Update_InTask` sigue activo.
- `FAC_Task_Update_InAccount` y `FAC_Update_Task_Field_Avence` siguen en source, pero en estado `Obsolete`.
- `Avance_FAC_Validacion` impide marcar contacto exitoso si la ficha no llego a `100%`.

Para el detalle completo de esta parte debe tomarse como referencia principal:

- `implementacion_actualizacion_ficha_afinidad_2026-03-23.md`

## 8. Hallazgos importantes al consolidar

### 8.1 El documento del proveedor es util como inventario, no como fuente unica de verdad

Sirve muy bien para:

- conocer el alcance funcional original,
- ubicar nombres de componentes,
- y entender el modelo operativo esperado.

Pero no debe tomarse como reflejo exacto de la implementacion activa sin contrastarlo con source u org, porque:

- mezcla componentes activos con componentes historicos u obsoletos,
- lista metadata que no esta en esta extraccion,
- y en algunos casos usa nombres que no coinciden exactamente con la source actual.

### 8.2 Hay diferencias puntuales entre documento y source

- El proveedor lista `PV_GestionTareas_LWC`, pero en source existe `pV_GestionTarea_lwc`.
- El proveedor lista `FAC_Task_Update_InAccount` y `FAC_Update_Task_Field_Avence` como parte del inventario, pero ambos aparecen `Obsolete`.
- La flexipage `Postventa` referencia `pv_FileUpload_LWC`, pero el componente no viene en esta linea base.
- La metadata de objetos y configuraciones declarativas de `Account`, `ConfiguracionActinver__c`, `ResumenGlobalPostventa__c`, reportes, permission sets y grupos no fue recuperada en este repo.

### 8.3 La implementacion real esta mas desacoplada de lo que sugiere el documento

El documento del proveedor presenta PostVenta como un modulo relativamente compacto. La source muestra algo mas distribuido:

- schedulers y batches para preparar cuentas,
- flow y queueable para asignar cadencias,
- trigger sobre step tracker para materializar tareas,
- trigger sobre task para devolver resultado a la cuenta,
- eventos de plataforma para retroalimentar la interfaz,
- y reglas especificas para Ficha de Afinidad y carga documental.

### 8.4 El proceso post-carga ya agrega una capa correctiva fuera del flujo mensual/diario original

La version implementada en `actidev` introduce una capa nueva que no aparece en la documentacion original del proveedor:

- no compite con la segmentacion mensual ni con la priorizacion diaria,
- pero si corrige efectos posteriores a la carga masiva diaria,
- especialmente para contratos que dejan de ser validos y para desalineaciones de owner entre cuenta, tareas, oportunidades y cadencias.

Punto abierto de negocio:

- la reconciliacion automatica de `Opportunity` ya esta implementada en dev para cuentas elegibles, pero debe confirmarse con operacion si siempre debe seguir `Account.OwnerId`, ya que existen casos reportados donde un asesor crea oportunidades en cuentas de otro owner como parte normal del proceso comercial.

## 9. Recomendacion de uso futuro

Para futuras revisiones de PostVenta conviene usar este orden de fuentes:

1. Este documento consolidado para contexto general.
2. Los cuatro documentos detallados de schedulers para el comportamiento batch.
3. El documento de Ficha de Afinidad para FAC.
4. La org o una recuperacion mas completa de metadata declarativa para:
   reportes, permission sets, grupos, fields de Account, fields de Task, custom metadata y custom objects.

## 10. Conclusion

El documento del proveedor si aporta una buena vista funcional y un inventario inicial del modulo PostVenta, pero la fuente mas confiable para explicar la implementacion vigente en esta linea base sigue siendo la combinacion de:

- el codigo Apex y los triggers del repo,
- los flows y flexipages recuperados,
- las validaciones disponibles en source,
- y los analisis profundos ya generados en `docs`.

Este archivo deja integrada esa vision y funciona como indice tecnico consolidado de PostVenta.
