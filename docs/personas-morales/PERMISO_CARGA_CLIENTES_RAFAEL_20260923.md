# Permiso de carga de Tipo de cliente para Rafael

Fecha de cierre: 23 de septiembre de 2026

## Diagnóstico

Se comparó al usuario Rafael Baruk Reyna Contreras entre ActiQA y ActiPM.

- En ambos ambientes utiliza el perfil `System Administrator` y tiene acceso API.
- En ActiQA, el perfil concede lectura y edición sobre `Account.Tipo_de_cliente_PM__c`.
- En ActiPM, ninguna de sus fuentes de permisos concedía acceso explícito al campo, por lo que Data Loader no lo mostraba para mapeo.

## Corrección en ActiPM

Se creó y asignó exclusivamente a Rafael el conjunto `PM_Carga_Clientes` (`PM - Carga de Clientes`) con:

- Lectura de `Account.Tipo_de_cliente_PM__c`.
- Edición de `Account.Tipo_de_cliente_PM__c`.
- Sin permisos adicionales sobre otros campos u objetos.

La asignación y los permisos de campo fueron verificados mediante API.

## Uso en Data Loader

El campo debe mapearse con el nombre API `Tipo_de_cliente_PM__c`. Rafael debe cerrar la sesión de Data Loader, iniciar nuevamente en ActiPM y volver a seleccionar el objeto `Account` para refrescar la descripción de campos.

## Rollback

El respaldo previo de las asignaciones del usuario está en `audit/rafael-account-type-pm-20260922/actipm/before.json`.

Para revertir, retirar de Rafael la asignación `PM_Carga_Clientes` y eliminar el conjunto si no tiene otras asignaciones.
