@isTest
private class UserLoginControllerTest {
    
    @isTest
    static void testLoginUser() {
        // Create test user
        User__c testUser = new User__c(
            First_Name__c = 'Test',
            Name = 'User',
            Role__c = 'User',
            Email__c = 'test@example.com',
            Password__c = 'testpassword'
        );
        insert testUser;
        
        // Create instance of the controller
        UserLoginController controller = new UserLoginController();
        
        // Set the email and password for the test user
        controller.email = 'test@example.com';
        controller.password = 'wrongpassword';
        
        // Call the loginUser method
        PageReference pageRef = controller.loginUser();
        
        // Assert that an error message is displayed
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertNotEquals(null, messages);
        System.assertEquals(1, messages.size());
        ApexPages.Message message = messages[0];
        System.assertEquals(ApexPages.Severity.ERROR, message.getSeverity());
        System.assertEquals('Invalid email or password. Please try again.', message.getDetail());
    }
    
}