/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     SCH_ServiceUtility_Test
 * @Author   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
 * @Date     Created: 03/01/2025
 * @Group    VASS
 * ------------------------------------------------------------------------------------------------
 * @Description Clase para almacenar métodos y funciones de apoyo para la ejecución de clases test para proyecto scheduler.
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         14/01/2025       Salvador Ramírez López             Class creation.
*--------------------------------------------------------------------------
 **/
public class SCH_ServiceUtility_Test {
    /*
        * Autor: Salvador Ramírez López (salvador.ramirez@vasscompany.com).
        * Función: createChannels (Función encargada de generar datos de prueba de los tipos de canales para scheduler).
        * Return: Objeto de tipo EngagementChannelType ya insertado en la base de datos.
    */
    public static EngagementChannelType createChannels(){
        EngagementChannelType objEC = new EngagementChannelType(Name = 'Presencial', UsageType = 'Salesforce Scheduler', ContactPointType = 'InPerson', IsActive = true);
        insert objEC;
        return objEC;
    }
    public static DefaultValuesScheduler__c createDefaultValues(){
        DefaultValuesScheduler__c objData = new DefaultValuesScheduler__c(DuracionEstimadaWorkType__c = 30, TipoDuracionWorkType__c = 'Minutes', AllEngChanSup_Shift__c = false);
        insert objData;
        return objData;
    }
    public static OperatingHours createOperatingHours(){
        OperatingHours objOH = new OperatingHours(Name = 'Test', TimeZone = 'America/Mexico_City');
        insert objOH;
        return objOH;
    }
    public static ServiceTerritory createServiceTerritory(OperatingHours objOH){
        ServiceTerritory objServTerr = new ServiceTerritory(Name = 'Test', IsActive = true, ExternalID__c = 'CF_123456', OperatingHoursId = objOH.Id);
        insert objServTerr;
        return objServTerr;
    }
    public static List<WorkTypeGroup> createWorkTypeGroups(){
        List<WorkTypeGroup> lstWTG = new List<WorkTypeGroup>();
        for(Integer i = 0; i < 5; i++){
            WorkTypeGroup objWTG = new WorkTypeGroup(IsActive = true, Name = 'Pruebas'+i, Description = 'Pruebas'+i, External_ID__c = '123'+i, TipoMotivo__c = 'Clientes');
            lstWTG.add(objWTG);
        }
        return lstWTG;
    }
    public static List<WorkType> createWorkTypes(){
        List<WorkType> lstWT = new List<WorkType>();
        for(Integer i = 0; i < 5; i++){
            WorkType objWT = new WorkType( Name = 'Pruebas'+i, Description = 'Pruebas'+i, External_ID__c = '123'+i, EstimatedDuration = 30, DurationType = 'Minutes');
            lstWT.add(objWT);
        }
        return lstWT;
    }
    public static Shift createTurnos(){
        Shift objTurno = new Shift();
        objTurno.StartTime = System.now();
        objTurno.EndTime = System.now() + 1;
        objTurno.Status = 'Intento';
        objTurno.TimeSlotType = 'Normal';
        objTurno.Type = 'Regular';
        insert objTurno;
        return objTurno;
    }
}