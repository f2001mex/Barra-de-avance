# ActiPM — clientes y actividades en contactos

## Hallazgos

- ActiPM conectado: sandbox DV31017UT2, Org ID 00DWF00000Gxl892AB.
- Account.MyAccounts tenía filterScope=Team en PM, QA y DEV. Account.FinServ__My_Clients ya tenía Mine y es una vista diferente.
- En PM faltaba PM_Account_Comercial_Internal_Edit; estaba en QA y DEV. Contact está controlado por Account.
- PM_GestionComercial ya contiene EditEvent, EditTask, EmailSingle y CRUD de Contact e Interaction.
- Sebastián Montalvo Reyes está presente en QA, pero no fue localizado en el PM conectado. No se alteró ningún usuario por aproximación de nombre.

## Cambios y evidencia

- Aplicada la regla PM_Account_Comercial_Internal_Edit: Edit en Account y Contact para Head_PM y subordinados internos. Se conserva lectura para Administrativo.
- Account.MyAccounts: filterScope=Mine; se conservaron nombre, columnas y etiqueta Mis Cuentas. Esta vista estándar afecta a sus usuarios en este sandbox, no solo a PM.
- Validación: 0AfWF00000GGAWr0AP, Succeeded, 3/3.
- Despliegue: 0AfWF00000GGAa50AH, Succeeded, 3/3.
- ListView actualizada por Metadata API, success=true; lectura posterior confirma Mine.
- Despliegue NoTestRun. La instalación de metadata no confirma una prueba funcional de actividades o envío de correo.
- Respaldo previo: audit/sebastian-20260918/actipm/before.json. Evidencia: validation.json y deploy.json en la misma carpeta.

## Rollback

1. Restaurar Account.MyAccounts a filterScope=Team, manteniendo columnas y etiqueta respaldadas.
2. Retirar exclusivamente PM_Account_Comercial_Internal_Edit. Mantener las demás reglas Account; el respaldo contiene su estado previo.
3. No cambiar OWD ni permisos de usuarios al revertir este pase.

## Pendiente

Confirmar URL del sandbox y Username de Sebastián. Probar con él Mis Cuentas y la creación de evento, llamada, tarea y correo desde un contacto ajeno. Revisar el contacto exacto y su cuenta si siguen bloqueados. El acceso de la regla se limita a propietarios de la jerarquía comercial PM; no cubre automáticamente cuentas de otras ramas. No se envió correo de prueba.
