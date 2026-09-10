# Rollback de vistas de lista de Oportunidades en ActiPM

## Alcance

Este cambio limita el selector de vistas de lista para el alcance de Personas Morales a:

- Todas (visto recientemente), vista automática de Salesforce.
- Mis oportunidades (`MyOpportunities`).
- Ganadas (`Won`).
- Cierran próximo mes (`ClosingNextMonth`).
- Cierran este mes (`ClosingThisMonth`).

## Ajuste aplicado

Se retiró el grupo global `Todos_los_Usuarios` de 23 vistas corporativas, conservando los demás grupos explícitos de cada vista. También se eliminaron de ActiPM seis vistas generales que seguían apareciendo a Personas Morales: `AllOpportunities`, `Default_Opportunity_Pipeline`, `Mis_Oportunidades_Leads_Gran_Filtro`, `Mis_Oportunidades_PPR_2026`, `Mis_Opps_Seguro_Dotales_Educaci_n_2026` y `NewThisWeek`.

## Respaldo y rollback

`before/objects/Opportunity.object` contiene el estado recuperado de ActiPM antes del ajuste. Para revertir, se despliega `before/package.xml` en ActiPM.

`deployed/objects/Opportunity.object` contiene exactamente las 23 vistas modificadas y su configuración posterior. `deployed/package.xml` permite repetir el cambio de forma controlada.

No se deben desplegar ni eliminar en bloque las vistas de Producción durante el pase productivo: allí se conservarán las vistas existentes y se aplicarán solamente los ajustes expresamente aprobados.
