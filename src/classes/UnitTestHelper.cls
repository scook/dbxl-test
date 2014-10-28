/**
 * Helper class for creating unit test data
 */
@isTest(SeeAllData=true)
public class UnitTestHelper 
{
    public static Integer incrementCounter = -1;
    public static final String defaultPrefix = 'd';

    public static Integer getIncrement() {
        incrementCounter += 1;
        return incrementCounter;
    }

    public static String generateUniqueName(String name) {
        return name + String.valueOf(getIncrement());
    }
        
    
    public static Database.SaveResult[] forcedInsert(SObject[] o) {
        Database.SaveResult[] result;
        while (result == null) { 
            try { 
                result = Database.insert(o);
            } catch (DmlException e) {
                if (!e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                    throw e;
                }
            }
        }
        return result;
    }

    public static Database.SaveResult forcedInsert(SObject o) {
        Database.SaveResult result;
        while (result == null) { 
            try { 
                result = Database.insert(o);
            } catch (DmlException e) {
                if (!e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                    throw e;
                }
            }
        }
        return result;
    }

    public static Database.SaveResult forcedUpdate(SObject o) {
        Database.SaveResult result;
        while (result == null) { 
            try { 
                result = Database.update(o);
            } catch (DmlException e) {
                if (!e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                    throw e;
                }
            }
        }
        return result;
    }

    public static Database.SaveResult[] forcedUpdate(SObject[] o) {
        Database.SaveResult[] result;
        while (result == null) { 
            try { 
                result = Database.update(o);
            } catch (DmlException e) {
                if (!e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                    throw e;
                }
            }
        }
        return result;
    }

    public static Database.DeleteResult forcedDelete(SObject o) {
        Database.DeleteResult result;
        while (result == null) { 
            try { 
                result = Database.delete(o);
            } catch (DmlException e) {
                if (!e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                    throw e;
                }
            }
        }
        return result;
    }

    public static Database.DeleteResult[] forcedDelete(SObject[] o) {
        Database.DeleteResult[] result;
        while (result == null) { 
            try { 
                result = Database.delete(o);
            } catch (DmlException e) {
                if (!e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                    throw e;
                }
            }
        }
        return result;
    }

    public static void assertCpuTimeUsagePercent(Decimal ceilingPercent) {
        Decimal ratio = Limits.getCpuTime() / Limits.getLimitCpuTime();
        Decimal actualPercent = ratio * 100;
        System.assert(actualPercent < ceilingPercent, 'CPU Time: ' + Limits.getCpuTime() + ', Limit: ' + Limits.getLimitCpuTime());
    }

    public static void assertDMLStatementsUsagePercent(Decimal ceilingPercent) {
        Decimal ratio = Limits.getDMLStatements() / Limits.getLimitDMLStatements();
        Decimal actualPercent = ratio * 100;
        System.assert(actualPercent < ceilingPercent, 'DML Statements: ' + Limits.getDMLStatements() + ', Limit: ' + Limits.getLimitDMLStatements());
    }

    public static void assertHeapSizeUsagePercent(Decimal ceilingPercent) {
        Decimal ratio = Limits.getHeapSize() / Limits.getLimitHeapSize();
        Decimal actualPercent = ratio * 100;
        System.assert(actualPercent < ceilingPercent, 'Heap Size: ' + Limits.getHeapSize() + ', Limit: ' + Limits.getLimitHeapSize());
    }

    public static void assertQueryUsagePercent(Decimal ceilingPercent) {
        Decimal ratio = Limits.getQueries() / Limits.getLimitQueries();
        Decimal actualPercent = ratio * 100;
        System.assert(actualPercent < ceilingPercent, 'Queries: ' + Limits.getQueries() + ', Limit: ' + Limits.getLimitQueries());
    }
    
    public static void assertQueryRowUsagePercent(Decimal ceilingPercent) {
        Decimal ratio = Limits.getQueryRows() / Limits.getLimitQueryRows();
        Decimal actualPercent = ratio * 100;
        System.assert(actualPercent < ceilingPercent, 'Queries: ' + Limits.getQueryRows() + ', Limit: ' + Limits.getLimitQueryRows());
    }
    
    
///////////////////////////////////////////////
    

    /**
    * @description Creates a list of accounts used for testing.  The default names of the fields are their fieldname + the count number;
    * @param       name The custom prefixed name of the test object list you want.
    * @param       count The number of test objects you want created.  
    * @param       generateDependencies Whether you want any dependencies automatically generated and inserted.
    * @return      Returns the generated list of test objects.  You must insert it yourself.
    */
    public static Account[] createAccounts(String name, Integer count, Boolean generateDependencies) {
        if (name == null || count == null || count < 0 || generateDependencies == null) return new List<Account>();

        Account[] accounts = new List<Account>();

        if (generateDependencies) {
        }

        for (Integer i = 0; i < count; i++) {
            String suffix = String.valueOf(i + 1);
            Account account = new Account(
                Name = generateUniqueName(name + 'Account'),
                Type = 'type' + suffix,
                Industry = 'industry' + suffix,
                phone = 'phone' + suffix,
                website = 'website' + string.valueOf(i + 1),
                BillingStreet = 'billingStreet' + suffix,
                BillingCity = 'billingCity' + suffix,
                BillingState = 'billingState' + suffix,
                BillingPostalCode = 'billingPostalCode' + suffix,
                BillingCountry = 'billingCountry' + suffix,
                Reason_for_no_NCES_ID__c = 'reason',
                ShippingStreet = 'shippingStreet' + suffix,
                ShippingCity = 'shippingCity' + suffix,
                ShippingState = 'NY',
                ShippingPostalCode = 'shippingPostalCode' + suffix,
                ShippingCountry = 'shippingCountry' + suffix
            );

            if (generateDependencies) {
            }

            accounts.add(account);
        }

        return accounts;
    }  


