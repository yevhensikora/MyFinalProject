global class CreateMeterReadingsB implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
    Datetime today = Datetime.now();
    if (today.day() >= 6 && today.day() < 10) {
        return Database.getQueryLocator([SELECT Id FROM User__c]);
    }
    return null;
}

    global void execute(Database.BatchableContext bc, List<User__c> scope) {
        List<Meter_Reading__c> readings = new List<Meter_Reading__c>();
        for (User__c user : scope) {
            Meter_Reading__c meterReading = new Meter_Reading__c();
            meterReading.User__c = user.Id;
            meterReading.Reading_Date__c = System.today();
        
        // Get the last month meter reading value
        List<Meter_Reading__c> lastMonthReading = [SELECT Water_Reading__c, Gas_Reading__c, Electricity_Reading__c 
                                                   FROM Meter_Reading__c 
                                                   WHERE User__c =: user.Id 
                                                   ORDER BY Reading_Date__c DESC 
                                                   LIMIT 1];
        if (lastMonthReading.size() > 0) {
            meterReading.Water_Reading__c = lastMonthReading[0].Water_Reading__c + 100;
            meterReading.Gas_Reading__c = lastMonthReading[0].Gas_Reading__c + 100;
            meterReading.Electricity_Reading__c = lastMonthReading[0].Electricity_Reading__c + 100;
        } else {
            meterReading.Water_Reading__c = 0;
            meterReading.Gas_Reading__c = 0;
            meterReading.Electricity_Reading__c = 0;
        }
        readings.add(meterReading);
        }
        insert readings;
    }

    global void finish(Database.BatchableContext bc) {

    }
}