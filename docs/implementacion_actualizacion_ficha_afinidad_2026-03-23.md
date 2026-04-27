# Implementacion de la Actualizacion de la Ficha de Afinidad

Fecha de actualizacion: 2026-03-24

## 1. Alcance y fuente de referencia

Este documento describe la implementacion vigente de la funcionalidad de Ficha de Afinidad tomando como fuente principal el ambiente `fullcopy`.

- Ambiente base del documento: `fullcopy`
- Fecha de validacion: `2026-03-24`
- Contraste adicional: `actiqa`

Resultado de la validacion:

- `fullcopy` y `actiqa` estan alineados en la logica funcional activa revisada para Ficha de Afinidad.
- `actidev` no se toma como fuente de verdad para este documento porque contiene cambios de prueba y componentes en pausa.

## 2. Objetivo funcional

La funcionalidad de Ficha de Afinidad permite:

- Calcular el porcentaje de avance de captura en la cuenta.
- Reflejar ese porcentaje en la tarea de Postventa asociada a la ficha.
- Marcar automaticamente la tarea como contactada cuando la cuenta ya esta al `100%` en escenarios definidos por flow.
- Controlar mediante validacion si la tarea puede guardarse con estatus de contacto cuando la ficha no ha llegado a `100%`.

## 3. Campos involucrados

### 3.1 Account

#### `Account.AvanceNum1FAC__c`

- Tipo: `Number(3,0)`
- Funcion: almacena el numero de preguntas aplicables para el calculo de avance.
- Fuente de actualizacion: flow `Flow_Avance_FAC`.

#### `Account.AvanceNum2FAC__c`

- Tipo: `Number(3,0)`
- Funcion: almacena el numero de preguntas contestadas.
- Fuente de actualizacion: flow `Flow_Avance_FAC`.

#### `Account.Avance_FAC__c`

- Tipo: `Formula (Percent)`
- Funcion: expone el porcentaje final de avance de la ficha.
- Formula actual:

```txt
IF(
  AvanceNum1FAC__c = 0,
  0,
  IF(
    (AvanceNum2FAC__c / AvanceNum1FAC__c) >= 0.9,
    1,
    (AvanceNum2FAC__c / AvanceNum1FAC__c)
  )
)
```

- Regla de negocio relevante:
  - Si el avance llega al `90%` o mas, el campo se muestra como `100%`.

### 3.2 Activity / Task

#### `Task.Avance_FAC__c`

- Objeto fisico: `Activity` (usable en `Task`).
- Tipo: `Formula (Percent)`.
- Funcion: replica en la tarea el valor actual de `Account.Avance_FAC__c`.
- Formula actual:

```txt
Account.Avance_FAC__c
```

- Implicacion funcional:
  - La tarea no guarda una fotografia independiente del avance; muestra el valor vigente de la cuenta.

#### `Task.El_cliente_fue_contactado__c`

- Objeto fisico: `Activity` (usable en `Task`).
- Tipo: `Picklist`.
- Valores identificados:
  - `Si`
  - `No`
  - `No quiere ser contactado`
- Funcion:
  - Permite registrar el resultado del contacto en la tarea.
  - Su cambio tambien puede actualizar informacion de contacto en la cuenta mediante Apex.

## 4. Flows activos en fullcopy

### 4.1 `Flow_Avance_FAC`

- Tipo: `Record-Triggered Flow`
- Objeto: `Account`
- Momento de ejecucion: `Before Save`
- Evento: `Create and Update`
- Version activa en `fullcopy`: `v3`
- Ultima modificacion validada: `2026-03-10`

#### Funcion

Calcula los contadores base de la Ficha de Afinidad:

- `AvanceNum1FAC__c`: preguntas aplicables.
- `AvanceNum2FAC__c`: preguntas contestadas.

#### Logica actual

1. Inicializa:
   - `vAplicables = 0`
   - `vLlenos = 0`
2. Suma `16` a `vAplicables`.
3. Evalua 16 preguntas base mediante formulas tipo `IF(ISBLANK(...),0,1)`.
4. Suma a `vLlenos` cada campo contestado.
5. Guarda:
   - `Account.AvanceNum1FAC__c = vAplicables`
   - `Account.AvanceNum2FAC__c = vLlenos`

#### Preguntas base consideradas hoy

