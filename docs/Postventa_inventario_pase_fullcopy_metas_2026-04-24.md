# Inventario pase Full Copy - Metas Postventa

## Objetivo
Dejar el inventario técnico y operativo para que el administrador de `fullcopy` pueda desplegar y activar correctamente la solución de metas Postventa, incluyendo:
- motor de cálculo mensual y diario
- LWC del Home
- reportes nuevos
- tableros nuevos
- dependencias de `Business Hours`
- activación/desactivación de jobs y flows

## Alcance
Este inventario cubre el frente de:
- `MetaMensual__c`
- `Meta__c` diaria
- `ContactadosMensual__c`
- `PorcentajeAvanceMensual__c`
- visualización en Home mediante LWC
- reporting y dashboards nuevos sobre `ResumenGlobalPostventa__c`

## 1. Componentes nuevos a desplegar

### 1.1 Motor mensual de resumen global
- `ApexClass`
  - `PSTA_RegistroResumenGlobalMensual_cls`
  - `PSTA_RegistroResumenGlobalMensual_bch`
  - `PSTA_RegistroResumenGlobalMensual_sch`
  - `PSTA_RResumenMes_thr`
  - pruebas relacionadas `PSTA_RResumenMensual_*_tst`
- `ApexTrigger`
  - `ResumenGlobalPostventa_trg`

### 1.2 Campos nuevos o modificados en `ResumenGlobalPostventa__c`
- `ExternalId_NominaFecha__c`
- `MetaMensual__c`
- `ContactadosMensual__c`
- `PorcentajeAvanceMensual__c`

Validación adicional:
- `ExternalId_Nomina__c` ya no debe quedar como `unique`, porque el modelo es diario por asesor.

### 1.3 Flows de operación
- `Flow`
  - `ACT_CrearTarea_OpptyStage_UpdateResumen`
  - `ACT_CrearTarea_OpptyStage_UpdateResumenMensual`
- `FlowDefinition`
  - `ACT_CrearTarea_OpptyStage_UpdateResumen`
  - `ACT_CrearTarea_OpptyStage_UpdateResumenMensual`

### 1.4 LWC para Home
- `ApexClass`
  - `PSTA_MetaMensualDashboard_ctr`
  - `PSTA_MetaMensualDashboard_ctr_tst`
- `LightningComponentBundle`
  - `pstaMetaMensualDashboard`
- `FlexiPage`
  - `P_gina_de_inicio_predeterminada`

### 1.5 Reporting nuevo
- `ReportType`
  - `Reporte_Resumen_Global_PostVenta`
- `ReportFolder`
  - `Postventa`
- `Report`
  - `Postventa/Meta_mensual_resumen_global`
  - `Postventa/Resumen_Global_Diario_Mensual`
- `DashboardFolder`
  - `Postventa`
- `Dashboard`
  - `Postventa/Meta_mensual_resumen_global`
  - `Postventa/Estatus_contacto_clientes_resumen_global`

## 2. Dependencias funcionales y técnicas

### 2.1 Business Hours
Debe existir un registro de `BusinessHours` con nombre exacto:
- `Postventa`

Uso:
- cálculo de días hábiles del mes
- validación de ejecución del scheduler mensual

### 2.2 Metadata de configuración batch
Debe existir un registro en `ACT_BatchConfig__mdt` para:
- `DeveloperName = PSTA_RegistroResumenGlobal`
- `BusinessHoursName__c = Postventa`

Nota:
- este registro no está en source local actual; debe validarse en Full Copy o crearse manualmente si no existe.

### 2.3 Custom Label
Debe existir:
- `PSTA_Resumen_Global_Registros`

Uso:
- tamaño de lote del scheduler `PSTA_RegistroResumenGlobalMensual_sch`

### 2.4 Configuración Actinver
Debe existir la configuración de `ConfiguracionActinver__c` para:
- record type `ContactoPostventa`
- metas diarias por segmento mediante `ClientesContactarPorDia__c`
- configuración de contratos válidos de Postventa
  - tipos válidos
  - estatus válidos

## 3. Componentes existentes que se conservan
No se eliminan:
- clases Apex existentes de la línea anterior
- reportes existentes
- tableros existentes
- Home actual
- flow viejo como respaldo

Razón:
- conservar rollback funcional y técnico
- evitar romper tableros o reportes ya usados por negocio

