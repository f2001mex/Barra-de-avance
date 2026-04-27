global class Data_Structure_Handle_Task {
    
    global class TaskObject {
        public String id;
        public String ownerId;
        public String ownerName;
        public string createdById;
        public String createdName;
        public String subject;
        public Boolean isClosed;
        public String description;
        public String status;
        public Datetime createdDate;
        public Date activityDate;
        public Datetime completedDateTime;
        public String accountId;
        public String accountName;
        public String whoId;
        public String whoName;
        public String whatId;
        public String whatName;
        public String recordTypeId;
        public String recordTypeName;
        public String type;
        public String callType;
        public Datetime startDateTime;
        public Datetime endDateTime;
        public String location;
        public String priority;
        public EmailObject emailObject;
        public String bp;
        global String claveAsesor;
        global String numeroCliente;
        global String estado { get; set; }
    }
    
    global class ResultTask {
        Public Boolean result;
        Public String message;
    }
    
    global class ResponseWithEvent {
        public Boolean result;
        public String message;
        public Map<String,Object> event {get; set;}
    }
    global class ResponseWithRelatedPerson {
        public Boolean result;
        public String message;
        public List<Contact> contactos{get; set;}
    }
    
    global class EventObject {
        public String id;
        public String bp;
        public String ownerId;
        public String ownerName;
        public string createdById;
        public String createdName;
        public String eventName;
        public String eventType;
        public Datetime eventDate;
        public String description;
        public String status;
        public Datetime createdDate;
        public String primaryPersonId;
        public String primaryPersonName;
        public String relatedPersonId;
        public String relatedPersonName;
        public Location eventLocation;
        public String accountType;
        public String primaryAccountId;
        public Boolean result;
        public String message;
        public Datetime expirationDate; 
    }
    
    global class Location{
        public String street;
        public String city;
        public String state;
        public String postalCode;
        public String country;
    }
    
    global class EmailObject{
        public String fromAddress;
        public String toAddress;
        public String ccoAddress;
        public String subject;
        public String textBody;
        public String fileName;
        public String fileBody;
    }
    
    global class responseWithTasksList {
        public Boolean result;
        public String message;
        public List<Map<String, Integer>> tasksList {get; set;}
    }
    global class ResultTaskWrapper {
        public Boolean result;
        public String message;
        public List<ResultTasksAndEvents> registros = new List<ResultTasksAndEvents>();
        // Constructor que acepta un booleano y una cadena
        global ResultTaskWrapper(Boolean result, String message) {
            this.result = result;
            this.message = message;
        }

        // Constructor predeterminado necesario para la serialización JSON
        global ResultTaskWrapper() {}
    }
    global class ActividadItem {
        public String Asunto;
        public String FechaVencimiento;
        public String Asignado_a;
        public String Comentarios;
        public String FechaInicio;
        public String HoraInicio;
        public String FechaFin;
        public String HoraFin;
        public String Descripcion;
        public Id SalesforceId;
        public String FechaDeCreacion;
        public String HoraDeCreacion;
        public String Estado;
    }

    global class ActividadWrapper {
        public String asunto;
        public String fechaVencimiento;
        public String asignado_a;
        public Id salesforceId;
        public String Descripcion;
        public String Comentarios;
        public String fechaDeCreacion;
        public String horaDeCreacion;
    }
    global class ResultTasksAndEvents{
        public String Tipo;
        public Integer Count;
        public List<ActividadItem> Actividades;
    }
}