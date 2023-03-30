public without sharing class UserHomePageController {
    public List<User__c> user {get;set;}
    public Date xDate {get;set;}
    public Integer meterReading {get;set;}
    public String selectedService {get;set;}
    public List<Meter_Reading__c> allMeterReadings;
    public List<Payment__c> allPayments;
    public String paymentType {get;set;}
    public Decimal numberOfPayments {get; set;}
    public Integer paymentAmount {get;set;}
    public Decimal gasRate {get;set;}
    public Decimal waterRate {get;set;}
    public Decimal electricityRate {get;set;}
    public String state {get;set;}
    public String city {get;set;}
    public Boolean isEditMode {get;set;}
    public Integer topUpAmount {get;set;}
    public String alertMessage {get; set;}
    public Subsc__c subscription {get; set;}
    public String managerMessage {get; set;}
    private String token;
    public String cityName{get;set;}
    public List<SelectOption> cities{get;set;}
    public String stateName {get;set;}
    public List<SelectOption> states{get;set;} 
    
    
    
    public UserHomePageController() {
		
        states = statesToSelectOptionList();
        stateName = states[0].getValue();
        getCities();
        isEditMode = false;
        token = ApexPages.currentPage().getCookies().get('token')?.getValue();
        user = new List<User__c>();
        
        if(token != null) {
            List<User__c> userList = [SELECT Id, Name, First_Name__c, Phone__c, Email__c, Balance__c, Debt_Amount__c, State__c, City__c, City__r.Gas_Rate__c, City__r.Water_Rate__c, City__r.Electricity_Rate__c, 
                                      (SELECT Id, Token__c FROM Tokens__r WHERE Token__c = :token) 
                                      FROM User__c 
                                      WHERE Id IN (SELECT User__c FROM Token__c WHERE Token__c = :token) LIMIT 1];
            
            if(!userList.isEmpty()) {
                user.add(userList[0]);
            }
        }
    }
    
    public PageReference init() {
        if(token == null) {
            PageReference loginPage = Page.UserLoginPage;
            loginPage.setRedirect(true);
            ApexPages.currentPage().setRedirect(true);
            return loginPage;
        }
        
        List<Token__c> existingToken = [SELECT User__r.Role__c FROM Token__c WHERE Token__c = :token];
        if(existingToken.isEmpty()) {
            PageReference loginPage = Page.UserLoginPage;
            loginPage.setRedirect(true);
            ApexPages.currentPage().setRedirect(true);
            return loginPage;
        }
        
        String role = existingToken[0].User__r.Role__c;
        if(role == 'Manager') {
            PageReference managerPage = Page.WelcomePage;
            managerPage.setRedirect(true);
            ApexPages.currentPage().setRedirect(true);
            return managerPage;
        } 
        
        return null;
    }
    
    
    public void toggleEditMode() {
        isEditMode = true;
    }
    
    public void saveUserInfo() {
        isEditMode = false;
        update user;   
    }
    
    public void saveCityInfo() {  
        List<Subsc__c> activeSubscriptions = [SELECT Id FROM Subsc__c WHERE User__c = :user[0].Id AND Is_Active__c = true];
        
        if (!activeSubscriptions.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You have active subscription.'));
        }else {
            isEditMode = false;
            
            City__c city = [SELECT Id, Name FROM City__c WHERE Name = :cityName];
            State__c state = [SELECT Id, Name FROM State__c WHERE Name = :stateName];
            user[0].City__c = city.Id;
            user[0].State__c = state.Id;
            update user;
        }   
    }
    
    public List<SelectOption> statesToSelectOptionList(){
        List<SelectOption> options= new List<SelectOption>();
        options.add(new SelectOption('--None--','--None--'));
        
        for(State__c state : [SELECT Name 
                              FROM State__c 
                              ORDER BY Name]){
                                  options.add(new SelectOption(state.Name,state.Name));
                              }     
        return options;
    }
    
    public void getCities(){
        List<SelectOption> options= new List<SelectOption>();
        options.add(new SelectOption('--None--','--None--'));
        for(City__c city : [SELECT Name,State__r.Name 
                            FROM City__c 
                            WHERE State__r.Name = : stateName 
                            ORDER BY Name]){
                                options.add(new SelectOption(city.Name,city.Name));
                            }
        
        cities = options;
    }
    
    public PageReference saveReading() {
        Meter_Reading__c MeterObject;
        List<Meter_Reading__c> lastMonthReading = [SELECT Id, Water_Reading__c, Gas_Reading__c, Electricity_Reading__c
                                                   FROM Meter_Reading__c
                                                   WHERE User__c = :user[0].Id
                                                   AND CALENDAR_MONTH(Reading_Date__c) = :xDate.month() - 1];
        
        List<Meter_Reading__c> existingReadings = [SELECT Id, Water_Reading__c, Gas_Reading__c, Electricity_Reading__c
                                                   FROM Meter_Reading__c
                                                   WHERE User__c = :user[0].Id
                                                   AND CALENDAR_MONTH(Reading_Date__c) = :xDate.month()];
        
        if (!existingReadings.isEmpty()) {
            MeterObject = existingReadings[0];
        } else {
            MeterObject = new Meter_Reading__c(User__c = user[0].Id,
                                               Reading_Date__c = xDate);
        }	
        
        if ( (isWater(selectedService) && isNotEmptyWater(MeterObject.Water_Reading__c)) ||
            (isGas(selectedService) && isNotEmptyGas(MeterObject.Gas_Reading__c)) ||
            (isElectricity(selectedService) && isNotEmptyElectricity(MeterObject.Electricity_Reading__c))) {
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'A reading for this service has already been entered for this month. If you want to change the indicators, write a message to the manager of your Region.'));
                return null;
            }
        
        if ( (isWater(selectedService) && isBiggerThanTheLastOneWater(lastMonthReading[0].Water_Reading__c)) ||
            (isGas(selectedService) && isBiggerThanTheLastOneGas(lastMonthReading[0].Gas_Reading__c)) ||
            (isElectricity(selectedService) && isBiggerThanTheLastOneElec(lastMonthReading[0].Electricity_Reading__c))) {
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The new reading cannot be less than the previous reading.'));
                return null;
            }
        
        if (xDate > Date.today() || xDate.month() > Date.today().month()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The reading date cannot be in the future or the next month.'));
            return null;
        }
        
        if (isWater(selectedService)) {
            MeterObject.Water_Reading__c = meterReading;
        } else if (isGas(selectedService)) {
            MeterObject.Gas_Reading__c = meterReading;
        } else if (isElectricity(selectedService)) {
            MeterObject.Electricity_Reading__c = meterReading;
        }
        
        try {
            upsert MeterObject;
        } catch (DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occurred while saving the meter reading.'));
            return null;
        }
        
        calculateDebtAmount();
        return null;
    }
    
    public void calculateDebtAmount() {
        Decimal totalCost = 0;
        List<Meter_Reading__c> previousReading = [SELECT Water_Reading__c, Gas_Reading__c, Electricity_Reading__c, User__r.City__r.Water_Rate__c FROM Meter_Reading__c WHERE User__c = :user[0].Id AND CALENDAR_MONTH(Reading_Date__c) = :xDate.month() - 1  ORDER BY Reading_Date__c DESC LIMIT 1];
        List<Meter_Reading__c> currentReading = [SELECT Water_Reading__c, Gas_Reading__c, Electricity_Reading__c, User__r.City__r.Water_Rate__c FROM Meter_Reading__c WHERE User__c = :user[0].Id AND CALENDAR_MONTH(Reading_Date__c) = :xDate.month() ORDER BY Reading_Date__c DESC LIMIT 1];
        System.debug(previousReading);
        System.debug(currentReading);
        
        if(!previousReading.isEmpty() && !currentReading.isEmpty()) {
            Decimal meterReading = currentReading[0].Water_Reading__c != null ? currentReading[0].Water_Reading__c : currentReading[0].Gas_Reading__c != null ? currentReading[0].Gas_Reading__c : currentReading[0].Electricity_Reading__c;
            
            if(currentReading[0].Water_Reading__c != null) {
                Decimal water = meterReading - previousReading[0].Water_Reading__c;
                totalCost += water * currentReading[0].User__r.City__r.Water_Rate__c; 
            } else if (currentReading[0].Gas_Reading__c != null) {
                Decimal Gas = meterReading - previousReading[0].Gas_Reading__c;
                totalCost += Gas * currentReading[0].User__r.City__r.Gas_Rate__c;
            } else if (currentReading[0].Electricity_Reading__c != null) {
                Decimal Electricity = meterReading - previousReading[0].Electricity_Reading__c;
                totalCost += Electricity * currentReading[0].User__r.City__r.Electricity_Rate__c;
            }   
        }
        if(totalCost > 0) {
            user[0].Debt_Amount__c = user[0].Debt_Amount__c - totalCost;
            update user;
        }
    }
    
    public List<Meter_Reading__c> getListOfMeterReadings() {
        return allMeterReadings = [SELECT Gas_Reading__c, Water_Reading__c, Electricity_Reading__c, Reading_Date__c FROM Meter_Reading__c]; ////////////
    }
    
    public List<Payment__c> getListOfPayments() {
        return allPayments = [SELECT Amount__c, Payment_Date__c, Is_Payd__c FROM Payment__c];
    }
    
    public void TopUYourWallet() {
        if (topUpAmount <= 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Enter the correct top-up amount!'));
            return;
        }
        user[0].Balance__c += topUpAmount;
        update user;
    }
    
    public void pay() {
        if (paymentType == 'AllMonth') {
            if (paymentAmount <= 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid payment amount.'));
                return;
            }
            if (user[0].Balance__c >= paymentAmount) {
                Payment__c payment = new Payment__c();
                payment.Amount__c = paymentAmount;
                payment.Payment_Date__c = Date.today();
                payment.User__c = user[0].Id;
                payment.Is_Payd__c = true;
                user[0].Balance__c -= paymentAmount;
                user[0].Debt_Amount__c += paymentAmount;
                update user;
                try {
                    insert payment;
                    Id paymentId = payment.Id;
                    
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    attachment.setFileName('Payment_Record.pdf');
                    attachment.setContentType('application/pdf');
                    attachment.setBody(generatePaymentPDF(paymentId));
                    
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new List<String>{user[0].Email__c});
                    email.setSubject('Payment Confirmation');
                    email.setHtmlBody('Dear ' + user[0].First_Name__c + ',<br><br>Your payment of $' + paymentAmount + ' for all services this month has been received.<br><br>Thank you for your business.<br><br>Sincerely,<br>Our Company');
                    email.setFileAttachments(new List<Messaging.EmailFileAttachment>{attachment});
                    
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
                    
                    if (results[0].success) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Payment made successfully and payment receipt has been sent to your email.'));
                    } else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to send payment receipt email.'));
                    }
                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Payment failed due to an error: ' + e.getMessage()));
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Insufficient balance to make the payment.'));
            }
        } else if (paymentType == 'ByParts') {
            if (paymentAmount <= 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid payment amount.'));
                return;
            }
            subscription = new Subsc__c();
            subscription.Duration__c = numberOfPayments;
            subscription.Price__c = paymentAmount;
            subscription.User__c = user[0].Id;
            subscription.Start_Date__c = Date.today();
            subscription.is_Active__c = true;
            
            try {
                insert subscription;
                createPaymentsForSubscription(subscription);
            } catch (Exception e) {
                System.debug('Failed to create subscription and payments: ' + e.getMessage());
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid payment type.'));
        }
    }
    
    private Blob generatePaymentPDF(Id paymentId) {
        Payment__c payment = [SELECT Id, Amount__c, Payment_Date__c, User__r.Name FROM Payment__c WHERE Id = :paymentId LIMIT 1];
        
        String pdfContent = 'Payment Record\n\n'
            + 'Payment Id: ' + payment.Id + '\n'
            + 'Amount: $' + payment.Amount__c + '\n'
            + 'Payment Date: ' + payment.Payment_Date__c.format() + '\n'
            + 'User: ' + payment.User__r.Name;
        
        return Blob.toPdf(pdfContent);
    }
    
    private void createPaymentsForSubscription(Subsc__c subscription) {
        Integer paymentCount = (Integer)subscription.Duration__c;
        Decimal paymentAmount = subscription.Price__c / paymentCount;
        
        for (Integer i = 0; i < paymentCount; i++) {
            Payment__c payment = new Payment__c();
            payment.Amount__c = paymentAmount;
            payment.Payment_Date__c = subscription.Start_Date__c.date().addMonths(i);
            payment.User__c = subscription.User__c;
            payment.Subscription__c = subscription.Id;
            payment.Is_Payd__c = false;
            
            try {
                insert payment;
            } catch (Exception e) {
                System.debug('Failed to create payment: ' + e.getMessage());
            }
        }
    }
    
    public void sendEmail() {
        try {
            List<State__c> stateManager = [SELECT User__r.Name, User__r.Email__c FROM State__c WHERE User__r.Role__c = 'Manager' LIMIT 1];
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] {stateManager[0].User__r.Email__c});
            email.setSubject('Manager Chat');
            email.setPlainTextBody(managerMessage);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            System.debug(managerMessage);
            System.debug(stateManager[0].User__r.Email__c);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Your message has been sent.'));
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to send email: ' + e.getMessage()));
        }
    }
    
    public PageReference logout() {
        PageReference loginPage = Page.UserLoginPage;
        loginPage.setRedirect(true);
        return loginPage;
    }
    
    private Boolean isWater(String selectedService){
        return selectedService == 'Water';
    }
    private Boolean isGas(String selectedService){
        return selectedService == 'Gas';
    }
    private Boolean isElectricity(String selectedService){
        return selectedService == 'Electricity';
    }
    private Boolean isNotEmptyWater(Decimal waterReading) {
        return waterReading != null && waterReading > 0;
    }
    private Boolean isNotEmptyGas(Decimal gasReading) {
        return gasReading != null && gasReading > 0;
    }
    private Boolean isNotEmptyElectricity(Decimal electricityReading) {
        return electricityReading != null && electricityReading > 0;
    }
    private Boolean isBiggerThanTheLastOneWater(Decimal lastMonthWaterReading) {
        return meterReading < lastMonthWaterReading;
    }
    private Boolean isBiggerThanTheLastOneGas(Decimal lastMonthGasReading) {
        return meterReading < lastMonthGasReading;
    }
    private Boolean isBiggerThanTheLastOneElec(Decimal lastMonthElectricityReading) {
        return meterReading < lastMonthElectricityReading;
    }
}