## 4. Componentes que salen de operación

### 4.1 Job viejo
Debe quedar fuera de operación:
- `PSTA_RegistroResumenGlobal`

Acción:
- descalendarizarlo
- no volverlo a usar para el cálculo nuevo de metas

### 4.2 Flow viejo
Debe quedar inactivo:
- `ACT_CrearTarea_OpptyStage_UpdateResumen`

Acción:
- desactivar el flow viejo
- dejar activo el nuevo flow mensual

## 5. Componentes que deben quedar activos

### 5.1 Job nuevo
Debe quedar calendarizado:
- `PSTA_RegistroResumenGlobalMensual`

### 5.2 Flow nuevo
Debe quedar activo:
- `ACT_CrearTarea_OpptyStage_UpdateResumenMensual`

### 5.3 LWC en Home
Debe quedar visible en:
- Home de la app `Bancas`

Ubicación:
- al final de los componentes existentes del Home

### 5.4 Reportes y tableros nuevos
Deben quedar visibles y funcionales:
- `Postventa/Meta_mensual_resumen_global`
- `Postventa/Resumen_Global_Diario_Mensual`
- `Postventa/Meta_mensual_resumen_global` dashboard
- `Postventa/Estatus_contacto_clientes_resumen_global` dashboard

## 6. Acciones manuales post-deploy
1. Validar o crear `BusinessHours` con nombre `Postventa`.
2. Validar o crear `ACT_BatchConfig__mdt.PSTA_RegistroResumenGlobal`.
3. Validar que exista el label `PSTA_Resumen_Global_Registros`.
4. Descalendarizar `PSTA_RegistroResumenGlobal`.
5. Calendarizar `PSTA_RegistroResumenGlobalMensual`.
6. Desactivar `ACT_CrearTarea_OpptyStage_UpdateResumen`.
7. Activar `ACT_CrearTarea_OpptyStage_UpdateResumenMensual`.
8. Validar que el Home `P_gina_de_inicio_predeterminada` conserve sus componentes originales.
9. Validar que el LWC `pstaMetaMensualDashboard` quede al final del Home.
10. Validar apertura de reportes y tableros nuevos.

## 7. Validaciones funcionales mínimas
1. Ejecutar `PSTA_RegistroResumenGlobalMensual_bch`.
2. Confirmar que se generen registros diarios por asesor en `ResumenGlobalPostventa__c`.
3. Confirmar que:
   - `Meta__c` represente la meta diaria
   - `MetaMensual__c` represente la meta mensual
   - `ContactadosMensual__c` represente el acumulado mensual
   - `PorcentajeAvanceMensual__c` represente el porcentaje mensual
4. Abrir reporte `Meta_mensual_resumen_global` y validar columnas nuevas.
5. Abrir reporte `Resumen_Global_Diario_Mensual` y validar detalle diario/mensual.
6. Abrir tableros nuevos y validar que carguen sin componentes rotos.
7. Abrir Home de `Bancas` y validar el LWC.

## 8. Componentes incluidos por manifest de referencia

### 8.1 Frontend y reporting
Manifest:
- `manifest/package-metas-fullcopy.xml`

### 8.2 Motor mensual
Manifest:
- `manifest/package-resumen-global-mensual.xml`

### 8.3 Reporting complementario
Manifest:
- `manifest/package-resumen-global-mensual-reporting.xml`

## 9. Observaciones
- Full Copy hoy no tiene completo este paquete.
- El cálculo nuevo de metas depende de la configuración y del modelo diario de `ResumenGlobalPostventa__c`.
- Los reportes y tableros nuevos no sustituyen automáticamente a los existentes; se agregan como nueva línea de consulta.
- El patrón recomendado es:
  - backend calcula
  - reportes detallan
  - LWC presenta en Home

## 10. Resumen ejecutivo
Para dejar operando metas Postventa en Full Copy se requiere:
- desplegar backend mensual
- desplegar campos nuevos
- desplegar flows nuevo y viejo para control de activación
- activar el flow mensual y desactivar el anterior
- descalendarizar el job viejo y calendarizar el nuevo
- validar `Business Hours`, `ACT_BatchConfig__mdt` y `Custom Label`
- desplegar report type, reportes y tableros nuevos
- desplegar el LWC y la FlexiPage del Home
