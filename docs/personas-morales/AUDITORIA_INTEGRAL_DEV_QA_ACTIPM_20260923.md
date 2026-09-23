# Auditoría integral Personas Morales — ActiDev, ActiQA y ActiPM

Fecha: 23 de septiembre de 2026

## Resultado ejecutivo

Los tres ambientes **no están completamente alineados**. Se recuperó el mismo inventario desde cada organización y se compararon 144 archivos de metadatos, además de validar configuración efectiva de permisos, colaboración, roles, OWD, flujo y reportes. Hay 122 archivos idénticos y 22 con ausencia o diferencia; dentro de estas últimas existen divergencias funcionales que deben corregirse antes de afirmar que la promoción está completa.

## Omisiones funcionales confirmadas

### ActiPM

1. Solo conserva `PM_Account_Comercial_Internal_Edit`; faltan las tres reglas HU5 de Opportunity:
   - `PM_Opportunity_Comercial_Internal_Read`
   - `PM_Opportunity_Comercial_to_Director_Edit`
   - `PM_Opportunity_Comercial_to_Head_Edit`
2. `PM_Director` tiene solo lectura, sin crear ni editar, sobre `Interaction`, `InteractionAttendee` e `InteractionRelatedAccount`. Dev y QA conceden crear/leer/editar.
3. `PM_Head` presenta la misma omisión de interacciones y además no tiene Delete sobre Opportunity; Dev y QA sí lo tienen.
4. Falta la vista de Oportunidades `AllOpportunities` (Todas/Vistos recientemente, según la traducción de Salesforce).

### ActiDev y ActiQA

5. La vista `Contact.Todos_Contactos` no está recuperable en Dev ni QA; sí existe en ActiPM.
6. La visibilidad de `FinServ__My_Clients` no coincide: Dev y QA la comparten con numerosos grupos globales; ActiPM la limita a `Head_PM` y subordinados. El filtro funcional sí es `Mine` en los tres.

### ActiDev

7. `Account.MyAccounts` usa `filterScope=Team`; QA y ActiPM usan `Mine`.
8. La página `Account_PM_Banca_Institucional` deja `Tipo_de_cliente_PM__c` opcional; únicamente QA lo marca obligatorio. ActiPM también lo deja opcional.
9. `OpenTextRazonabilidadRest` y su prueba están detrás de QA/ActiPM: en Dev no está la lógica de reintento para reasignar el propietario de Task.

### ActiQA

10. El record type `Cuentas_empresariales` no contiene la restricción de valores de `FinServ__Status__c`; Dev y ActiPM limitan el estado a `Active`, `Bloqueado` e `Inactive`.
11. `PM_GestionComercial` no contiene acceso a `FinServ__MoiAppConfigController`; Dev y ActiPM sí lo contienen.

### Código e informes con divergencia adicional

12. `Service_Utility_Trigger` de ActiPM no coincide con Dev/QA: difieren la consulta por sucursal y el cache de usuarios por nómina; ActiPM conserva API 62.0 y Dev/QA API 66.0.
13. El reporte `RPT_Clientes_por_Tipo_Institucional` filtra solo `Active` en Dev y `Active,Activo` en QA/ActiPM.
14. Cuatro reportes de la carpeta organizacional contienen `terr=all` solamente en Dev. Las carpetas segregadas de Banquero y Director sí tienen 14 reportes con los mismos nombres y alcances en los tres ambientes.

## Componentes alineados

- 122 de 144 archivos del inventario comparado son idénticos.
- `OpportunityTrigger` y `PM_Crear_Oportunidades` son idénticos en los tres ambientes.
- OWD: Account y Opportunity privados; Contact controlado por Account; Task y Event privados.
- Jerarquía de roles: Banquero → Director → Head, con Administrativo en rama paralela.
- Flujo `PM_Nueva_Oportunidad_Con_Contacto` activo y con validación de permiso.
- Regla `PM_OPP_Solo_Owner_Cierra` funcionalmente idéntica.
- Permisos base de Account, Contact, Opportunity, `Contact.AccountId` y los campos de AccountContactRelation, salvo las omisiones de ActiPM indicadas.
- Las vistas `MyOpportunities`, `Won`, `ClosingNextMonth` y `ClosingThisMonth` están presentes e idénticas.
- Las carpetas de reportes por rol están alineadas y no existen dashboards PM en ninguno de los tres ambientes.

## Diferencias no clasificadas como omisión

- `Bancas.app` contiene muchas anulaciones de página por perfiles que varían por ambiente. Son configuración global de la aplicación y requieren una decisión explícita antes de promoverlas en bloque.
- El orden de `Bloqueado` en la definición global de `FinServ__Status__c` cambia en ActiPM, pero el conjunto de valores es el mismo.
- ActiQA conserva el reporte exclusivo `Cuentas_por_propietario_QA_Modificado`.
- Usuarios y asignaciones nominales varían por ambiente y no deben igualarse automáticamente.

## Conclusión

No es correcto declarar todavía que ActiDev, ActiQA y ActiPM están completamente alineados. Las diferencias anteriores deben revisarse y promoverse mediante un paquete controlado; no se modificó ninguna de ellas durante esta auditoría.

## Evidencia

- `audit/full-three-way-20260923/source-comparison.json`
- `audit/hu5-dev-qa-20260923/actidev.json`
- `audit/hu5-dev-qa-20260923/actiqa.json`
- `audit/hu5-dev-qa-20260923/actipm.json`
- `audit/hu5-dev-qa-20260923/actidev-reports.json`
- `audit/hu5-dev-qa-20260923/actiqa-reports.json`
- `audit/hu5-dev-qa-20260923/actipm-reports.json`
