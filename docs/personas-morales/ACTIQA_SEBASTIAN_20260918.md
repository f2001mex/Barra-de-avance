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
