# Componentes creados y migrados a QA

## Solución
Cancelación de contrato en PostVenta.

## Alcance funcional migrado a QA
La versión migrada a QA atiende únicamente el caso de cancelación de contrato.

Regla funcional:
- El proceso se detona por cambios de `ContractHistory.Status__c`.
- Solo considera estatus de cancelación `C02` y `CC02`.
- Si una cuenta queda sin contratos válidos para PostVenta:
  - limpia `ContactoPriorizadoEsteMes__c`
  - limpia `PriorizacionContacto__c`
  - limpia `PriorizacionVisita__c`
  - elimina tareas abiertas
  - elimina oportunidades abiertas
  - remueve cadencias activas
  - refresca `Meta__c` de `ResumenGlobalPostventa__c`
- Si todavía quedan contratos válidos:
  - mantiene a la cuenta en el proceso
  - recalcula `SaldoIntegral__c`
  - recalcula `FechaAntiguedad__c`
  - recalcula `Segmento__c`
  - no recalcula priorización mensual ni diaria
  - no modifica `FechaUltimoContacto__c`
  - no modifica `FechaUltimaVisita__c`

## Componentes creados para la iniciativa

### Componentes de la solución de cancelación de contrato
- `PSTA_PostCargaPostventa_sch`
- `PSTA_PostCargaPostventa_bch`
- `PSTA_PostCargaPostventa_cls`
- `PSTA_PostCargaPostventa_soql`
- `PSTA_PostCargaPostventaCadencias_qbl`
- `PSTA_PostCargaPostventa_Request`
- `PSTA_PostCargaPostventa_tst`

### Componentes creados previamente pero fuera del alcance final de QA
- `PSTA_ReasignacionAsesorPostventa__c`
- `PSTA_ReasignacionAsesorPostventa_cls`

Estos componentes se conservan en source, pero no forman parte del alcance funcional de cancelación de contrato que se migró a QA.

## Componentes migrados a QA
Org destino: `actiqa`

### Apex migrado
- `PSTA_PostCargaPostventa_sch`
- `PSTA_PostCargaPostventa_bch`
- `PSTA_PostCargaPostventa_cls`
- `PSTA_PostCargaPostventa_soql`
- `PSTA_PostCargaPostventaCadencias_qbl`
- `PSTA_PostCargaPostventa_Request`
- `PSTA_PostCargaPostventa_tst`

### Componentes no migrados en esta salida
- `PSTA_ReasignacionAsesorPostventa__c`
- `PSTA_ReasignacionAsesorPostventa_cls`

## Evidencia de migración
- Deploy QA: `0AfWF00000Cuh3N0AR`
- Org: `francisco.ortega@optimissa.com.actiqa`
- Clase de prueba ejecutada: `PSTA_PostCargaPostventa_tst`
- Resultado de pruebas: `8/8` exitosas

## Archivos fuente asociados
- `force-app/main/default/classes/PSTA_PostCargaPostventa_sch.cls`
- `force-app/main/default/classes/PSTA_PostCargaPostventa_bch.cls`
- `force-app/main/default/classes/PSTA_PostCargaPostventa_cls.cls`
- `force-app/main/default/classes/PSTA_PostCargaPostventa_soql.cls`
- `force-app/main/default/classes/PSTA_PostCargaPostventaCadencias_qbl.cls`
- `force-app/main/default/classes/PSTA_PostCargaPostventa_Request.cls`
- `force-app/main/default/classes/PSTA_PostCargaPostventa_tst.cls`
- `force-app/main/default/classes/PSTA_ReasignacionAsesorPostventa_cls.cls`
- `force-app/main/default/objects/PSTA_ReasignacionAsesorPostventa__c/`
