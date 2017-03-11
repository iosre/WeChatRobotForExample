#import "../WeChatRobotForExample.h"

@interface CMessageWrap (WCRAdditions)

- (BOOL)WCRIsExampleAppMessage;
- (BOOL)WCRIsFromTeamExample;
- (BOOL)WCRIsFromAdmin;
- (BOOL)WCRIsFromGroup;
- (BOOL)WCRIsToGroup;
- (BOOL)WCRIsAtMe;
- (BOOL)WCRIsFromMe;
- (BOOL)WCRIsAttachment;
- (BOOL)WCRIsGroupInvitation;
- (BOOL)WCRIsGroupInvited;
- (BOOL)WCRIsGroupInviter;
- (BOOL)WCRIsGroupRemoved;
- (BOOL)WCRIsFriendAdded;
- (BOOL)WCRIsFriendRemoved;
- (NSString *)WCRInviterIDFromGroupInvitation;

// Commands
- (BOOL)WCRIsAllGroupsCommand;
- (BOOL)WCRIsAllUsersCommand;
- (BOOL)WCRIsNotifyCommand;
- (BOOL)WCRIsToUserCommand;
- (BOOL)WCRIsToGroupToUserCommand;
- (BOOL)WCRIsPasswordCommand;
- (BOOL)WCRIsInviteUserToAllGroupsCommand;
- (BOOL)WCRIsClearAllSessionsCommand;
- (BOOL)WCRIsStopBroadcastingCommand;
- (BOOL)WCRIsStartBroadcastingCommand;
- (BOOL)WCRIsQuitGroupCommand;
- (BOOL)WCRIsToGroupCommand;
- (BOOL)WCRIsViewIPCommand;

@end
