/**
 * @author [Harold Garcia]
 * @email [hgarcia@freewayconsulting.com]
 * @create date 09-11-2023 18:39:46
 * @modify date 09-11-2023 18:39:46
 * @desc Salesforce Apex class for handling REST requests related to tasks and Event.
 */

 @RestResource(urlMapping='/ActivityList/*')
 global with sharing class ACT_TaskAndEventApiRest {

    /**
    * @descripción:Este método es un controlador HTTP POST que consulta tareas y devuelve los resultados en formato JSON. Si hay errores, 
      devuelve un mensaje de error en lugar de los resultados.
    * @author Harold Garcia - hgarcia@freewayconsulting.com | 14-11-2023
    * @param records Data_Structure_Handle_Task.TaskObject
    **/
     @HttpPost
     global static void getTaskList(Data_Structure_Handle_Task.TaskObject records) {
         List<Data_Structure_Handle_Task.ResultTaskWrapper> result = new List<Data_Structure_Handle_Task.ResultTaskWrapper>();
 
         
         result = ACT_Controller_Task.consultTask(records);
         
         
         setRestResponse(result);
     }
 
     private static void setRestResponse(List<Data_Structure_Handle_Task.ResultTaskWrapper> result) {
         RestResponse res = RestContext.response;
         res.addHeader('Content-Type', 'application/json');
         res.responseBody = Blob.valueOf(JSON.serialize(result));
     }
 }