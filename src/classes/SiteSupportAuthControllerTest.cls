@isTest
private class SiteSupportAuthControllerTest{
    
    static testmethod void testSiteSupportAuthController() {
        
        // --------------- Set up records for test scenarios ------------------
        
        // Check to make sure settings record has been created, and PC is in Simulation Mode (to
        // prevent API callouts from being made during test method execution.
        pymt__Settings__c[] oldsettings = [ Select id, pymt__Gateway_Simulation_Mode__c from pymt__Settings__c where isdeleted = false ];
        if (oldsettings.size()>0) delete oldsettings;
        pymt__Settings__c settings = new pymt__Settings__c();
        settings.name = 'ApexTestSettings';
        settings.pymt__Gateway_Simulation_Mode__c = true;                    
        insert settings;
        System.assert( settings.Id <> null, 'Error finding/creating settings record for test methods to use.');
 
        // Retrieve a closed/won stage
        String stagename = [Select o.MasterLabel, o.IsClosed, o.IsActive From OpportunityStage o where o.IsClosed = true limit 1].MasterLabel;
        
        String apexTestLabel = 'ApexTestSiteCheckoutPageController';
        
        Account[] accounts = [Select id from Account where isDeleted = false and name = :apexTestLabel ];
        if (accounts != null && accounts.size() > 0) delete accounts;
        Account account =  new Account( name = apexTestLabel,   
                                       ShippingStreet = '123 Test Street',
                                       ShippingCity = 'Encinitas',
                                       ShippingState = 'CA',
                                       ShippingPostalCode = '92024',
                                       BillingStreet = '123 Test Street',
                                       BillingCity = 'Encinitas',
                                       BillingState = 'CA',
                                       BillingPostalCode = '92024',
                                       Reason_for_no_NCES_ID__c = 'International - No NCES ID' );
        insert account;
         
        Contact[] contacts = [Select id from Contact where isDeleted = false and lastname = :apexTestLabel];
        if (contacts != null && contacts.size() > 0) delete contacts;
        Contact contact = new Contact(firstname = 'Albert', 
                                      lastname = apexTestLabel,
                                      mailingstreet = '123 Test Street',
                                      mailingcity = 'Encinitas',
                                      mailingstate = 'CA',
                                      mailingpostalcode = '92024',
                                      otherstreet = '456 Test Street',
                                      othercity = 'Encinitas',
                                      otherstate = 'CA',
                                      otherpostalcode = '92024',
                                      accountId = account.id
                                      );
        insert contact;

        String caseSubject = apexTestLabel+'Case';
        Case[] cases = [Select id from Case where isDeleted = false and subject = :caseSubject];
        if (cases != null && cases.size() > 0) delete cases;

        Case newCase = new Case(subject = caseSubject, 
                QI_Statement_of_Work__c = 'Test case', 
                QI_Authorization_Hours__c = 5, 
                QI_Quote_Expiration__c = Date.Today()+1, contactId = contact.Id);
        insert newCase;
                
        // ------------------ Begin Tests -------------------------
        SiteSupportAuthController controller;  
      
        // No Case -----------------
        // Provoke error for not specifying Case record id...
        controller = new SiteSupportAuthController();
        System.assert(controller.disableForm == true, 'Expected form to be disabled after passing in NULL payment record Id parameter.');

        // Test isNullOrEmpty() method
        System.assert(controller.isNullOrEmpty(null),'Failed to identify null as NullOrEmpty');
        System.assert(controller.isNullOrEmpty(''),'Failed to identify "" as NullOrEmpty');
        System.assert(controller.isNullOrEmpty(' '),'Failed to identify " " as NullOrEmpty');                                             
        
        // Pass in Case record with an invalid Case id 
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('id','bogus_id');
        controller = new SiteSupportAuthController();
        System.assert(controller.disableForm == true, 'Expected form to be disabled after instantiating controller with invalid Case id');
        
        // Add processor connections
        pymt__Processor_Connection__c connection1 = new pymt__Processor_Connection__c(
                name = 'ApexTestProcessorConnection1',
                pymt__PaymentConnect_Setup__c = settings.id,
                pymt__Assigned_To_Terminal__c = true,
                pymt__Default_Connection__c = true,
                pymt__Processor_Id__c = 'Authorize.Net',
                pymt__Enabled_Card_Types__c = 'Visa;Mastercard',
                pymt__Authnet_Enable_Echecks__c = true);
            Database.SaveResult sr =    Database.insert(connection1);
            System.assert(sr.isSuccess(), 'Error inserting test processor connection object. '+sr);     
        pymt__Processor_Connection__c connection2 = new pymt__Processor_Connection__c(
                name = 'ApexTestProcessorConnection2',
                pymt__PaymentConnect_Setup__c = settings.id,
                pymt__Assigned_To_Terminal__c = true,
                pymt__Processor_Id__c = 'PayPal', 
                pymt__Authnet_Enable_Echecks__c = false);
            sr =    Database.insert(connection2);
            System.assert(sr.isSuccess(), 'Error inserting test processor connection object: '+sr);     
                                                                            
        
        // Pass in all required parameters and process the quote
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('id',newCase.Id);
        ApexPages.currentPage().getParameters().put('debug','1');
        controller = new SiteSupportAuthController();
        controller.processAuthorization();
        controller.finishTransaction();

        // Pass in same parameters and add account id, and contact id as parameters 
        ApexPages.currentPage().getParameters().put('aid',account.Id);
        ApexPages.currentPage().getParameters().put('cid',contact.Id);
        controller = new SiteSupportAuthController();
        
        // Set the quote expiration date on the case to a date in the past so the auth page will catch it 
        newCase.QI_Quote_Expiration__c = Date.today().addDays(-1);
        update newCase;
        controller = new SiteSupportAuthController();
        
    }

}