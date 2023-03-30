public class RegisterPageController {
    public User__c user;
    public String email{get;set;}
    public String password{get;set;}
    public String firstName{get;set;}
    public String lastName{get;set;}
    public String cityName{get;set;}
    public List<SelectOption> cities{get;set;}
    public String stateName {get;set;}
    public List<SelectOption> states{get;set;}    
    
    public RegisterPageController(){
        states = statesToSelectOptionList();
        stateName = states[0].getValue();
        getCities();
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
    
    public Boolean isEmailUnique(String email) {
        List<User__c> users = [SELECT Id FROM User__c WHERE Email__c = :email];
        return users.isEmpty();
    }
    
    public PageReference registerUser() {
    if(!isEmailUnique(email)) {
        ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Email already exists!');
        ApexPages.addMessage(msg);
        return null;
    }
    
    if(String.isBlank(email) || String.isBlank(password) || String.isBlank(firstName) || String.isBlank(lastName) || cityName == '--None--' || stateName == '--None--') {
        ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error registering user: Make sure you fill in all the fields!');
        ApexPages.addMessage(msg);
        return null;
    }
    
    List<City__c> cities = [SELECT Id, Name FROM City__c WHERE Name = :cityName];
    if (cities.isEmpty()) {
        ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error registering user: City not found!');
        ApexPages.addMessage(msg);
        return null;
    }
    City__c city = cities[0];
    
    State__c state = [SELECT Id, Name FROM State__c WHERE Name = :stateName];
    
    String pass = password;
    Blob hashedPassword = Crypto.generateDigest('SHA-256', Blob.valueOf(pass));
    String hashedPasswordString = EncodingUtil.convertToHex(hashedPassword);
    
    user = new User__c(Email__c = email, Password__c = hashedPasswordString, Name = lastName, First_Name__c = firstName, City__c = city.id, State__c = state.Id);
    insert user;
        
        ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'User registered successfully!');
        ApexPages.addMessage(msg);
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] {user.Email__c});
        email.setSubject('User Registration');
        email.setPlainTextBody('User ' + User.Name + ' has been registered successfully.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        
        PageReference loginPage = Page.UserLoginPage;
        loginPage.setRedirect(true);
        return loginPage;
    }
    
    public PageReference redirectToLoginPage(){
        PageReference pageReference = new pageReference('/apex/UserLoginPage');
        return pageReference;
    }  
}