# Restricción de creación de oportunidades para Administrativo

Fecha: 22 de septiembre de 2026

## Resultado

El rol/conjunto Administrativo puede consultar oportunidades, pero no puede crearlas.

Se verificó que `PM_Administrativo` ya tenía `Opportunity.allowCreate = false`. Para proteger también la acción personalizada `Nueva Oportunidad PM`, se agregó una validación explícita al inicio del flujo `PM_Nueva_Oportunidad_Con_Contacto`.

## Control aplicado

- Permiso personalizado: `PM_Crear_Oportunidades`.
- Con permiso: `PM_GestionComercial` (Banquero), `PM_Director` y `PM_Head`.
- Sin permiso: `PM_Administrativo`.
- Si el usuario no tiene el permiso, el flujo termina en la pantalla `Sin_Permiso_Crear_Oportunidad` antes de consultar o crear registros.
- Administrativo conserva acceso de lectura a Oportunidades.

## Ambientes verificados

- ActiDev
- ActiQA
- ActiPM

En los tres ambientes se verificaron el permiso de objeto, la asignación del permiso personalizado, la decisión inicial del flujo y la pantalla de denegación.

## Rollback

Los respaldos previos están en `audit/admin-opportunity-create-20260922/<ambiente>/before.json`.

Para regresar al estado anterior:

1. Restaurar el flujo y los conjuntos de permisos desde el respaldo del ambiente.
2. Eliminar `PM_Crear_Oportunidades` si ya no tiene referencias.
3. Reactivar la versión anterior de `PM_Nueva_Oportunidad_Con_Contacto`.