1. `Pasatiempo__c`
2. `Viajas_recurrentemente__c`
3. `Frecuencia_para_ser_contactado__c`
4. `Cuantos_hijos_tienes__c`
5. `Estudiaoestudianfueradelpais__c`
6. `InstitucionFinancieraPrincipal__c`
7. `PorqueIndentInteres__c`
8. `Otrosproductosfinancierosteinteresan__c`
9. `Conquetipodeseguroscuentas__c`
10. `MedioPreferidoContacto__c`
11. `Alguien_InfluyeEnTuPatrimonio__c`
12. `Ingreso_mensual_despu_s_de_impuestos__c`
13. `Gastos_mensuales__c`
14. `depatrimoniofinancierototalenActinver__c`
15. `PrincipalActividadProfesional__c`
16. `MesPreferenteInversion_o_ahorrar__c`

#### Observacion importante

La logica activa en `fullcopy` ya esta simplificada a preguntas base. No esta usando la logica condicional ampliada que existio en otras iteraciones para hijos, seguros, familiar, destinos u otras preguntas dependientes.

### 4.2 `FAC_Task_Update_InTask`

- Tipo: `Record-Triggered Flow`
- Objeto: `Task`
- Momento de ejecucion: `After Save`
- Evento: `Create`
- Version activa en `fullcopy`: `v1`
- Ultima modificacion validada: `2026-03-06`

#### Funcion

Cuando se crea una tarea Postventa cuyo asunto contiene `Ficha de afinidad con el cliente`, valida si la cuenta relacionada ya tiene `Avance_FAC__c = 100` y, de ser asi, marca la tarea como contactada.

#### Logica actual

1. Se dispara al crear una `Task`.
2. Filtra tareas con:
   - `RecordTypeId = Postventa`
   - `Subject contains "Ficha de afinidad con el cliente"`
3. Busca la cuenta relacionada (`WhatId`).
4. Si la cuenta existe y su `Avance_FAC__c = 100`, actualiza la tarea creada:
   - `El_cliente_fue_contactado__c = "Si"`

#### Implicacion funcional

Este flow aplica un cambio automatico sobre la tarea cuando nace ya ligada a una cuenta con FAC completo.

### 4.3 `FAC_Task_Update_InAccount`

- Tipo: `Record-Triggered Flow`
- Objeto: `Account`
- Momento de ejecucion: `After Save`
- Evento: `Update`
- Version activa en `fullcopy`: `v1`
- Ultima modificacion validada: `2026-03-06`

#### Funcion

Cuando una cuenta alcanza `Avance_FAC__c = 100`, busca la tarea FAC de Postventa relacionada y la actualiza para marcar al cliente como contactado.

#### Logica actual

1. Se dispara al actualizar `Account`.
2. Solo entra cuando `Avance_FAC__c = 100`.
3. Busca la tarea mas reciente que cumpla:
   - `WhatId = Account.Id`
   - `RecordTypeId = Postventa`
   - `Subject contains "Ficha de afinidad con el cliente"`
4. Actualiza esa tarea:
   - `El_cliente_fue_contactado__c = "Si"`

#### Implicacion funcional

Este flow complementa el escenario de `FAC_Task_Update_InTask`. Si la tarea ya existia y despues la cuenta llego al `100%`, el flow la normaliza desde `Account`.

### 4.4 Componentes no activos en la linea base fullcopy

#### `FAC_Update_Task_Field_Avence`

- No aparece como flow activo en `fullcopy`.
- Se considera una iteracion historica o de pruebas.
- No forma parte de la implementacion vigente documentada.

## 5. Validacion activa en Task

### Regla activa: `Task.Avance_FAC_Validacion`

- Estado en `fullcopy`: `Active`
- Campo donde muestra el error: `El_cliente_fue_contactado__c`
- Mensaje actual:

```txt
La ficha de afinidad no ha sido completada al 100%, no se podra registrar como NO contactado y quedara pendiente la Tarea Ficha de Afinidad de Cliente
```

- Formula vigente validada en `fullcopy`:

```txt
AND(
    RecordType.DeveloperName = "Postventa",
    Subject = "Ficha de afinidad con el cliente",
    OR(
        ISNEW(),
        ISCHANGED(El_cliente_fue_contactado__c)
    ),
    NOT(ISBLANK(TEXT(El_cliente_fue_contactado__c))),
    BLANKVALUE(Avance_FAC__c, 0) < 1
)
```

#### Funcion

Impide guardar la tarea cuando:

- es una tarea `Postventa`,
- su asunto es `Ficha de afinidad con el cliente`,
- se esta creando o cambiando el campo `El_cliente_fue_contactado__c`,
- el campo se esta dejando con cualquier valor no vacio,
- y el avance de la ficha todavia no llega a `100%`.

#### Implicacion

La validacion vigente en `fullcopy` bloquea tanto escenarios de `Si` como de `No` o cualquier otro valor no vacio si la ficha no esta completa.

## 6. Apex relacionado con la funcionalidad

### 6.1 `TriggerActionCadenceStepTracker_thr`

