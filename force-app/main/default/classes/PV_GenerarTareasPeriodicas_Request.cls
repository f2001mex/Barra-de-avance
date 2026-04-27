/**
 * @description       : 
 * @author            : Martin Martinez
 * @group             : 
 * @last modified on  : 07-16-2025
 * @last modified by  : Martin Martinez
**/
public class PV_GenerarTareasPeriodicas_Request{

    @AuraEnabled @InvocableVariable(required=true)
    public String salesCadenceNameOrId;

    @AuraEnabled @InvocableVariable(required=true)
    public String targetId;

    @AuraEnabled @InvocableVariable
    public String userId;
    
    public PV_GenerarTareasPeriodicas_Request(String cadence, String target, String user) {
        this.salesCadenceNameOrId = cadence;
        this.targetId = target;
        this.userId = user;
    }
}