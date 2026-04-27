# Evidencia de reproceso manual en QA

## Proceso
Cancelacion de contrato en PostVenta.

## Ambiente
- `actiqa`

## Contexto
El batch nocturno ejecutado el `2026-04-14` corrio correctamente, pero no proceso registros porque los contratos cancelados no generaron filas en `ContractHistory` antes de que se activara el tracking del campo `Status__c`.

Por este motivo se realizo un reproceso manual puntual usando la misma logica de:
- `PSTA_PostCargaPostventa_cls`
- `PSTA_PostCargaPostventaCadencias_qbl`

## Contratos revisados
- `800WP00000gtd0FYAQ`
- `800WP00000hSEleYAG`
- `800WP00000hSEqVYAW`
- `800WP00000hBSC0YAO`
- `800WP00000hBSE7YAO`

## Cuentas impactadas
- `001WP00000fwupCYAQ` - Ronald Cook
- `001WP00000gXWXgYAO` - Wendy Young
- `001WP00000gGOJyYAO` - Nicole Henderson

## Estado previo
- Las 3 cuentas tenian:
  - `ContactoPriorizadoEsteMes__c = true`
  - `PriorizacionContacto__c = true`
  - `PriorizacionVisita__c = true`
- Tareas abiertas antes del reproceso:
  - `001WP00000fwupCYAQ` -> `5`
  - `001WP00000gXWXgYAO` -> `5`
  - `001WP00000gGOJyYAO` -> `4`
- Oportunidades abiertas antes del reproceso:
  - `0`

## Resultado del reproceso manual
Ejecucion manual:
- `accountsToUpdate = 3`
- `tasksToDelete = 9`
- `opportunitiesToDelete = 0`
- `cadenceRequests = 9`

Queueable de cadencias:
- `AsyncApexJob Id`: `707WF0000HcXMg9YQG`
- Clase: `PSTA_PostCargaPostventaCadencias_qbl`
- Estado: `Completed`
- Errores: `0`

## Resultado final por cuenta

### 001WP00000gXWXgYAO - Wendy Young
- `ContactoPriorizadoEsteMes__c = false`
- `PriorizacionContacto__c = false`
- `PriorizacionVisita__c = false`
- Sin tareas abiertas posteriores al reproceso

### 001WP00000gGOJyYAO - Nicole Henderson
- `ContactoPriorizadoEsteMes__c = false`
- `PriorizacionContacto__c = false`
- `PriorizacionVisita__c = false`
- Sin tareas abiertas posteriores al reproceso

### 001WP00000fwupCYAQ - Ronald Cook
- `ContactoPriorizadoEsteMes__c = true`
- `PriorizacionContacto__c = true`
- `PriorizacionVisita__c = true`
- Mantiene `5` tareas abiertas

## Explicacion funcional del caso que se mantuvo activo
La cuenta `001WP00000fwupCYAQ` no fue dada de baja del proceso porque, conforme a la configuracion vigente en QA, todavia conserva un contrato valido para PostVenta.

Configuracion de contratos en QA:
- `TipoContratos__c = 01;02;03;08`
- `EstatusContrato__c = C05;CC05`

Contratos de esa cuenta:
- `C02` tipo `01`
- `C02` tipo `02`
- `CC05` tipo `08`

El contrato `CC05` tipo `08` sigue siendo valido para PostVenta bajo la configuracion actual, por lo que la cuenta permanece correctamente dentro del proceso.

## Conclusiones
- La logica de cancelacion de contrato funciona correctamente en QA.
- Dos cuentas fueron depuradas correctamente del proceso.
- Una cuenta permanecio activa de manera correcta porque sigue teniendo un contrato valido conforme a configuracion.
- El comportamiento observado es consistente con la parametrizacion actual de `ConfiguracionActinver__c`.
