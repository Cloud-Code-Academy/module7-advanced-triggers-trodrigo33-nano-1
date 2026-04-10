public with sharing class OpportunityHandler extends TriggerHandler {

    public override void beforeInsert() {
    OpportunityHelper.setDefaultType(Trigger.new);
    }

    public override void beforeUpdate() {
    OpportunityHelper.stageDescriptionUpdate((Map<Id,Opportunity>)Trigger.oldMap, Trigger.new);
    OpportunityHelper.amountValidation(Trigger.new);
    handlerOpportunity.updatePrimaryContact(Trigger.new);
    }

    public override void beforeDelete() {
    OpportunityHelper.preventDeletion(Trigger.old);
    }

    public override void afterInsert(){
    OpportunityHelper.createTaskRecords(Trigger.new);
    }

    public override void afterDelete(){
    OpportunityHelper.notifyOwnersOpportunity(Trigger.old);

    }
    
    public override void afterUndelete(){
    OpportunityHelper.updatePrimaryContactAfterUndelete((Map<Id,Opportunity>)Trigger.newMap);

}
}
