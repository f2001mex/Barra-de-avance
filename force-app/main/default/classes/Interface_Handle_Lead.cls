/**
 * @description       : 
 * @author            : JC Cruz
 * @group             : 
 * @last modified on  : 12-18-2023
 * @last modified by  : JC Cruz
**/
public interface Interface_Handle_Lead {
Data_Structure_Handle_Lead.ResultWithLeads createLead(Data_Structure_Handle_Lead.LeadObject leadsRecords);
Data_Structure_Handle_Lead.ResponseWithRelatedLead consultLead(string leadName, String id_Asesor);
}