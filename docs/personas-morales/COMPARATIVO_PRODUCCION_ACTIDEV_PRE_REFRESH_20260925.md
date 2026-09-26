# Comparativo Producción vs ActiDev previo a refresh

Fecha: 25 de septiembre de 2026  
Alcance: funcionalidad de Personas Morales HU1 a HU5 y configuración necesaria para restaurarla.

## Conclusión ejecutiva

ActiDev **no puede refrescarse desde Producción sin un respaldo y una restauración posterior**. La revisión de solo lectura confirmó que Producción no contiene una parte sustancial del desarrollo de Personas Morales que actualmente existe en ActiDev.

Al refrescar ActiDev desde Producción, Salesforce sustituirá la metadata, configuración y datos del sandbox por una copia del estado de Producción. En consecuencia, los elementos exclusivos o más recientes de ActiDev dejarán de estar disponibles hasta que se vuelvan a desplegar y configurar.

## Diferencias confirmadas

| Tipo | ActiDev respaldado | Encontrado en Producción | Riesgo del refresh |
|---|---:|---:|---|
| Clases Apex incluidas | 7 | 4 | Se perderían las 3 clases de seguridad/control del dashboard que no están en Producción. |
| LWC incluidos | 7 bundles (20 archivos) | 0 | Se perderían dashboard, tarjetas, mensajes y ruta PM. |
| Conjuntos de permisos | 5 | 0 | Se perdería el modelo de permisos PM por rol y el acceso a dashboards. |
| Flujos | 2 | 0 | Se perdería la creación guiada de oportunidad y su validación de contacto. |
| Campos revisados | 15 | 6 en el objeto esperado | Nueve campos PM no se encontraron en Producción. |

Clases faltantes en Producción:

- `BancasDashboardControllerTest`
- `BancasDashboardSecurity`
- `BancasDashboardSelector`

LWC faltantes en Producción:

- `bancasChart`
- `bancasDashboardComercial`
- `bancasDashboardHome`
- `bancasDashboardMessage`
- `bancasDashboardRelacionActividad`
- `bancasKpiCard`
- `pmOpportunityPath`

Conjuntos de permisos faltantes en Producción:

- `PM_Administrativo`
- `PM_Director`
- `PM_GestionComercial`
- `PM_Head`
- `PS_Acceso_Dashboards_Bancas`

Flujos faltantes en Producción:

- `PM_Nueva_Oportunidad_Con_Contacto`
- `PM_Validar_Opportunity_Contact_Role`

Campos PM no encontrados en Producción sobre el objeto esperado:

- `Account.Evalua_Nombre_de_la_Cuenta__c`
- `Account.Id_del_banquero_responsable__c`
- `Account.Tipo_de_cliente_PM__c`
- `Activity.Competidor__c`
- `Opportunity.Especifica_Otro_Producto__c`
- `Opportunity.Motivo_de_Perdida_PM__c`
- `Opportunity.Motivo_de_perdidaPM__c`
- `Opportunity.PM_Siguiente_paso__c`
- `Opportunity.Profit_and_Loss_PM__c`

## Respaldo realizado

Se extrajo desde ActiDev un paquete restaurable de 93 archivos mediante Metadata API. El respaldo incluye:

- 7 clases Apex.
- 7 bundles LWC, representados por 20 archivos recuperados.
- 5 páginas Lightning.
- 5 conjuntos de permisos y 1 permiso personalizado.
- 2 flujos.
- 6 layouts.
- 5 roles y 3 grupos públicos.
- 2 conjuntos de reglas de colaboración.
- 14 reportes, su carpeta, tipo de reporte y carpeta de dashboards.
- Metadata de objetos para campos, record type, proceso comercial y reglas de validación.
- Aplicación, acción rápida, vínculo, compact layout y custom metadata relacionados.
- Inventarios de usuarios PM, asignaciones de conjuntos de permisos y membresías de grupos.

El archivo principal es `backup/actidev-pre-refresh-20260925/metadata.zip` y su SHA-256 es:

`D6A38298C45C16A2E0A78DD592EA147C7A9B644D73F04DE2EACEAD4088EC40BC`

## Qué no restaura automáticamente el despliegue

Después del refresh deben reconstruirse o comprobarse por separado:

- Asignaciones de conjuntos de permisos a usuarios.
- Membresías de grupos públicos.
- Correspondencia de usuarios con roles.
- Datos de prueba y relaciones entre registros.
- Autorizaciones, sesiones, contraseñas, MFA y conexiones externas.
- Jobs programados, integraciones, endpoints y credenciales nombradas que dependan del ambiente.
- Activación efectiva de flujos y páginas por aplicación/perfil.

Los inventarios JSON son referencia; no deben insertarse usando los IDs anteriores porque los identificadores pueden cambiar con el refresh.

## Secuencia recomendada

1. Congelar cambios funcionales en ActiDev antes de iniciar el refresh.
2. Conservar este respaldo y verificar su hash.
3. Ejecutar el refresh.
4. Autorizar nuevamente ActiDev y realizar una validación del manifiesto sin desplegar.
5. Desplegar el paquete de restauración.
6. Reasignar permisos, grupos y roles por nombres funcionales.
7. Validar flujos, páginas, layouts, sharing, reportes y dashboards.
8. Ejecutar regresión HU1 a HU5 con los cuatro perfiles PM.
9. Comparar nuevamente ActiDev contra QA/ActiPM antes de continuar la cadena de ambientes.

## Dictamen

El refresh es viable, pero **solo si se programa la restauración inmediata del paquete y de sus asignaciones**. Sin esa restauración, ActiDev regresaría a un estado que no contiene la mayor parte de la solución de Personas Morales desarrollada hasta HU5.
