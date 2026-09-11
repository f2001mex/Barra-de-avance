# ActiPM — correcciones de vistas y actividades PM

Fecha: 2026-09-11

## Cambios aplicados

- `Account.FinServ__My_Clients`: compartida con `Head_PM` y subordinados (Head, Director y Banquero); conserva alcance `Mine`.
- `Contact.Todos_Contactos`: alcance cambiado de `Mine` a `Everything` y compartida con `Head_PM` y subordinados.
- Eliminadas globalmente en ActiPM:
  - `Contact.FinServ__Upcoming_Birthdays_Next_7_Days`
  - `Contact.FinServ__Upcoming_RMDs_Next_7_Days`
- `EinsteinActivityCaptureIncluded`: verificada para los 11 usuarios activos con perfil `PM - Ejecutivo Personas Morales` y rol `Banquero_Institucional`, `Director_PM` o `Head_PM`.

## Evidencia

- Deploy de vistas corregidas: `0AfWF00000G70YL0AZ` — `Succeeded`.
- Validación previa del borrado: `0AfWF00000G73WD0AZ` — `Succeeded`.
- Deploy destructivo: `0AfWF00000G6zPO0AZ` — `Succeeded`, exactamente dos vistas eliminadas.
- Consulta posterior: únicamente `Contact.Todos_Contactos` permanece entre las tres vistas revisadas.
- Consulta posterior: 11 de 11 usuarios objetivo tienen `EinsteinActivityCaptureIncluded`.

## Consideración operativa

La asignación de permisos habilita Einstein Activity Capture, pero cada usuario debe completar la conexión/autorización de su correo y calendario. Hasta entonces, Salesforce puede seguir mostrando el aviso de sincronización incompleta y no cargar eventos externos.

## Rollback

- Las definiciones previas de las dos vistas eliminadas están en `docs/rollback/actipm-contact-upcoming-listviews/`.
- Para revertir las vistas modificadas, retirar `roleAndSubordinates Head_PM` de `FinServ__My_Clients` y restaurar `Todos_Contactos` con `filterScope=Mine` y los roles individuales originales.
- Para revertir Einstein Activity Capture, eliminar únicamente las asignaciones de `EinsteinActivityCaptureIncluded` creadas para los usuarios PM afectados.
