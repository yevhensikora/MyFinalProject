@isTest
public class RegisterPageControllerTest {
    
    @isTest
    static void testRegisterUser() {
        
        // Arrange
        RegisterPageController controller = new RegisterPageController();
        controller.email = 'test@test.com';
        controller.password = 'test1234';
        controller.firstName = 'Test';
        controller.lastName = 'User';
        controller.stateName = 'California';
        controller.cityName = 'Los Angeles';
        
        // Act
        PageReference result = controller.registerUser();
        
        // Assert
        System.assertEquals('/apex/UserLoginPage', result.getUrl());
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size());
        System.assertEquals(ApexPages.Severity.INFO, messages[0].getSeverity());
        System.assertEquals('User registered successfully!', messages[0].getSummary());
    }
    
    @isTest
    static void testRegisterUserWithExistingEmail() {
        
        // Arrange
        RegisterPageController controller = new RegisterPageController();
        controller.email = 'test@test.com';
        controller.password = 'test1234';
        controller.firstName = 'Test';
        controller.lastName = 'User';
        controller.stateName = 'California';
        controller.cityName = 'Los Angeles';
        User__c existingUser = new User__c(Email__c = 'test@test.com');
        insert existingUser;
        
        // Act
        PageReference result = controller.registerUser();
        
        // Assert
        System.assertEquals(null, result);
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size());
        System.assertEquals(ApexPages.Severity.ERROR, messages[0].getSeverity());
        System.assertEquals('Email already exists!', messages[0].getSummary());
    }
    
    @isTest
    static void testRegisterUserWithMissingFields() {
        
        // Arrange
        RegisterPageController controller = new RegisterPageController();
        controller.email = '';
        controller.password = 'test1234';
        controller.firstName = 'Test';
        controller.lastName = 'User';
        controller.stateName = 'California';
        controller.cityName = 'Los Angeles';
        
        // Act
        PageReference result = controller.registerUser();
        
        // Assert
        System.assertEquals(null, result);
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size());
        System.assertEquals(ApexPages.Severity.ERROR, messages[0].getSeverity());
        System.assertEquals('Error registering user: Make sure you fill in all the fields!', messages[0].getSummary());
    }
}