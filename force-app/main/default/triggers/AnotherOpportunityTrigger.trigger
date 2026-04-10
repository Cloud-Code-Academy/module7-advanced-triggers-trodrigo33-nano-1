/*
AnotherOpportunityTrigger Overview

This trigger was initially created for handling various events on the Opportunity object. It was developed by a prior developer and has since been noted to cause some issues in our org.

IMPORTANT:
- This trigger does not adhere to Salesforce best practices.
- It is essential to review, understand, and refactor this trigger to ensure maintainability, performance, and prevent any inadvertent issues.

ISSUES:
Avoid nested for loop - 1 instance (FOUND LINE 63/64) (PASSED)
Avoid DML inside for loop - 1 instance (FOUND LINE 56) 
Bulkify Your Code - 1 instance (FOUND LINE 28)
Avoid SOQL Query inside for loop - 2 instances (FOUND) 
Stop recursion - 1 instance (FOUND LINE 74)

RESOURCES: 
https://www.salesforceben.com/12-salesforce-apex-best-practices/
https://developer.salesforce.com/blogs/developer-relations/2015/01/apex-best-practices-15-apex-commandments
*/
trigger AnotherOpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete, after undelete) {


    //ISSUE BEFORE INSERT: Sets the first opp object's type if null. Does not loop through list of opps, just the first one in index 0.
    //PASSED
    
    if (Trigger.isBefore){
        //PASSED
        if (Trigger.isInsert){
            for (Opportunity opp : Trigger.new){
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }
        }
     } //PASSED - moved this section from isAfter.IsUpdate block as we can't update the already inserted opp records there. It is read only.
     else if (Trigger.isUpdate){
        Map<Id, Opportunity> oldOpps = new Map<Id, Opportunity>(Trigger.oldMap);
            for (Opportunity oppNew : Trigger.new){
                 Opportunity oppOld = oldOpps.get(oppNew.Id);
                    if (oppNew.StageName != oppOld.StageName){
                        oppNew.Description += '\n Stage Change:' + oppNew.StageName + ':' + DateTime.now().format();
                    }
                }                
            }
            // PASSED - Prevent deletion of closed Opportunities
        else if (Trigger.isDelete){
            for (Opportunity oldOpp : Trigger.old){
                if (oldOpp.IsClosed) {
                    oldOpp.addError('Cannot delete closed opportunity');
                }
            }
        }
     } // PASSED - Create a new Task for newly inserted Opportunities 
      
    if (Trigger.isAfter){
        if (Trigger.isInsert){
            List<Task> tasks = new List<Task>();
            for (Opportunity opp : Trigger.new){
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
        // Send email notifications when an Opportunity is deleted 
        else if (Trigger.isDelete){
            notifyOwnersOpportunityDeleted(Trigger.old);
        } 
        // Assign the primary contact to undeleted Opportunities
        else if (Trigger.isUndelete){
            assignPrimaryContact(Trigger.newMap);
        }
    }

    /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */

    private static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        Set<Id> oppOwnerId = new Set<Id>();
        for (Opportunity opp :opps) {
            if (!oppOwnerId.contains(opp.Id)) {
                oppOwnerId.add(opp.OwnerId);
            }
        }

        //Create map to store User Id, User Record
        Map<Id,User> oppOwnerEmail = new Map <Id, User>([SELECT Id, Email FROM User WHERE Id IN :oppOwnerId]);

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

    /*
    assignPrimaryContact:
    - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    - Only updates the Opportunities that don't already have a primary contact. 
    - TR: Adding in extra context as the original problem indicates it. '... Assigns a primary contact with the title of 'VP Sales' to the opportunity who belongs to the same account the opp is related to.
    */

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


        /*
        // ISSUE - REMOVED ENTIRE CODE BLOCK AS this is an attempt to update the list of opportunity records in an after update context. 
        //ISSUE - AFTER UPDATE Nested for loop; LOOP through each new opp. FOR EACH new opp, LOOP through each old opp. FOR EACH old opp, if stage name is null, set description.
        //ISSUE - AFTER UPDATE - can't update record that is already committed to database. 
        //ISSUE - Looks like trying to compare prior stage name with new stage name. This for loop does not work to do that. Must update.
        else if (Trigger.isUpdate){
            // Append Stage changes in Opportunity Description
            Map<Id, Opportunity> oldOpps = new Map<Id, Opportunity>(Trigger.oldMap);
            for (Opportunity opp : Trigger.new){
                {Opportunity oldOpp = oldOpps.get(opp.Id);
                    if (opp.StageName != oldOpp.StageName){
                        opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
                    }
                }                
            }
            //REMOVED TO AVOID RECURSION. Changes have already been committed after update. Trigger.new is read only.
            // If needing to update the triggering record, this would be best placed in a before update context.
            //update Trigger.new;
        }
             */