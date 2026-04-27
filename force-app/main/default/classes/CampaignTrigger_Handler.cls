public without sharing class CampaignTrigger_Handler extends TriggerHandler{
    list<Campaign> campaignNew = Trigger.new;
	list<Campaign> campaignOld = Trigger.Old;
	Map<Id, Campaign> campaignNewMap = ((Map<Id, Campaign>) (Trigger.NewMap));
	Map<Id, Campaign> campaignOldMap = ((Map<Id, Campaign>) (Trigger.OldMap));
    List<CampaignMemberStatus> newStatusList = new List<CampaignMemberStatus>();
    Schema.DescribeFieldResult twilioFieldDescription = Outbound_Settings__mdt.CampaignMember_All_Statuses__c.getDescribe();
    List<Schema.PicklistEntry> pickEntries = twilioFieldDescription.getPicklistValues();
    Id OutboundRecordTypeId = Schema.getGlobalDescribe()
                            .get('Campaign').getDescribe().getRecordTypeInfosByName()
                            .get('Outbound').getRecordTypeId();
    Set<String> standardStatus = new Set<String>{'Enviado', 'Respondió'};
    Set<String> respondedStatus = new Set<String>{'Contactado', 'Si', 'No', 'No Convertido'};

    @TestVisible
	protected override void afterInsert() {
		for(Campaign cmp: campaignNew){
            if(cmp.RecordTypeId == OutboundRecordTypeId){
                createNewCampaignStatus();
                deleteStandardCampaignStatus(standardStatus);
            }
        }
	}

    private void deleteStandardCampaignStatus(Set<String> deletedStatus){
        delete [SELECT Id, Label FROM CampaignMemberStatus 
        WHERE CampaignId IN: campaignNewMap.keySet()
        AND Label IN: deletedStatus];
    }

    private void createNewCampaignStatus(){
        for(Campaign c: campaignNew){
            for(Schema.PicklistEntry key: pickEntries){
                newStatusList.add(new CampaignMemberStatus(
                    Label = key.getValue(),
                    CampaignId = c.Id,
                    HasResponded = respondedStatus.contains(key.getValue()) ? true : false,
                    IsDefault = key.getValue()== 'Nuevo'? true : false
                ));
            }
        }

        insert newStatusList;
    }
}