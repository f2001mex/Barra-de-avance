global class Data_Structure_Handle_Lead {
    global class LeadObject {
        global String claveAsesor;
        global String Name;
        global String middleName;
        global String MotherLastName;
        global String FatherLastName;
        global string phone;
        global String email;
        global String PostalCode;
        global String recordType;
        global String salution;
        global String montoAlternaES;
        global String montoAlternaUS;
        global String montoAlternaMX;
        global String fechaProbableDeCierre;
        global String lineaDeAccion;
        global String tipoDeLead;
    }
    
    global class ResultWithLeads{
        public Boolean result;
        public String message;
        public datosLead lead {get; set;}
    }
    
    global class Result {
        Public Boolean result;
        Public String message;
    }
    
    global class datosLead {
        public String LeadEmail;
        public String LeadId;
        public String LeadConsecutiveId;
        public String LeadName;
    }
    
    global class ResponseWithRelatedLead {
        global String claveAsesor; 
        public string LeadName;
        public Boolean result;
        public String message;
        public List<Lead> candidatos {get; set;}
    }
}