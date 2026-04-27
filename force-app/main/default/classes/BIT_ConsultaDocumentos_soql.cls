/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase con las consultas SOQL necesarias para la ejecución de servicio de OTP

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-08-20      Salvador Ramírez	    Creación de la Clase.
*/
public with sharing class BIT_ConsultaDocumentos_soql {
    public static List<Contract> getContractInfo(String strContractNumber){
        return [SELECT 
					Id,
                    ContractNumber__c,
                    Account.Client_ID__c,
                    (SELECT PRINCIPAL__C,
                            Phone_Type__c,
                            Phone__c,
                            CreatedDate
                    FROM Telefono_de_Contratos__R 
                    WHERE 
                        principal__c = TRUE OR 
                        Phone_Type__c = 'CELULAR') 
                FROM CONTRACT 
                WHERE ContractNumber__c = :strContractNumber];
    }
	public static String getCFEnvio() {
		List<User> currentUsr = [SELECT Id, (SELECT CurrentBranch.Name FROM BankerBM)
					FROM User
					WHERE Id =: UserInfo.getUserId()];
		return currentUsr[0].BankerBM[0].CurrentBranch.Name;
	}
}