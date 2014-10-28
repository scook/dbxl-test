public with sharing class PtlInvoiceController {
// ---------------------------------------------------------------------------
// PtlInvoice controller for PaymentConnect
// Copyright: Linvio, Inc.
// URL: www.linvio.com
// Last Update: 04/07/2012 
// ---------------------------------------------------------------------------

 
    private AccessControllerWithoutSharing acwos;
    
    // Parameters
    public String cancelURL {get;set;}
    public String finishURL {get;set;}
    public String contactId {get;set;} 
    public String accountId {get;set;} 
    
    public Boolean debug {get;set;} 
    public Boolean enableBillingInfoEdit {get;set;}
    public Boolean requireSignatory {get;set;}  // controls whether or not "Accept Terms" options are displayed
    public String signature {get;set;}
    public Boolean isMultiCurrencyEnabled {get;set;}
    public String lang {get;set;}
    
    public Opportunity opportunity {get;set;}
    public Contact contact {get;set;}
    public Contact updatedContact {get;set;}
    public Account account {get;set;}
    public pymt__PaymentX__c payment {get;set;}
    public pymt__Payment_Profile__c paymentProfile {get;set;}
    public pymt__Processor_Connection__c processor {get;set;}
    public String processorName {get;set;}
    
    public Boolean disableForm {get;set;}
    public Boolean hasRecurringAmount {get;set;}
    public Boolean termsAccepted {get;set;}
    public String recurringSetup {get;set;}
    
    public class LocalException extends Exception {
        String privateErrorMsg = '';
        String publicErrorMsg = '';
        public String getPrivateMessage() {
            return this.privateErrorMsg;
        }
        public LocalException( String publicMsg, String privateMsg) {
            this.setMessage(publicMsg);
            this.privateErrorMsg = privateMsg;
        }
    }
    
    public class Opp {
        public String name {get;set;}
        public String invoiceNumber {get;set;} 
        public String description {get;set;}    
        public Account account {get;set;}
        public Boolean hasLines {get;set;}
        public Boolean paidOff {get;set;}
        public OppLine[] lineItems {get;set;}
        public String conditions {get;set;}
        public Date expirationDate {get;set;}
        public Decimal amount {get;set;}
        public Decimal balance {get;set;}
        public Decimal tax {get;set;}
        public Decimal shipping {get;set;}
        public Decimal totalAmount {get;set;}
        public Decimal recurringAmount {get;set;}
        public String period {get;set;}
        public Decimal frequency {get;set;}
        public Decimal occurrences {get;set;}
    }
    public class OppLine {
        public String name {get;set;}
        public String description {get;set;}
        public Decimal unitPrice {get;set;}
        public Decimal quantity {get;set;}
        public Decimal total {get;set;}
        public String productCode {get;set;}
        public String opcTag {get;set;}
        public Product2 product {get;set;}
        
    }
    public Opp opp {get;set;}
    
    public String returnURL {
        get {
            returnURL = ApexPages.currentPage().getHeaders().get('Referer');
            if (returnURL <> null && returnURL.contains('?')) {
                    returnURL = returnURL.split('\\?')[0];
            } else {
                String host = Site.getCurrentSiteURL();
                if (host <> null && host.length() > 0) {
                    String pageName = '';
                    String[] urlParts = ApexPages.currentPage().getUrl().split('/');
                    if (urlParts.size()>0) {
                        pageName = urlParts[urlParts.size()-1].split('\\?')[0];  // drop off any parameters (e.g. relayscript?relay_script_test=1)
                    } 
                    returnURL = host+ pageName;
                } 
                
            }
            return returnURL;
        }
        set; 
    
    }
    
    public PtlInvoiceController() {
        Id oppId = ApexPages.currentPage().getParameters().get('id');
        
        this.termsAccepted = false;
        this.requireSignatory = true;  // set to false to disable options for accepting terms and conditions
        this.signature = '';
        this.hasRecurringAmount = false;
        
        this.lang = pymt.Util.assignIfNotEmpty(ApexPages.currentPage().getParameters().get('lang'),this.lang);
        if (isNullOrEmpty(this.lang)) {
            ApexPages.currentPage().getParameters().put('lang', UserInfo.getLocale());
        }

        this.debug = !isNullOrEmpty(ApexPages.currentPage().getParameters().get('debug'));
        this.enableBillingInfoEdit = false;
        
        this.acwos = new AccessControllerWithoutSharing(); 
        this.isMultiCurrencyEnabled = Schema.sObjectType.pymt__PaymentX__c.fields.getMap().keyset().contains('CurrencyISOCode');
        
              
        try {
        
            // See if multicurrency is enabled in this org
            
            
            this.contactId = ApexPages.currentPage().getParameters().get('cid');     // contact id
            this.contactId = pymt.Util.isValidSalesforceId(this.contactId)?this.contactId:null;  // Make sure parm is a valid SF Id
            this.accountId = ApexPages.currentPage().getParameters().get('aid');     // account id
            this.accountId = pymt.Util.isValidSalesforceId(this.accountId)?this.accountId:null;  // Make sure parm is a valid SF Id

            //this.cancelURL = ApexPages.currentPage().getURL();  //  << doesn't return the full path

            this.cancelURL = this.returnURL+'?id='+oppId;
            this.finishURL = '';  // may want to set this to the company home page
            
            String soql = 'Select id, name, amount, pymt__paid_off__c, owner.firstname, owner.lastname, '+ 
                                'isClosed, isWon, '+ (this.isMultiCurrencyEnabled?'CurrencyISOCode, ':'')+
                                'description, account.name, account.billingstreet, account.billingcity, '+
                                'account.billingpostalcode, account.billingstate, account.billingcountry,  '+
                                'account.shippingstreet, account.shippingcity, '+
                                'account.shippingpostalcode, account.shippingstate, account.shippingcountry,  '+
                                'HasOpportunityLineItem, pymt__recurring_amount__c, pymt__Balance__c, '+
                                'pymt__frequency__c, pymt__occurrences__c, pymt__period__c,  pymt__SiteQuote_Expiration__c, '+
                                'Quote_Number__c, Quote_Version__c, pymt__Invoice_Number__c, QI_Terms_and_Conditions__c, pymt__SiteQuote_Recurring_Setup__c, '+
                                'pymt__Tax__c, pymt__Shipping__c, pymt__Total_Amount__c, '+
                                '(Select ContactId, Role, IsPrimary From OpportunityContactRoles where IsPrimary = true) '+
                                ' from Opportunity where Publish_as_Invoice__c = true and id = \''+ String.escapeSingleQuotes(oppId)+'\'';
                                 
            Opportunity[] opps = this.acwos.dbQuery(soql);
            
            if (opps <> null && opps.size() >0 ) {
                this.opportunity = opps[0];  

                if (!(this.opportunity.isClosed && this.opportunity.isWon)) throw new LocalException('Invoice has not been posted.','Opportunity must be closed and won to enable online invoice payment.');
                
                this.opp = new Opp();
                this.opp.name = this.opportunity.Name;
                this.opp.account = this.opportunity.Account;
                this.opp.invoiceNumber = this.opportunity.pymt__Invoice_Number__c;
                this.opp.lineItems = new OppLine[]{};
                this.opp.amount = this.opportunity.amount;
                this.opp.balance = this.opportunity.pymt__Balance__c;
                this.opp.paidOff = this.opportunity.pymt__Paid_Off__c;
                this.opp.tax = this.opportunity.pymt__Tax__c;
                this.opp.shipping = this.opportunity.pymt__Shipping__c;
                this.opp.totalAmount = this.opportunity.pymt__Total_Amount__c;
                this.opp.recurringAmount = this.opportunity.pymt__Recurring_Amount__c;
                this.opp.frequency = this.opportunity.pymt__Frequency__c;
                this.opp.period = this.opportunity.pymt__Period__c;
                this.opp.occurrences = this.opportunity.pymt__Occurrences__c;
                this.opp.conditions = this.opportunity.QI_Terms_and_Conditions__c;
                this.opp.expirationDate = this.opportunity.pymt__SiteQuote_Expiration__c;
                
                
                
                // If contactId is provided as a parameter, use it, otherwise try to use the id of the primary opportunity contact
                if (isNullOrEmpty(this.contactId) && this.opportunity.opportunitycontactroles <> null && this.opportunity.opportunitycontactroles.size()>0) {
                    this.contactId = this.opportunity.opportunitycontactroles[0].ContactId;
                } 
                if (!isNullOrEmpty(this.contactId)) {
                    Contact[] contacts = [Select id, name, firstname, lastname, mailingstreet, mailingcity, mailingpostalcode, 
                                mailingstate, mailingcountry, email 
                                from Contact
                                where id = :this.contactId];
                    if (contacts <> null && contacts.size() > 0)  {
                        this.contact = contacts[0];  
                        this.updatedContact = this.contact.clone(false,true); // clone: clear id, deep clone      
                    }     
                }
                if (this.updatedContact == null) {
                        throw new LocalException('Invoice configuration error - contact not assigned.','Unable to find primary opportunity contact.');                  
                }
                                
                // If account is provided as a parameter, use it, otherwise try to use the account from the opportunity record
                if (isNullOrEmpty(this.accountId)) {
                    this.account = this.opportunity.Account;
                } else {
                    this.account = [Select id, name, billingstreet, billingcity, billingpostalcode, billingstate, billingcountry from Account where id = :this.accountId];
                }
                Map<String,String> recurringSetupOptions = new Map<String,String>{
                                    'Recurring Payments = Total Amount'=>'Installment',
                                    'Total Amount + Recurring Payments'=>'RecurringTackedOn',
                                    'Total Amount Includes First Recurring Payment'=>'FirstRecurringIncluded'};
                this.recurringSetup = recurringSetupOptions.get(this.opportunity.pymt__SiteQuote_Recurring_Setup__c);
                if (this.recurringSetup == 'Installment' ) {
                    if (this.opportunity.pymt__Occurrences__c == null) throw new LocalException('Invoice configuration error.  Installment payments must have a fixed number of occurrences.');                       
                    if (this.opportunity.pymt__Recurring_Amount__c == null 
                        || this.opportunity.pymt__Occurrences__c == 0 
                        || this.opportunity.pymt__Recurring_Amount__c == 0 
                        || Math.abs(this.opportunity.pymt__Recurring_Amount__c * this.opportunity.pymt__Occurrences__c 
                                - this.opportunity.pymt__Total_Amount__c) > 0.01 * this.opportunity.pymt__Occurrences__c) { // account for possible rounding errors
                            throw new LocalException('Invoice configuration error.  Installment payments do not equal the total amount.');
                        }
                }
                if (this.recurringSetup == 'FirstRecurringIncluded' && 
                    this.opportunity.pymt__total_amount__c < this.opportunity.pymt__recurring_amount__c) {
                      throw new LocalException('Invoice configuration error.  Total amount must be greater than or equal to the first recurring payment amount when '+
                                'including first recurring payment in total.');                         
                        
                }                    
            } else {
                    throw new LocalException('Invoice could not be found', 'Query results empty.');             
            }
                
            
            if (this.opportunity.pymt__Recurring_Amount__c != null && this.opportunity.pymt__Recurring_Amount__c > 0 && this.opportunity.pymt__Frequency__c != null &&
                this.opportunity.pymt__Frequency__c > 0 && !isNullOrEmpty(this.opportunity.pymt__Period__c) && this.recurringSetup <> null) {
                    this.hasRecurringAmount = true;
                }
            if (this.opportunity.pymt__paid_off__c) {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This invoice is paid in full.'));
            }
                       
            if (this.contact == null) {
                throw new LocalException('Invoice configuration error - contact not assigned', 'Cannot process quote without a contact record.  Please add a primary opportunity contact to the opportunity record.'); 
            }
            if (this.account == null) {
                throw new LocalException('Invoice configuration error - account not assigned', 'Cannot process quote without an account record.  Please add an account to the opportunity record.'); 
            }
            
            // Retrieve default processor connection record
            // Otherwise search for the first available supported processor connection
            pymt__Processor_Connection__c[] connections = this.acwos.dbQuery('Select id, pymt__default_connection__c, pymt__processor_id__c, pymt__test_mode__c, pymt__Default_Currency__c,  '+
                    'pymt__PP_Merchant_Id__c from pymt__Processor_Connection__c where isDeleted = false'); 
            Set<String> supportRecurring = new Set<String>{'Authorize.Net', 'PayPal', 'WorldPay'};
            Set<String> supported = new Set<String>{'Authorize.Net', 'PayPal', 'WorldPay', 'Google','eWay'};
            Boolean found = false;
            if (connections.size()>0 ) {
                // Find the default connection
                for (pymt__Processor_Connection__c conn :connections) {
                    if (conn.pymt__default_connection__c) {
                        this.processor = conn;
                        this.processorName = conn.pymt__processor_id__c;
                        found = true;
                        break;
                    }
                }
                // otherwise use the first available
                if (!found) {
                    this.processor = connections[0];
                    this.processorName = this.processor.pymt__processor_id__c;
                }
                // See if the processor supports the type of payment required on this page
                if (!supported.contains(connections[0].pymt__Processor_Id__c) || 
                    (this.hasRecurringAmount && !supportRecurring.contains(this.processor.pymt__Processor_Id__c))) {
                    throw new LocalException('Configuration Error.', 'The processor connection '+ this.processorName + ' cannot be used for this quote.');              
                }
            } 
            if (this.processor == null) {
                throw new LocalException('Configuration Error.', 'Could not find a processor connection to use for this invoice.  Please check your settings.'); 
            }     
            
            OpportunityLineItem[] oppLines = getOppLineItems();
       system.debug('=====> testing....');
            if (oppLines <> null && oppLines.size()>0) {
       system.debug('=====> found line items: '+oppLines);
                this.opp.hasLines = true;
                for (OpportunityLineItem item :oppLines) {
          system.debug('=====> opp line item: '+ item);
                    OppLine line = new OppLine();
                    line.name = item.pricebookentry.name;
                    line.opcTag  = item.pricebookentry.product2.pymt__on_Payment_Completed__c;
                    line.productCode = item.pricebookentry.productcode;
                    line.description = item.description;
                    line.unitPrice = item.unitPrice;
                    line.quantity = item.quantity;
                    line.product = item.pricebookentry.product2;
                    line.total = item.TotalPrice;
                    this.opp.lineItems.add(line);
                }
            }

        
        } Catch (LocalException lex) {
            System.debug('An error encountered loading the SiteInvoice page: '+lex);
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, (this.debug?lex.getPrivateMessage():lex.getMessage())));
            this.disableForm = true;                            
        } Catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading page.'+ ex.getMessage()));
            this.disableForm = true;
        }        
    
    }
    
    public PageReference changeBillingInformation() {
        this.enableBillingInfoEdit = true;
        return null;
    }
    
    

    // Applications my have to twice encode fully qualified URLs to get around a bug in visualforce url parsing
    // Check to see if these urls have been twice encoded  ("%3A%2F%2F" = "://")
    public String specialDecodeURLParm(String parm) {
        String result = isNullOrEmpty(parm)?'':EncodingUtil.UrlDecode(parm,'UTF-8');                                      
        if (result.contains('%3A%2F%2F')) result = Encodingutil.urlDecode(result, 'UTF-8');
        return result;
    }
    
    public OpportunityLineItem[] getOppLineItems() {
        OpportunityLineItem[] lineItems = new OpportunityLineItem[]{};
        
        if (this.opportunity <> null && this.opportunity.HasOpportunityLineItem ) {
            String soql = 'Select UnitPrice, TotalPrice, SystemModstamp, SortOrder, ServiceDate, Quantity, PricebookEntryId, PricebookEntry.Name, '+
                'pricebookentry.product2.pymt__on_Payment_Completed__c, pricebookentry.productcode, '+
                 (this.isMultiCurrencyEnabled?'CurrencyISOCode, ':'')+
                'OpportunityId, ListPrice, LastModifiedDate, LastModifiedById, IsDeleted, Id, Description, CreatedDate, CreatedById '+ 
                'From OpportunityLineItem '+ 
                'where isDeleted = false and OpportunityId = \''+String.escapeSingleQuotes(this.opportunity.Id)+'\' ORDER BY SortOrder Asc';
            lineItems = this.acwos.dbQuery(soql);       
        }
        return lineItems;
        
    }

    public Boolean isURL(String str) {
        if (isNullOrEmpty(str)) return false;
        if (str.contains('https:') || str.contains('http:')) return true;
        return false;
    }
    
    public Boolean isNullOrEmpty(String astring) {
        if (astring == null) return true;
        if (astring.trim()=='') return true;
        return false;
    }

    public PageReference cancelTransaction() {
        PageReference cancelPage = null;
        if (!isNullOrEmpty(this.cancelURL)) {
            cancelPage = new PageReference(this.cancelURL);
        }
        return cancelPage;
    
    }
    
    public PageReference finishTransaction() {
        PageReference finishPage = null;
        if (!isNullOrEmpty(this.finishURL)) {
            finishPage = new PageReference(this.finishURL);
        }
        return finishPage;
    
    }   
    // Creates a Recurring Payment Profile record to be passed to the checkout page.
    public pymt__Payment_Profile__c setupRecurringPaymentProfile() {
        String recordTypeId;
            
        try {               
            if (this.paymentProfile == null) {
                this.paymentProfile = new pymt__Payment_Profile__c();
                this.paymentProfile.pymt__Contact__c = this.contact.Id;
                this.paymentProfile.pymt__Opportunity__c = this.opportunity.Id;
                this.paymentProfile.pymt__Account__c = this.account.Id;
            }
            String period;          
            Double frequency = 1;
            Double recurringAmount = this.opportunity.pymt__Recurring_Amount__c;
            Double occurrences = this.opportunity.pymt__Occurrences__c;
            if (this.processor.pymt__processor_id__c.equalsIgnoreCase('PayPal')){
                // Retrieve PayPal recurring payment record type to store in payment profile
                recordTypeId = [Select id from RecordType where developername like 'PayPal_Recurring_Payment'].id;
                if (this.recurringSetup == 'FirstRecurringIncluded') {
                    this.paymentProfile.pymt__Initial_Amount__c = this.opportunity.pymt__total_amount__c - recurringAmount;
                } else if (this.recurringSetup == 'RecurringTackedOn') {
                    this.paymentProfile.pymt__Initial_Amount__c = this.opportunity.pymt__total_amount__c;   
                }
                frequency = this.opportunity.pymt__Frequency__c;
                period = this.opportunity.pymt__Period__c;
                

            } else if (this.processor.pymt__processor_id__c.equalsIgnoreCase('authorize.net')){
                // Retrieve PayPal recurring payment record type to store in payment profile

                recordTypeId = [Select id from RecordType where developername like 'AuthNet_Subscription'].id;
                if (this.recurringSetup == 'FirstRecurringIncluded' || this.recurringSetup == 'RecurringTackedOn') {
                    this.paymentProfile.pymt__Trial_Amount__c = this.opportunity.pymt__total_amount__c;
                    this.paymentProfile.pymt__Trial_Occurrences__c = 1;
                } 
                if (this.recurringSetup == 'FirstRecurringIncluded') {
                    occurrences = occurrences == null?null:occurrences -1;   

                }               
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Day')) {period = 'Day'; frequency = this.opportunity.pymt__Frequency__c;}
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Week')) { period = 'Day'; frequency = this.opportunity.pymt__Frequency__c * 7;}
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Semi/Month')) { period = 'Day'; frequency = this.opportunity.pymt__Frequency__c * 15;} // approximate of every half month as authnet doesn't offer semi-monthly option
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Month')) {period = 'Month';frequency = this.opportunity.pymt__Frequency__c; }
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Year')) { period = 'Month'; frequency = this.opportunity.pymt__Frequency__c * 12;}
                            
            } else if (this.processor.pymt__processor_id__c.equalsIgnoreCase('worldpay')){
                // Retrieve worldpay recurring payment record type to store in payment profile

                recordTypeId = [Select id from RecordType where developername like 'WorldPay_Recurring_Payment'].id;
                if (this.recurringSetup == 'FirstRecurringIncluded') {
                    this.paymentProfile.pymt__Initial_Amount__c = this.opportunity.pymt__total_amount__c;
                    occurrences = occurrences == null?null:occurrences -1;  

                }  else if (this.recurringSetup == 'RecurringTackedOn') {
                    this.paymentProfile.pymt__Initial_Amount__c = this.opportunity.pymt__total_amount__c;
                }
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Day')) {period = 'Day'; frequency = this.opportunity.pymt__Frequency__c;}
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Week')) { period = 'Week'; frequency = this.opportunity.pymt__Frequency__c * 1;}
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Semi/Month')) { period = 'Day'; frequency = this.opportunity.pymt__Frequency__c * 15;} // approximate of every half month as authnet doesn't offer semi-monthly option
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Month')) {period = 'Month';frequency = this.opportunity.pymt__Frequency__c; }
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Year')) { period = 'Year'; frequency = this.opportunity.pymt__Frequency__c * 1;}

             } else {
                // recurring payments for this processor type not yet supported.
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Current default payment processor not supported for recurring payments ('+this.processorName+').'));
                return null;                
            }

            this.paymentProfile.name = this.opportunity.Name;
            this.paymentProfile.pymt__key__c = pymt.PaymentX.generateAccessKey();
            this.paymentProfile.recordTypeId = recordTypeId;
            this.paymentProfile.pymt__Processor_Connection__c = this.processor.Id;
            this.paymentProfile.pymt__Subscription_Start_Date__c = Date.today();
            this.paymentProfile.pymt__Subscription_Status__c = 'Not Activated';  // temporary status used until subscription has been activated
            this.paymentProfile.pymt__Period__c = period;
            this.paymentProfile.pymt__Frequency__c = frequency;
            this.paymentProfile.pymt__Amount__c = recurringAmount;  
            this.paymentProfile.pymt__Total_Occurrences__c = this.opportunity.pymt__Occurrences__c;                     
            
            upsert this.paymentProfile;
            return this.paymentProfile;
            
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error setting up payment profile: '+ex.getMessage()));

            return null;
        }
    }
    
    
    public Boolean setupPaymentRecord() {        
            
            // Setup Payment record
            if (this.payment == null) {
                this.payment = new pymt__PaymentX__c();
            }
            try {
                this.payment.name = pymt.Util.assignIfNotEmpty(this.opportunity.name,'Payment');
                this.payment.pymt__amount__c = this.opportunity.pymt__total_amount__c;
                this.payment.pymt__key__c = pymt.PaymentX.generateAccessKey();
                this.payment.pymt__tax__c = this.opportunity.pymt__tax__c;
                this.payment.pymt__shipping__c = this.opportunity.pymt__shipping__c;
                this.payment.pymt__contact__c = this.contact.id;
                this.payment.pymt__status__c = 'In Process';
                this.payment.pymt__date__c = System.today();
                this.payment.pymt__Currency_ISO_Code__c = this.processor.pymt__default_currency__c;
                this.payment.pymt__payment_processor__c = this.processor.pymt__processor_id__c;
                this.payment.pymt__processor_connection__c = this.processor.id;
                this.payment.pymt__opportunity__c = this.opportunity.id;  
                this.payment.pymt__account__c = this.account.id;   
                this.payment.pymt__Is_Test_Transaction__c = this.processor.pymt__Test_Mode__c;
                this.payment.pymt__log__c = ' ++++ Payment on Opportunity Sales Invoice:\n'+ 'Credit card charge for '+
                                          this.payment.pymt__Amount__c + this.payment.pymt__Currency_ISO_Code__c;
    
    
                if (this.payment.id == null) {
                    insert this.payment; 
                } else {
                    update this.payment;
                }
            
                // Insert/update related shopping cart items        
                pymt__Shopping_Cart_Item__c[] itemsToInsert = new pymt__Shopping_Cart_Item__c[]{};
                if (this.opp.lineItems <> null) {
                    for (OppLine lineItem :this.opp.lineItems) {                 
                        itemsToInsert.add(new pymt__Shopping_Cart_Item__c(name = pymt.Util.firstN(lineItem.name,80),
                                                                            pymt__quantity__c = lineItem.quantity,
                                                                            pymt__unit_price__c = lineItem.unitprice,
                                                                            pymt__contact__c = this.contact.id,
                                                                            pymt__product__c = lineItem.product.id,
                                                                            pymt__product_code__c = lineItem.productcode,
                                                                            pymt__payment__c = this.payment.id,
                                                                            pymt__On_Payment_Completed__c = lineItem.opcTag
                                                                        )
                                            );
                    
                    }
                    if (itemsToInsert.size()>0) insert itemsToInsert;
                }
            } catch (Exception ex) {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Error setting up purchase records:' + ex.getMessage()));                           
                return false;
                
                
            }
        
        return true;        
        
    }
    
    // Returns IP address of current user.
    public String getCurrentIPAddress(){
        string ipAddress;
        if (isNullOrEmpty(ipAddress)){
            ipAddress = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
            if (isNullOrEmpty(ipAddress)) ipAddress='255.255.255.0';
        }
        return ipAddress;
    }   
    
    // Set up payment or payment profile records and redirect to checkout page
    public PageReference processQuote() {
        PageReference nextPage;     

        // If billing contact info changed, upsert contact 
        if (this.enableBillingInfoEdit) {
            if (pymt.Util.isNullOrEmpty(this.updatedContact.email)) {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please provide the billing contact email address.'));                           
                return null;
            }
            Boolean isUpdate = false;
            // Determine whether we are updating an existing contact or creating a new one
            Contact tempContact;
            if (this.updatedContact.email == this.contact.email &&  !pymt.Util.isNullOrEmpty(this.contact.email)) {
                // email matches, update current contact
                isUpdate = true;
                tempContact = new Contact(id = this.contact.id);
                tempContact.accountId = this.contact.accountId;
            } else {
                // new email address, upsert this contact
                String soql = 'Select id, accountId, name, firstname, lastname, email, mailingstreet, mailingcity, mailingstate, mailingpostalcode, '+
                             'mailingcountry from Contact where email = \''+ String.escapeSingleQuotes(this.updatedContact.email) + '\' limit 1';
                Contact[] existing = this.acwos.dbQuery(soql);
                if (existing.size()>0) {
                    // contact with same email found, update this contact
                    isUpdate = true;
                    tempContact = new Contact(id = existing[0].id);
                    tempContact.accountId = existing[0].accountId;
                } else {
                    // no match in the database, insert new contact
                    isUpdate = false;
                    tempContact = new Contact();
                    tempContact.accountId = this.opportunity.accountId;
                }
            }

            tempContact.firstname = this.updatedContact.firstname;
            tempContact.lastname = this.updatedContact.lastname;
            tempContact.mailingstreet = this.updatedContact.mailingstreet;
            tempContact.mailingcity = this.updatedContact.mailingcity;
            tempContact.mailingstate = this.updatedContact.mailingstate;
            tempContact.mailingpostalcode = this.updatedContact.mailingpostalcode;
            tempContact.mailingcountry = this.updatedContact.mailingcountry;
            tempContact.email = this.updatedContact.email;
            tempContact.phone = this.updatedContact.phone;
            

            if (isUpdate) {
                this.acwos.dbUpdate(tempContact);                           
                
            } else {
                this.acwos.dbInsert(tempContact);
            }
            this.contact = tempContact.clone(true, true);
            this.updatedContact = tempContact.clone(false, true); // false/true = don't preserve id, and make this a complete copy (non reference)
                
            
            // Also update opportunity roles to include the new contact as a primary contact
            Integer roleCount = [Select Count() From OpportunityContactRole where ContactId = :tempContact.id and OpportunityId = :this.opportunity.id];
            if (roleCount == 0) {
                // Contact is not currently an opportunity contact
                this.acwos.dbInsert(new OpportunityContactRole( ContactId = tempContact.id,
                                                                OpportunityId = this.opportunity.id,
                                                                IsPrimary = true,       
                                                                Role = 'Economic Buyer' 
                                                                ));
            }
             
        }
        
        if (this.requireSignatory && this.termsAccepted) {
            Task newTask = new Task(Subject = 'SiteInvoice Terms & Conditions Accepted',
                                    Description='SiteInvoice Terms & Conditions accepted by '+ signature + ' customer for '+
                                    this.opportunity.Name+' (Invoice: '+this.opportunity.pymt__Invoice_Number__c+
                                                            ') from IP:'+ this.getCurrentIPAddress(), 
                                    whatId = this.opportunity.Id,
                                    whoId = this.contact.Id,
                                    status = 'Completed'
                                    
                                    );
            
            // Portal users can't own tasks.
            //insert newTask;

            Opportunity opp = new Opportunity( Id = this.opportunity.Id, Quote_Approved__c = Datetime.now());
            this.acwos.dbUpdate(opp);
        }
        if (this.hasRecurringAmount) {
            // This is a recurring payment opportunity
            this.paymentProfile = setupRecurringPaymentProfile();
            if (this.paymentProfile == null) return null;               
            nextPage = Page.pymt__PtlSubscribe;
            nextPage.getParameters().put('ppid',this.paymentProfile.Id);    // pass payment profile record  id to checkout page 
            nextPage.getParameters().put('key',this.paymentProfile.pymt__Key__c);
             
        } else {
            // This is a single charge opportunity
            if (!setupPaymentRecord()) return null;                 
            nextPage = Page.pymt__PtlCheckout;     
            nextPage.getParameters().put('pid',this.payment.Id);  // pass payment record id to checkout page
            nextPage.getParameters().put('key',this.payment.pymt__Key__c);  
        }
        if (isNullOrEmpty(this.cancelURL)) {
            this.cancelURL = ApexPages.currentPage().getURL();
        }

        if (this.debug) nextPage.getParameters().put('debug', '1');
        if (!isNullOrEmpty(this.cancelURL)) nextPage.getParameters().put('cancel_url', EncodingUtil.urlEncode(this.cancelURL,'UTF-8'));        
        if (!isNullOrEmpty(this.finishURL)) nextPage.getParameters().put('finish_url', EncodingUtil.urlEncode(this.finishURL,'UTF-8'));        
        
        return nextPage;    
        
    }   
}