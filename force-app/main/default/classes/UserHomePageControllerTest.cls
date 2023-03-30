@isTest
private class UserHomePageControllerTest {
    
    @isTest
    static void testSaveUserInfo() {
        List<User__c> testUser = new List<User__c>{new User__c(Name='Test User', Debt_Amount__c=0, Balance__c=0, State__c='a000900000b5JhVAAU', City__c='a010900002aVNmyAAG')};
            insert testUser;
        
        Token__c testToken = new Token__c(User__c=testUser[0].Id, Token__c='test_token');
        insert testToken;
        
        UserHomePageController controller = new UserHomePageController();
        controller.user = testUser;
        
        controller.toggleEditMode();
        controller.user[0].Name = 'Updated Name';
        controller.saveUserInfo();
        
        testUser = [SELECT Name FROM User__c WHERE Id=:testUser[0].Id];
        
        System.assertEquals('Updated Name', testUser[0].Name);
    }
    
    @isTest
    static void testSaveCityInfo() {
        List<User__c> testUser = new List<User__c>{new User__c(Name='Test User', Debt_Amount__c=0, Balance__c=0, State__c ='a000900000b5JhVAAU', City__c ='a010900002aVNmyAAG')};
            insert testUser;
        
        Token__c testToken = new Token__c(User__c=testUser[0].Id, Token__c='test_token');
        insert testToken;
        
        UserHomePageController controller = new UserHomePageController();
        controller.user = testUser;
        
        controller.saveCityInfo();
        
        testUser = [SELECT City__c FROM User__c WHERE Id=:testUser[0].Id];
        
        System.assertEquals(null, testUser[0].City__c);
        
        Subsc__c testSubscription = new Subsc__c(User__c=testUser[0].Id, Is_Active__c=true);
        insert testSubscription;
        
        controller.saveCityInfo();
        
        System.assertEquals(1, ApexPages.getMessages().size());
        System.assertEquals(ApexPages.Severity.ERROR, ApexPages.getMessages()[0].getSeverity());
        System.assertEquals('You have active subscription.', ApexPages.getMessages()[0].getDetail());
        
        testUser = [SELECT City__c FROM User__c WHERE Id=:testUser[0].Id];
        
        System.assertEquals('Chortkiv', testUser[0].City__c);
    }
        @isTest
        static void testPayAllMonth() {
            User__c testUser = new User__c();
            testUser.First_Name__c = 'Test';
            testUser.Name = 'User';
            testUser.Balance__c = 1000;
            testUser.Email__c = 'testuser@test.com';
            insert testUser;
        
        UserHomePageController controller = new UserHomePageController();
        controller.user = [SELECT Id, First_Name__c, Name, Balance__c, Email__c FROM User__c WHERE Id =: testUser.Id];
        controller.paymentType = 'AllMonth';
        controller.paymentAmount = 500;
        
        Test.startTest();
        controller.pay();
        Test.stopTest();
        
        List<Payment__c> payments = [SELECT Id, Amount__c, Payment_Date__c, User__c FROM Payment__c WHERE User__c =: testUser.Id];
        System.assertEquals(1, payments.size(), 'Expected one payment record to be created.');
        System.assertEquals(500, payments[0].Amount__c, 'Expected payment amount to be 500.');
        System.assertEquals(Date.today(), payments[0].Payment_Date__c, 'Expected payment date to be today.');
        System.assertEquals(testUser.Id, payments[0].User__c, 'Expected payment to be associated with the test user.');
        
        User__c updatedUser = [SELECT Id, Balance__c, Debt_Amount__c FROM User__c WHERE Id =: testUser.Id];
        System.assertEquals(500, updatedUser.Balance__c, 'Expected user balance to be updated after payment.');
        System.assertEquals(500, updatedUser.Debt_Amount__c, 'Expected user debt amount to be updated after payment.');
        
    }
}