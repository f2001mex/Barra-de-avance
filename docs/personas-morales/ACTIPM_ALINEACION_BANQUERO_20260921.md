# ActiPM — alineación PM-Banquero con ActiQA

## Comparación previa

ActiPM coincidía con QA en CRUD de Account, Contact, Opportunity e Interaction; permisos EditEvent, EditTask y EmailSingle; record types PM; regla PM_Account_Comercial_Internal_Edit; y Account.MyAccounts con alcance Mine.

Faltaban en ActiPM los permisos de lectura/edición para AccountContactRelation.FinServ__PrimaryGroup__c y AccountContactRelation.FinServ__IncludeInGroup__c, además de las acciones LogACall, NewTask, NewEvent y SendEmail en los layouts PM de Account y Contact.

## Aplicación y evidencia

- Respaldo previo: audit/sebastian-20260921/actipm/before.json.
- Validación de layouts: 0AfWF00000GIquz0AD, Succeeded, 2/2.
- Despliegue de layouts: 0AfWF00000GIqwb0AD, Succeeded, 2/2.
- PermissionSet PM_GestionComercial actualizado como componente completo por Metadata API; success=true.
- Lectura posterior: ambos campos readable/editable, cuatro acciones en ambos layouts y CRUD Create/Edit conservado en Account, Contact, Opportunity e Interaction.
- No se modificaron usuarios, perfiles, roles, OWD, reglas adicionales ni datos.

## Rollback

Restaurar PM_GestionComercial y los dos layouts desde before.json. Retirar únicamente los dos FieldPermissions y las cuatro Quick Actions añadidas, preservando el resto del componente.

## Pendiente funcional

Probar con un Banquero de ActiPM: crear/editar cliente, editar contacto y cambiar cuenta, registrar llamada/tarea/evento/correo y crear/editar oportunidad. La validación de metadata no sustituye UAT.
