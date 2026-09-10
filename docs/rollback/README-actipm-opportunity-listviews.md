# Rollback de vistas de lista de Oportunidades en ActiPM

## Alcance

Este cambio limita el selector de vistas de lista para el alcance de Personas Morales a:

- Todas (visto recientemente), vista automática de Salesforce.
- Mis oportunidades (`MyOpportunities`).
- Ganadas (`Won`).
- Cierran próximo mes (`ClosingNextMonth`).
- Cierran este mes (`ClosingThisMonth`).

## Ajuste aplicado

No se eliminaron vistas. Se retiró el grupo global `Todos_los_Usuarios` de 23 vistas corporativas, conservando los demás grupos explícitos de cada vista. Esto evita que los usuarios de Personas Morales las reciban por pertenecer al grupo global.

## Respaldo y rollback

`before/objects/Opportunity.object` contiene el estado recuperado de ActiPM antes del ajuste. Para revertir, se despliega `before/package.xml` en ActiPM.

`deployed/objects/Opportunity.object` contiene exactamente las 23 vistas modificadas y su configuración posterior. `deployed/package.xml` permite repetir el cambio de forma controlada.

No se deben desplegar ni eliminar en bloque las vistas de Producción durante el pase productivo: allí se conservarán las vistas existentes y se aplicarán solamente los ajustes expresamente aprobados.
