# ActiQA — revisión de Sebastián Montalvo Reyes

- Usuario confirmado: smont@actinver.com.mx.actiqa, 005WF00000agz2PYAQ.
- Perfil PM - Ejecutivo Personas Morales, rol Banquero_Institucional, conjunto PM_GestionComercial.
- Dos Account propios encontrados.
- Account.MyAccounts corregida de Team a Mine mediante Metadata API; success=true y lectura posterior confirmada. Etiqueta y columnas conservadas.
- Account.FinServ__My_Clients es otra vista, ya configurada con Mine; no fue modificada.
- HasReadAccess y HasEditAccess confirmados para cinco contactos ajenos de cuentas comerciales PM: 003WF00001IhgNTYAZ, 003WF00001JWZgBYAX, 003WF00001MmlsKYAR, 003WF00001MOqOcYAL y 003WF00001MgAysYAF.
- No se ha reproducido el error al registrar actividades como Sebastián. Se requiere contacto exacto y mensaje o captura para distinguir campos, acción, automatización o acceso a registros relacionados. No se enviaron correos de prueba ni se ampliaron permisos globales.

## Rollback

Restaurar Account.MyAccounts a filterScope=Team con las columnas y etiqueta del respaldo audit/sebastian-20260918/actiqa/MyAccounts-before.json. No modificar otros permisos o reglas.

## Corrección del error de campo obligatorio

La captura de Nuevo evento identificó AccountContactRelation.FinServ__PrimaryGroup__c sin acceso. Describe confirma campo booleano obligatorio (nillable=false), editable. Ni DEV ni QA incluían su FLS en PM_GestionComercial.

En QA se añadió readable=true y editable=true únicamente para ese campo en PM_GestionComercial. Metadata API devolvió success=true; FieldPermissions confirmó lectura/edición. Sebastián ya tiene este conjunto asignado, por lo que no requiere una asignación adicional. No se han cambiado Director, Head, Administrativo, perfiles o DEV/PM en esta corrección.

Respaldo previo del conjunto: audit/sebastian-20260918/actiqa/PM_GestionComercial-primarygroup-before.json. Rollback: restaurar el acceso previo a este campo (sin concesión por PM_GestionComercial), conservando los demás permisos del respaldo. Pendiente repetir Nuevo evento como Sebastián y registrar resultado; no se afirma resuelto el registro de tareas, llamadas y correos solo por esta corrección.

## Revisión integral del 21 de septiembre

- Las capturas confirmaron un segundo campo: el mensaje decía `IncludedInGroup`, pero Describe de QA confirmó el API name real `AccountContactRelation.FinServ__IncludeInGroup__c`. Se otorgó lectura/edición junto con `FinServ__PrimaryGroup__c` en PM_GestionComercial de QA.
- `FinServ__IncludeInGroup__c` no existe en DEV. En DEV se incorporó únicamente `FinServ__PrimaryGroup__c`; la diferencia se debe a la versión administrada y queda como ajuste específico de QA.
- Se detectó que una actualización parcial de PermissionSet había reemplazado temporalmente propiedades no enviadas. El conjunto completo fue restaurado de inmediato desde respaldo en QA y desde Git en DEV. Verificación posterior: Account, Contact, Opportunity e Interaction con Create/Edit; EditEvent, EditTask y EmailSingle activos; record types Account.Cuentas_empresariales y Opportunity.Oportunidad_Personas_Morales visibles.
- Los layouts `Account-Account - PM Banca Institucional` y `Contact-Contact - PM Banca Institucional` tenían la lista de acciones rápidas vacía. Se añadieron LogACall, NewTask, NewEvent y SendEmail primero en DEV y después en QA.
- Deploy layouts DEV: validación `0Afdp000009Px4XCAS`, despliegue `0Afdp000009Px69CAC`. QA: validación `0AfWF00000GIpdx0AD`, despliegue `0AfWF00000GILWF0A5`. Ambos 2/2 y exitosos.
- Restauración PermissionSet DEV: validación `0Afdp000009PwwTCAS`, despliegue `0Afdp000009Pwy5CAC`, exitoso.
- Sebastián conserva PM_GestionComercial, FinancialServicesCloudExtension y EinsteinActivityCaptureIncluded. Tiene dos cuentas propias y acceso Read/Edit efectivo a contactos ajenos consultados.

Pendiente UAT: cerrar/recargar sesión como Sebastián y comprobar crear/editar cliente, editar contacto y cambiar cuenta, cuatro interacciones, crear/editar oportunidad. Los despliegues y consultas de permisos no sustituyen estas pruebas.
