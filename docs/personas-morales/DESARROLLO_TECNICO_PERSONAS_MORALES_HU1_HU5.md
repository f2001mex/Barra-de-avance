# Documento técnico del desarrollo de Personas Morales

## Alcance

Este documento describe exclusivamente el desarrollo funcional implementado desde la HU1 hasta la HU5. Clasifica cada elemento como componente nuevo, componente existente modificado o componente existente reutilizado.

## Resumen por historias de usuario

| HU | Alcance |
| --- | --- |
| HU1 | Gestión de Clientes Personas Morales |
| HU2 | Gestión de Contactos |
| HU3 | Gestión de Oportunidades |
| HU4 | Registro de Actividades e Interacciones |
| HU5 | Seguridad Colaboración y Analítica por Rol |

## HU1 Gestión de Clientes Personas Morales

**Objetivo:** Permitir el alta, consulta y mantenimiento de Clientes empresariales con la información mínima necesaria para la operación institucional.

### Comportamiento

- El Cliente se registra en Account con el record type Cuentas_empresariales.
- La captura presenta información general, datos del banquero y datos adicionales de la Persona Moral.
- Se controlan segmento, estado, industria, tipo de cliente, identificador y relación con el banquero.
- Las listas Mis clientes y Todos los clientes respetan propiedad, jerarquía y reglas de compartición.

### Componentes

| Clasificación | Componente | Desarrollo |
| --- | --- | --- |
| Nuevo | Account.Tipo_de_cliente_PM__c | Picklist con la clasificación específica del Cliente PM. |
| Nuevo | Account.Id_del_banquero_responsable__c | Identificador del responsable comercial. |
| Existente modificado | Account.Segmento__c | Valores aplicables al record type empresarial. |
| Existente modificado | Account.FinServ__Status__c | Estados permitidos para el Cliente PM. |
| Existente reutilizado | Account.BanqueroAsignado__c | Relación con Banker utilizada por la lógica comercial. |
| Existente reutilizado | Account.Evalua_Nombre_de_la_Cuenta__c | Control existente empleado en la captura. |
| Existente reutilizado | Account.NombreBanqueroAsignado__c | Dato derivado o informativo del banquero. |
| Nuevo | Account.Cuentas_empresariales | Record type de Cliente empresarial. |
| Nuevo | Account_RecordType_Config.Default_Business | Configuración para asignar el record type empresarial. |
| Nuevo | Account_PM_Banca_Institucional | Lightning Record Page de Clientes PM. |
| Nuevo | Account Account PM Banca Institucional | Page Layout con campos y acciones de negocio. |
| Nuevo | Account_PM_Banca_Institucional compact layout | Resumen de datos clave del Cliente. |
| Nuevo | Account.Nuevo_Cliente_PM | Botón de alta desde la lista de Clientes. |
| Existente modificado | Bancas.app | Navegación y anulaciones de página para el perfil PM. |
| Existente modificado | Service_Utility_Trigger | Asignación de propietario, Banker e identificador de asesor. |

## HU2 Gestión de Contactos

**Objetivo:** Administrar los contactos de una Persona Moral y asegurar que cada contacto esté relacionado con un Cliente válido.

### Comportamiento

- Cada Contacto debe relacionarse con una Account.
- La captura valida nombre, apellidos y correo electrónico.
- La página muestra el Cliente asociado y permite navegar entre Cliente, Contacto y Oportunidades relacionadas.
- La relación AccountContactRelation participa en la agrupación FSC y en el registro de interacciones.

### Componentes

| Clasificación | Componente | Desarrollo |
| --- | --- | --- |
| Nuevo | Contact_PM_Banca_Institucional | Lightning Record Page de Contactos PM. |
| Nuevo | Contact Contact PM Banca Institucional | Page Layout de Contacto y acciones de interacción. |
| Nuevo | Contact.Todos_Contactos | Vista de todos los Contactos accesibles. |
| Existente modificado | Contact.AccountId | Permisos y edición de la cuenta asociada según el rol. |
| Existente modificado | AccountContactRelation.FinServ__PrimaryGroup__c | FLS requerido por procesos de FSC. |
| Existente modificado | AccountContactRelation.FinServ__IncludeInGroup__c | FLS requerido por la relación FSC cuando el campo existe. |

## HU3 Gestión de Oportunidades

**Objetivo:** Crear y gestionar Oportunidades institucionales desde un Cliente, con un Contacto principal y datos comerciales específicos.

