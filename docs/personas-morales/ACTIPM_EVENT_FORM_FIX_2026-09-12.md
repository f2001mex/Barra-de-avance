# ActiPM — corrección del formulario Nuevo evento

Fecha: 2026-09-12  
Alcance: Personas Morales — perfiles Banquero, Director, Head y Administrativo.

## Hallazgo

El layout `Event-Event Layout` y las acciones de creación de eventos eran iguales en ActiDev, ActiQA y ActiPM. La diferencia estaba en el perfil base compartido `PM - Ejecutivo Personas Morales`: ActiPM no tenía asignado el layout de Event y el campo `Event.Location` no estaba visible/editable. Por ello, el modal Nuevo evento abría sin campos.

## Cambio aplicado

- Se asignó `Event-Event Layout` como layout predeterminado.
- Se asignó `Event-Event Layout` a los record types `Event.FinServ__AdvisorEvent` y `Event.FinServ__ClientAssociateEvent`.
- Se habilitó lectura y edición de `Event.Location`.
- No se modificaron ni reemplazaron los permission sets PM.

## Evidencia de despliegue

- Validación (dry-run): `0AfWF00000G7ZRF0A3` — Succeeded.
- Despliegue ActiPM: `0AfWF00000G7ZSr0AN` — Succeeded.
- Componente desplegado: perfil `PM - Ejecutivo Personas Morales`.

## Validación funcional

Con José Alberto Paredes Cuevas (PM - Banquero), desde Inicio > Eventos del día > Ver calendario > Nuevo evento, el formulario mostró los campos Asunto, Asignado a, Ubicación, Inicio, Fin, Tipo, Descripción, Nombre, Relacionado con y Recordatorio. La prueba se canceló sin crear datos.

La corrección aplica también a Director, Head y Administrativo porque todos usan el mismo perfil base; sus permission sets agregan permisos y no eliminan las asignaciones de layout del perfil.

## Rollback

Para regresar al estado anterior, retirar del perfil las tres asignaciones de `Event-Event Layout` y devolver `Event.Location` a no visible/no editable. Después ejecutar validación y despliegue del perfil únicamente.
