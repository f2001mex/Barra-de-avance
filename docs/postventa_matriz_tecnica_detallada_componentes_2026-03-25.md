# PostVenta - Matriz tecnica detallada de componentes

Fecha de elaboracion: 2026-04-01

## 1. Alcance

Esta matriz lista los componentes productivos de PostVenta identificados en la linea base del repo y resume, para cada uno:

- tipo de componente,
- prueba asociada cuando existe,
- responsabilidad principal,
- objetos o artefactos sobre los que opera,
- y observaciones de uso dentro del modelo.

No se incluyen todas las clases de prueba como filas independientes. En su lugar, se referencian desde la columna `Prueba asociada`.

## 2. Scheduler, batch y priorizacion

| Componente | Tipo | Prueba asociada | Responsabilidad principal | Objetos / dependencias clave | Observaciones |
| --- | --- | --- | --- | --- | --- |
| `PSTA_SegmentacionClientes_sch` | Apex scheduler | `PSTA_SegmentacionClientes_sch_tst` | Dispara el batch principal de segmentacion. | `Label.PSTA_Segmentacion_Registros_Batch` | No valida business hours. |
| `PSTA_SegmentacionClientes_bch` | Apex batch | `PSTA_SegmentacionClientes_bch_tst` | Consulta cuentas elegibles y delega el recalculo. | `Account`, `PSTA_Consultas__mdt` | Encadena priorizacion mensual al finalizar. |
| `PSTA_SegmentacionClientes_cls` | Apex service | `PSTA_SegmentacionClientes_cls_tst` | Orquesta la segmentacion y persiste updates parciales. | `Account`, `Database.update`, `EventLogger` | Punto central de persistencia del batch. |
| `PSTA_SegmentacionClientesSelector_cls` | Apex selector | `PSTA_SegmentacionClientesSel_cls_tst` | Obtiene queries y configuracion del flujo de segmentacion y resumen global. | `PSTA_Consultas__mdt`, `ConfiguracionActinver__c`, `Account`, `Contract` | Tambien expone `getQueryAllBBM()` y `getQueryStatusCuentas()`. |
| `PSTA_FechaPrimerContacto_cls` | Apex service | `PSTA_FechaPrimerContacto_cls_tst` | Calcula saldo integral, antiguedad y fechas base con contratos validos. | `Account`, `Contract`, `ConfiguracionActinver__c` | Resetea banderas mensuales antes de persistir. |
| `PSTA_Segmentacion_cls` | Apex service | `PSTA_Segmentacion_cls_tst` | Resuelve el segmento funcional del cliente a partir del banker. | `Banker`, `ConfiguracionActinver__c` | Reutilizado tambien desde trigger de cuenta. |
| `PSTA_AgrupacionPriorizacionMensual_bch` | Apex batch | `PSTA_AgrupacionPriorizacionMensual_tst` | Reconstruye la priorizacion mensual al terminar la segmentacion. | `Account`, `PSTA_Consultas__mdt` | Se ejecuta en `finish()` del batch principal. |
| `PSTA_PriorizacionMensual_cls` | Apex service | `PSTA_PriorizacionMensual_cls_tst` | Determina que cuentas quedan priorizadas en el mes y si requieren visita. | `Account`, `ConfiguracionActinver__c`, `BusinessHours` | Consume reglas por segmento. |
| `PSTA_PriorizacionSelector_cls` | Apex selector | `PSTA_PriorizacionSelector_cls_tst` | Centraliza queries de priorizacion diaria y mensual. | `PSTA_Consultas__mdt`, `ConfiguracionActinver__c`, `BusinessHours` | Selector comun a multiples procesos de PostVenta. |
| `PSTA_ResetearEstatusContacto_sch` | Apex scheduler | `PSTA_ResetearEstatusContacto_sch_tst` | Lanza el reinicio de estatus solo si el dia es habil. | `ACT_BatchConfig__mdt`, `BusinessHours`, custom label | Usa `ACT_BusinessHoursHelper_cls`. |
| `PSTA_ResetearEstatusContacto_bch` | Apex batch | `PSTA_ResetearEstatusContacto_bch_Test` | Lee cuentas vencidas y delega el reset de estatus. | `Account`, `PSTA_Consultas__mdt` | Encadena priorizacion diaria. |
| `PSTA_ResetearEstatusContacto_cls` | Apex service | `PSTA_ResetearEstatusContacto_cls_Test` | Cambia `EstatusContacto__c` a `Pendiente` y baja la bandera diaria. | `Account` | No toca fechas directamente. |
| `PSTA_AgrupacionPriorizacionDiaria_bch` | Apex batch | `PSTA_AgrupacionPriorizacionDiaria_tst` | Recorre cuentas listas para priorizacion diaria. | `Account`, `PSTA_Consultas__mdt` | Stateful para llevar conteo por asesor. |
| `PSTA_PriorizacionDiaria_cls` | Apex service | `PSTA_PriorizacionDiaria_cls_tst` | Marca `PriorizacionContacto__c` segun reglas de dia y cupo por asesor. | `Account`, `ConfiguracionActinver__c`, `BusinessHours` | La frecuencia se recibe como parametro, pero el filtro final observado usa dias habiles `>= 0`. |
| `PSTA_ComparadorSaldos_cls` | Apex comparator | `PSTA_ComparadorSaldos_cls_tst` | Ordena cuentas por `SaldoIntegral__c` descendente. | `Account.SaldoIntegral__c` | Utileria de apoyo para priorizacion. |
| `PSTA_ListaClientesSelector_cls` | Apex selector | `PSTA_ListaClientesSelector_cls_tst` | Apoya consultas auxiliares para calculos de listado y fechas. | `Account`, configuracion asociada | Se usa desde la logica de listado de clientes. |
| `PSTA_ListadoClientes_cls` | Apex service | `PSTA_ListadoClientes_tst` | Recalcula fechas siguientes y reglas operativas del listado de clientes. | `Account`, `ConfiguracionActinver__c`, `BusinessHours` | Es una pieza indirecta clave via `PSTA_Account_thr`. |
| `PSTA_Account_thr` | Apex trigger handler | `PSTA_Account_thr_tst` | Handler de PostVenta para cambios de cuenta. | `Account` | Recalcula fechas y segmento en updates de cuenta. |
| `PSTA_RegistroResumenGlobal_sch` | Apex scheduler | `PSTA_RegistroResumenGlobal_sch_tst` | Dispara el resumen global diario si el calendario habil lo permite. | `ACT_BatchConfig__mdt`, `BusinessHours`, custom label | Controlado por helper de business hours. |
| `PSTA_RegistroResumenGlobal_bch` | Apex batch | `PSTA_RegistroResumenGlobal_bch_Test` | Consulta miembros de negocio y arma resumenes a upsert. | `BranchUnitBusinessMember`, `PSTA_Consultas__mdt` | Trabaja por banquero / external id. |
| `PSTA_RegistroResumenGlobal_cls` | Apex service | `PSTA_RegistroResumenGlobal_cls_Test` | Cuenta metas y hace `upsert` sobre `ResumenGlobalPostventa__c`. | `ResumenGlobalPostventa__c`, `Account`, `Banker`, `User` | Usa llave externa `ExternalId_Nomina__c`. |
| `PSTA_PostCargaPostventa_sch` | Apex scheduler | `PSTA_PostCargaPostventa_tst` | Dispara el proceso nocturno correctivo posterior a la carga masiva diaria. | `Database.executeBatch`, `PSTA_PostCargaPostventa_bch` | Ya desplegado en `actidev`; aun no programado. |
| `PSTA_PostCargaPostventa_bch` | Apex batch | `PSTA_PostCargaPostventa_tst` | Detecta cuentas impactadas por historial de campos y ejecuta depuracion funcional, reconciliacion de owner y refresh de metas. | `AccountHistory`, `ContractHistory`, `Account`, `ResumenGlobalPostventa__c` | Usa ventana movil de 24 horas sobre `CreatedDate` del historial. |
| `PSTA_PostCargaPostventa_cls` | Apex service | `PSTA_PostCargaPostventa_tst` | Revalua contratos validos, limpia banderas mensuales/diarias, recalcula saldo y segmento, y decide reasignaciones de tareas, oportunidades y cadencias. | `Account`, `Contract`, `ConfiguracionActinver__c`, `Task`, `Opportunity`, `ActionCadenceTracker` | La reconciliacion de `Opportunity` sigue sujeta a validacion operativa. |
| `PSTA_PostCargaPostventa_soql` | Apex selector | `PSTA_PostCargaPostventa_tst` | Centraliza consultas del proceso post-carga. | `Account`, `Contract`, `Task`, `Opportunity`, `ActionCadenceTracker`, `ResumenGlobalPostventa__c`, `Contact` | Selector exclusivo del job nocturno. |
| `PSTA_PostCargaPostventa_Request` | Apex DTO | `PSTA_PostCargaPostventa_tst` | Transporta instrucciones de remocion o reasignacion de cadencias. | `ActionCadenceTracker`, `ActionCadence`, `Account`, `User` | Define `trackerId`, `cadenceId`, `accountId`, `userId`, `shouldReassign`. |
| `PSTA_PostCargaPostventaCadencias_qbl` | Apex queueable | `PSTA_PostCargaPostventa_tst` | Remueve trackers `Running` y, cuando aplica, vuelve a asignar la cadencia al owner correcto. | `ActionCadenceTracker`, `removeTargetFromSalesCadence`, `PV_EjecutarAsignacionCadencias_Queueable` | Reusa el motor actual de asignacion de cadencias. |

