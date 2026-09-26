# Respaldo de ActiDev previo al refresh

Fecha de extracción: 25 de septiembre de 2026.

## Contenido

- `metadata.zip`: extracción Metadata API de los componentes de Personas Morales definidos en el manifiesto vigente.
- `metadata/`: la misma extracción descomprimida y lista para inspección.
- `package-personas-morales-restore.xml`: manifiesto de restauración.
- `retrieve-result.json`: resultado y propiedades de los archivos recuperados.
- `organization.json`: identificación de ActiDev al momento del respaldo.
- `users-pm.json`: inventario de usuarios activos ligados a roles o perfiles PM.
- `permission-set-assignments.json`: asignaciones de conjuntos de permisos PM.
- `groups.json` y `group-members.json`: grupos públicos PM y sus miembros.
- `production-comparison-evidence.json`: evidencia del comparativo de existencia contra Producción.

## Integridad

SHA-256 de `metadata.zip`:

`D6A38298C45C16A2E0A78DD592EA147C7A9B644D73F04DE2EACEAD4088EC40BC`

La extracción finalizó con estado `Succeeded` y contiene 93 archivos. No contiene contraseñas, tokens ni sesiones.

## Uso posterior al refresh

1. Validar que el refresh concluyó y que ActiDev tiene un nuevo estado estable.
2. Autorizar nuevamente el ambiente ActiDev en Salesforce CLI si cambió su autenticación.
3. Ejecutar primero una validación del paquete con `package-personas-morales-restore.xml`.
4. Corregir dependencias reportadas por la validación antes de desplegar.
5. Desplegar el paquete.
6. Reasignar conjuntos de permisos y membresías usando los inventarios JSON como referencia; no reutilizar IDs antiguos.
7. Verificar activación de flujos, aplicación Lightning, páginas, layouts, reglas de colaboración, reportes y dashboards.
8. Ejecutar pruebas funcionales HU1 a HU5 con Banquero, Director, Head y Administrativo.

Los IDs de usuarios, grupos y registros son evidencia del estado previo; después del refresh deben resolverse nuevamente por `Username`, `DeveloperName` o nombre funcional.
