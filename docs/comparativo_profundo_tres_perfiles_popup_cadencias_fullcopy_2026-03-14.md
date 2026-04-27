# Comparativo Profundo de Perfiles y Analisis del Popup de Cadencias

## Objetivo

Comparar de forma profunda los perfiles `Asesor Soluciones`, `Banquero Wealth Management` y `Banquero Privada`, usando la metadata recuperada del proyecto, para identificar diferencias que puedan explicar por que el popup estandar de finalizacion de cadencias se muestra para `Asesor Soluciones` y no se muestra para los perfiles banquero.

## Fuentes Analizadas

1. `force-app/main/default/profiles/Asesor Soluciones.profile-meta.xml`
2. `force-app/main/default/profiles/Banquero Wealth Management.profile-meta.xml`
3. `force-app/main/default/profiles/Banquero Privada.profile-meta.xml`
4. Pruebas funcionales realizadas en `fullcopy` con tres usuarios y cuentas reales.
5. Validacion previa de que el popup aparece cuando `ActionCadenceTracker.State` pasa a `Complete`.

## Limite Tecnico del Analisis

La metadata de perfiles recuperada localmente contiene `userPermissions`, pero no expone en estos archivos una fotografia completa de:

- `objectPermissions`
- `fieldPermissions`
- `classAccesses`
- `applicationVisibilities`
- `tabVisibilities`
- `layoutAssignments`

Por lo tanto, esta comparacion es profunda para permisos de sistema, pero no es suficiente por si sola para afirmar diferencias de acceso efectivo a objetos o features no reflejados en estos XML.

## Conclusiones Ejecutivas

1. Los tres perfiles ya comparten los permisos base que mas probablemente podrian relacionarse con la ejecucion del proceso o la experiencia Lightning: `EnableNotifications`, `LightningExperienceUser`, `RunFlow`, `EditTask`, `ActivitiesAccess`.
2. Las diferencias reales entre perfiles estan concentradas en colaboracion, contenido, reportes, dashboards, gobierno de datos y monitoreo.
3. No aparece en estos perfiles una diferencia visible de `userPermissions` que explique de forma directa el popup estandar de finalizacion de cadencia.
4. El hallazgo principal es negativo pero util: la causa no parece estar en los permisos de sistema visibles del perfil.
5. La explicacion mas probable sigue siendo una combinacion de permisos efectivos no reflejados aqui, feature access de Sales Engagement, visibilidad de app/tab o configuracion a nivel usuario/cliente.

## Evidencia Funcional Relevante

1. `Asesor Soluciones` si muestra el popup.
2. `Banquero Wealth Management` no muestra el popup.
3. `Banquero Privada` no muestra el popup.
4. En los tres casos, el backend si completa la cadencia: el cambio tecnico real ocurre cuando `ActionCadenceTracker.State` pasa a `Complete`.
5. Eso confirma que el problema no esta en Apex, Flow o Trigger del cierre, sino en la capa de entrega/render de la notificacion estandar o en permisos efectivos del usuario.

## Conteo de userPermissions por Perfil

| Perfil | Total userPermissions |
|---|---|
| Asesor Soluciones | 43 |
| Banquero Wealth Management | 49 |
| Banquero Privada | 48 |

Lectura:

1. Los perfiles banquero tienen mas permisos de sistema visibles que `Asesor Soluciones`.
2. Eso hace menos probable que el popup falte por una carencia simple de `userPermissions` en los banqueros.

## Permisos Comunes a los Tres Perfiles

Los tres perfiles comparten esta base:

- `ActivitiesAccess`
- `AllowUniversalSearch`
- `AllowViewKnowledge`
- `ApexRestServices`
- `ApiEnabled`
- `AssignTopics`
- `CanAccessCE`
- `ChatterInternalUser`
- `ConvertLeads`
- `CreateCustomizeFilters`
- `EditEvent`
- `EditOppLineItemUnitPrice`
- `EditTask`
- `EmailMass`
- `EmailSingle`
- `EnableNotifications`
- `ExportReport`
- `LightningConsoleAllowedForUser`
- `LightningExperienceUser`
- `ListEmailSend`
- `RunFlow`
- `RunReports`
- `SendExternalEmailAvailable`
- `ShareFilesWithNetworks`
- `ViewHelpLink`

## Impacto de los Comunes Sobre el Popup

1. `EnableNotifications` ya esta presente en los tres perfiles comparados en la metadata actual.
2. `LightningExperienceUser` tambien esta presente en los tres.
3. `RunFlow` y `EditTask` tambien estan presentes en los tres.
4. Por lo tanto, estos permisos no discriminan entre el perfil que si ve el popup y los dos perfiles que no lo ven.

