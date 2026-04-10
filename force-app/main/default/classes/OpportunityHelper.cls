public with sharing class OpportunityHelper {
    //////////////////////////////////////////BEFORE INSERT/////////////////////////////////////////////
    public static void setDefaultType (List <Opportunity> Opportunities){
            for (Opportunity opp : Opportunities){
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }
        }
    }

    ///////////////////////////////////////// BEFORE UPDATE//////////////////////////////////////////////
     //Update description if stage is changed
    public static void stageDescriptionUpdate (Map <Id, Opportunity> oldMapOpportunities, List <Opportunity> newOpportunities){
            for (Opportunity oppNew : newOpportunities){
                 Opportunity oppOld = oldMapOpportunities.get(oppNew.Id);
                    if (oppNew.StageName != oppOld.StageName){
                        oppNew.Description += '\n Stage Change:' + oppNew.StageName + ':' + DateTime.now().format();
                    }
                }                
            }

    //Validates amount on opportunity to be greater than 5000
     public static void amountValidation (List <Opportunity> newOpportunities) {
        for (Opportunity newOpp : newOpportunities ) {
            if (newOpp.Amount <= 5000) {
                newOpp.Amount.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

    // Update opportunity Primary contact with the contact who's contact.Role = CEO && that belongs to the same account the opportunity is related to.
    public static void updatePrimaryContact (List<Opportunity> newOpportunities){
        Set<Id> accountIds = accountIdSet(newOpportunities);
        List <Contact> contactList = ([
            SELECT Id, AccountId 
            FROM Contact 
            WHERE Title = 'CEO' 
            AND AccountId IN :accountIds]);
        
        Map <Id, Contact> conCEO = new Map<Id, Contact>();
        for (Contact con : contactList) {
            conCEO.put(con.AccountId, con);
        }

        for (Opportunity opp : newOpportunities) {
            if (conCEO.containsKey(opp.AccountId)) {
                opp.Primary_Contact__c = conCEO.get(opp.AccountId).Id;
            }
    }
}

/////////////////////////////////////BEFORE DELETE///////////////////////////////////////////////////////////
//Prevents deletion of opportunity 
    public static void preventDeletion (List <Opportunity> oldOpportunities){
        Set<Id> accountIds = new Set<Id>(accountIdSet(oldOpportunities));
        Map<Id, Account> accountMap = new Map<Id, Account>([Select Id, Industry FROM Account WHERE Id IN :accountIds]);

           for (Opportunity oppError : oldOpportunities) {
            Account acc = accountMap.get(oppError.AccountId);
            if ((acc != null && acc.Industry == 'Banking' && oppError.StageName == 'Closed Won') || (oppError.IsClosed)) {
                oppError.addError('Cannot delete closed opportunity');
           }
        }
    }

    public static void preventClosedOppDeletion (List <Opportunity> oldOpportunities){
            for (Opportunity oldOpp : oldOpportunities){
                if (oldOpp.IsClosed) {
                    oldOpp.addError('Cannot delete closed opportunity');
                }
            }
    }

    //Helper Method to return accountIdSet.
    public static Set<Id> accountIdSet (List <Opportunity> Opportunities){
        Set<Id> accountIds = new Set<Id>();
            for (Opportunity opp : Opportunities) {
                if (opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
            }
        return accountIds;
    }

    /////////////////////////////////////////// AFTER INSERT ////////////////////////////////////////////////////////
         // Create a new Task for newly inserted Opportunities 
         public static void createTaskRecords(List <Opportunity> newOpportunities){
            List<Task> tasks = new List<Task>();
            for (Opportunity opp : newOpportunities){
                Task tsk = new Task();
                tsk.Subject = 'Call Primary Contact';
                tsk.WhatId = opp.Id;
                tsk.WhoId = opp.Primary_Contact__c;
                tsk.Priority = 'Normal';
                tsk.Status = 'Not Started';
                tsk.OwnerId = opp.OwnerId;
                tsk.ActivityDate = Date.today().addDays(3);
                tasks.add(tsk);
            }
            if (!tasks.isEmpty()){
            insert tasks;
        }
}

///////////////////////////////////////////////////////////////AFTER DELETE/////////////////////////////////////////////////////////
    // Sends an email notification to the owner of the Opportunity when it gets deleted.
    // Uses Salesforce's Messaging.SingleEmailMessage to send the email.
        public static void notifyOwnersOpportunity(List <Opportunity> opps){
        notifyOwnersOpportunityDeleted(opps);
    }

        private static void notifyOwnersOpportunityDeleted(List <Opportunity> opps){
        Set<Id> oppOwnerId = new Set<Id>();
        for (Opportunity opp :opps) {
            if (!oppOwnerId.contains(opp.Id)) {
                oppOwnerId.add(opp.OwnerId);
            }
        }

        //Create map to store User Id, User Record
        Map<Id,User> oppOwnerEmail = new Map <Id, User>([SELECT Id, Email FROM User WHERE Id IN :oppOwnerId]);

        // Populate mails list with mail for each opp
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        for (Opportunity opp : opps){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if (oppOwnerEmail.containsKey(opp.OwnerId)) {
                String[] toAddresses = new List<String>();
                toAddresses.add(oppOwnerEmail.get(opp.OwnerId).Email);
                mail.setToAddresses(toAddresses);
                mail.setSubject('Opportunity Deleted : ' + opp.Name);
                mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
                mails.add(mail); 
            }
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
            
        }
        
    ////////////////////////////////////////////////AFTER UNDELETE///////////////////////////////////////////////////////////////
    //Assigns a primary contact with the title of 'VP Sales' to the opportunity who belongs to the same account the opp is related to.
    
    public static void updatePrimaryContactAfterUndelete(Map<Id,Opportunity> oppNewMap){
    assignPrimaryContact(oppNewMap);
    }

    private static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {
        Set<Id> accIds = new Set<Id>();
        for (Opportunity opp : oppNewMap.values()) {
            if (!accIds.contains(opp.AccountId)) {
                accIds.add(opp.AccountId);
            }
        }

        Contact primaryContact = [SELECT Id, AccountId FROM Contact WHERE Title = 'VP Sales' AND AccountId IN :accIds LIMIT 1];
        List<Opportunity> newopps = new List<Opportunity>();

        for (Opportunity opp : oppNewMap.values()){            
            if (opp.Primary_Contact__c == null){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = primaryContact.Id;
                newopps.add(oppToUpdate);
            }
        }
        if (!newopps.isEmpty()) {
            update newopps; 
        }
    }
}




