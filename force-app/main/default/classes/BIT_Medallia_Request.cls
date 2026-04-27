/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase wrapper para el request de encuesta medallia

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-08-19      Salvador Ramírez	    Creación de la Clase.
*/
public class BIT_Medallia_Request implements RequestBody_cls {
    public payload[] payload;
    public BIT_Medallia_Request() {
        this.payload = new List<payload>();
    }
    public class payload {
        public String fullName;
        public String userType;
        public String uniqueClientId;
        public String contractNumber;
        public String email;
        public String phone;
        public String financialCenter;
        public String visitReason;
        public String visitDate;
        public String entryTime;
        public String exitTime;
        public String advisorName;
        public String contractStatus;
        public String enrollmentStatus;
        public String contractOrigin;
        public String otherFunctions;
        public payload() {
            this.fullName = '';
            this.userType = '';
            this.uniqueClientId = '';
            this.contractNumber = '';
            this.email = '';
            this.phone = '';
            this.financialCenter = '';
            this.visitReason = '';
            this.visitDate = '';
            this.entryTime = '';
            this.exitTime = '';
            this.advisorName = '';
            this.contractStatus = '';
            this.enrollmentStatus = '';
            this.contractOrigin = '';
            this.otherFunctions = '';
        }
    }
    public String serializeRequestBody(RequestBody_CLS requestBody) {
        return JSON.serialize( ( BIT_Medallia_Request ) requestBody, true);
    }
}