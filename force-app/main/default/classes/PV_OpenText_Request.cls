/****************************************************************************************************
    Desarrollado por: Martín Martínez (martin.martinez@vasscompany.com)
    Proyecto        : Post Venta
    Descripción     : Clase wrapper para el request de Open Text

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-08-19      Salvador Ramírez	    Creación de la Clase.
*/
public class PV_OpenText_Request implements RequestBody_cls {

    public String contractNumber;
    public String bankingArea;
    public String extension;
    public String fileName;
    public String invoiceId;
    public String file;
    public String instruction;
    public String clientId;
    public String clientName;
    public String advisorId;
    public String advisorName;

    public PV_OpenText_Request() {
        this.contractNumber = '';
        this.bankingArea = '';
        this.extension = '';
        this.fileName = '';
        this.invoiceId = '';
        this.file = '';
        this.instruction = '';
        this.clientId = '';
        this.clientName = '';
        this.advisorId = '';
        this.advisorName = '';
    }

    public String serializeRequestBody(RequestBody_cls requestBody) {
        return JSON.serialize((PV_OpenText_Request) requestBody, true);
    }
}