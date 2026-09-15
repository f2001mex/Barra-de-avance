# PMNOVA-293 — HU5 en ActiQA

## Despliegue

- Fuente: commit `19c6528` (`codex/pmn-293-actidev`).
- Validación previa: `0AfWF00000GAe4b0AD`, exitosa, 10/10 componentes, cero errores.
- Despliegue: `0AfWF00000GAe7p0AD`, exitoso, 10/10 componentes, cero errores.
- Componentes fuente: reglas de compartición Account y Opportunity; conjuntos de permisos PM_Director y PM_Head. No se desplegaron perfiles, roles ni asignaciones de usuarios.
- Nivel de pruebas del despliegue: `NoTestRun`; el resultado confirma la instalación de metadata, no una prueba funcional completa con cada usuario.

## Verificación posterior

- Perfil `PM - Ejecutivo Personas Morales` presente en los siete usuarios PM activos consultados.
- Banquero: Griselda Daniela Vargas Ochoa y Sebastián Montalvo Reyes — `PM_GestionComercial`, rol `Banquero_Institucional`.
- Director: Leonardo Manuel Ledezma Avila y Patricia Salinas Vega — `PM_Director`, rol `Director_PM`.
- Head: Tania Beatriz Jacome Ramos y Mauricio Beltran Flores — `PM_Head`, rol `Head_PM`.
- Administrativo: Sergio Eduardo Novelo Puga — `PM_Administrativo`, rol `Administrativo_PM`; sin modificación de sus permisos.
- Jerarquía comercial: Banquero bajo Director, Director bajo Head; Administrativo en otra rama.
- OWD conservado: Account y Opportunity privados; Contact controlado por Account.
- Reglas HU5 presentes: `PM_Account_Comercial_Internal_Edit`, `PM_Opportunity_Comercial_Internal_Read`, `PM_Opportunity_Comercial_to_Director_Edit` y `PM_Opportunity_Comercial_to_Head_Edit`. Se conservaron las dos reglas de lectura para Administrativos.
- Director y Head tienen lectura, creación y edición de Interaction, InteractionAttendee e InteractionRelatedAccount; Banquero mantiene estos permisos; Administrativo permanece de solo lectura.
- Opportunity Delete solo en `PM_Head` entre estos conjuntos. Ninguno recibió View All Records ni Modify All Records.
- Validación `PM_OPP_Solo_Owner_Cierra` permanece activa.

## Pendiente funcional

Probar con usuarios de Banquero, Director y Head la lectura/edición cruzada de clientes y contactos, creación de interacciones y las restricciones de edición/cierre/eliminación lógica de oportunidades. Las reglas acotan el acceso a la jerarquía PM; no conceden acceso universal a registros de ramas ajenas.

## Rollback

Restaurar las versiones anteriores de las cuatro reglas y de `PM_Director`/`PM_Head` siguiendo el plan en `PMNOVA-293_ACTIDEV.md`; conservar OWD, jerarquía de roles y la validación de cierre.