### Comportamiento

- La acción Nueva Oportunidad PM inicia un Screen Flow desde Account.
- El flujo valida autorización, Cliente, Contacto, record type y datos capturados.
- La creación genera Opportunity y OpportunityContactRole principal como una sola operación funcional.
- El avance controla producto, monto, fecha, probabilidad, motivo de pérdida, reapertura y cierre por propietario.

### Componentes

| Clasificación | Componente | Desarrollo |
| --- | --- | --- |
| Nuevo | Opportunity.Oportunidad Persona Moral | Business Process con etapas PM. |
| Nuevo | Opportunity.Oportunidad_Personas_Morales | Record type utilizado por el flujo y la interfaz. |
| Nuevo | OpportunityPM | Lightning Record Page de la Oportunidad PM. |
| Nuevo | Opportunity Opportunity PM | Page Layout con datos de producto, inversión y cierre. |
| Nuevo | Account.Nueva_Oportunidad_PM | Quick Action que abre el Screen Flow. |
| Nuevo | PM_Nueva_Oportunidad_Con_Contacto | Screen Flow de autorización, captura y creación. |
| Nuevo | PM_Validar_Opportunity_Contact_Role | Flow before save que exige Contact Role al avanzar. |
| Nuevo | PM_Crear_Oportunidades | Custom Permission consultado por el Screen Flow. |
| Nuevo | pmOpportunityPath | LWC para el seguimiento de etapas. |
| Existente modificado | OpportunityTrigger | Se incorpora el evento after insert requerido por el proceso PM. |
| Existente modificado | Opportunity.Producto_Solicitado__c | Catálogo de productos utilizado por Personas Morales. |

## HU4 Registro de Actividades e Interacciones

**Objetivo:** Registrar llamadas, tareas, eventos y correos desde Clientes, Contactos y Oportunidades.

### Comportamiento

- Las acciones LogACall, NewTask, NewEvent y SendEmail se presentan en los layouts PM.
- Los formularios de Task y Event utilizan layouts con campos visibles y editables para el perfil PM.
- Las actividades pueden relacionarse con el Cliente, Contacto u Oportunidad conforme al acceso del usuario.
- Los campos Competidor y Contrato vinculado enriquecen el seguimiento comercial.

### Componentes

| Clasificación | Componente | Desarrollo |
| --- | --- | --- |
| Nuevo | Activity.Competidor__c | Competidor asociado a la interacción. |
| Nuevo | Activity.ContratoVinculado__c | Contrato relacionado con la actividad. |
| Existente modificado | Account y Contact Page Layouts | Se incluyen las cuatro acciones rápidas de interacción. |
| Existente modificado | Event Event Layout | Se asigna al perfil y record types de evento utilizados. |
| Existente modificado | Task General y Task Layout | Se asignan para capturar los datos de la tarea. |
| Existente modificado | Event.Location | FLS de lectura y edición para el formulario de evento. |
| Existente reutilizado | Einstein Activity Capture | Sincronización de correo y calendario mediante licencia y autorización individual. |

## HU5 Seguridad Colaboración y Analítica por Rol

**Objetivo:** Aplicar visibilidad organizacional y edición diferenciada para Banquero, Director, Head y Administrativo.

### Comportamiento

- Banquero, Director y Head consultan Clientes y Contactos y registran interacciones conforme a su acceso.
- Todos los roles comerciales consultan Oportunidades; Banquero edita las propias, Director edita las visibles y Head administra todas las visibles.
- Banquero y Director solo cierran Oportunidades propias; Head puede cerrar cualquier Oportunidad accesible.
- Administrativo consulta Clientes, Contactos, Oportunidades e informes y no crea Oportunidades.
- Los reportes se ejecutan con alcance propio, de equipo u organizacional según el rol.

### Componentes

| Clasificación | Componente | Desarrollo |
| --- | --- | --- |
| Nuevo | Jerarquía de roles PM | Personas Morales, Head, Director, Banquero y Administrativo. |
| Nuevo | PM_Administrativos | Grupo destinatario de lectura organizacional. |
| Nuevo | Reglas de compartición Account y Opportunity | Lectura o edición según jerarquía y rol. |
| Nuevo | PM_GestionComercial | Permission Set operativo del Banquero. |
| Nuevo | PM_Director | Permission Set del Director. |
| Nuevo | PM_Head | Permission Set del Head. |
| Nuevo | PM_Administrativo | Permission Set de consulta administrativa. |
| Nuevo | PS_Acceso_Dashboards_Bancas | Acceso a componentes analíticos de Bancas. |
| Nuevo | BancasDashboardSelector y Security | Consulta de indicadores y aplicación del contexto de seguridad. |
| Nuevo | Componentes LWC de dashboard | Inicio comercial, KPI, gráficas, relación de actividad y mensajes. |
| Nuevo | Carpetas y reportes por rol | 14 reportes funcionales con scope user, team u organization. |
| Nuevo | Actividades_con_Clientes_Actinver_V2 | Custom Report Type de actividades comerciales. |

