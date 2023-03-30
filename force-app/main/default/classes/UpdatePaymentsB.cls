global class UpdatePaymentsB implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Amount__c, Payment_Date__c, Subscription__r.User__r.Email__c, Subscription__r.User__r.Debt_Amount__c, Subscription__r.User__r.Balance__c 
                                             FROM Payment__c
                                             WHERE Payment_Date__c <= TODAY
                                             AND Is_Payd__c = FALSE]);
    }

    global void execute(Database.BatchableContext bc, List<Payment__c> scope) {
    List<Payment__c> paymentsToUpdate = new List<Payment__c>();
    List<User__c> usersToUpdate = new List<User__c>();
    List<Id> subscriptionIdsToUpdate = new List<Id>();
    List<Subsc__c> subscriptionToDeactivate = new List<Subsc__c>();

    for(Payment__c payment : scope) {
        if(payment.Payment_Date__c == Date.today()) {
            Decimal balance = payment.Subscription__r.User__r.Debt_Amount__c;
            if(balance >= payment.Amount__c) {
                payment.Subscription__r.User__r.Debt_Amount__c += payment.Amount__c;
                payment.Subscription__r.User__r.Balance__c -= payment.Amount__c;
                payment.Is_Payd__c = TRUE;
                paymentsToUpdate.add(payment);
                usersToUpdate.add(payment.Subscription__r.User__r);
            } else {
                try {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new String[] { payment.Subscription__r.User__r.Email__c });
                    email.setSubject('Insufficient Balance');
                    email.setPlainTextBody('Dear ' + payment.Subscription__r.User__r.Name + ',\n\nYour account balance is insufficient to pay for your subscription. Please top up your account balance to continue using our service.\n\nThank you,\nOur Service Team');
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                } catch(Exception e) {
                    System.debug('Failed to send email: ' + e.getMessage());
                }
            }
        }

        if(!subscriptionIdsToUpdate.contains(payment.Subscription__c)){
            subscriptionIdsToUpdate.add(payment.Subscription__c);
        }
    }

  
    for(Id subscriptionId : subscriptionIdsToUpdate){
        List<Payment__c> listOfPayments = [SELECT Id, Is_Payd__c FROM Payment__c WHERE Subscription__c = :subscriptionId];
        Boolean allPaymentsPaid = true;
        for(Payment__c payment : listOfPayments){
            if(!payment.Is_Payd__c){
                allPaymentsPaid = false;
                break;
            }
        }
        
        if(allPaymentsPaid){
            Subsc__c subscriptionToUpdate = new Subsc__c(Id=subscriptionId, is_Active__c=false);
            subscriptionToDeactivate.add(subscriptionToUpdate);
        }
    }

    update paymentsToUpdate;
    update usersToUpdate;
    update subscriptionToDeactivate;
}

    global void finish(Database.BatchableContext bc) {
        
    }
}