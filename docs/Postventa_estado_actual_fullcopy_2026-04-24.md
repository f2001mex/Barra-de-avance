# Estado actual Full Copy - Postventa

## Objetivo
Dejar evidencia del estado actual de `fullcopy` después de la actualización de los frentes activos de Postventa.

## Alcance actualizado
Quedó actualizado en `fullcopy` lo siguiente:
- motor de metas mensuales
- reportes y tableros nuevos de metas
- línea de resumen global mensual
- trigger y handler de cuenta
- línea de cancelación de contratos
- ajuste de generación de tareas

## Componentes actualizados

### Metas mensuales
- `PSTA_RegistroResumenGlobalMensual_*`
- `PSTA_RResumenMes_thr`
- `ResumenGlobalPostventa_trg`
- campos nuevos en `ResumenGlobalPostventa__c`
  - `ExternalId_NominaFecha__c`
  - `MetaMensual__c`
  - `ContactadosMensual__c`
  - `PorcentajeAvanceMensual__c`

### LWC de metas
- `PSTA_MetaMensualDashboard_ctr`
- `pstaMetaMensualDashboard`

### Trigger y handler de cuenta
- `AccountTrigger`
- `PSTA_Account_thr`
- `PSTA_FACCadenceCompletion_cls`

### Cancelación de contratos
- `PSTA_PostCargaPostventa_bch`
- `PSTA_PostCargaPostventa_cls`
- `PSTA_PostCargaPostventa_Request`
- `PSTA_PostCargaPostventa_sch`
- `PSTA_PostCargaPostventa_soql`
- `PSTA_PostCargaPostventaCadencias_qbl`

### Generación de tareas
- `PV_GenerarTareasPeriodicas`
- `PV_GenerarTareasPeriodicasSelector_cls`

## Reporting desplegado

### Report type
- `Reporte_Resumen_Global_PostVenta`

### Reportes
- `Postventa/Meta_mensual_resumen_global`
- `Postventa/Resumen_Global_Diario_Mensual`

### Tableros
- `Postventa/Meta_mensual_resumen_global`
- `Postventa/Estatus_contacto_clientes_resumen_global`

## Configuración validada

### Business Hours
Existe:
- `Postventa`

### Metadata batch
Existe:
- `ACT_BatchConfig__mdt.PSTA_RegistroResumenGlobal`
- `BusinessHoursName__c = Postventa`

### History tracking
Quedó validado a nivel campo:
- `Account.OwnerId = true`
- `Account.ID_Asesor__c = true`
- `Contract.OwnerId = true`
- `Contract.Status__c = true`

## Jobs programados

### Activos
- `PSTA_SegmentacionClientes`
- `PSTA PostCarga Postventa Nocturno`
- `PSTA_ResetearEstatusContacto`
- `PV_GenerarTareasPeriodicas`
- `PSTA_RegistroResumenGlobalMensual`

### Fuera de operación
- `PSTA_RegistroResumenGlobal`

## Elementos no aplicados

### Home compartido
No se insertó el LWC de metas en la Home compartida.

Razón:
- la Home también depende de componentes `AntiChurn`
- el frente `AntiChurn` quedó pausado

### AntiChurn
No se aplicaron cambios ni activaciones del frente `AntiChurn`.

## Deploys relevantes
- metas base en Full Copy:
  - `0AfWF00000DCDzh0AH`
- `AccountTrigger`, `PSTA_Account_thr`, `PSTA_FACCadenceCompletion_cls`:
  - `0AfWF00000DCLdt0AH`
- cancelación de contratos y generación de tareas:
  - `0AfWF00000DCM250AH`

## Conclusión
`fullcopy` quedó alineado para los frentes activos de Postventa que no estaban pausados:
- metas
- resumen global mensual
- cancelación de contratos
- generación de tareas
- trigger y handler de cuenta

No quedó aplicado:
- `AntiChurn`
- inserción del LWC de metas en la Home compartida

Esto deja el ambiente listo para continuar con validaciones funcionales sin mezclar el frente pausado de `AntiChurn`.
