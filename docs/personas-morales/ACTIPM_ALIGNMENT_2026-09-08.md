# Alineación de Personas Morales en ActiPM

Fecha de corte: 8 de septiembre de 2026.

## Fuentes de referencia

- ActiDev: versión funcional más reciente de Personas Morales.
- ActiQA: versión de integración validada y fuente para dependencias comunes.
- ActiPM: sandbox destino, creado desde Producción.
- Fullprodu: consultado solo como antecedente; no se utilizó como fuente de despliegue.

## Alcance revisado

Account, Contact, Opportunity y Activity; campos, record types, layouts, Lightning pages, listas de vista, reglas de validación, quick actions, botones, aplicación Bancas, permisos, roles, grupos, sharing rules, reportes, dashboards, Apex, triggers, flows y LWC.

## Resultado

El núcleo de Personas Morales de ActiPM coincide con DEV/QA: dashboards, controladores, seguridad, flow `PM_Nueva_Oportunidad_Con_Contacto`, flow de Opportunity Contact Role, layouts PM, páginas Lightning, LWC, campos PM, reglas PM, permisos, roles, grupos, sharing rules y reportes.

Se incorporaron cuatro componentes que faltaban en ActiPM y estaban presentes en DEV/QA:

- `Account.Evalua_Nombre_de_la_Cuenta__c`
- `Activity.ContratoVinculado__c`
- `OpenTextRazonabilidadRest`
- `OpenTextRazonabilidadRest_Test`

Despliegue aplicado: `0AfWF00000G1d9N0AR` (4 de 4 componentes, sin errores).

Prueba posterior: `OpenTextRazonabilidadRest_Test`, 9 de 9 métodos exitosos; cobertura de la clase `OpenTextRazonabilidadRest`: 77%.

La dependencia de Sales Engagement quedó habilitada y las clases `PSTA_Account_thr` y `PSTA_FACCadenceCompletion_cls` fueron recompiladas previamente. La prueba `Service_Utility_TriggerTest` pasó 9 de 9 métodos.

## Control DevOps agregado

- Manifiesto canónico: `manifest/package-personas-morales.xml`.
- La configuración de Search Layout de Account conserva `Nuevo_Cliente_PM` en `listViewButtons`; este detalle no estaba versionado y podía ocultar el botón aun con un despliegue exitoso.
- La aplicación Bancas se capturó desde la fusión funcional de ActiPM para evitar referencias a componentes ajenos existentes en DEV/QA (`rdocPendingInbox` y `Task_Record_Page`).
- El record type `Account.Cuentas_empresariales` se versionó desde la variante compatible de ActiPM. La recuperación completa de DEV incluía el valor ajeno `Bloqueado`, inexistente en ActiPM, por lo que no se utilizó esa variante.

## Promoción posterior validada

- La versión vigente de DEV de `OpportunityTrigger`, que incorpora el evento `after insert`, se promovió correctamente a QA (`0AfWF00000G1eGj0AJ`) y ActiPM (`0AfWF00000G1eIL0AZ`).
- Se creó el punto de rollback de Git `pm-pre-opportunity-after-insert-20260908`, anterior a esta promoción.
- En ActiPM se corrigió la visibilidad de las listas de Account desde la configuración controlada en Git. Las listas operativas quedaron restringidas a `Banqueros_Postventa` o `Directores_Postventa`, según corresponda. Despliegue: `0AfWF00000G1fr70AB`.
- Para la prueba de Griselda Daniela Vargas Ochoa en ActiPM se alineó la licencia/conjunto `Financial Services Cloud Extension` y se completaron los datos operativos de `Banker`, `BranchUnit` y `BranchUnitBusinessMember`. Estos tres últimos son datos de referencia y no metadata desplegable.

## Hallazgos no promovidos

- ActiPM contiene dos vistas privadas adicionales de Opportunity. No se eliminaron porque no son parte del paquete PM ni están compartidas globalmente.
- `Segmento__c` tiene los mismos valores permitidos para `Cuentas_empresariales` en DEV, QA y ActiPM: `Gobierno` e `Institucional`. Las opciones adicionales observadas pertenecen a valores maestros u otros tipos de registro, no a una diferencia del record type PM.

## Validaciones de paquete

- Paquete PM sin componentes ajenos: validación exitosa `0AfWF00000G1dHR0AZ`.
- Aplicación Bancas fusionada de ActiPM: validación exitosa `0AfWF00000G1de10AB`.
- Conjuntos `PM_Administrativo`, `PM_Director`, `PM_GestionComercial`, `PM_Head` y `PS_Acceso_Dashboards_Bancas`: iguales entre DEV, QA y ActiPM.
- Permisos de Account, Contact y Opportunity: iguales entre DEV, QA y ActiPM para el perfil `PM - Ejecutivo Personas Morales` y los conjuntos PM.
