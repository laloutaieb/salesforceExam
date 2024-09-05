public with sharing class UserController {
    @AuraEnabled(cacheable=true)
    public static UserInfoResponse getCurrentUserInfo() {

        User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return new UserInfoResponse(currentUser.Id, currentUser.Name);
    }


    public class UserInfoResponse {
        @AuraEnabled public String userId { get; set; }
        @AuraEnabled public String userName { get; set; }
        
        public UserInfoResponse(String id, String name) {
            this.userId = id;
            this.userName = name;
        }
    }
}