## Reglas de validación

| Objeto | Regla | Control |
| --- | --- | --- |
| Account | PM_ACC_BP_Requerido | Identificador de Cliente obligatorio. |
| Account | PM_ACC_Sector_Requerido | Sector obligatorio. |
| Account | PM_ACC_Segmento_Requerido | Segmento obligatorio. |
| Account | PM_ACC_Status_Requerido | Estado obligatorio. |
| Account | PM_ACC_Tipo_Requerido | Tipo de cliente obligatorio. |
| Contact | PM_CON_Account_Requerida | Cuenta obligatoria. |
| Contact | PM_CON_Email_Requerido_Valido | Correo requerido y con formato válido. |
| Contact | PM_CON_FirstName_Formato | Formato del nombre. |
| Contact | PM_CON_LastName_Formato | Formato de apellidos. |
| Contact | PM_CON_MiddleName_Formato | Formato del segundo nombre. |
| Opportunity | PM_OPP_Account_Requerida | Cliente obligatorio. |
| Opportunity | PM_OPP_CloseDate_Valida | Fecha de cierre válida. |
| Opportunity | PM_OPP_Especifica_Otro | Detalle obligatorio cuando el producto es Otro. |
| Opportunity | PM_OPP_Monto_Mayor_Cero | Monto estimado mayor a cero. |
| Opportunity | PM_OPP_Motivo_Perdida_PM | Motivo obligatorio al perder. |
| Opportunity | PM_OPP_No_Reabrir_Cerrada | Impide reabrir una oportunidad cerrada. |
| Opportunity | PM_OPP_Producto_Requerido | Producto solicitado obligatorio. |
| Opportunity | PM_OPP_Solo_Owner_Cierra | Banquero y Director solo cierran oportunidades propias; Head queda exceptuado. |

## Modelo de permisos

| Conjunto | Account | Contact | Opportunity | Interaction | Attendee | Related Account |
| --- | --- | --- | --- | --- | --- | --- |
| PM_GestionComercial | CRU | CRU | CRU | CRU | CRU | CRU |
| PM_Director | CRU | CRU | CRU | CRU | CRU | CRU |
| PM_Head | CRU | CRU | CRUD | CRU | CRU | CRU |
| PM_Administrativo | R | R | R | R | R | R |

Leyenda: C crear, R leer, U actualizar y D eliminar.

## Reglas de colaboración

| Objeto | Regla | Acceso | Destino |
| --- | --- | --- | --- |
| Account | PM_Account_Comercial_Internal_Edit | Edit | Head y subordinados internos |
| Account | PM_Account_Comercial_to_Administrativos_Read | Read | PM_Administrativos |
| Opportunity | PM_Opportunity_Comercial_Internal_Read | Read | Jerarquía comercial PM |
| Opportunity | PM_Opportunity_Comercial_to_Director_Edit | Edit | Director_PM |
| Opportunity | PM_Opportunity_Comercial_to_Head_Edit | Edit | Head_PM |
| Opportunity | PM_Opportunity_Comercial_to_Administrativos_Read | Read | PM_Administrativos |

## Reportes

| Rol | Carpeta | Scope |
| --- | --- | --- |
| Banquero | PERSONAS_MORALES_BANQUERO | user |
| Director | PERSONAS_MORALES_DIRECTOR | team |
| Head | PERSONAS_MORALES | organization |
| Administrativo | PERSONAS_MORALES | organization |

## Componentes transversales

- `Bancas.app`: aplicación existente modificada para presentar la experiencia PM.
- `PM - Ejecutivo Personas Morales`: perfil base del desarrollo.
- `OpenTextRazonabilidadRest` y prueba: integración utilizada por la solución.
- `Service_Utility_Trigger` y prueba: lógica existente modificada para la asignación de Banker y propietario.
- `OpportunityTrigger`: trigger existente modificado para incorporar `after insert`.