## 3. Cadencias, tareas y actualizacion de cuenta

| Componente | Tipo | Prueba asociada | Responsabilidad principal | Objetos / dependencias clave | Observaciones |
| --- | --- | --- | --- | --- | --- |
| `PV_GenerarTareasPeriodicas_sch` | Apex scheduler | `PV_GenerarTareasPeriodicas_sch_Test` | Inicia el proceso de asignacion de cadencias en dia habil. | `ACT_BatchConfig__mdt`, `BusinessHours`, custom labels | Entrada principal al motor de cadencias PostVenta. |
| `PV_GenerarTareasPeriodicas_bch` | Apex batch | `PV_GenerarTareasPeriodicas_bch_Test` | Toma el universo de cuentas y construye la corrida por scope. | `Account`, `PSTA_Consultas__mdt` | Stateful. |
| `PV_GenerarTareasPeriodicas` | Apex service | `PV_GenerarTareasPeriodicas_Test` | Evalua reglas de negocio para decidir que cadencias asignar. | `ActionCadence`, `ActionCadenceTracker`, `Contract`, `Task`, `Banker` | Aplica reglas por periodicidad, tarea unica y no contacto. |
| `PV_GenerarTareasPeriodicasSelector_cls` | Apex selector | `PV_GenerarTareasPeriodicasSelector_Test` | Centraliza consultas de cuentas, cadencias, contratos, tareas y banker. | `PSTA_Consultas__mdt`, `ActionCadence`, `Contract`, `Task`, `BusinessHours` | Fuente principal de lectura del motor de cadencias. |
| `PV_GenerarTareasPeriodicas_Request` | Apex DTO | `PV_GenerarTareasPeriodicas_Request_Test` | Wrapper Apex usado como input del flow de asignacion. | `Flow`, `assignTargetToSalesCadence` | Pasa `salesCadenceNameOrId`, `targetId`, `userId` y datos asociados. |
| `PV_EjecutarAsignacionCadencias_Queueable` | Apex queueable | `PV_EjecutarAsignCadencias_Queueable_Test` | Parte la carga en bloques e invoca el flow de asignacion de cadencias. | `Flow.Interview.PV_AsignarCadencesCuentas_Flow` | Recoge y registra errores devueltos por flow. |
| `TriggerActionCadanceStepTracker` | Trigger | `TriggerActionCadenceStepTracker_tst` | Reacciona a cambios del tracker de pasos de cadencia. | `ActionCadenceStepTrackerChangeEvent`, `Trigger_Management__mdt` | Punto de arranque de materializacion de tarea. |
| `TriggerActionCadenceStepTracker_thr` | Apex trigger handler | `TriggerActionCadenceStepTracker_thr_tst` | Delega el cierre de cadencia a la logica de tareas. | `ActionCadenceStepTrackerChangeEvent` | Llama a `PSTA_GestionTareas_Helper`. |
| `PSTA_GestionTareas_Helper` | Apex service | `PSTA_GestionTareas_Helper_tst` | Actualiza la tarea asociada a la cadencia cerrada y publica evento de finalizacion. | `Task`, `Contact`, `Banker`, `PV_FinalizacionCadencia__e` | No crea tarea nueva en la version actual; actualiza la existente. |
| `PSTA_GestionTareas_soql` | Apex selector | `PSTA_GestionTareas_soql_tst` | Resuelve queries de task, trackers, contactos y banker para cierre de cadencia. | `Task`, `ActionCadenceStepTracker`, `Contact`, `Banker` | Soporte directo del helper de tareas. |
| `Task_trg` | Trigger | `Task_thr_tst` | Trigger de `Task` en `after update`. | `Task`, `Trigger_Management__mdt` | Solo entra si el trigger esta activo por metadata. |
| `Task_thr` | Apex trigger handler | `Task_thr_tst` | Orquesta la actualizacion de cuenta y eventos de UI al cambiar una tarea. | `Task` | Llama a `PSTA_ChangeAccountInfo_ctr` y `Task_Helper`. |
| `PSTA_ChangeAccountInfo_ctr` | Apex controller/service | `PSTA_ChangeAccountInfo_ctr_tst` | Punto de entrada de la logica que mueve el resultado de la tarea hacia la cuenta. | `Task`, `Account` | Orquesta helper y consultas. |
| `PSTA_ChangeAccountInfo_helper` | Apex service | `PSTA_ChangeAccountInfo_helper_tst` | Actualiza fechas y estatus de `Account` cuando cambia el resultado de contacto. | `Task`, `Account`, `ActionCadence` | Puede enviar encuesta Medallia al cerrar con exito. |
| `PSTA_ChangeAccountInfo_soql` | Apex selector | `PSTA_ChangeAccountInfo_ctr_tst` | Obtiene cuentas y configuracion de cadencia para la actualizacion del trigger. | `Account`, `ActionCadence` | Dependencia de soporte del helper. |
| `PSTA_FACCadenceCompletion_cls` | Apex service + future callout | `PSTA_FACCadenceCompletion_cls_tst` | Cuando la cuenta llega a 100% FAC, completa la cadencia FAC, actualiza la tarea y publica evento. | `Account`, `ActionCadenceTracker`, `Task`, `PV_FinalizacionCadencia__e` | Puente especifico entre FAC y Sales Engagement. |

