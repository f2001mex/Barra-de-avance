/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase PSTA_EnvioEncuestaMedallia_soql
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     20-06-2025      Salvador Ramirez Lopez                    Creación
*******************************************************************************************/
public with sharing class PSTA_EnvioEncuestaMedallia_soql {

    public static List<Task> getInfoTask(Id recordId){
    
        String mdtDeveloperName = 'PSTA_Query_EnvioEncuestaMedalia';
        String baseQuery = '';

        PSTA_Consultas__mdt consultaMDT = [SELECT Consulta__c 
                                        FROM PSTA_Consultas__mdt 
                                        WHERE DeveloperName = :mdtDeveloperName
                                        LIMIT 1];
        
        baseQuery = consultaMDT.Consulta__c;
        
        String filtro = baseQuery.toUpperCase().contains(' WHERE ') ? ' AND ID = :recordId' : ' WHERE ID = :recordId';
        String finalQuery = baseQuery + filtro;
        System.debug('Consulta final a ejecutar: ' + finalQuery);
        return (List<Task>) Database.query(finalQuery);

        
    }
}