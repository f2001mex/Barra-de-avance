# ACT_Mejoras_PSTA

Conjunto de cambios salientes preparado solo con el alcance funcional de metas/MSC/postventa.

No incluye componentes de Gerardo (`ACT_CadenceReassign*`, `Act_Cadence_Reassign_Queue__c`, `PSTA_Account_thr`, `Patrim_AvanceDeEtapasOportunidad`, `Opportunity.NoEditarOpportunidadCerradaPerdidaGanada`).

## Archivo principal

- `manifest/ACT_Mejoras_PSTA_package.xml`

## Prerrequisitos de configuracion en target (Prod)

- Activar Field History Tracking en `Contract.Status__c`.
- Activar Field History Tracking en `Account.ID_Asesor__c`.
- Revisar `Business Hours` con nombre `Postventa` (usado por `ACT_BatchConfig__mdt.BusinessHoursName__c`).

## Registros metadata a crear/validar

Tipo: `ACT_BatchConfig__mdt`

- `ACT_BatchConfig.PSTA_RegistroResumenGlobal`
- `ACT_BatchConfig.PSTA_ResetearEstatusContacto`
- `ACT_BatchConfig.PV_GenerarTareasPeriodicas`

Cada registro debe tener `BusinessHoursName__c = Postventa`.

## Jobs esperados despues del pase

- `PSTA_SegmentacionClientes`
- `PSTA PostCarga Postventa Nocturno`
- `PSTA_ResetearEstatusContacto`
- `PV_GenerarTareasPeriodicas`
- `PSTA_RegistroResumenGlobalMensual`

## Notas de alcance

- Este paquete si incluye reportes y dashboards de `Postventa` para el modelo mensual.
- Este paquete no fuerza despliegue de LWC de metas (se excluyo deliberadamente).
- No se ejecuto despliegue a Prod en esta preparacion.

## Mapeo de dashboards (nombre tecnico -> nombre funcional)

- `Postventa/BOrPHuSRgxobFUGfBCNRiUgZHyZRDN` -> `Estatus de contacto a clientes` (`01ZWP000003s7E52AI`)
- `Postventa/fSZMSKeDwQsurNjEcFpHSwVhXTzuxy1` -> `Meta mensual` (`01ZWP000003rjbd2AA`)