## 4. Integraciones, callouts y soporte de evidencia

| Componente | Tipo | Prueba asociada | Responsabilidad principal | Objetos / dependencias clave | Observaciones |
| --- | --- | --- | --- | --- | --- |
| `PV_FileUpload_ctr` | Apex controller | `PV_FileUpload_ctr_Test` | Controla carga de archivo, obtencion de contratos y envio de evidencia a OpenText. | `Task`, `Contract`, `ContentVersion`, `ContentDocument`, OpenText | Hace callout asincrono y luego actualiza tarea y contrato. |
| `PV_FileUpload_soql` | Apex selector | `PV_FileUpload_soql_Test` | Centraliza queries usadas por el componente de carga documental. | `Task`, `ActionCadence`, `Contract`, `ContentVersion`, `ContentDocument` | Determina si la cadencia requiere evidencia. |
| `PV_OpenText_Request` | Apex wrapper | `PV_OpenText_Request_Test` | Modelo del request enviado a OpenText. | Callout OpenText | Incluye datos de contrato, archivo, cliente y asesor. |
| `PV_OpenText_Response` | Apex wrapper | `PV_OpenText_Response_Test` | Modelo del response de OpenText. | Callout OpenText | Contiene `status`, `messages`, `result` y `payload.referenceId`. |
| `PSTA_EnvioEncuestaMedallia_cls` | Apex service | `PSTA_EnvioEncuestaMedallia_cls_tst` | Recorre tareas y lanza la preparacion del envio Medallia. | `Task` | Es un orquestador ligero. |
| `PSTA_EnvioEncuestaMedallia_ctr` | Apex controller | `PSTA_EnvioEncuestaMedallia_cls_tst` | Prepara parametros y ejecuta el callout Medallia. | `Task`, `Account`, `Banker`, callout Medallia | Construye payload con datos del cliente y asesor. |
| `PSTA_EnvioEncuestaMedallia_soql` | Apex selector | `PSTA_EnvioEncuestaMedallia_cls_tst` | Obtiene la tarea y joins necesarios a partir de una query almacenada en metadata. | `PSTA_Consultas__mdt`, `Task` | Usa `PSTA_Query_EnvioEncuestaMedalia`. |
| `PSTA_EnvioEncuestaMedallia_Mockup` | Apex mock | `PSTA_EnvioEncuestaMedallia_cls_tst` | Mock del servicio de encuesta para pruebas o simulacion. | Medallia | Apoyo de testing e integracion. |
| `PV_EnvioEncuestaMedallia_Action_cls` | Apex invocable | `PV_EnvioEncuestaMedallia_Action_cls_tst` | Expone el envio Medallia como accion invocable para Flow. | Flow, `Task`, Medallia | Etiqueta invocable `CalloutMedallia_PV`. |
| `PSTA_PlatformEvent_ctr` | Apex service | `PSTA_PlatformEvent_ctr_Test` | Publica `UpdateTask__e` para controlar la visibilidad del componente de archivos. | `UpdateTask__e` | En el documento del proveedor aparece un nombre similar, pero aqui lo verificado es el evento `UpdateTask__e`. |

