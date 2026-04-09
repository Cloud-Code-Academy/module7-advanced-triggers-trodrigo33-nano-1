public class AccountTriggerHandler extends TriggerHandler {
    //TR - Before Insert
    public override void beforeInsert() {
        AccountHelper.setTypeProspect(Trigger.new);
        AccountHelper.addressCopy(Trigger.new);
        AccountHelper.setHotRating(Trigger.new);
    }

    //TR - After Insert
    public override void afterInsert() {
        AccountHelper.createContact(Trigger.new);
    }
}