    /**
    * @description Creates a list of contacts used for testing.  The default names of the fields are their fieldname + the count number;
    * @param       name The custom prefixed name of the test object list you want.
    * @param       count The number of test objects you want created.  
    * @param       generateDependencies Whether you want any dependencies automatically generated and inserted.
    * @return      Returns the generated list of test objects.  You must insert it yourself.
    */
    public static Contact[] createContacts(String name, Integer count, Boolean generateDependencies) {
        if (name == null || count == null || count < 0 || generateDependencies == null) return new List<Contact>();

        Contact[] contacts = new List<Contact>();

        if (generateDependencies) {
            //Currently unused
        }

        for (Integer i = 0; i < count; i++) {
            String suffix = String.valueOf(i + 1);
            Contact contact = new Contact(
                FirstName = 'firstName' + suffix,
                LastName = 'lastName' + suffix
            );

            if (generateDependencies) {
                //Currently unused
            }

            contacts.add(contact);
        }

        return contacts;
    }


    /**
    * @description Creates a list of opportunities used for testing.  The default names of the fields are their fieldname + the count number;
    * @param       name The custom prefixed name of the test object list you want.
    * @param       count The number of test objects you want created.  
    * @param       generateDependencies Whether you want any dependencies automatically generated and inserted.
    * @return      Returns the generated list of test objects.  You must insert it yourself.
    */
    public static Opportunity[] createOpportunities(String name, Integer count, Boolean generateDependencies) {
        if (name == null || count == null || count < 0 || generateDependencies == null) return new List<Opportunity>();

        Opportunity[] opportunities = new List<Opportunity>();
        Account account = null;

        if (generateDependencies) {
            account = createAccounts(name, 1, true)[0]; //Inserting accounts is volatile
            while (true) { 
                try { 
                    UnitTestHelper.forcedInsert(new List<sObject>{account});
                } catch (DmlException e) {
                    if (e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                        continue;
                    }
                    else {
                        throw e;
                    }
                }
                break;
            }
        }

        for (Integer i = 0; i < count; i++) {
            String suffix = String.valueOf(i + 1);
            Opportunity opportunity = new Opportunity(
                Name = generateUniqueName(name + 'Opportunity'),
                CloseDate = system.today() + count,
                StageName = 'stageName' + suffix,
                Lead_Source_Detail__c = 'leadSourceDetail' + suffix
            );

            if (generateDependencies) {
                opportunity.accountId = account.id;
            }

            opportunities.add(opportunity);
        }

        return opportunities;
    }


    /**
    * @description Creates a list of opportunities used for testing.  The default names of the fields are their fieldname + the count number;
    * @param       name The custom prefixed name of the test object list you want.
    * @param       count The number of test objects you want created.  
    * @param       generateDependencies Whether you want any dependencies automatically generated and inserted.
    * @return      Returns the generated list of test objects.  You must insert it yourself.
    */
    public static Product2[] createProduct2s(String name, Integer count, Boolean generateDependencies) {
        if (name == null || count == null || count < 0 || generateDependencies == null) return new List<Product2>();

        Product2[] products = new List<Product2>();

        if (generateDependencies) {
            //Currently unused
        }

        for (Integer i = 0; i < count; i++) {
            String suffix = String.valueOf(i + 1);
            Product2 p = new Product2(
                IsActive = true,
                Name = generateUniqueName('Product2'),
                Family = 'family'
            );

            if (generateDependencies) {
                //Currently unused
            }

            products.add(p);
        }

        return products;
    }

    /**
    * @description Creates a list of opportunities used for testing.  The default names of the fields are their fieldname + the count number;
    * @param       name The custom prefixed name of the test object list you want.
    * @param       count The number of test objects you want created.  
    * @param       generateDependencies Whether you want any dependencies automatically generated and inserted.
    * @return      Returns the generated list of test objects.  You must insert it yourself.
    */
    public static Pricebook2[] createPricebook2s(String name, Integer count, Boolean generateDependencies) {
        if (name == null || count == null || count < 0 || generateDependencies == null) return new List<Pricebook2>();

        Pricebook2[] pricebooks = new List<Pricebook2>();

        if (generateDependencies) {
            //Currently unused
        }

        for (Integer i = 0; i < count; i++) {
            String suffix = String.valueOf(i + 1);
            Pricebook2 pricebook = new Pricebook2(
                Name = generateUniqueName('pricebook2'),
                IsActive = true,
                Description = 'description' + suffix
            );

            if (generateDependencies) {
                //Currently unused
            }

            pricebooks.add(pricebook);
        }

        return pricebooks;
    }


