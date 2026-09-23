# Auditoría HU5 — ActiDev vs ActiQA

Fecha: 23 de septiembre de 2026

## Resultado ejecutivo

Las dos diferencias funcionales detectadas entre ActiDev y ActiQA fueron corregidas el 23 de septiembre de 2026 y verificadas nuevamente. HU5 queda alineada entre ambos ambientes en el alcance auditado.

## Correcciones aplicadas

1. Se agregó a `PM_GestionComercial` de ActiDev lectura y edición de `AccountContactRelation.FinServ__IncludeInGroup__c`.
2. Se retiró del perfil base `PM - Ejecutivo Personas Morales` de ActiDev el permiso de creación/edición de `Interaction`. Los permisos permanecen en los conjuntos de Banquero, Director y Head; Administrativo continúa en solo lectura.

## Componentes alineados

- OWD: Account y Opportunity privados; Contact controlado por Account; Task y Event privados.
- Jerarquía: Banquero → Director → Head; Administrativo en rama paralela bajo Personas Morales.
- Cuatro reglas HU5 de colaboración de Account y Opportunity.
- Permisos de Account, Contact, Opportunity e interacciones en `PM_GestionComercial`, `PM_Director`, `PM_Head` y `PM_Administrativo`, salvo la diferencia de campo indicada.
- Head: Delete de Opportunity habilitado, sin View All ni Modify All.
- Administrativo: lectura sin creación/edición de Account, Contact, Opportunity e interacciones.
- Regla `PM_OPP_Solo_Owner_Cierra` activa y con fórmula funcionalmente idéntica; solo cambian los saltos de línea.
- Flujo `PM_Nueva_Oportunidad_Con_Contacto` activo con validación `PM_Crear_Oportunidades` y pantalla de denegación.
- Acciones `LogACall`, `NewEvent`, `NewTask` y `SendEmail` presentes en layouts PM de Account y Contact.
- Carpetas de reportes Banquero y Director: 14 reportes cada una, mismos nombres, alcances y comparticiones.
- Carpeta organizacional: 14 reportes comunes alineados; Head con edición total y Administrativo con lectura.
- No existen dashboards dentro de `PERSONAS_MORALES` en ninguno de los dos ambientes.

## Diferencias esperadas

- ActiQA contiene el reporte adicional `Cuentas_por_propietario_QA_Modificado`; fue identificado previamente como excepción exclusiva de QA.
- Usuarios activos PM: ActiDev tiene cuatro usuarios consultados (dos Banqueros y dos Directores); ActiQA tiene siete (dos Banqueros, dos Directores, dos Head y un Administrativo). Las asignaciones de los usuarios presentes corresponden a sus roles.

## Evidencia

- `audit/hu5-dev-qa-20260923/actidev.json`
- `audit/hu5-dev-qa-20260923/actiqa.json`
- `audit/hu5-dev-qa-20260923/comparison.json`
- `audit/hu5-dev-qa-20260923/actidev-reports.json`
- `audit/hu5-dev-qa-20260923/actiqa-reports.json`

## Validación posterior

La lectura independiente posterior confirmó el permiso de campo en `PM_GestionComercial` y la ausencia de la concesión de `Interaction` en el perfil base de ActiDev.