## 5. Utilerias y soporte transversal

| Componente | Tipo | Prueba asociada | Responsabilidad principal | Objetos / dependencias clave | Observaciones |
| --- | --- | --- | --- | --- | --- |
| `PSTA_UtilityClass` | Apex utility | `PSTA_UtilityClass_tst` | Utileria exclusiva de PostVenta. | Fechas, business hours, constantes de developer name | Soporte transversal para reglas y nombres de cadencia. |
| `PSTA_TestDataFactory` | Apex test utility | `PSTA_TestDataFactory_tst` | Fabrica de datos de prueba para escenarios PostVenta. | Datos de test | Uso principal en pruebas. |

## 6. Flujos verificados

| Componente | Tipo | Prueba asociada | Responsabilidad principal | Objetos / dependencias clave | Observaciones |
| --- | --- | --- | --- | --- | --- |
| `Flow_Avance_FAC` | Record-triggered flow | N/A en source | Calcula el avance de Ficha de Afinidad en cuenta. | `Account` | Activo. |
| `FAC_Task_Update_InTask` | Record-triggered flow | N/A en source | Marca tarea FAC como contactada al crearse si la cuenta ya esta al 100%. | `Task`, `Account` | Activo. |
| `FAC_Task_Update_InAccount` | Record-triggered flow | N/A en source | Flujo historico para actualizar tarea FAC desde cuenta. | `Account`, `Task` | Estado `Obsolete`. |
| `FAC_Update_Task_Field_Avence` | Record-triggered flow | N/A en source | Flujo historico adicional de actualizacion de tarea FAC. | `Account`, `Task` | Estado `Obsolete`. |
| `PV_AsignarCadencesCuentas_Flow` | Autolaunched flow | N/A en source | Ejecuta `assignTargetToSalesCadence` para cada request recibido desde Apex. | Sales Engagement, `PV_GenerarTareasPeriodicas_Request` | Activo y central para asignacion de cadencias. |