## Permisos Exclusivos de Asesor Soluciones

Estos permisos aparecen solo en `Asesor Soluciones`:

- `ConnectOrgToEnvironmentHub`
- `ConsentApiUpdate`
- `CreateLtngTempFolder`
- `CreateWorkspaces`
- `ManageC360AConnections`
- `ManageHubConnections`
- `ManageRecommendationStrategies`
- `RetainFieldHistory`
- `ScheduleReports`
- `TransferAnyEntity`
- `UseTeamReassignWizards`
- `ViewDataAssessment`
- `ViewDataLeakageEvents`
- `ViewEventLogFiles`
- `ViewPlatformEvents`
- `ViewPublicDashboards`
- `ViewPublicReports`
- `ViewUserPII`

### Interpretacion Tecnica

1. Estos permisos son mas cercanos a gobierno, integraciones, analitica, monitoreo y acceso operativo a datos.
2. Ninguno de ellos apunta de forma natural a la visualizacion de notificaciones estandar de cadencias.
3. Aun asi, si hubiera una dependencia indirecta del popup con alguna capacidad de monitoreo/eventos, el candidato menos debil seria `ViewPlatformEvents`; pero eso seria una hipotesis fragil y sin evidencia de soporte.

## Permisos Comunes a los Dos Banqueros y Ausentes en Asesor Soluciones

Los perfiles `Banquero Wealth Management` y `Banquero Privada` comparten, y `Asesor Soluciones` no tiene, los siguientes permisos:

- `AddDirectMessageMembers`
- `ChatterEditOwnPost`
- `ChatterFileLink`
- `ChatterInviteExternalUsers`
- `ChatterOwnGroups`
- `ContentWorkspaces`
- `CreateTopics`
- `DistributeFromPersWksp`
- `EditTopics`
- `ImportPersonal`
- `MassInlineEdit`
- `OverrideForecasts`
- `RemoveDirectMessageMembers`
- `SelectFilesFromSalesforce`
- `SendSitRequests`
- `ShowCompanyNameAsUserBadge`
- `SubmitMacrosAllowed`
- `SubscribeToLightningReports`
- `TransactionalEmailSend`
- `UseWebLink`
- `ViewDeveloperName`
- `ViewTrustMeasures`

### Interpretacion Tecnica

1. Estos permisos estan orientados a colaboracion, contenido, reportes Lightning, macros y experiencia de usuario.
2. Si existiera un problema de falta de capacidades Lightning o notificaciones, estos perfiles deberian estar mejor posicionados, no peor.
3. El hecho de que precisamente estos perfiles no vean el popup debilita la hipotesis de que el problema este en un permiso simple del perfil.

## Diferencias Entre Banquero Wealth Management y Banquero Privada

Solo en `Banquero Wealth Management`:

- `CreateCustomizeReports`
- `CreateReportFolders`

Solo en `Banquero Privada`:

- `CreateCustomizeDashboards`

### Interpretacion Tecnica

1. La diferencia entre ambos perfiles banquero es marginal.
2. Esta diferencia se concentra en reportes y dashboards.
3. No tiene relacion defendible con el popup de cierre de cadencias.

## Matriz de Hallazgos y Posible Impacto

| Grupo de permisos | Perfil(es) | Posible impacto en popup | Lectura tecnica |
|---|---|---|---|
| `EnableNotifications` | Los 3 | Bajo | Ya no discrimina entre el perfil que si ve el popup y los dos que no |
| `LightningExperienceUser` | Los 3 | Bajo | Los tres operan en experiencia Lightning |
| `RunFlow` | Los 3 | Nulo o bajo | El popup no depende del Flow custom segun las pruebas realizadas |
| `EditTask` / `ActivitiesAccess` | Los 3 | Bajo | Las pruebas mostraron que el popup no nace por cambios en `Task` |
| Gobierno / monitoreo (`ViewPlatformEvents`, `ViewEventLogFiles`, etc.) | Solo Asesor | Bajo | Diferencia real, pero sin nexo claro con popup estandar |
| Colaboracion / contenido / reportes Lightning | Ambos banqueros | Bajo o inverso | Si ayudaran al popup, los banqueros deberian verlo y ocurre lo contrario |
| Reportes / dashboards entre banqueros | WM o Privada | Nulo | No explica por que ambos fallan igual |

## Referencias de Archivo y Linea

### Permisos base comunes

- `EditTask`
  - `force-app/main/default/profiles/Asesor Soluciones.profile-meta.xml:71`
  - `force-app/main/default/profiles/Banquero Wealth Management.profile-meta.xml:95`
  - `force-app/main/default/profiles/Banquero Privada.profile-meta.xml:91`
