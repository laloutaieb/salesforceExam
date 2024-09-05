//difference between chatter group & public group : 
//https://trailhead.salesforce.com/fr/trailblazer-community/feed/0D54V00007DtR4hSAF

//CollaborationGroupMember class Documentatiom : 
//https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_collaborationgroupmember.htm

//Group Classs Documentatiom : 
//https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_group.htm

public class ChatterGroupMemberHandler {

    public static void handleGroupMemberInsert(List<CollaborationGroupMember> newMembers) {
        Set<Id> chatterGroupIds = new Set<Id>();

        for (CollaborationGroupMember member : newMembers) {
            chatterGroupIds.add(member.CollaborationGroupId);
        }

        Map<Id, CollaborationGroup> chatterGroupMap = new Map<Id, CollaborationGroup>(
            [SELECT Id, Name FROM CollaborationGroup WHERE Id IN :chatterGroupIds]
        );

        Set<String> chatterGroupNames = new Set<String>();
        for (Id groupId : chatterGroupIds) {
            if (chatterGroupMap.containsKey(groupId)) {
                chatterGroupNames.add(chatterGroupMap.get(groupId).Name);
            }
        }

        Map<String, Group> publicGroups = new Map<String, Group>();
        try {
            publicGroups = fetchOrCreatePublicGroups(chatterGroupNames);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        List<Id> memberIds = new List<Id>();
        List<Id> publicGroupIds = new List<Id>();
        
        for (CollaborationGroupMember member : newMembers) {
            CollaborationGroup chatterGroup = chatterGroupMap.get(member.CollaborationGroupId);
            Group publicGroup = publicGroups.get(chatterGroup.Name);
            if (publicGroup != null) {
                memberIds.add(member.MemberId);
                publicGroupIds.add(publicGroup.Id);
            }
        }

        if (!memberIds.isEmpty() && !publicGroupIds.isEmpty()) {
            try {
                ChatterGroupMemberHandler.addMembersToPublicGroupsAsync(memberIds, publicGroupIds);
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
        }
    }

    public static void handleGroupMemberDelete(List<CollaborationGroupMember> oldMembers) {
        Set<Id> chatterGroupIds = new Set<Id>();

        for (CollaborationGroupMember member : oldMembers) {
            chatterGroupIds.add(member.CollaborationGroupId);
        }
       
        Map<Id, CollaborationGroup> chatterGroupMap = new Map<Id, CollaborationGroup>(
            [SELECT Id, Name FROM CollaborationGroup WHERE Id IN :chatterGroupIds]
        );

        Set<String> chatterGroupNames = new Set<String>();
        for (Id groupId : chatterGroupIds) {
            if (chatterGroupMap.containsKey(groupId)) {
                chatterGroupNames.add(chatterGroupMap.get(groupId).Name);
            }
        }

        Map<String, Group> publicGroups = new Map<String, Group>();
        try {
            publicGroups = fetchExistingPublicGroups(chatterGroupNames);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        List<Id> memberIds = new List<Id>();
        List<Id> publicGroupIds = new List<Id>();

        for (CollaborationGroupMember member : oldMembers) {
            CollaborationGroup chatterGroup = chatterGroupMap.get(member.CollaborationGroupId);
            Group publicGroup = publicGroups.get(chatterGroup.Name);
            if (publicGroup != null) {
                memberIds.add(member.MemberId);
                publicGroupIds.add(publicGroup.Id);
            }
        }

        if (!memberIds.isEmpty() && !publicGroupIds.isEmpty()) {
            try {
                ChatterGroupMemberHandler.removeMembersFromPublicGroupsAsync(memberIds, publicGroupIds);
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
        }
    }


    @future
    public static void addMembersToPublicGroupsAsync(List<Id> memberIds, List<Id> groupIds) {
        List<GroupMember> membersToAdd = new List<GroupMember>();
        for (Integer i = 0; i < memberIds.size(); i++) {
            GroupMember newGroupMember = new GroupMember(GroupId = groupIds[i], UserOrGroupId = memberIds[i]);
            membersToAdd.add(newGroupMember);
        }
        try {
            if (!membersToAdd.isEmpty()) {
                insert membersToAdd;
        
            }
        } catch (DmlException e) {
            System.debug(e.getMessage());
        }
    }

    //why I used @future : 
    //https://www.apexhours.com/mixed-dml-operation-error-in-salesforce/#avoiding-mixed-dml-errors-using-future-method

        @future
        public static void removeMembersFromPublicGroupsAsync(List<Id> memberIds, List<Id> groupIds) {
      
            Set<Id> groupIdSet = new Set<Id>(groupIds);
            Set<Id> memberIdSet = new Set<Id>(memberIds);

            List<GroupMember> groupMembers = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember 
                                            WHERE GroupId IN :groupIdSet AND UserOrGroupId IN :memberIdSet];

            List<GroupMember> membersToRemove = new List<GroupMember>();
 
            for (GroupMember gm : groupMembers) {
                if (groupIds.contains(gm.GroupId) && memberIds.contains(gm.UserOrGroupId)) {
                    membersToRemove.add(gm);
                } 
            }

            try {
                if (!membersToRemove.isEmpty()) {
                    delete membersToRemove;
          
                }
            } catch (DmlException e) {
                System.debug(e.getMessage());
            }
        }



    private static Map<String, Group> fetchOrCreatePublicGroups(Set<String> groupNames) {
        Map<String, Group> publicGroups = new Map<String, Group>();

        try {

            List<Group> existingGroups = [SELECT Id, Name FROM Group WHERE Name IN :groupNames];
            for (Group publicGroup : existingGroups) {
                publicGroups.put(publicGroup.Name, publicGroup);
            }

            List<Group> groupsToCreate = new List<Group>();
            for (String groupName : groupNames) {
                if (!publicGroups.containsKey(groupName)) {
                    Group newPublicGroup = new Group(Name = groupName, Type = 'Regular');
                    groupsToCreate.add(newPublicGroup);
                }
            }
            if (!groupsToCreate.isEmpty()) {
                insert groupsToCreate;
                for (Group publicGroup : groupsToCreate) {
                    publicGroups.put(publicGroup.Name, publicGroup);
                }
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        
        return publicGroups;
    }


    private static Map<String, Group> fetchExistingPublicGroups(Set<String> groupNames) {
        Map<String, Group> publicGroups = new Map<String, Group>();

        try {
            List<Group> existingGroups = [SELECT Id, Name FROM Group WHERE Name IN :groupNames];
            for (Group publicGroup : existingGroups) {
                publicGroups.put(publicGroup.Name, publicGroup);
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        return publicGroups;
    }
}