## 7. LWC y paginas relacionadas

| Componente | Tipo | Prueba asociada | Responsabilidad principal | Objetos / dependencias clave | Observaciones |
| --- | --- | --- | --- | --- | --- |
| `taskProgressBar` | LWC | N/A en source | Muestra el avance FAC dentro de la tarea. | `Task.Avance_FAC__c`, `Task.Subject` | Visible en la flexipage `Postventa`. |
| `accountProgressBar` | LWC | N/A en source | Muestra el avance FAC en cuenta. | `Account.Avance_FAC__c` | Visible en paginas de cuenta de PostVenta. |
| `pV_GestionTarea_lwc` | LWC | N/A en source | Escucha `PV_FinalizacionCadencia__e` y muestra un toast con liga a la tarea generada. | EMP API, `PV_FinalizacionCadencia__e` | Refuerza la experiencia del asesor tras cerrar la cadencia. |
| `Postventa.flexipage-meta.xml` | Flexipage | N/A en source | Pagina de tarea con detalle, carga documental, barra FAC y flow de reagenda. | `Task`, `PSTA_NuevoEventoTarea`, `pv_FileUpload_LWC` | El componente `pv_FileUpload_LWC` esta referenciado, pero no vino en esta linea base. |
| `Account_Privada.flexipage-meta.xml` | Flexipage | N/A en source | Pagina de cuenta privada con widgets de PostVenta. | `Account`, `accountProgressBar`, `pV_GestionTarea_lwc` | Verificada en source. |
| `Account_PatrimonialRP1.flexipage-meta.xml` | Flexipage | N/A en source | Pagina de cuenta patrimonial con widgets de PostVenta. | `Account`, `accountProgressBar`, `pV_GestionTarea_lwc` | Verificada en source. |

