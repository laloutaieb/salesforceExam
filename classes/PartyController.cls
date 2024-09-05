public with sharing class PartyController {

    @AuraEnabled
    public static Id createParty(String name, String code, String description, String leader) {
        Party__c newParty = new Party__c(
            Name = name,
            Code__c = code,
            Description__c = description,
            Party_Leader__c = leader
        );
        try {
            insert newParty;
            System.debug('Insert successful. Party ID: ' + newParty.Id);
        } catch (DmlException e) {
            System.debug('Insert failed. Error: ' + e.getMessage());
        }
        System.debug('name & id party '+newParty.name + ' '+ newParty.Id); 

        return newParty.Id;
    }

    @AuraEnabled(cacheable=true)
    public static List<Party__c> getParties() {
        return [SELECT Id, Name, Description__c, Code__c, Party_Leader__c FROM Party__c];
    }
}
