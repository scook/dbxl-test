public with sharing class ContractTriggerHandler extends TriggerBase {  
    
    //Members
    Account[] accountsToUpdate = new List<Account>();
    Set<Id> accountIds = new Set<Id>();

    //Constructor
    public ContractTriggerHandler() {}
    
    //Methods
    override public void afterUpdate(SObject oldSo, SObject so) {
        Contract oldContract = (Contract) oldSo;
        Contract newContract = (Contract) so;
        
        System.debug('NEW CONTRACT => ' + newContract.Status);
        System.debug('OLD CONTRACT => ' + oldContract.Status);
        
        Map<Id,Contract> accountContractMap = new Map<Id,Contract>();
        if (newContract.Status != oldContract.Status &&
            (newContract.Status == 'Purchased' ||
             newContract.Status == 'Expired')) {
            system.debug('I am here');
            accountIds.add(newContract.AccountId);
            system.debug('CONTRACT TRIGGER => ' + accountIds);
            //accountContractMap.put(newContract.Account.Id,newContract);
        }
        
        //Map<Id,Account> accountMap = new Map<Id,Account>([SELECT Id,
        //                                                         Client_Status_Tr__c
        //                                                    FROM Account
        //                                                   WHERE Id IN :accountIds]);
                                                           
        //for(Account acct : accountMap.values()) {
        //    acct.Client_Status_Tr__c = accountContractMap.get(acct.Id).Status;
        //    accountsToUpdate.add(acct);
        //}
    }
    
    override public void andFinally() {
        system.debug('CONTRACT TRIGGER => ' + accountIds);
        if (!accountIds.isEmpty()) {
            updateContractAccounts();
        }
    }

    private void updateContractAccounts() {



        Map<Id,Account> accountMap = new Map<Id,Account>([SELECT Id,
                                                                 Client_Status_Tr__c
                                                            FROM Account
                                                           WHERE Id IN :accountIds]);

        for(Account acct: accountMap.values()) {
            acct.Client_Status_Tr__c = 'Former Customer';
        }

        Contract[] contracts = [SELECT Id
                                      ,AccountId
                                      ,Status 
                                  FROM Contract
                                 WHERE AccountId IN :accountIds
                                 ORDER BY AccountId];  

        for(Contract cntrct : contracts) {
            if(cntrct.Status == 'Purchased') {
                accountMap.get(cntrct.AccountId).Client_Status_Tr__c = 'Customer'; 
            }
        }

        //Account[] accounts = accountMap.values();
        update accountMap.values();
    }

}