## 8. Relacion de lectura recomendada

Para recorrer tecnicamente el modelo conviene seguir este orden:

1. `PSTA_SegmentacionClientes_*`
2. `PSTA_ResetearEstatusContacto_*`
3. `PSTA_RegistroResumenGlobal_*`
4. `PV_GenerarTareasPeriodicas_*`
5. `PV_EjecutarAsignacionCadencias_Queueable`
6. `PV_AsignarCadencesCuentas_Flow`
7. `TriggerActionCadanceStepTracker` + `TriggerActionCadenceStepTracker_thr`
8. `PSTA_GestionTareas_*`
9. `Task_trg` + `Task_thr`
10. `PSTA_ChangeAccountInfo_*`
11. `PV_FileUpload_*` y `PV_OpenText_*`
12. `PSTA_EnvioEncuestaMedallia_*`
13. `PSTA_FACCadenceCompletion_cls`

## 9. Observaciones de consolidacion

1. El modelo PostVenta no esta encapsulado en un solo modulo tecnico; esta repartido entre schedulers, batches, trigger handlers, flows, eventos de plataforma y componentes UI.
2. El documento del proveedor describe bien el inventario funcional general, pero en source hay diferencias de estado y nomenclatura.
3. El job `PSTA_PostCargaPostventa_*` ya agrega una capa correctiva adicional para eventos diarios de carga masiva, apoyandose en `AccountHistory` y `ContractHistory` en lugar de cambios generales por `LastModifiedDate`.
4. En esta linea base no se recupero toda la metadata declarativa del proyecto, por lo que esta matriz debe leerse como `componentes verificados en source` y no como inventario total de la org.
