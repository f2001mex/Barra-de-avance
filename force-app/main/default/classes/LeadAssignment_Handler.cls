public class LeadAssignment_Handler {
    
    
       
    	public static Boolean checkBusinessHoursById(String businessHoursId)
    	{
		Boolean isWithin = false;
		if (businessHoursId != null)
		{
			
		    isWithin = BusinessHours.isWithin(businessHoursId, System.now());
		}

		return isWithin;
    	}

    	
	public static List<Boolean> checkBusinessHoursByName(){
        
		List<Boolean> results = new List<Boolean>();

			// Look up the Business hours by name to find the ID
		    List <BusinessHours> businessHours =[SELECT Name FROM BusinessHours where Name = 'Lead Assignment' AND IsActive = true];
		    if (businessHours.size() == 1) {
			    // Call method to check if now is within business hours based on the found hours
			results.add(LeadAssignment_Handler.checkBusinessHoursById(businessHours[0].Id));
		    }
		    else
		    {
			    // If name didn't match an active business hours then return false.
			results.add(false);
		    }
		
            System.debug('aplica horario: '+results);
		return results;
    	}
    
    
 /**
     * This method performs lead assignment business logic.
     * @param List <Lead> Leads.
     */
    
    public static void leadAssignment (List <Lead> Leads) {
        
        User MCconnectUser = [SELECT id FROM User WHERE Name = 'MC Connect-CRM'];
        String MCconnectUserId = MCconnectUser.id;
        List<Lead> leadstoprocess = [SELECT Id, Name, PostalCode, Email, OwnerId, CC_CF__c FROM Lead WHERE Id=:Leads];  
        System.debug(leadstoprocess);
        
        List<String> leadEmailsList = New List<String>();
        List<Lead> activeLeads = New List<Lead>();
        for(lead l : Leads){
            if(!String.isBlank(l.Email)){
            		leadEmailsList.add(l.Email);
          }
        }
            System.debug('Lista de emails: ' + leadEmailsList );
            
        if(!leadEmailsList.isEmpty()){
        
            activeLeads = [SELECT ownerId, email FROM Lead WHERE status != 'closed' AND ownerId != :MCconnectUserId AND Email IN :leadEmailsList];
            System.debug('Leads activos con  email duplicado: ' + activeLeads );
        }
        
        //Duplicate email verification method
        duplicatedEmailVerification(leadstoprocess, activeLeads);
        System.debug('Paso por duplicatedEmailVerification');
        
        Set<String> centrosFinancieros = new Set<String>();
        Set<String> unmatchedPostalCodes = new Set<String>();
        string centroFinanciero;
        
        for (Lead l : leadstoprocess) {
           String ccp = l.PostalCode;
           centroFinanciero = getCFwithPC(ccp);
        
            if (!String.isBlank(centroFinanciero) && centroFinanciero != 'CAT') {
                centrosFinancieros.add(centroFinanciero);
            }else{
                // No matching CP found
                unmatchedPostalCodes.add(ccp);
            }
            
            
        }
        System.debug('Centros Financieros: ' + centrosFinancieros);
        System.debug('Unmatched Postal Codes: ' + unmatchedPostalCodes);
        
        List<User> ejecutivosCAT = [SELECT id, Fecha_asignaci_n_leads__c, division 
                                    FROM User 
                                    WHERE Profile.Name  = 'Ejecutivo CAT SEDI'
                                    AND Activo_para_asignacion__c = true
                                    AND IsActive = true 
                                    ORDER BY Fecha_asignaci_n_leads__c ASC];
        System.debug('Asesores CAT ordenados por fecha de asignacion: ' + ejecutivosCAT);
        
        List<User> asesorSoluciones = [SELECT id, Fecha_asignaci_n_leads__c, Division 
                                        FROM User 
                                        WHERE Profile.Name  = 'Asesor Soluciones'
                                        AND Activo_para_asignacion__c = true
                                        AND IsActive = true 
                                        AND REQ36_Centro_Financiero__c =: centrosFinancieros 
                                        ORDER BY Fecha_asignaci_n_leads__c ASC];
        System.debug('Asesores soluciones ordenados por fecha de asignacion: ' + asesorSoluciones);
      
        
    //First Lead assignment logic
	
        //List<Lead> remainingLeads = New List <Lead> ([SELECT Id, PostalCode, OwnerId FROM Lead WHERE Id=:Leads AND OwnerId =: MCconnectUserId]);  
        //System.debug('Leads sin email duplicado, a asignar: ' + remainingLeads);
            
        List<Lead> unmatchedLeads = new List<Lead>();
        List<Lead> matchedLeads = new List<Lead>();
    
       
        for (Lead lead : leadstoprocess) {
            if(lead.OwnerId == MCconnectUserId){
            if (unmatchedPostalCodes.contains(lead.PostalCode)) {
                unmatchedLeads.add(lead);
        System.debug('Leads sin CP valido: ' + unmatchedLeads);
            }else {
                matchedLeads.add(lead);
        System.debug('Leads con CP valido: ' + matchedLeads);
            }
           }
        }
            
        if(matchedLeads != null && !matchedLeads.isEmpty()){
            System.debug('Entra en asignación a Asesores patrimonial');
            leadAssignmentLogic(asesorSoluciones, matchedLeads);
        } 
        if(unmatchedLeads != null && !unmatchedLeads.isEmpty()){
            System.debug('Entra en asignación a Asesores CAT');
            CC_LeadAssignment_CAT.leadAssignmentLogic(unmatchedLeads);
            
        }
    }
    
    /**
* This method performs a duplicated email verification.
* @param List <Lead> LeadsToAssign, List <Lead> activeLeads.
*/
    
    public static void duplicatedEmailVerification(List<Lead> leadsToAssign, List<Lead> activeLeads) {
    Map<String, Id> emailToLeadOwnerIdMap = new Map<String, Id>();
    Set<Id> userIdsToCheck = new Set<Id>();
    

    for (Lead activeLead : activeLeads) {
        if (!String.isBlank(activeLead.Email)) {
            emailToLeadOwnerIdMap.put(activeLead.Email, activeLead.OwnerId);
            userIdsToCheck.add(activeLead.OwnerId);
        }
    }

    Map<Id, User> activeUsersMap = new Map<Id, User>([
        SELECT Id, IsActive
        FROM User
        WHERE Id IN :userIdsToCheck
    ]);

    List<Lead> leadsToUpdate = new List<Lead>();
    List<Lead> leadsWithInactiveOwners = new List<Lead>();

 
    for (Lead leadToAssign : leadsToAssign) {
        String email = leadToAssign.Email;

        if (!String.isBlank(email) && emailToLeadOwnerIdMap.containsKey(email)) {
            
            Id leadOwnerId = emailToLeadOwnerIdMap.get(email);
            User leadOwner = activeUsersMap.get(leadOwnerId);

            if (leadOwner != null && leadOwner.IsActive) {
                leadToAssign.OwnerId = leadOwnerId;
                leadToAssign.CC_Fecha_Hora_Asignacion__c = Datetime.now();
                leadsToUpdate.add(leadToAssign);
                System.debug('Se ha asignado el prospecto ' + leadToAssign.Name + ' al asesor ID ' + leadOwnerId);
                
            } else {
                
                leadsWithInactiveOwners.add(leadToAssign);
                System.debug('El propietario del prospecto ' + leadToAssign.Name + ' está inactivo.');
            }
            
        }
    }
        Set<String> centrosFinancieros = new Set<String>();
        Set<String> unmatchedPostalCodes = new Set<String>();
        string centroFinanciero;
        
        for (Lead l : leadsWithInactiveOwners) {
           String ccp = l.PostalCode;
           centroFinanciero = getCFwithPC(ccp);
        
            if (!String.isBlank(centroFinanciero) && centroFinanciero != 'CAT') {
                centrosFinancieros.add(centroFinanciero);
            }else{
                // No matching CP found
                unmatchedPostalCodes.add(ccp);
            }
        }
        
        List<User> asesoresActivos = [SELECT id, Fecha_asignaci_n_leads__c, Division 
                                        FROM User 
                                        WHERE Profile.Name  = 'Asesor Soluciones'
                                        AND Activo_para_asignacion__c = true
                                        AND IsActive = true 
                                        AND REQ36_Centro_Financiero__c =: centrosFinancieros 
                                        ORDER BY Fecha_asignaci_n_leads__c ASC];
      
    if (!leadsToUpdate.isEmpty()) {
        update leadsToUpdate;
    }
    
    if (!leadsWithInactiveOwners.isEmpty()) {
            leadAssignmentLogic(asesoresActivos, leadsWithInactiveOwners);
        }
  
}
    
    

/**
     * This method performs one by one lead assignment based on an Asesors list.
     * @param List<User> users, List<Lead> leads.
     
*/
    
    public static void leadAssignmentLogic(List<User> users, List<Lead> leads) {
        Map<String, List<Lead>> leadsByDivision = new Map<String, List<Lead>>();
        Map<String, List<User>> usersByDivision = new Map<String, List<User>>();
        
        // Group leads by division
        for (Lead lead : leads) {
            if (!leadsByDivision.containsKey(lead.CC_CF__c)) {
                System.debug('----- KEY00: '+ lead.CC_CF__c);
                leadsByDivision.put(lead.CC_CF__c, new List<Lead>());
            }
            leadsByDivision.get(lead.CC_CF__c).add(lead);
            System.debug('----- Lista leads/division: '+ leadsByDivision);
        }
        
        //Add by ccruz
        //if(users.size() > 0 && !users.isEmpty()){
        
        for(User u: users){
            if(!usersByDivision.containsKey(u.Division)){
                usersByDivision.put(u.Division,new List<User>());
            }
            
            usersByDivision.get(u.Division).add(u);
            
        }
        
  
        List<Lead> leadsToAssign = new List<Lead>();
        List<User> assignedUsers = new List<User>();
        
        for(String key: usersByDivision.keySet()){
            System.debug('----- KEY: '+ key);
            
            if(leadsByDivision.containsKey(key)){
                
                List<Lead> leadsInDivision 		= leadsByDivision.get(key);
                Integer totalUsersPerDivision 	= usersByDivision.get(key).size();
                Integer totalLeadsInDiv 		= leadsInDivision.size();
                Integer leadPerUser 			= totalLeadsInDiv / totalUsersPerDivision;
                Integer remainingLeads 			= Math.mod(totalLeadsInDiv, totalUsersPerDivision);
                Integer leadIndex 				= 0;
                
                System.debug('LOG-CC totalUsersPerDivision: ' + totalUsersPerDivision );
                System.debug('LOG-CC totalLeadsInDiv: ' + totalLeadsInDiv );
                System.debug('LOG-CC leadPerUser: ' + leadPerUser );
                System.debug('LOG-CC remainingLeads: ' + remainingLeads );
                
                for(User u: usersByDivision.get(key)){
                    Integer leadsForEach = leadPerUser + (remainingLeads > 0 ? 1 : 0);
                    remainingLeads = Math.max(0, remainingLeads - 1);
                    
                    Set<Id> assignedLeadIds = new Set<Id>();
                    Set<Id> assignedUsersId = new Set<Id>();
                    
                    for (Integer i = 0; i < leadsForEach && leadIndex < leadsInDivision.size(); i++) {
                        if (leadsByDivision.containsKey(u.Division) && !leadsByDivision.get(u.Division).isEmpty()) {
                            Lead lead = leadsByDivision.get(u.Division).remove(0);
                            leadIndex++;
                            if (lead.CC_CF__c == u.Division && !assignedLeadIds.contains(lead.Id)) {
                                lead.OwnerId = u.Id;
                                lead.CC_Fecha_Hora_Asignacion__c = Datetime.now();
                                leadsToAssign.add(lead);
                                if(!assignedUsersId.contains(u.Id)) {
                                    u.Fecha_asignaci_n_leads__c = Datetime.now();
                                    assignedUsers.add(u);
                                }
                                assignedLeadIds.add(lead.Id);
                                assignedUsersId.add(u.Id);
                            }
                        }
                    }
                }
                
            }
        }
        
        update leadsToAssign;
        update assignedUsers;
        
        List<Lead> leadsResagados = new List<Lead>();
        for(List<Lead> leadList: leadsByDivision.values()){
            leadsResagados.addAll(leadList);
        }
        
        System.debug('LOG_CCO Leads Map resagados: '+leadsByDivision);
        System.debug('LOG_CCO Leads Map resagados: '+leadsByDivision.values());
        
        if(leadsResagados.size()>0)
            CC_LeadAssignment_CAT.leadAssignmentLogic(leadsResagados); 
        
    
    }
        
        
            /*Integer totalLeads = leads.size();
            Integer leadsPerUser = totalLeads / users.size();
            Integer remainingLeads = Math.mod(totalLeads, users.size());
            Integer leadIndex = 0;
            
            System.debug('----- Numero de usuarios: '+users.size());
            System.debug('----- Leads por usuario: '+leadsPerUser);
            System.debug('----- Queries antes del loop de usuarios: '+Limits.getQueries());
            System.debug('----- llamadas dml antes del loop de usuarios: '+Limits.getDmlStatements());
            
            List<Lead> leadsToAssign = new List<Lead>();
            List<User> assignedUsers = new List<User>();
            
            for (User user : users) {
                
                Integer leadsForEach = leadsPerUser + (remainingLeads > 0 ? 1 : 0);
                remainingLeads = Math.max(0, remainingLeads - 1);
                
                Set<Id> assignedLeadIds = new Set<Id>();
                Set<Id> assignedUsersId = new Set<Id>();
                
                for (Integer i = 0; i < leadsForEach && leadIndex < leads.size(); i++) {
                    if (leadsByDivision.containsKey(user.Division) && !leadsByDivision.get(user.Division).isEmpty()) {
                        Lead lead = leadsByDivision.get(user.Division).remove(0);
                        leadIndex++;
                        if (lead.CC_CF__c == user.Division && !assignedLeadIds.contains(lead.Id)) {
                            lead.OwnerId = user.Id;
                            lead.CC_Fecha_Hora_Asignacion__c = Datetime.now();
                            leadsToAssign.add(lead);
                            if(!assignedUsersId.contains(user.Id)) {
                                user.Fecha_asignaci_n_leads__c = Datetime.now();
                                assignedUsers.add(user);
                            }
                            assignedLeadIds.add(lead.Id);
                            assignedUsersId.add(user.Id);
                            
                            
                        }
                    }
                }
                
                System.debug('----- Queries antes de assignLeadsToUser: '+Limits.getQueries());
                System.debug('----- llamadas dml antes de assignLeadsToUser: '+Limits.getDmlStatements());
                System.debug('----- Queries despues de assignLeadsToUser: '+Limits.getQueries());
                System.debug('----- llamadas dml antes de assignLeadsToUser: '+Limits.getDmlStatements());
            }
            
            update leadsToAssign;
            update assignedUsers;
            
        }else{
            CC_LeadAssignment_CAT.leadAssignmentLogic(leads); 
        }*/

/**
    * This method performs a CF verification based on a Postal code.
    * @param String cp.
    * @return A list of Strings.
   */
    
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