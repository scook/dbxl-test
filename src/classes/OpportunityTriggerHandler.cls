public with sharing class OpportunityTriggerHandler extends TriggerBase {  
    //Members
    Case[] casesToInsert = new List<Case>();
    Opportunity[] opportunitiesToInsert = new List<Opportunity>();

    Set<Id> oldOpportunityIds = new Set<Id>();
    Set<Id> newOppAccountIds = new Set<Id>();
    
    //Constructor
    public OpportunityTriggerHandler() {}
    
    //Methods
    override public void beforeUpdate(SObject oldSo, SObject so) {
        Opportunity oldO = (Opportunity) oldSo;
        Opportunity o = (Opportunity) So;
        if (o.StageName != oldO.StageName) {
            Case c = generateCase(o);
            if (c != null) casesToInsert.add(c);
        }
    }

    override public void afterUpdate(SObject oldSo, SObject so) {
        Opportunity oldO = (Opportunity) oldSo;
        Opportunity o = (Opportunity) So;
        if (o.StageName != oldO.StageName &&
            o.StageName == 'Closed Won') {

            generateRenewalOpportunity(o);
        }
    }

    override public void afterInsert(Sobject so) {
        Opportunity o = (Opportunity) so;

        newOppAccountIds.add(o.AccountId);
    }

    override public void andFinally() {
        if (!casesToInsert.isEmpty()) {
            Database.insert(casesToInsert);
        }

        if(!opportunitiesToInsert.isEmpty()) {
            insertRenewalOpportunities();
        }

        if(!newOppAccountIds.isEmpty()) {
            UpdateProspectAccounts(newOppAccountIds);
        }
    }
    
    //Properites    
    private Case_Template__c[] p_templates = null;
    public Case_Template__c[] templates {
        get {
            if (p_templates == null) {
                p_templates = Case_Template__c.getall().values();
            }
            return p_templates;
        }
    }
    
    private Set<Id> p_opportunityIds = null;
    public Set<Id> opportunityIds {
        get {
            if (p_opportunityIds == null) {
                p_opportunityIds = new Set<Id>();
                if (Trigger.newMap != null) {
                    p_opportunityIds = Trigger.newMap.keySet();
                }
            }
            return p_opportunityIds;
        }
    }
    
    private Set<Id> p_accountIds = null;
    public Set<Id> accountIds {
        get {
            if (p_accountIds == null) {
                p_accountIds = new Set<Id>();
                if (Trigger.newMap != null) {
                    for (Opportunity o : (Opportunity[]) Trigger.new) {
                        if (o.AccountId != null) {
                          p_accountIds.add(o.AccountId);
                        }
                    }
                }
            }
            return p_accountIds;
        }
    }
    
    private Account[] p_accounts = null;
    public Account[] accounts {
        get {
            if (p_accounts == null) {
                p_accounts = [
                 SELECT Id, Name
                 FROM Account
                 WHERE Id IN :accountIds
                ];
            }
            return p_accounts;
        }
    }
    
    private Map<Id, Account> p_accountMap = null;
    public Map<Id, Account> accountMap {
        get {
            if (p_accountMap == null) {
                p_accountMap = new Map<Id, Account>(accounts);
            }
            return p_accountMap;
        }
    }
    
    private List<Case> p_cases = null;
    public List<Case> cases {
        get {
            if (p_cases == null) {
                p_cases = [SELECT Id, Opportunity__c FROM Case WHERE Opportunity__c IN :opportunityIds];
            }
            return p_cases;
        }
    }
    
    private Map<Id, List<Case>> p_caseMap = null;
    public Map<Id, List<Case>> caseMap {
        get {
            if (p_caseMap == null) {
                p_caseMap = new Map<Id, List<Case>>();
                for (Case c : cases) {
                    Id i = c.Opportunity__c;
                    if (p_caseMap.get(i) == null) {
                        p_caseMap.put(i, new List<Case>());
                    }
                    p_caseMap.get(i).add(c);
                }
            }
            return p_caseMap;
        }
    }
   
   private OpportunityLineItem[] p_products = null;
   public OpportunityLineItem[]  products {
        get {
            if (p_products == null) {
                p_products = [
                  SELECT Id, PricebookEntry.Product2.Name, PricebookEntry.Product2.Family,
                         OpportunityId, Product_Family__c, Description
                  FROM OpportunityLineItem 
                  WHERE OpportunityId IN :opportunityIds
                ];
            }
            return p_products;
        }
   }
   
    private Map<Id, List<OpportunityLineItem>> p_productsMap = null;
    public Map<Id, List<OpportunityLineItem>> productsMap {
        get {
            if (p_productsMap == null) {
                p_productsMap = new Map<Id, List<OpportunityLineItem>>();
                for (OpportunityLineItem p : products) {
                    Id i = p.OpportunityId;
                    if (p_productsMap.get(i) == null) {
                        p_productsMap.put(i, new List<OpportunityLineItem>());
                    }
                    p_productsMap.get(i).add(p);
                }
            }
            return p_productsMap;
        }
    }

    private Map<Id, Set<String>> p_productFamiliesMap = null;
    public Map<Id, Set<String>> productFamiliesMap {
        get {
            if (p_productFamiliesMap == null) {
                p_productFamiliesMap = new Map<Id, Set<String>>();
                for (Id i : new List<Id>(opportunityIds)) {
                    if (p_productFamiliesMap.get(i) == null) {
                        p_productFamiliesMap.put(i, new Set<String>());
                    }
                }
                for (OpportunityLineItem p : products) {
                    Id i = p.OpportunityId;
                    
                    if (i != null && !String.isBlank(p.Product_Family__c)) {
                        String normalized = p.Product_Family__c.toLowerCase().trim();
                        p_productFamiliesMap.get(i).add(normalized);
                    }
                }
            }
            return p_productFamiliesMap;
        }
    } 
    
    private OpportunityContactRole[] p_contactRoles = null;
    public OpportunityContactRole[] contactRoles {
        get {
            if (p_contactRoles == null) {
                p_contactRoles = [
                 SELECT ContactId, OpportunityId, Role
                 FROM OpportunityContactRole
                 WHERE OpportunityId IN :opportunityIds
                ];
                if (p_contactRoles == null) {
                    p_contactRoles = new List<OpportunityContactRole>();
                }
            }
            return p_contactRoles;
        }
    }
    
    private Map<Id, Map<String, OpportunityContactRole>> p_contactRoleMap = null;
    public Map<Id, Map<String, OpportunityContactRole>> contactRoleMap {
        get {
            if (p_contactRoleMap == null) {
                p_contactRoleMap = new Map<Id, Map<String, OpportunityContactRole>>();
                for (Id i : opportunityIds) {
                    p_contactRoleMap.put(i, new Map<String, OpportunityContactRole>());
                }
                for (OpportunityContactRole c : contactRoles) {
                    String normalized =  '';
                    if(c.Role <> null) {
                        c.Role.toLowerCase().trim();
                    }
                    if (p_contactRoleMap.get(c.OpportunityId).get(normalized) == null) {
                        p_contactRoleMap.get(c.OpportunityId).put(normalized, c);
                    }
                }
            }
            return p_contactRoleMap;
        }
    }  
    
    private AssignmentRule p_assignmentRule = null;
    public AssignmentRule assignmentRule {
        get {
            if (p_assignmentRule == null) {
                AssignmentRule[] a = [
                    SELECT Id
                    FROM AssignmentRule
                    WHERE SObjectType = 'Case' AND Active = true
                    LIMIT 1
                ];
                if (a != null && !a.isEmpty()) {
                    p_assignmentRule = a[0];
                }
            }
            return p_assignmentRule;
        }
    }
    
    //Helper methods    
    public boolean hasCase(Opportunity o) {
        return caseMap.get(o.Id) != null;
    }
    
    public boolean hasProductFamily(Opportunity o, String family) {
        if (String.isBlank(family)) return true;
        
        String normalized = family.toLowerCase().trim();
        return (productFamiliesMap.get(o.Id).contains(normalized));
    }
    
    public Id getContactId(Opportunity o, Case_Template__c t) {
        if (String.isBlank(t.Contact_Role_Role_Filter__c)) return null;

        String contactRole = t.Contact_Role_Role_Filter__c;
        Id contactId = null;

        String normalized = contactRole.toLowerCase().trim();
        Map<String, OpportunityContactRole> m = contactRoleMap.get(o.Id);
        if (m != null) {
            OpportunityContactRole c = m.get(normalized);
            if (c != null) {
               contactId = c.contactId;
            }
        }
        
        return contactId;
    }
    
    public String getSubject(Opportunity o, Case_Template__c t) {
        String productType = t.Type__c;
        String accountName = null;
        
        if (accountMap.get(o.AccountId) != null) {
            accountName = accountMap.get(o.AccountId).Name;
        }
        
        if (productType == null) {
            productType = 'Unset';
        }
        
        if (accountName == null) {
            accountName = 'No Account';
        }
        
        return productType + ':' + accountName;
    }
    
    public String getDescription(Opportunity o) {
        String[] descriptions = new List<String>();
        String description = null;
        
        if (productsMap.get(o.Id) != null) {
            for (OpportunityLineItem i : productsMap.get(o.Id)) {
                if (!String.isBlank(i.Description)) {
                    descriptions.add(i.Description);
                }
            }
        }
        
        if (descriptions != null) {
            description = String.join(descriptions, '\n');
        }
        
        if (String.isBlank(description)) {
            description = 'No Description';
        }
        
        return description;
    }
     
     
    public String getLicenses(Opportunity o) {
        String[] licenses = new List<String>();
        String license = null;
        
        if (productsMap.get(o.Id) != null) {
            for (OpportunityLineItem i : productsMap.get(o.Id)) {
                if (!String.isBlank(i.PricebookEntry.Product2.Name)) {
                    licenses.add(i.PricebookEntry.Product2.Name);
                }
            }
        }
        
        if (licenses != null) {
            license = String.join(licenses, '\n');
        }
        
        if (String.isBlank(license)) {
            license = 'No Description';
        }
        
        return license;
    }
    
     
    public Case_Template__c findCaseTemplate(Opportunity o) {
        Case_Template__c template = null;
        
        for (Case_Template__c c : templates) {
            if ((String.isBlank(c.Opportunity_Stage__c) || o.StageName == c.Opportunity_Stage__c) &&
                hasProductFamily(o, c.Product_Family__c)) {
              template = c;
              break;
            }
        }
        
        return template;
    }
    
    public Case generateCase(Opportunity o) {
        if (o == null) return null;
        
        Case c = null;

        Case_Template__c t = findCaseTemplate(o);
        if (t != null) {
            c = new Case();
            c.Origin = t.Case_Origin__c;
            c.ContactId = getContactId(o, t);
            c.Priority = t.Priority__c;
            c.Product_Type__c = t.Product_Type__c;
            c.Status = t.Status__c;
            c.AccountId = o.AccountId;
            c.Subject = getSubject(o, t);
            c.Description = getDescription(o);
            c.Products_Licenses__c = getLicenses(o);
            c.Type = t.Type__c;
            c.Opportunity__c = o.Id;
            c.Is_Generated__c = true;

            if (assignmentRule != null) {
                Database.DMLOptions options = new Database.DMLOptions();
                options.AssignmentRuleHeader.assignmentRuleId = assignmentRule.Id;
                c.setOptions(options);
            }
        }
        
        return c;
    }

    public void generateRenewalOpportunity(Opportunity opp) {

        Opportunity newO = new Opportunity();
        newO.AccountId = opp.AccountId;
        newO.Type = 'Existing';
        newO.StageName = 'Purchase / Timeline';
        newO.Probability = 50;
        newO.Prior_Year_Opportunity__c = opp.Id;
        newO.Lead_Source_Detail__c = opp.Lead_Source_Detail__c;
        newO.Level_of_Purchase__c = opp.Level_of_Purchase__c;
        newO.PriceBook2Id = opp.PriceBook2Id;
        newO.Number_of_Licenses__c = opp.Number_of_Licenses__c;
        newO.License_Level__c = opp.License_Level__c;
        
        String newYear = String.valueOf(opp.CloseDate.year() +1);

        String newName = opp.Name;

        if(newName.toLowerCase().contains('renewal')) {
            newName = opp.Name.substring(0,opp.Name.toLowerCase().indexOf('renewal'));
        }
            
        newO.Name = newName + ' RENEWAL ' + newYear;
            
        opportunitiesToInsert.add(newO);
        oldOpportunityIds.add(opp.Id);

        system.debug('OLD OPPORTUNITY ACCOUNT ID => ' + opp.AccountId);
    }

    public void insertRenewalOpportunities(){

        system.debug('Old Oppty Id => ' + oldOpportunityIds);

        Date todaysDate = Date.today();

        Contract[] contracts = [SELECT Id
                                      ,AccountId
                                      ,EndDate
                                      ,Opportunity__c
                                      ,Status
                                  FROM Contract
                                 WHERE Opportunity__c IN :oldOpportunityIds
                                   AND Status = 'Purchased'
                                   AND EndDate > :todaysDate
                                 ORDER By AccountId, EndDate
                                ];
        Map<Id,Contract> contractsMap = new Map<Id,Contract>();

        Set<Id> accountIds = new Set<Id>();

        for(Opportunity opp : opportunitiesToInsert) {
            accountIds.add(opp.AccountId);
        }

        Account[] accounts = [SELECT Id,OwnerId FROM Account WHERE Id IN :accountIds];

        Map<Id,Id> accountIdToOwnerMap = new Map<Id,Id>();

        for(Account acct : accounts) {
            accountIdToOwnerMap.put(acct.Id,acct.OwnerId);
        }

        system.debug('CONTRACTS => ' + contracts);

        for(Contract c : contracts) {
            contractsMap.put(c.AccountId,c);
            system.debug('CONTRACT END DATE => ' + c.EndDate);
        }

        system.debug('Opptys To Insert => ' + opportunitiesToInsert);
        for(Opportunity opp : opportunitiesToInsert) {
            system.debug('CONTRACTS MAP => ' + contractsMap);
            system.debug('OPPORTUNITY ACCOUNT ID => ' + opp.AccountId);
            system.debug('CONTAINS KEY => ' + contractsMap.containsKey(opp.AccountId));
            if(contractsMap.containsKey(opp.AccountId)) {
                opp.CloseDate = contractsMap.get(opp.AccountId).EndDate;
                opp.OwnerId = accountIdToOwnerMap.get(opp.AccountId);
                system.debug('CLOSE DATE => ' + opp.CloseDate);
            }
        }

        Database.Insert(opportunitiesToInsert);
        generateRenewalOpportunityDependencies();
        
    }

    private void generateRenewalOpportunityDependencies() {

        Map<Id,Opportunity> oldOppIdToNewOppMap = new Map<Id,Opportunity>();
        OpportunityLineItem[] newOpportunityLineItems = new List<OpportunityLineItem>();
        OpportunityContactRole[] newOppContactRoles = new List<OpportunityContactRole>();
        
        for(Opportunity opp : opportunitiesToInsert) {
            oldOppIdToNewOppMap.put(opp.Prior_Year_Opportunity__c,opp);
        }

        OpportunityLineItem[] lineItems = [SELECT Id
                                                 ,Discount
                                                 ,Description
                                                 ,ListPrice
                                                 ,Existing_License_Id__c
                                                 ,OpportunityId
                                                 ,PricebookEntryId
                                                 ,Quantity
                                                 ,UnitPrice
                                                 ,SubTotal
                                                 ,ProductCode2__c
                                             FROM OpportunityLineItem 
                                            WHERE OpportunityId IN :oldOpportunityIds
                                              AND Product_Family__c = 'License'];


        Set<Id> existingLicenseId = new Set<Id>();
        for(OpportunityLineItem li : lineItems) {
            if(!String.isBlank(li.Existing_License_Id__c)) {
                existingLicenseId.add(li.Existing_License_Id__c);
            }
        }

        PricebookEntry[] priceBookEntries = [SELECT Id
                                                   ,Product2Id
                                               FROM PriceBookEntry
                                              WHERE Product2Id IN :existingLicenseId];

        Map<Id,Id> existingLicensePriceBookEntry = new Map<Id,Id>();

        for(PricebookEntry pbi : priceBookEntries) {
            existingLicensePriceBookEntry.put(pbi.Product2Id,pbi.Id);
        }

        for(OpportunityLineItem li : lineItems) {
            OpportunityLineItem newLI = li.Clone();
            newLI.OpportunityId = oldOppIdToNewOppMap.get(li.OpportunityId).Id;
            if(!String.isBlank(li.Existing_License_Id__c)) {
                newLI.PriceBookEntryId = existingLicensePriceBookEntry.get(li.Existing_License_Id__c);
            }
            newOpportunityLineItems.add(newLI);
        }

        OpportunityContactRole[] contactRoles = [SELECT ContactId
                                                       ,OpportunityId
                                                       ,Role
                                                   FROM OpportunityContactRole
                                                  WHERE OpportunityId IN :oldOpportunityIds];

        for(OpportunityContactRole ocr : contactRoles) {
            OpportunityContactRole nocr = new OpportunityContactRole();
            nocr = ocr.Clone();
            nocr.OpportunityId = oldOppIdToNewOppMap.get(ocr.OpportunityId).Id;

            newOppContactRoles.add(nocr);
        }

        insert newOpportunityLineItems;
        insert newOppContactRoles;
    }

    private void UpdateProspectAccounts(Set<Id> accountIds) {

        Account[] accountsToUpdate = [SELECT Id
                                            ,Client_Status__c
                                        FROM Account
                                       WHERE Id IN :accountIds
                                       ];

        for(Account acct : accounts) {
            acct.Client_Status__c = 'Prospect';
        }

        update accounts;
    }

}