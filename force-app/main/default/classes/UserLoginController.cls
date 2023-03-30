public without sharing class UserLoginController {
    
    public String email {get; set;}
    public String password {get; set;}
    
    public PageReference loginUser() {
        User__c user = [SELECT Id, First_Name__c, Name, Role__c, Password__c FROM User__c WHERE Email__c = :email LIMIT 1];
        
        String inputPassword = password;
        Blob hashedInputPassword = Crypto.generateDigest('SHA-256', Blob.valueOf(inputPassword));
        String hashedInputPasswordString = EncodingUtil.convertToHex(hashedInputPassword);
        
        if (hashedInputPasswordString.equals(user.Password__c)) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'Welcome ' + user.First_Name__c + ' ' + user.Name + '!');
            ApexPages.addMessage(msg);
            
            String token = generateToken();
            
            List<Token__c> tokensToUpdate = new List<Token__c>();
            List<Token__c> existingToken = [SELECT Id, User__c FROM Token__c WHERE User__c = :user.Id LIMIT 1];
            
            if (existingToken.isEmpty()) {
                Token__c newToken = new Token__c();
                newToken.Token__c = token;
                newToken.User__c = user.Id;
                tokensToUpdate.add(newToken);
            } else {
                existingToken[0].Token__c = token;
                tokensToUpdate.add(existingToken[0]);
            }
            
            Database.UpsertResult[] result = Database.upsert(tokensToUpdate, false);
            for (Database.UpsertResult r : result) {
                if (r.isSuccess()) {
                    System.debug('Token upserted successfully.');
                } else {
                    for (Database.Error e : r.getErrors()) {
                        System.debug('Error upserting token: ' + e.getStatusCode() + ' ' + e.getMessage());
                    }
                }
            }
            if(user.Role__c.equals('User')) {
                ApexPages.currentPage().setCookies(new Cookie[]{new Cookie('token', token, null, 3600, false)});
                return Page.UserHomePage;
            } else if (user.Role__c.equals('Manager')) {
                ApexPages.currentPage().setCookies(new Cookie[]{new Cookie('token', token, null, 3600, false)});
                return Page.WelcomePage;
            } else {
                ApexPages.Message msgs = new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid user role.');
                ApexPages.addMessage(msgs);
                return null;
            }
        } else {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid email or password. Please try again.');
            ApexPages.addMessage(msg);
            return null;
        }
    }
    
    
    private String generateToken() {
        String token = '';
        while (token.length() < 32) {
            Integer rand = Math.abs(Crypto.getRandomInteger());
            String hash = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(String.valueOf(rand))));
            token += hash.substring(0, Math.min(hash.length(), 32 - token.length()));
        }
        return token;
    }
}