- Rol: punto de entrada sobre eventos de cambio de `ActionCadenceStepTracker`.
- Funcion relevante:
  - invoca la logica que actualiza la tarea generada por la cadencia cuando esta se completa.

### 6.2 `PSTA_GestionTareas_Helper`

- Rol: logica principal validada en `fullcopy` para normalizar tareas provenientes de `ActionCadenceStepTrackerChangeEvent`.

#### Funcion

La clase no crea una tarea FAC nueva en este flujo. Toma la tarea ya generada por la cadencia y la actualiza.

#### Logica principal

1. Recibe eventos de cambio de `ActionCadenceStepTracker`.
2. Recupera los trackers relacionados.
3. Busca las tareas asociadas a esos trackers.
4. Actualiza la tarea existente con datos de negocio de la cadencia:
   - `Subject = ActionCadenceName`
   - `Status = "Completado"`
   - `Type = Tipo_de_actividad__c`
   - `DeveloperName__c = ActionCadence.DeveloperName__c`
   - `Description`
   - `PV_ExternalID__c`
   - `RecordTypeId = Postventa`
5. Publica el evento `PV_FinalizacionCadencia__e`.

#### Observacion funcional

Esta clase se encarga de normalizar la tarea de la cadencia completada. El porcentaje FAC no se calcula aqui; ese porcentaje viene de `Account` y se refleja en `Task` por formula.

### 6.3 `PSTA_ChangeAccountInfo_helper`

- Rol: actualizar informacion comercial en `Account` cuando cambia el resultado de contacto en una `Task`.

#### Funcion

Cuando una tarea completada cambia `El_cliente_fue_contactado__c`, la clase puede actualizar:

- `Account.FechaUltimoContacto__c`
- `Account.EstatusContacto__c`
- `Account.FechaNoRequiereSerContacto__c`

#### Implicacion funcional

La tarea FAC no solo refleja avance; tambien puede impactar el estatus comercial de contacto de la cuenta.

### 6.4 Componente identificado en Dev pero fuera de la linea base fullcopy

#### `PSTA_FACCadenceCompletion_cls`

- No fue encontrado en `fullcopy`.
- Fue identificado previamente en `actidev`.
- No forma parte de la implementacion vigente documentada en este archivo.

## 7. Componentes de interfaz

### `lwc/accountProgressBar`

- Lee `Account.Avance_FAC__c`.
- Muestra visualmente el porcentaje de avance de la ficha sobre la cuenta.

### `lwc/taskProgressBar`

- Lee `Task.Avance_FAC__c`.
- Muestra el mismo porcentaje desde el contexto de la tarea.
- Solo se muestra para asuntos relacionados con `Ficha de afinidad con el cliente`.

## 8. Flujo funcional resumido

1. El usuario captura informacion en la cuenta.
2. `Flow_Avance_FAC` calcula:
   - preguntas aplicables
   - preguntas respondidas
3. `Account.Avance_FAC__c` calcula el porcentaje final.
4. `Task.Avance_FAC__c` refleja el valor del avance de la cuenta.
5. Cuando la cadencia se completa, `TriggerActionCadenceStepTracker_thr` y `PSTA_GestionTareas_Helper` normalizan la tarea generada por la cadencia.
6. Si la tarea FAC se crea cuando la cuenta ya esta al `100%`, `FAC_Task_Update_InTask` marca `El_cliente_fue_contactado__c = "Si"`.
7. Si la tarea ya existia y despues la cuenta llega al `100%`, `FAC_Task_Update_InAccount` actualiza la tarea y la marca como contactada.
8. La regla de validacion en `Task` impide guardar un valor de contacto cuando el avance aun no llega a `100%`.

## 9. Conclusiones

- La linea base vigente en `fullcopy` usa `Flow_Avance_FAC` para calcular el avance FAC con 16 preguntas base.
- `Task.Avance_FAC__c` no es un valor independiente; proviene por formula de `Account.Avance_FAC__c`.
- En `fullcopy` hay dos flows activos que pueden marcar `El_cliente_fue_contactado__c = "Si"`:
  - `FAC_Task_Update_InTask`
  - `FAC_Task_Update_InAccount`
- La tarea de cadencia se normaliza principalmente por `TriggerActionCadenceStepTracker_thr` y `PSTA_GestionTareas_Helper`.
- La regla `Task.Avance_FAC_Validacion` en `fullcopy` bloquea cualquier valor no vacio en `El_cliente_fue_contactado__c` cuando la ficha no ha llegado a `100%`.
- Los componentes detectados solo en `actidev`, como `PSTA_FACCadenceCompletion_cls` o iteraciones historicas como `FAC_Update_Task_Field_Avence`, quedaron fuera de esta documentacion porque no representan la implementacion activa de `fullcopy`.
