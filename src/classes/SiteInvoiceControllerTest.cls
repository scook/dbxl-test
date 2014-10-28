@isTest(SeeAllData=true)
private class SiteInvoiceControllerTest{
    static testmethod void testSiteInvoiceController() {
        
        // --------------- Set up records for test scenarios ------------------
        
        // Check to make sure settings record has been created, and PC is in Simulation Mode (to
        // prevent API callouts from being made during test method execution.
        pymt__Settings__c settings = null;
        pymt__Settings__c[] oldsettings = [ Select id, pymt__Gateway_Simulation_Mode__c from pymt__Settings__c where isdeleted = false limit 1];
        if (oldsettings.size()>0) {
			oldsettings[0].pymt__Gateway_Simulation_Mode__c = true;
            update oldsettings;
            settings = oldsettings[0];
        }
        else {
            settings = new pymt__Settings__c();
            settings.name = 'ApexTestSettings';
            settings.pymt__Gateway_Simulation_Mode__c = true;                    
            Database.insert(settings, false);
    	}
        System.assert( settings.Id <> null, 'Error finding/creating settings record for test methods to use.');
 
        // Retrieve a closed/won stage
        String stagename = [Select o.MasterLabel, o.IsClosed, o.IsActive From OpportunityStage o where o.IsClosed = true and IsWon = true limit 1].MasterLabel;
        
        String apexTestLabel = 'ApexTestSiteInvoicePageController';
        
        Account[] accounts = [Select id from Account where isDeleted = false and name = :apexTestLabel ];
        if (accounts != null && accounts.size() > 0) delete accounts;
        Account account = new Account( name = apexTestLabel,   
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

        String oppName = apexTestLabel+'Opp';
        Opportunity[] opps = [Select id from Opportunity where isDeleted = false and name = :oppName];
        if (opps != null && opps.size() > 0) delete opps;
        Opportunity newOppNotInserted = new Opportunity(name = oppName,
                                            closedate = System.today(),
                                            stagename = 'Opportunity',
                                            License_Level__c = 'Site',
                                            Lead_Source_Detail__c = 'Test Partner',  
                                            Publish_As_Invoice__c = true,
                                            amount = 450.00
                                            );
        Opportunity newOpp = new Opportunity(name = oppName,
                                            closedate = System.today(),
                                            stagename = 'Opportunity',
                                            License_Level__c = 'Site',
                                            Lead_Source_Detail__c = 'Test Partner',  
                                            Publish_As_Invoice__c = true,
                                            amount = 450.00
                                            );
        insert newOpp;
                
        // Add opportunity line items
        //    get standard pricebook id
        Pricebook2[] pricebooks = [select id from Pricebook2 where isstandard = true limit 2];
        system.assert(pricebooks.size()>0, 'PaymentConnect test methods require that at least on standard pricebook be available.');
        Product2 newProduct = new Product2(name = 'test product',productcode = 'apextest_123', isActive = true, description = 'test',
                                            pymt__on_payment_completed__c = 'Test');
        insert newProduct;
        PricebookEntry newEntry = new PricebookEntry( isactive = true, product2Id = newProduct.id, 
                                        pricebook2id = pricebooks[0].id, unitprice = 2.00); 
        insert newEntry;
        OpportunityLineItem newLineItem = new OpportunityLineItem( opportunityId = newOpp.id,
                                                                    pricebookentryId = newEntry.id,
                                                                    quantity=2,
                                                                    unitprice = 2.00 );
        insert newLineItem;
        newOpp.stagename = 'Closed Won';
        newOpp.Execution_Document__c = 'test document';
        update newOpp;
        Opportunity newOppRecurring = new Opportunity(name = oppName+'-recurring',
                                            closedate = System.today(),
                                            pymt__sitequote_expiration__c = Date.today().addDays(30),
                                            stagename = 'Opportunity',
                                            amount = 1000,
                                            License_Level__c = 'Site',
                                            Lead_Source_Detail__c = 'Test Partner',                                              
                                            Publish_As_Invoice__c = true,
                                            pymt__tax__c = 50,
                                            pymt__shipping__c = 150,
                                            pymt__recurring_amount__c = 100,
                                            pymt__frequency__c = 1,
                                            pymt__period__c = 'Month',
                                            pymt__occurrences__c = 12,
                                            pymt__SiteQuote_Recurring_Setup__c = 'Recurring Payments = Total Amount', 
                                            accountid = account.id,
                                            Execution_Document__c = 'test execution document'
                                            );
        insert newOppRecurring;
        OpportunityLineItem newLineItem2 = new OpportunityLineItem( opportunityId = newOppRecurring.id,
                                                                    pricebookentryId = newEntry.id,
                                                                    quantity=2,
                                                                    unitprice = 2.00 );
        insert newLineItem2;

        Opportunity newOppRecurring2 = newOppRecurring.clone(false, true); // don't clone Id, deep clone
        newOppRecurring2.pymt__SiteQuote_Recurring_Setup__c = 'Total Amount + Recurring Payments';
        insert newOppRecurring2;
        newOppRecurring.stagename = 'Closed Won';
        update newOppRecurring;
        OpportunityLineItem newLineItem3 = new OpportunityLineItem( opportunityId = newOppRecurring2.id,
                                                                    pricebookentryId = newEntry.id,
                                                                    quantity=2,
                                                                    unitprice = 2.00 );
        insert newLineItem3;
        newOppRecurring2.stagename = 'Closed Won';
        update newOppRecurring2;
        System.assert(newOpp.Id <> null,'Error creating test opportunity for SiteInvoiceController');
        System.assert((newOppRecurring.Id <> null && newOppRecurring2.Id <> null),'Error creating recurring test opportunities for SiteInvoiceController');

        System.debug('======>Begin Tests');
        Test.setCurrentPage(Page.SiteInvoice);
        
        // ------------------ Begin Tests -------------------------
        SiteInvoiceController controller;  
      
        // No Opp -----------------
        // Provoke error for not specifying opportunity record id...
        controller = new SiteInvoiceController();
        
        controller.specialDecodeURLParm('testing');
        controller.specialDecodeURLParm('%3A%2F%2F');
        controller.isURL('1123');
        controller.isURL('');
        controller.isURL('http://www.salesforce.com');
        String ipAddr = controller.getCurrentIPAddress();

        ApexPages.currentPage().getParameters().put('id',newOpp.Id);
        controller = new SiteInvoiceController();

        // Test isNullOrEmpty() method
        System.assert(controller.isNullOrEmpty(null),'Failed to identify null as NullOrEmpty');
        System.assert(controller.isNullOrEmpty(''),'Failed to identify "" as NullOrEmpty');
        System.assert(controller.isNullOrEmpty(' '),'Failed to identify " " as NullOrEmpty');                                             
        
       
    System.debug('======>Paid Off');

        // Opportunity is already "Paid Off"
        newOpp.pymt__Paid_Off__c = true;
        update newOpp;
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('id',newOpp.Id);
        controller = new SiteInvoiceController();
        System.assert(controller.showPageContents == false, 'Expected form to be disabled after instantiating controller with paid opportunity');
                
    System.debug('======>Quote Expired');
                
        // Quote is expired
        newOpp.pymt__Paid_Off__c = false;  // undo flag for previous test scenario
        newOpp.pymt__SiteQuote_Expiration__c = Date.today().addDays(-1); // set expiration to yesterday
        update newOpp;
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('id',newOpp.Id);
        controller = new SiteInvoiceController();
        System.assert(controller.showPageContents == false, 'Expected form to be disabled after instantiating controller with expired quote');
        
        // set expiration to 1 month out
        newOpp.pymt__SiteQuote_Expiration__c = Date.today().addDays(30); 
        update newOpp;
        
    System.debug('======>No Contact');

        // No Contact
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('id',newOpp.Id);
        controller = new SiteInvoiceController();
        System.assert(controller.showPageContents == false, 'Expected form to be disabled after instantiating controller without an opportunity contact');

        // Create opportunity contacts (primary)
        OpportunityContactRole oppContact = new OpportunityContactRole(isPrimary = true, opportunityId = newOpp.id, contactId = contact.id, role = 'Decision Maker');
        insert oppContact;
        oppContact = new OpportunityContactRole(isPrimary = true, opportunityId = newOppRecurring.id, contactId = contact.id, role = 'Decision Maker');
        insert oppContact;
        oppContact = new OpportunityContactRole(isPrimary = true, opportunityId = newOppRecurring2.id, contactId = contact.id, role = 'Decision Maker');
        insert oppContact;
                

        // No Account
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('id',newOpp.Id);
        controller = new SiteInvoiceController();
  //      System.assert(controller.showPageContents == false, 'Expected form to be disabled after instantiating controller without an account');
        
        // Add account
        newOpp.AccountId = account.Id; 
        update newOpp;

    System.debug('======>No Connection');

        // No Processor Connection
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('id',newOpp.Id);
        controller = new SiteInvoiceController();
 //       System.assert(controller.showPageContents == false, 'Expected form to be disabled after instantiating controller without an available processor connection');
        controller.cancelTransaction();

        
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
        ApexPages.currentPage().getParameters().put('id',newOpp.Id);
        ApexPages.currentPage().getParameters().put('debug','1');
//        ApexPages.currentPage().getParameters().put('css','http%253A%252F%252Fwww.amazon.com%252Fdummy.css');
//        ApexPages.currentPage().getParameters().put('banner','/s.gif');
        ApexPages.currentPage().getParameters().put('cancel_url','http%253A%252F%252Fwww.amazon.com%252Fdummy.css');
        ApexPages.currentPage().getParameters().put('finish_url','http%253A%252F%252Fwww.amazon.com%252Fdummy.css');
        controller = new SiteInvoiceController();
        controller.getLineItems();
        controller.processQuote();
        controller.finishTransaction();

        // Pass in same parameters and add account id, and contact id as parameters 
        ApexPages.currentPage().getParameters().put('id',newOpp.Id);
        ApexPages.currentPage().getParameters().put('aid',account.Id);
        ApexPages.currentPage().getParameters().put('cid',contact.Id);
        controller = new SiteInvoiceController();

    System.debug('======>Authnet recurring');
        
        // Process a quote with recurring payment terms using AuthNet
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('id',newOppRecurring.Id);
        ApexPages.currentPage().getParameters().put('debug','1');
        controller = new SiteInvoiceController();
        
        // 
        controller.changeBillingInformation();
        //System.assert(controller.updatedContact <> null,'Error creating and finding primary opportunity contact record for testing.');
        //controller.updatedContact.FirstName = 'Sam';
        //controller.updatedContact.LastName = 'ApexTest';
        //controller.updatedContact.email = 'sam.apextest@test.com';
        //controller.updatedContact.mailingstreet = '123 Oak';
        //controller.updatedContact.mailingcity = 'Encinitas';
        //controller.updatedContact.mailingstate = 'CA';
        //controller.updatedContact.mailingpostalcode = '92024';
        //controller.updatedContact.mailingcountry = 'US';
        controller.processQuote();      

        // Process a quote with recurring payment terms (incorrect installment amount)
        ApexPages.currentPage().getParameters().clear();
        newOppRecurring.pymt__Recurring_Amount__c = 50; // incorrect amount - doesn't add up to total amount of opportunity over 12 payments
        update newOppRecurring;
        ApexPages.currentPage().getParameters().put('id',newOppRecurring.Id);
        ApexPages.currentPage().getParameters().put('debug','1');
        controller = new SiteInvoiceController();
         
        
    System.debug('======>PayPal recurring');

        // Process a quote with recurring payment terms using PayPal (change the default payment processor and go again)
        connection2.pymt__Default_Connection__c = true;
        connection1.pymt__Default_Connection__c = false;
        update connection1; 
        update connection2;
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('id',newOppRecurring2.Id);
        ApexPages.currentPage().getParameters().put('debug','1');
        controller = new SiteInvoiceController();
        controller.processQuote();      

        System.debug('======>PayPal recurring done');
        
    }
}