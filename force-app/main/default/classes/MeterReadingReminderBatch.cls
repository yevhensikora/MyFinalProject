global class MeterReadingReminderBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Email__c FROM User__c]);
    }
    
    global void execute(Database.BatchableContext bc, List<User__c> scope) {
        List<Id> userIds = new List<Id>();
        for (User__c user : scope) {
            userIds.add(user.Id);
        }
        List<Meter_Reading__c> readings = [SELECT Id, User__c, Reading_Date__c FROM Meter_Reading__c WHERE User__c IN :userIds];
        Set<Id> usersWithReadings = new Set<Id>();
        for (Meter_Reading__c meterReading : readings) {
            usersWithReadings.add(meterReading.User__c);
        }
        
        List<User__c> usersWithoutReadings = new List<User__c>();
        for (User__c user : scope) {
            if (!usersWithReadings.contains(user.Id)) {
                usersWithoutReadings.add(user);
            }
        }
        if (usersWithoutReadings.size() > 0) {
            String body = 'Dear User,<br><br>Please be reminded that you need to provide meter readings for this month.<br><br>Thank you.<br>System';
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            for (User__c user : usersWithoutReadings) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{user.Email__c});
                email.setSubject('Meter Reading Reminder');
                email.setHtmlBody(body);
                emails.add(email);
            }
            Messaging.sendEmail(emails);
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        
    }
}