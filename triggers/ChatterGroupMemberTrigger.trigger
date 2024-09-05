trigger ChatterGroupMemberTrigger on CollaborationGroupMember (after insert, after delete) {
    if (Trigger.isInsert) {
        ChatterGroupMemberHandler.handleGroupMemberInsert(Trigger.new);
    }

    if (Trigger.isDelete) {
        ChatterGroupMemberHandler.handleGroupMemberDelete(Trigger.old);
    }
}
