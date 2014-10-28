@isTest
private class ContractTriggerHandlerTest {
    
    @isTest static void afterUpdate_Test() {

    Account acct = new Account();
    acct.Name = 'Test';
    acct.BillingStreet = '1st';
    acct.BillingPostalCode = '11111';
    acct.BillingCity = 'Seattle';
    acct.BillingState = 'WA';
    acct.ShippingStreet = '1st';
    acct.ShippingPostalCode = '11111';
    acct.ShippingCity = 'Seattle';
    acct.ShippingState = 'WA';
    acct.NCES_ID__c = 'Test267';
    acct.Client_Status__c = 'Prospect';
    insert acct;

    Contact contact1 = new Contact();
    contact1.FirstName = 'A';
    contact1.LastName = 'Contact';
    contact1.AccountId = acct.Id;

    insert contact1;

    Opportunity[] opps = UnitTestHelper.createOpportunities('String name', 2, true);

    system.debug(opps);

    for(Opportunity opp : opps) {
        opp.AccountId = acct.Id;
    }

    Contract contract1 = new Contract();

    contract1.AccountId = acct.Id;
    contract1.Contact__c = contact1.Id;
    contract1.Status = 'Draft';
    contract1.Purchasing_Entity__c = 'Me';
    contract1.ContractTerm = 12;
    contract1.Opportunity__c = opps[0].Id;
    contract1.Contract_Value__c = 1000;
    insert contract1;

    SObject so1 = contract1;

    Contract contract2 = contract1.clone(true,true);
    contract2.Status = 'Purchased';
    update contract2;

    SObject so2 = contract2;

    Test.startTest();

    ContractTriggerHandler cth = new ContractTriggerHandler();

    cth.afterUpdate(so1, so2);
    cth.andFinally();

    Account foundAccount = [SELECT Id,Client_Status__c FROM Account WHERE Id = :contract1.AccountId];

    system.assertEquals('Customer', foundAccount.Client_Status__c);

    //Test.stopTest();
  }
    

    
}