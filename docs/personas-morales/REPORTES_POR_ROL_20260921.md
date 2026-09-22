# Segregación de reportes de Personas Morales por rol

Fecha: 21 de septiembre de 2026

## Objetivo

Evitar que el perfil Banquero consulte en reportes información perteneciente a otros usuarios y conservar la visibilidad solicitada para Director, Head y Administrativo.

## Configuración aplicada

| Rol | Carpeta | Alcance de los 14 reportes | Acceso a la carpeta |
| --- | --- | --- | --- |
| Banquero | `PERSONAS_MORALES_BANQUERO` | `user` (registros propios) | Rol exacto `Banquero_Institucional` |
| Director | `PERSONAS_MORALES_DIRECTOR` | `team` (equipo) | Rol exacto `Director_PM` |
| Head | `PERSONAS_MORALES` | `organization` (organización) | Rol exacto `Head_PM`, edición total de contenidos |
| Administrativo | `PERSONAS_MORALES` | `organization` (organización) | Rol exacto `Administrativo_PM` |

Se eliminaron de la carpeta organizacional las comparticiones amplias por rol y subordinados y por los grupos públicos de edición/lectura.

El 22 de septiembre de 2026 se corrigió el acceso de `Head_PM` de `View` a `EditAllContents`. El conjunto `PM_Head` ya contenía los permisos funcionales de creación y edición; el nivel de acceso de la carpeta era el bloqueo que impedía guardar cambios.

## Ambientes

La configuración se aplicó y se verificó por Metadata API en:

- ActiDev
- ActiQA
- ActiPM

En cada ambiente se validaron 14 reportes por carpeta, el alcance uniforme correspondiente y las comparticiones por rol exacto. Las tres verificaciones finalizaron correctamente.

## Excepciones y dashboards

- El reporte exclusivo de QA `Cuentas_por_propietario_QA_Modificado` no se promovió ni se duplicó.
- La carpeta `PERSONAS_MORALES` no contiene dashboards en ninguno de los tres ambientes; por tanto, no hubo dashboards que segregar.

## Respaldo y rollback

Los archivos `audit/report-scope-20260921/<ambiente>/before.json` contienen la metadata previa de la carpeta y los reportes originales.

Para regresar al estado anterior:

1. Restaurar `PERSONAS_MORALES` y sus 14 reportes desde el respaldo del ambiente.
2. Eliminar las carpetas `PERSONAS_MORALES_BANQUERO` y `PERSONAS_MORALES_DIRECTOR` con sus reportes duplicados.
3. Validar nuevamente los accesos y los alcances mediante Metadata API.

## Validación funcional pendiente

Ejecutar UAT con un usuario representativo de Banquero, Director, Head y Administrativo para confirmar la información visible desde la interfaz de Salesforce.