- `EnableNotifications`
  - `force-app/main/default/profiles/Asesor Soluciones.profile-meta.xml:83`
  - `force-app/main/default/profiles/Banquero Wealth Management.profile-meta.xml:111`
  - `force-app/main/default/profiles/Banquero Privada.profile-meta.xml:107`
- `LightningExperienceUser`
  - `force-app/main/default/profiles/Asesor Soluciones.profile-meta.xml:95`
  - `force-app/main/default/profiles/Banquero Wealth Management.profile-meta.xml:127`
  - `force-app/main/default/profiles/Banquero Privada.profile-meta.xml:123`
- `RunFlow`
  - `force-app/main/default/profiles/Asesor Soluciones.profile-meta.xml:119`
  - `force-app/main/default/profiles/Banquero Wealth Management.profile-meta.xml:147`
  - `force-app/main/default/profiles/Banquero Privada.profile-meta.xml:143`

### Exclusivos de Asesor Soluciones

- `ConnectOrgToEnvironmentHub`
  - `force-app/main/default/profiles/Asesor Soluciones.profile-meta.xml:39`
- `ManageRecommendationStrategies`
  - `force-app/main/default/profiles/Asesor Soluciones.profile-meta.xml:111`
- `ViewPlatformEvents`
  - `force-app/main/default/profiles/Asesor Soluciones.profile-meta.xml:163`
- `ViewUserPII`
  - `force-app/main/default/profiles/Asesor Soluciones.profile-meta.xml:175`

### Comunes a ambos banqueros

- `AddDirectMessageMembers`
  - `force-app/main/default/profiles/Banquero Wealth Management.profile-meta.xml:11`
  - `force-app/main/default/profiles/Banquero Privada.profile-meta.xml:11`
- `ChatterInviteExternalUsers`
  - `force-app/main/default/profiles/Banquero Wealth Management.profile-meta.xml:51`
  - `force-app/main/default/profiles/Banquero Privada.profile-meta.xml:51`
- `ContentWorkspaces`
  - `force-app/main/default/profiles/Banquero Wealth Management.profile-meta.xml:59`
  - `force-app/main/default/profiles/Banquero Privada.profile-meta.xml:59`
- `SelectFilesFromSalesforce`
  - `force-app/main/default/profiles/Banquero Wealth Management.profile-meta.xml:155`
  - `force-app/main/default/profiles/Banquero Privada.profile-meta.xml:151`
- `SubscribeToLightningReports`
  - `force-app/main/default/profiles/Banquero Wealth Management.profile-meta.xml:179`
  - `force-app/main/default/profiles/Banquero Privada.profile-meta.xml:175`
- `ViewTrustMeasures`
  - `force-app/main/default/profiles/Banquero Wealth Management.profile-meta.xml:199`
  - `force-app/main/default/profiles/Banquero Privada.profile-meta.xml:195`

### Diferencias entre los dos perfiles banquero

- `CreateCustomizeReports`
  - `force-app/main/default/profiles/Banquero Wealth Management.profile-meta.xml:71`
- `CreateReportFolders`
  - `force-app/main/default/profiles/Banquero Wealth Management.profile-meta.xml:75`
- `CreateCustomizeDashboards`
  - `force-app/main/default/profiles/Banquero Privada.profile-meta.xml:67`

## Dictamen Tecnico

1. No hay evidencia en los `userPermissions` comparados de que el popup este bloqueado por un permiso de sistema faltante en `Banquero Wealth Management` o `Banquero Privada`.
2. Dado que ambos perfiles banquero tienen incluso mas permisos visibles que `Asesor Soluciones`, el problema no apunta a una carencia simple de perfil.
3. Si la causa sigue estando en seguridad/configuracion, lo mas probable es que este en alguno de estos niveles:
   - permisos efectivos no visibles en esta recuperacion de perfil
   - feature access o licencia de Sales Engagement no expuesta aqui
   - visibilidad de app/tab/componente
   - configuracion personal del usuario o comportamiento del navegador
4. La comparacion de perfiles, por si sola, no explica el comportamiento observado del popup.

## Siguiente Paso Recomendado

1. Comparar permisos efectivos por usuario en org, no solo el XML del perfil.
2. Revisar acceso efectivo a objetos y features relacionados con `ActionCadenceTracker`, `ActionCadenceStepTracker`, `Task` y Sales Engagement.
3. Revisar preferencias personales de notificaciones y comportamiento del navegador de los usuarios banquero.
4. Si quieres cerrar la hipotesis de seguridad, el siguiente entregable correcto es una matriz de `usuario -> perfil -> permission sets -> object access -> feature access -> resultado popup`.
