/**
 * @description       : 
 * @author            : Martin Martinez
 * @group             : 
 * @last modified on  : 08-11-2025
 * @last modified by  : Martin Martinez
**/
public class PV_EjecutarAsignacionCadencias_Queueable implements Queueable {

    private List<PV_GenerarTareasPeriodicas_Request> fullList;
    private Integer offset;

    public PV_EjecutarAsignacionCadencias_Queueable(List<PV_GenerarTareasPeriodicas_Request> fullList, Integer offset) {
        this.fullList = fullList;
        this.offset = offset;
    }

    public void execute(QueueableContext context) {
        Integer chunkSize = 200;
        Integer endList = Math.min(offset + chunkSize, fullList.size());

        //List<PV_GenerarTareasPeriodicas_Request> subList = fullList.subList(offset, endList);
        List<PV_GenerarTareasPeriodicas_Request> subList = new List<PV_GenerarTareasPeriodicas_Request>();
        for (Integer i = offset; i < endList; i++) {
            subList.add(fullList[i]);
        }

        // Ejecuta el flow con el chunk actual
        Flow.Interview.PV_AsignarCadencesCuentas_Flow flow = new Flow.Interview.PV_AsignarCadencesCuentas_Flow(
            new Map<String, Object>{
                'inputCadenceList' => subList
            }
        );
        flow.start();

        // Obtener la variable de errores del flow
        List<String> errores = (List<String>) flow.getVariableValue('ErroresAsignacionCadence');
        PV_GenerarTareasPeriodicas.saveErrorFlow(errores);

        // Encola siguiente bloque si hay más registros
        if (endList < fullList.size()) {
            System.enqueueJob(new PV_EjecutarAsignacionCadencias_Queueable(fullList, endList));
        }
    }
}