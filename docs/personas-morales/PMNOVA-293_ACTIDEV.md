# PMNOVA-293 — Amplitud de permisos (ActiDev)

## Alcance aplicado

- Cuenta y Contacto: lectura y edición entre Head PM y su jerarquía comercial interna.
- Oportunidad: lectura para Banquero, Director y Head PM.
- Oportunidad: edición de oportunidades de la jerarquía PM para Director y Head.
- Oportunidad: permiso de eliminación para PM - Head, sin conceder `Modify All Records`.
- Interacciones: creación y edición habilitadas para PM - Director y PM - Head, alineadas con PM - Banquero.
- PM - Administrativo: sin cambios.
- Reportes y dashboards: sin cambios; conservan su filtrado vigente.

## Controles conservados

- `PM_OPP_Solo_Owner_Cierra` permanece activa: Banquero y Director solo pueden cerrar oportunidades propias; Head conserva la excepción prevista.
- Los valores OWD no se modificaron. Cuenta y Oportunidad permanecen privadas; Contacto continúa controlado por Cuenta.
- No se otorgó `View All Records` ni `Modify All Records` a los conjuntos PM.

## Evidencias de despliegue

- Validación inicial: `0Afdp000009HyCHCA0` — exitosa, 10/10 componentes, 0 errores.
- Despliegue inicial: `0Afdp000009HyFVCA0` — exitoso, 10/10 componentes, 0 errores.
- Validación final con Delete para Head: `0Afdp000009HyIjCAK` — exitosa, 10/10 componentes, 0 errores.
- Despliegue final: `0Afdp000009HyKLCA0` — exitoso, 10/10 componentes, 0 errores.

## Comparación de referencia con Producción

Producción fue consultada en modo de solo lectura. Su modelo base coincide con ActiDev para los objetos relevantes: Cuenta privada, Contacto controlado por Cuenta, Oportunidad privada y Actividad privada. Por ello se mantuvo el modelo global y se acotó la ampliación mediante reglas de compartición para la jerarquía PM.

## Rollback

1. Retirar las reglas `PM_Account_Comercial_Internal_Edit`, `PM_Opportunity_Comercial_Internal_Read`, `PM_Opportunity_Comercial_to_Director_Edit` y `PM_Opportunity_Comercial_to_Head_Edit`.
2. Restaurar `Interaction`, `InteractionAttendee` e `InteractionRelatedAccount` en PM - Director y PM - Head a solo lectura.
3. Restaurar `Delete = false` para Opportunity en PM - Head.
4. Validar que `PM_OPP_Solo_Owner_Cierra` continúe activa.
