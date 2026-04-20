/*
AccountHelper Overview

The `AccountHelper` class is designed to provide helper methods that assist in performing specific operations on Account records. 
This class is intended to modularize the logic used in the `AccountTrigger` to ensure separation of concerns, improve readability, and ease maintenance. 

This class is currently stubbed out. As part of this exercise, you are expected to:
1. Implement the method bodies to carry out the specified operations on Account records.
2. Refactor the `AccountTrigger` to utilize the methods provided in this `AccountHelper` class.

Methods:
- `setTypeProspect(SObject objects)`: 
    - Purpose: Update the 'Type' field of the given Account record to 'Prospect' if it's not already set.
    - Note: You'll likely need to adjust the method signature to accept the necessary parameters.

- `addressCopy()`: 
    - Purpose: Copy the shipping address of the Account to its billing address. 
    - Note: You'll likely need to adjust the method signature to accept the necessary parameters.

- `setRating`: 
    - Purpose: Evaluate certain conditions on the Account and assign a rating based on that evaluation. 
    You'll need to define the method's signature and implement its logic.

- `defaultContact`: 
    - Purpose: Create a default contact related to the Account after the Account is inserted. You'll need to define the method's signature and implement its logic.

Remember:
Always ensure that your helper methods are bulk-safe to handle multiple records efficiently. 
*/
public with sharing class AccountHelper {
    
    // Q1 handler method: Sets the inserted account field's type to Prospect if original value is null.
    public static void setTypeProspect(List <Account> accounts){
            for (Account acc : accounts) {
            if (acc.Type == null) {
                acc.Type = 'Prospect';
            }
        }
    }

    // Q2 handler method: Sets the inserted account's Billing address field values WITH Shipping Address value if Billing address is null and Shipping address is not null.
    public static void addressCopy(List <Account> accounts){
    for (Account acc : accounts) {
            if (billingFieldsBlank(acc) && shippingFieldsNotBlank(acc)) 
                {
                    acc.BillingCity = acc.ShippingCity;
                    acc.BillingCountry =  acc.ShippingCountry; 
                    acc.BillingPostalCode = acc.ShippingPostalCode;
                    acc.BillingState = acc.ShippingState;
                    acc.BillingStreet = acc.ShippingStreet;
            }
        }
    }

    // Q3 handler method: Sets the inserted account's rating to Hot if the phone, website, and fax field are populated.
     public static void setHotRating (List <Account> accounts) {
        for (Account acc : accounts) {
            if (setToHotRating(acc)) {
                acc.Rating = 'Hot';
            }
        }
     }

    // Q4 Handler method - when an account is inserted, creates a contact record related to account fields. Contact record to hold default values.
     public static void createContact (List <Account> accounts) {
        List <Contact> newContacts = new List<Contact>();
        for (Account acc : accounts) {
            Contact con = new Contact(AccountId = acc.Id);
            con.LastName = 'DefaultContact';
            con.Email = 'default@email.com';
            newContacts.add(con);
        }
        insert newContacts;
       }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Q2 HELPERS
    //return true if account billing fields are null
    private static Boolean billingFieldsBlank (Account acc) {
        return (acc.BillingStreet == null && acc.BillingCity == null && acc.BillingState == null && acc.BillingPostalCode == null && acc.BillingCountry == null);
    }
    
     //return true if account shipping fields are not null
    private static Boolean shippingFieldsNotBlank (Account acc) {
        return (acc.ShippingStreet != null || acc.ShippingCity != null || acc.ShippingState != null || acc.ShippingPostalCode != null || acc.ShippingCountry != null);
    }

    // Q3 HELPER - return true if phone, webiste, fax are not null.
     private static Boolean setToHotRating (Account acc){
        return (acc.Phone != null && acc.Website != null && acc.Fax != null);
     }
}