    /**
    * @description Creates a list of opportunities used for testing.  The default names of the fields are their fieldname + the count number;
    * @param       name The custom prefixed name of the test object list you want.
    * @param       count The number of test objects you want created.  
    * @param       generateDependencies Whether you want any dependencies automatically generated and inserted.
    * @return      Returns the generated list of test objects.  You must insert it yourself.
    */
    public static PricebookEntry[] createPricebookEntries(String name, Integer count, Boolean generateDependencies) {
        if (name == null || count == null || count < 0 || generateDependencies == null) return new List<PricebookEntry>();

        PricebookEntry[] pricebookEntries = new List<PricebookEntry>();
        Product2[] products = new List<Product2>();
        Pricebook2[] pricebooks = new List<Pricebook2>();
        Pricebook2 standardPricebook = [select id from Pricebook2 where IsStandard = true limit 1];

        if (generateDependencies) {
            products = UnitTestHelper.createProduct2s(name, count, generateDependencies);
            UnitTestHelper.forcedInsert(products);
            pricebooks = UnitTestHelper.createPricebook2s(name, count, generateDependencies);
            UnitTestHelper.forcedInsert(pricebooks);
        }

        for (Integer i = 0; i < count; i++) {
            String suffix = String.valueOf(i + 1);
            PricebookEntry pricebookEntry = new PricebookEntry(
                IsActive = true,
                UnitPrice = 3,
                UseStandardPrice = false
            );

            if (generateDependencies) {
                pricebookEntry.Product2Id = products[i].Id;
                pricebookEntry.Pricebook2Id = standardPricebook.Id;
            }

            pricebookEntries.add(pricebookEntry);
        }

        return pricebookEntries;
    }


    /**
    * @description Creates a list of opportunities used for testing.  The default names of the fields are their fieldname + the count number;
    * @param       name The custom prefixed name of the test object list you want.
    * @param       count The number of test objects you want created.  
    * @param       generateDependencies Whether you want any dependencies automatically generated and inserted.
    * @return      Returns the generated list of test objects.  You must insert it yourself.
    */
    public static OpportunityLineItem[] createOpportunityLineItems(String name, Integer count, Boolean generateDependencies) {
        if (name == null || count == null || count < 0 || generateDependencies == null) return new List<OpportunityLineItem>();

        OpportunityLineItem[] opportunityLineItems = new List<OpportunityLineItem>();
        PricebookEntry[] PricebookEntries = new List<PricebookEntry>();
        Opportunity opportunity = null;

        if (generateDependencies) {
            opportunity = UnitTestHelper.createOpportunities(name, 1, true)[0];
            UnitTestHelper.forcedInsert(opportunity);
            pricebookEntries = UnitTestHelper.createPricebookEntries(name, count, true);
            UnitTestHelper.forcedInsert(pricebookEntries);
        }

        for (Integer i = 0; i < count; i++) {
            String suffix = String.valueOf(i + 1);
            OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
                Description = 'description' + suffix,
                Quantity = 2,
                UnitPrice = 3
            );

            if (generateDependencies) {
                opportunityLineItem.opportunityId = opportunity.id;
                opportunityLineItem.pricebookEntryId = pricebookEntries[i].id;
            }

            opportunityLineItems.add(opportunityLineItem);
        }

        return opportunityLineItems;
    }

    /**
    * @description Creates a list of contracts used for testing.  The default names of the fields are their fieldname + the count number;
    * @param       name The custom prefixed name of the test object list you want.
    * @param       count The number of test objects you want created.  
    * @param       generateDependencies Whether you want any dependencies automatically generated and inserted.
    * @return      Returns the generated list of test objects.  You must insert it yourself.
    */
    public static Contract[] createContracts(String name, Integer count, Opportunity[] opportunities,Contact[] contacts) {
        if (name == null || count == null || count < 0) return new List<Contract>();

        Contract[] contracts = new List<Contract>();
        
        if (opportunities == null) {
            opportunities = UnitTestHelper.createOpportunities(name, count, true);
            UnitTestHelper.forcedInsert(opportunities);
        }

        if(contacts == null) {
            contacts = UnitTestHelper.createContacts('test', count, false);
            UnitTestHelper.forcedInsert(contacts);
        }

        for (Integer i = 0; i < count; i++) {
            String suffix = String.valueOf(i + 1);
            Contract ctrct = new Contract(
               AccountId = opportunities[i].AccountId
               ,Opportunity__c = opportunities[i].Id
               ,Contact__c = contacts[i].Id
               ,Purchasing_Entity__c = name
               ,StartDate = system.Date.today()
               ,ContractTerm = 12
               ,Contract_Value__c = 1000
               ,Status = 'Draft'
            );

            contracts.add(ctrct);
        }

        return contracts;
    }


//////////////////////////////////////


}