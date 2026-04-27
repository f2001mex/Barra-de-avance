/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     OpportunityTrigger
 * @Author   ivan.mora@pwc.com
 * @Date     Created: 03/03/2024
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Trigger on Opportunity.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 03/03/2024 ivan.mora@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
trigger OpportunityTrigger on Opportunity (before insert,  before update, after update) {
    F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.label.F4_OpportunityTrigger);
    Id MC_CONNECT_CRM_ID = [SELECT Id FROM User WHERE Name = 'MC Connect-CRM'].Id;

    if ((triggerMetadata == null || triggerMetadata.F3_isActive__c) && UserInfo.getUserId() == MC_CONNECT_CRM_ID) new OpportunityTriggerHandler().run();

    if ((triggerMetadata == null || triggerMetadata.F3_isActive__c)) new OpportunityTrigger_Handler().run();
}