# Aclaración meta mensual y contratos cancelados

## Objetivo
Dejar documentada la regla final del cálculo de `MetaMensual__c` en `ResumenGlobalPostventa__c` y su relación con la cancelación de contratos.

## Regla funcional final
La meta mensual del asesor ya no depende del total de clientes priorizados del mes.

La meta mensual se calcula así:
- `Meta base mensual = meta diaria configurada por segmento x días hábiles del mes`
- `Meta mensual final = mínimo entre la meta base mensual y la cartera elegible del asesor`

## Fuente de la meta diaria
La meta diaria se toma de `ConfiguracionActinver__c`, record type `ContactoPostventa`, campo `ClientesContactarPorDia__c`, de acuerdo con el segmento del asesor.

## Días hábiles
Los días hábiles del mes se calculan usando `Business Hours` del proceso Postventa.

## Definición de cartera elegible
La cartera elegible del asesor se define como el total de cuentas del asesor que conservan al menos un contrato válido para Postventa.

Contrato válido significa:
- tipo de contrato incluido en la configuración de contratos Postventa
- estatus incluido en la configuración de contratos Postventa

La validación usa la misma regla funcional que la segmentación de clientes.

## Relación con contratos cancelados
Si una cuenta pierde sus contratos válidos por cancelación:
- deja de formar parte de la cartera elegible
- deja de contribuir al cálculo de la meta mensual del asesor

Si la cuenta conserva al menos un contrato válido:
- sigue formando parte de la cartera elegible
- sigue contando para la meta mensual

## Momento en que se refleja el ajuste
El ajuste no se refleja sobre un resumen ya creado en el mismo instante del cambio del contrato.

La secuencia operativa es:
1. la carga / actualización de contratos deja el cambio de estatus
2. el job nocturno `PSTA PostCarga Postventa Nocturno` depura las cuentas sin contratos válidos
3. el job `PSTA_RegistroResumenGlobalMensual` recalcula la cartera elegible y genera el resumen del día

Por lo tanto:
- una cuenta con contratos cancelados sale de la meta mensual en la siguiente corrida del resumen global
- en la calendarización actual de QA, esto se refleja al día siguiente

## Ejemplo
Supuestos:
- meta diaria configurada: `10`
- días hábiles del mes: `20`
- meta base mensual: `200`
- cartera elegible del asesor: `9`

Resultado:
- `MetaMensual__c = 9`
- `Meta__c` diaria ajustada = `1`

## Criterio de validación QA
Para validar esta regla en QA:
- identificar un asesor con cartera elegible conocida
- validar cuántas cuentas conserva con al menos un contrato válido
- ejecutar el correctivo nocturno de contratos si hubo cancelaciones
- ejecutar o validar la corrida de `PSTA_RegistroResumenGlobalMensual`
- confirmar que `MetaMensual__c` quede topada al tamaño de la cartera elegible

## Componentes relacionados
- `PSTA_PostCargaPostventa_*`
- `PSTA_RegistroResumenGlobalMensual_cls`
- `PSTA_RegistroResumenGlobalMensual_bch`
- `ResumenGlobalPostventa__c.Meta__c`
- `ResumenGlobalPostventa__c.MetaMensual__c`
- `ResumenGlobalPostventa__c.ContactadosMensual__c`
- `ResumenGlobalPostventa__c.PorcentajeAvanceMensual__c`
