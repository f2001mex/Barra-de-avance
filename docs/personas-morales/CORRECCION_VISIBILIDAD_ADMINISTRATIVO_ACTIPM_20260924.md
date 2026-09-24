# Corrección de visibilidad — Administrativo en ActiPM

Fecha: 24 de septiembre de 2026

## Incidencia

Los usuarios con rol `Administrativo_PM` no obtenían registros en las vistas de Clientes y Oportunidades ni en los reportes de Personas Morales. Asimismo, no tenían disponible la vista de Contactos `Todos los Contactos`.

## Causa raíz

- Las reglas de colaboración de Account y Opportunity compartían registros con el grupo público `PM_Administrativos`, pero dicho grupo no contenía a los usuarios administrativos activos.
- La vista `Contact.Todos_Contactos` estaba compartida con Head y subordinados, pero no con el rol `Administrativo_PM`.

## Corrección aplicada

- Se incorporaron al grupo `PM_Administrativos` los dos usuarios activos que tienen el rol `Administrativo_PM`.
- Se agregó el rol `Administrativo_PM` a la audiencia de la vista `Contact.Todos_Contactos`.
- Se desplegó la vista corregida en ActiPM mediante el despliegue `0AfWF00000GNvve0AD`.

## Validación

- La consulta posterior confirmó que los dos usuarios administrativos activos pertenecen al grupo público.
- Salesforce generó accesos de lectura por regla para registros de Account y Opportunity dirigidos al grupo `PM_Administrativos`.
- La lectura del metadato desplegado confirmó que `Contact.Todos_Contactos` está compartida con `Administrativo_PM` y con `Head_PM` y sus subordinados.
- La carpeta organizacional de reportes de Personas Morales ya estaba compartida directamente con el rol `Administrativo_PM`; por tanto, al restaurar la visibilidad de registros, los reportes recuperan las filas accesibles.

## Alcance de seguridad

La corrección otorga lectura por las reglas de colaboración existentes. No habilita al perfil Administrativo para crear Oportunidades ni amplía permisos de edición.
