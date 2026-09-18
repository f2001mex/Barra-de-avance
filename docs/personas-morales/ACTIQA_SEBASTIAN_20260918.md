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
