/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     LWC_Cedes_Pagares_Schedule
 * @Author   ivan.mora@pwc.com
 * @Date     Created: 16/05/2024
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Class in Charge to call the Cedes/Pagares Interface every thuesday
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 16/05/2024 ivan.mora@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
global with sharing class LWC_Cedes_Pagares_Schedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        System.enqueueJob(new QueueableProcess());
    }


    global class QueueableProcess implements Queueable, Database.AllowsCallouts {
        global void execute(QueueableContext context) {
            List<Integration_Service.ServiceResponse> responseList = new List<Integration_Service.ServiceResponse>();
            Integration_Service.ServiceResponse response = Integration_Service.calloutService(
                'getInstrumentsCedes',
                null,
                null,
                null,
                false
            );
            response.serviceHeaders = null;
            response.logger = null;
            responseList.add(response);
        }
    }
}