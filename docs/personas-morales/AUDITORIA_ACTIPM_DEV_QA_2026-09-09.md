# Auditoría ActiPM vs. ActiDev y ActiQA — Personas Morales

Fecha de corte: 9 de septiembre de 2026.

## Resultado ejecutivo

ActiPM no estaba completamente alineado cuando se inició esta revisión. El paquete canónico de Personas Morales fue desplegado nuevamente y terminó correctamente, pero la revisión ampliada detectó diferencias fuera del alcance que tenía el manifiesto original, principalmente en el perfil `PM - Ejecutivo Personas Morales`.

## Evidencia de despliegue

- Validación específica: `0AfWF00000G2pIA0AZ`.
- Resultado: 100 componentes procesados, 28 pruebas ejecutadas, 28 exitosas, 0 errores y 0 advertencias de cobertura.
- Despliegue real: `0AfWF00000G37rl0AB`.
- Resultado: 100 componentes desplegados, 28 pruebas ejecutadas, 28 exitosas y 0 errores.
- La validación con todas las pruebas locales (`0AfWF00000G361F0AR`) no fue utilizable como criterio del paquete: fallaron 355 pruebas heredadas por datos y reglas ajenos al alcance PM. No hubo errores de metadatos del paquete.

## Comparación directa del paquete canónico

Se recuperaron directamente de ActiDev, ActiQA y ActiPM los componentes declarados en `manifest/package-personas-morales.xml`.

- 94 archivos recuperados por ambiente.
- 86 archivos idénticos en los tres ambientes.
- 8 archivos con diferencias brutas.

Clasificación de las ocho diferencias:

1. `Bancas.app`: los nueve overrides del perfil PM son iguales en los tres ambientes. Las pestañas funcionales PM son las mismas; ActiPM conserva diferencias de orden y omite overrides ajenos a PM heredados de otros perfiles.
2. `OpenTextRazonabilidadRest` y su prueba: ActiQA y ActiPM son idénticos; ActiDev conserva una versión anterior sin los reintentos programados de reasignación de propietario.
3. `Account_PM_Banca_Institucional`: ActiDev y ActiPM son idénticos. En QA, `Tipo_de_cliente_PM__c` está marcado como obligatorio en la Lightning Page.
4. `Account.object`: las diferencias extensas provienen principalmente de campos y valores maestros disponibles en cada sandbox. Para el record type `Cuentas_empresariales`, ActiDev y ActiPM coinciden en los valores PM críticos:
   - `Segmento__c`: Gobierno, Institucional.
   - `FinServ__Status__c`: Active, Bloqueado, Inactive.
   - `Tipo_de_cliente_PM__c`: diez valores coincidentes.
   - `Industry`: valores coincidentes.
5. `Contact.object` y `Opportunity.object`: ActiQA y ActiPM son idénticos; las diferencias de hash con ActiDev no produjeron diferencias funcionales en el contenido recuperado del alcance.
6. `RPT_Clientes_por_Tipo_Institucional`: ActiDev y ActiPM filtran `Active`; QA filtra `Active,Activo`.

## Triggers

El código fuente de los siguientes triggers es idéntico en ActiDev, ActiQA y ActiPM:

- `AccountTrigger`
- `OpportunityTrigger`
- `Task_trg`

La versión de `OpportunityTrigger` contiene el evento `after insert` promovido previamente. Solo el archivo descriptor de `AccountTrigger` presenta una diferencia de versión API; QA y ActiPM coinciden entre sí.

## Perfil PM: hallazgo pendiente

La consulta directa de permisos efectivos demostró:

- Permisos de objeto Account, Contact y Opportunity: iguales en los tres ambientes (lectura desde perfil; creación y edición complementadas mediante conjuntos PM).
- Permisos de campo recuperados para Account, Contact, Opportunity, Task y Event:
  - ActiDev: 95.
  - ActiQA: 96.
  - ActiPM: 76.

ActiPM no tiene en el perfil permisos de lectura/edición para campos necesarios de la HU04, aunque los conjuntos de permisos PM sí contienen parte de la cobertura. Entre los faltantes confirmados están:

- `Opportunity.Motivo_de_perdidaPM__c`
- `Opportunity.Profit_and_Loss_PM__c`
- `Opportunity.AccountId`
- `Opportunity.CampaignId`
- `Opportunity.Description`
- `Opportunity.MotivoDeRechazo__c`
- `Opportunity.Probability` (lectura)

También faltan permisos de campos utilizados por los formularios PM de Account, Contact, Task y Event. ActiPM conserva permisos adicionales de Opportunity provenientes de Producción; no deben retirarse automáticamente.

## Listas de vista

Inventario recuperado por Metadata API:

| Objeto | ActiDev | ActiQA | ActiPM |
|---|---:|---:|---:|
| Account | 17 | 17 | 12 |
| Contact | 19 | 19 | 19 |
| Opportunity | 30 | 31 | 33 |

- Contact: mismos nombres y compartición entre QA y ActiPM.
- Opportunity: las vistas comunes tienen la misma compartición. ActiPM conserva dos vistas adicionales: `Mis_Oportunidades_Leads_Gran_Filtro` y `Mis_Oportunidades_PPR_2026`.
- Account: ActiPM no contiene `Clientes_Belora`, `EFRAIN_CEBALLLOS_RIVAS`, `FinServ__My_Businesses`, `FinServ__My_Groups` ni `FinServ__My_Institutions`. Las dos primeras no forman parte de las vistas PM autorizadas. Las vistas comunes conservan la misma compartición.

## Control DevOps

- Código canónico: `force-app/main/default`.
- Paquete desplegable: `manifest/package-personas-morales.xml`.
- Complemento de auditoría para perfil y triggers: `manifest/package-personas-morales-audit.xml`.
- Commit del ajuste de estados de Account: `d99d00f`.
- Las recuperaciones completas de ambientes permanecen fuera de Git para evitar respaldar metadatos ajenos, datos internos o artefactos temporales. Git conserva el código canónico, manifiestos y este informe reproducible.

## Conclusión

El núcleo desplegable está actualizado y probado en ActiPM, pero no debe declararse alineación total hasta corregir y volver a comprobar los permisos de campo del perfil PM. La corrección debe ser aditiva: incorporar los permisos PM faltantes y preservar los permisos adicionales heredados de Producción.
