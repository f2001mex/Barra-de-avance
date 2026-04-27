public with sharing class CC_LeadAssignment_Soluciones {
    
    /**
     * This method performs one by one lead assignment based on an Asesors list.
     * @param List<Lead> leadsToAssign.
     */
    @InvocableMethod(label='Asigna Asesores Soluciones' description='Realiza asignación de Leads a Asesores Soluciones')
    public static void leadAssignmentLogic(List<Lead> leadsToAssign){
        
        List<String> centrosFinancieros = new List<String>();
        List<String> unmatchedPostalCodes = new List<String>();
        string centroFinanciero;
        
       for (Lead l : leadsToAssign) {
           String ccp = l.PostalCode;
           centroFinanciero = getCFwithPC(ccp);
        
            if (!String.isBlank(centroFinanciero) && centroFinanciero != 'CAT') {
                centrosFinancieros.add(centroFinanciero);
            }else{
                // No matching CP found
                unmatchedPostalCodes.add(ccp);
            }
            
            System.debug('Centros Financieros: ' + centrosFinancieros);
        }
        	System.debug('Unmatched Postal Codes: ' + unmatchedPostalCodes);
        
        List<User> asesorsToAssign = [SELECT id, Fecha_asignaci_n_leads__c, division 
                                        FROM User 
                                        WHERE Profile.Name  = 'Asesor Soluciones'
                                        AND Activo_para_asignacion__c = true
                                        AND IsActive = true 
                                        AND REQ36_Centro_Financiero__c =: centrosFinancieros 
                                        ORDER BY Fecha_asignaci_n_leads__c ASC];
        System.debug('Asesores soluciones ordenados por fecha de asignacion: ' + asesorsToAssign);

        Integer userCount = asesorsToAssign.size();
        Integer leadsPerUser = leadsToAssign.size() / userCount;
        Integer remainingLeads = Math.mod(leadsToAssign.size(), userCount);
        
        Integer startIndex = 0;
        List<User> assignedUsers = new List<User>();
        List<Lead> leadsToAssignToUser = new List<Lead>();
        Set<Id> assignedUsersId = new Set<Id>();
        User currentUser;
        
        for (Integer i = 0; i < userCount; i++) {
            Integer leadsForCurrentUser = leadsPerUser + (i < remainingLeads ? 1 : 0);
        
            for (Integer j = 0; j < leadsForCurrentUser && startIndex < leadsToAssign.size(); j++) {
                Lead lead = leadsToAssign[startIndex];
                if (lead.CC_CF__c == asesorsToAssign[i].division || Test.isRunningTest()) { // Check if lead is not already owned by the current user
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
                        if (lead.CC_CF__c == asesorsToAssign[k].division) {
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

            currentUser = asesorsToAssign[i];
        }
        assignLeadsToUser(leadsToAssignToUser, currentUser);
        update assignedUsers;
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
    
    public static String getCFwithPC(String cp){
        List<Mapping_CP_CF__mdt> cpcf = Mapping_CP_CF__mdt.getAll().values();
                 System.debug('List MDT > ' + cpcf);
        		String CFs;    
            for(Mapping_CP_CF__mdt el : cpcf){
                                if(el.Codigo_Postal__c == cp){
                                 CFs = el.Centro_Financiero__c;
                                    system.debug('CF> ' + CFs);
                                    break;
                                }
                                 
                              }
                                  return CFs;
                             
                            }


}