public with sharing class CC_LeadAssignment_CAT {
    
    /**
     * This method performs one by one lead assignment based on an Asesors list.
     * @param List<Lead> leadsToAssign.
     */
    @InvocableMethod(label='Asigna Asesores CAT' description='Realiza asignación de Leads a Asesores CAT')
    public static void leadAssignmentLogic(List<Lead> leadsToAssign){
        
         List<User> asesorsToAssign = [SELECT id, Fecha_asignaci_n_leads__c 
                                    FROM User 
                                    WHERE Profile.Name  = 'Ejecutivo CAT SEDI' 
                                    AND Activo_para_asignacion__c = true
                                    AND IsActive = true    
                                    ORDER BY Fecha_asignaci_n_leads__c ASC];
        System.debug('Asesores CAT ordenados por fecha de asignacion: ' + asesorsToAssign);
        
          List<BusinessHours> leadassignBHid = [SELECT Name FROM BusinessHours where Name = 'Lead Assignment' AND IsActive = true ];
        boolean BHverif = LeadAssignment_Handler.checkBusinessHoursById(leadassignBHid[0].id);
		System.debug('Is active BH >' + BHverif);

        Integer userCount = asesorsToAssign.size();
        Integer leadsPerUser = leadsToAssign.size() / userCount;
        Integer remainingLeads = Math.mod(leadsToAssign.size(), userCount);
        
        Integer startIndex = 0;
        List<User> assignedUsers = new List<User>();
        if(BHverif == true || Test.isRunningTest()){
        for (Integer i = 0; i < userCount; i++) {
            Integer leadsForCurrentUser = leadsPerUser + (i < remainingLeads ? 1 : 0);
            List<Lead> leadsToAssignToUser = new List<Lead>();
            Set<Id> assignedUsersId = new Set<Id>();
        
            for (Integer j = 0; j < leadsForCurrentUser && startIndex < leadsToAssign.size(); j++) {
                Lead lead = leadsToAssign[startIndex];
                if (lead.OwnerId != asesorsToAssign[i].Id) { // Check if lead is not already owned by the current user
                    System.debug('Entra en primer chequeo');
                    System.debug('OwnerID del lead: ' + lead.OwnerId);
                    System.debug('ID nuevo owner: ' + asesorsToAssign[i].Id);
                    leadsToAssignToUser.add(lead);
                    	if(!assignedUsersId.contains(asesorsToAssign[i].Id)) {
                            asesorsToAssign[i].Fecha_asignaci_n_leads__c = Datetime.now();
                        	assignedUsers.add(asesorsToAssign[i]);
                        	}
                    
                    		assignedUsersId.add(asesorsToAssign[i].Id);
                    
                        } else {
                            // Find another user to assign the lead to
                            for (Integer k = 0; k < asesorsToAssign.size(); k++) {
                                if (lead.OwnerId != asesorsToAssign[k].Id) {
                                    System.debug('Entra en segundo chequeo');
                                    System.debug('OwnerID del lead: ' + lead.OwnerId);
                                    System.debug('ID nuevo owner: ' + asesorsToAssign[k].Id);
                                    leadsToAssignToUser.add(lead);
                                        if(!assignedUsersId.contains(asesorsToAssign[k].Id)) {
                                    asesorsToAssign[k].Fecha_asignaci_n_leads__c = Datetime.now();
                                    assignedUsers.add(asesorsToAssign[k]);
                                    }
                                    
                                    assignedUsersId.add(asesorsToAssign[k].Id);
                                    
                                    break;
                                }
                            }
                        }
                        startIndex++;
                    }
        
            User currentUser = asesorsToAssign[i];
            assignLeadsToUser(leadsToAssignToUser, currentUser);
        }
        update assignedUsers;
        }
    }
    
    private static void assignLeadsToUser(List<Lead> leads, User user) {
        // Assign leads to the specified user
        for (Lead lead : leads) {
            lead.OwnerId = user.Id;
            lead.CC_Fecha_Hora_Asignacion__c = Datetime.now();
            system.debug('Se ha asignado el prospecto ' + lead + 'al asesor ID ' + user.Id);
        }

        update leads;
    }


}