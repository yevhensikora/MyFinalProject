public without sharing class UserWelcomePageController {
    public List<User__c> user {get;set;}
    public Meter_Reading__c meterReading {get;set;}
    public Decimal MTGas {get;set;}
    public Decimal MTWater {get;set;}
    public Decimal MTElectricity {get;set;}
    public Boolean isEditMode {get;set;}
    public List<Wrapperclass> wrapperList {get; set;}
    public Boolean SaveMethod {get; set;}
    public List<State__c> userManagedState;
    private String token;
    
    public List<SelectOption> cityOptions { get; set; }
    public String selectedCityId { get; set; }
    public City__c selectedCity { get; set; }
    
    public Id selectedUserId { get; set; }
    public List<Payment__c> payments { get; set; }
    public List<SelectOption> userOptions {get;set;}
    
    public UserWelcomePageController() {
        this.selectedCity = new City__c();
        
        token = ApexPages.currentPage().getCookies().get('token')?.getValue();
        user = new List<User__c>();
        
        if(token != null) {
            List<User__c> userList = [SELECT Id, Name, First_Name__c, Phone__c, Email__c, Balance__c, Debt_Amount__c, State__c, City__c, City__r.Gas_Rate__c, City__r.Water_Rate__c, City__r.Electricity_Rate__c, 
                                      (SELECT Id, Token__c FROM Tokens__r WHERE Token__c = :token) 
                                      FROM User__c 
                                      WHERE Id IN (SELECT User__c FROM Token__c WHERE Token__c = :token) 
                                      LIMIT 1];
            if(!userList.isEmpty()) {
                user.add(userList[0]);
            }
        }
        
        userManagedState = [SELECT Id, Name FROM State__c WHERE User__c = :user[0].Id];
        System.debug(userManagedState);
        SaveMethod = false;
        
        wrapperList = new List<Wrapperclass>();
        for(User__c user : [SELECT Id, Name, First_Name__c, State__c, City__c, Phone__c, Email__c, Debt_Amount__c FROM User__c WHERE Role__c = 'User' AND State__c = :userManagedState]) {
            wrapperList.add(new Wrapperclass(user));
        }   
        
        List<City__c> cities = [SELECT Id, Name, Gas_Rate__c, Water_Rate__c, Electricity_Rate__c 
                                FROM City__c 
                                WHERE State__r.User__c = :user[0].id];
        
        cityOptions = new List<SelectOption>();
        cityOptions.add(new SelectOption('--None--','--None--'));
        for (City__c city : cities) {
            cityOptions.add(new SelectOption(city.Id, city.Name));
        }
        
        userOptions = userOptions();
        if (userOptions.size() > 0) {
            selectedUserId = (Id)userOptions[0].getValue();
        }
        displayPayments();
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
        return null;
    }
    
    public List<SelectOption> userOptions() {
        List<SelectOption> options = new List<SelectOption>();
        for (User__c user : [SELECT Id, Name FROM User__c ORDER BY Name ASC]) {
            options.add(new SelectOption(user.Id, user.Name));
        }
        return options;
    }
    
    public void setSelectedUser() {
        displayPayments();
    }
    
    public void displayPayments() {
        String query = 'SELECT Id, Amount__c, Payment_Date__c FROM Payment__c';
        if (selectedUserId != null) {
            query += ' WHERE User__c = \'' + selectedUserId + '\'';
        }
        payments = Database.query(query);
    }
    
      
    public void setSelectedCityId() {
        if (selectedCityId != null) {
            selectedCity = [SELECT Id, Name, Gas_Rate__c, Water_Rate__c, Electricity_Rate__c FROM City__c WHERE Id = :selectedCityId];
        }
        else {
            selectedCity = null;
        }
    }
    
    public void editDelaction() {
        for(Wrapperclass wrap : wrapperList) {
            if(wrap.isSelEdit == true) {
                SaveMethod = true;
                break;
            }
        }
    }
    public void Save() {
        List<User__c> usersList = new List<User__c>();
        for(Wrapperclass wrap : wrapperList) {
            wrap.isSelEdit = false;
            usersList.add(wrap.user);
        }
        SaveMethod = false;
        update usersList;
    }
    
    public void toggleEditMode() {
        isEditMode = true;
    }
    
    public void saveUserInfo() {
        
        isEditMode = false;
        update user;
        
    }
    public void saveCityInfo() {
        isEditMode = false;
        update selectedCity;
    }
    
    public class WrapperClass {
        public User__c user {get;set;}
        public boolean isSelEdit{get;set;}
        
        public WrapperClass(User__c usr) {
            user = usr;
            isSelEdit = false;
        }
    }
}