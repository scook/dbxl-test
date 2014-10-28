public with sharing class SiteSupportAuthController {
// ---------------------------------------------------------------------------
// SiteSupportAuth controller for PaymentConnect
// Copyright: Linvio, Inc.
// URL: www.linvio.com
// Last Update: 05/06/2012 
// ---------------------------------------------------------------------------

    // Parameters
    public String caseId {get;set;}
    public String cancelURL {get;set;}
    public String finishURL {get;set;}
    public String contactId {get;set;} 
    public String accountId {get;set;} 
    
    public Boolean debug {get;set;} 
    
    public Case caseRecord {get;set;}
    public Contact contact {get;set;}
    public Account account {get;set;}
    public pymt__PaymentX__c payment {get;set;}
    public pymt__Payment_Profile__c paymentProfile {get;set;}
    public pymt__Processor_Connection__c processor {get;set;}
    public String processorName {get;set;}
    
    public Boolean disableForm {get;set;}
    public Boolean hasRecurringAmount {get;set;}
    
    
    public class LocalException extends Exception {}
    
    public SiteSupportAuthController() {
        this.debug = !isNullOrEmpty(ApexPages.currentPage().getParameters().get('debug'));
        
        try { 
            
            this.caseId = ApexPages.currentPage().getParameters().get('id');     // case id
            this.caseId = pymt.Util.isValidSalesforceId(this.caseId)?this.caseId:null;  // Make sure parm is a valid SF Id
            this.contactId = ApexPages.currentPage().getParameters().get('cid');     // contact id
            this.contactId = pymt.Util.isValidSalesforceId(this.contactId)?this.contactId:null;  // Make sure parm is a valid SF Id
            this.accountId = ApexPages.currentPage().getParameters().get('aid');     // account id
            this.accountId = pymt.Util.isValidSalesforceId(this.accountId)?this.accountId:null;  // Make sure parm is a valid SF Id

            this.cancelURL = specialDecodeURLParm(ApexPages.currentPage().getParameters().get('cancel_url'));
            //this.cancelURL = isNullOrEmpty(cancelURL)?ApexPages.currentPage().getURL()+'?id='+this.caseId:this.cancelURL;
            this.finishURL = specialDecodeURLParm(ApexPages.currentPage().getParameters().get('finish_url'));
    

            if (isNullOrEmpty(this.caseId)) { 
                // don't bother trying to retrieve opportunity, contact and account records 
            } else {
                Case[] cases = [Select id, CaseNumber, subject, description, QI_Statement_of_Work__c, QI_Authorization_Amount__c, QI_Quote_Expiration__c, AccountId, ContactId, QI_rate__c, QI_Authorization_hours__c from Case where id = :this.caseId];
                if (cases.size() >0 ) {
                    this.caseRecord = cases[0];
                    // If contactId is provided as a parameter, use it, otherwise try to use the id of the primary opportunity contact
                    if (isNullOrEmpty(this.contactId) && this.caseRecord.contactId <> null) {
                        this.contactId = this.caseRecord.ContactId;
                    } 
                    if (!isNullOrEmpty(this.contactId)) {
                        this.contact = [Select id, name, mailingstreet, mailingcity, mailingpostalcode, mailingstate, mailingcountry, email from Contact
                                    where id = :this.contactId];                
                    }
                    // If account is provided as a parameter, use it, otherwise try to use the account from the opportunity record
                    if (isNullOrEmpty(this.accountId)) {
                        this.accountId = this.caseRecord.AccountId;
                    } 
                    if (!isNullOrEmpty(this.accountId))  {
                        this.account = [Select id, name, billingstreet, billingcity, billingpostalcode, billingstate, billingcountry from Account where id = :this.accountId];
                    }
                    
                }
                
            }
            if (this.caseRecord == null) {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Support ticket could not be found.'));
                this.disableForm = true;
                return;
            }
            this.hasRecurringAmount = false;

            if (this.caseRecord.QI_quote_expiration__c == null || this.caseRecord.QI_quote_expiration__c < Date.today()) {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This quote has expired.'));
                this.disableForm = true;
                return;
            }
            
            
            if (this.contact == null) {
                throw new LocalException('Cannot process this support authorization without a contact record. '); 
            }
            
            // Retrieve default processor connection record
            // Otherwise search for the first available supported processor connection
            pymt__Processor_Connection__c[] connections = [Select id, pymt__default_connection__c, pymt__processor_id__c, pymt__test_mode__c, pymt__Default_Currency__c,  pymt__PP_Merchant_Id__c from pymt__Processor_Connection__c where isDeleted = false and (pymt__processor_id__c like 'paypal' or pymt__processor_id__c like 'authorize.net') ];
            if (connections.size()>0) {
                Boolean found = false;
                for (pymt__Processor_Connection__c conn :connections) {
                    if (conn.pymt__default_connection__c) {
                        this.processor = conn;
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    this.processor = connections[0];
                }
            }               

            this.processorName = this.processor.pymt__processor_id__c.toLowerCase(); // paypal, authorize.net, google
            
            if (this.processor == null) {
                throw new LocalException('Processor connection record not found.  Make sure you have marked a processor connection record as the "Default" connection or pass in the processor connection record Id in the parameter list to enable this page.');               
            }
            if (this.processorName <> 'paypal' && this.processorName <> 'authorize.net') {
                throw new LocalException('Processor connections through '+ this.processorName + ' are not currently supported by this page.');              
            }
            
        
        } Catch (Exception ex) {
            System.debug('An error encountered loading the SiteSupportAuth page: '+ex);
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error was encountered loading the page. '+(this.debug?ex.getMessage():'')));
            this.disableForm = true;                            
        }
        
    
    }

    // Applications my have to twice encode fully qualified URLs to get around a bug in visualforce url parsing
    // Check to see if these urls have been twice encoded  ("%3A%2F%2F" = "://")
    public String specialDecodeURLParm(String parm) {
        String result = isNullOrEmpty(parm)?'':EncodingUtil.UrlDecode(parm,'UTF-8');                                      
        if (result.contains('%3A%2F%2F')) result = Encodingutil.urlDecode(result, 'UTF-8');
        return result;
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
    
    
    
    public Boolean setupPaymentRecord() {        
            
            // Setup Payment record
            if (this.payment == null) {
                this.payment = new pymt__PaymentX__c();
            }
            try {
                this.payment.name = 'Case '+this.caseRecord.Id;
                this.payment.pymt__Account__c = this.caseRecord.AccountId;
                this.payment.pymt__amount__c = this.caseRecord.QI_Authorization_Amount__c;
                this.payment.pymt__contact__c = this.contact.id;
                this.payment.pymt__status__c = 'In Process';
                this.payment.pymt__transaction_type__c = 'Authorization';
                this.payment.pymt__date__c = System.today();
                this.payment.pymt__Currency_ISO_Code__c = this.processor.pymt__default_currency__c;
                this.payment.pymt__payment_processor__c = this.processor.pymt__processor_id__c;
                this.payment.pymt__processor_connection__c = this.processor.id;
                this.payment.case__c = this.caseRecord.id;    
                this.payment.pymt__account__c = this.account.id;   
                this.payment.pymt__Is_Test_Transaction__c = this.processor.pymt__Test_Mode__c;
                this.payment.pymt__log__c = ' ++++ Authorization through SiteTicketAuthorization page:\n'+ 'Card authorization for '+
                                          this.payment.pymt__Amount__c + this.payment.pymt__Currency_ISO_Code__c;
    
    
                if (this.payment.id == null) {
                    insert this.payment; 
                } else {
                    update this.payment;
                }
            
            } catch (Exception ex) {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Error setting up purchase records:' + ex.getMessage()));                           
                return false;
                
                
            }
        
        return true;        
        
    }
    
    // Set up payment or payment profile records and redirect to checkout page
    public PageReference processAuthorization() {
        PageReference nextPage;     
        

        // This is a single charge opportunity
        if (!setupPaymentRecord()) return null;                 
        nextPage = Page.pymt__SiteCheckout;     
        nextPage.getParameters().put('pid',this.payment.Id);  // pass payment record id to checkout page

        if (this.debug) nextPage.getParameters().put('debug', '1');
        if (!isNullOrEmpty(this.cancelURL)) nextPage.getParameters().put('cancel_url', EncodingUtil.urlEncode(this.cancelURL,'UTF-8'));        
        if (!isNullOrEmpty(this.finishURL)) nextPage.getParameters().put('finish_url', EncodingUtil.urlEncode(this.finishURL,'UTF-8'));        
        
        return nextPage;     
        
    }   
}