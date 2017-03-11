#import "CMessageWrap-WCRAdditions.h"
#import "WCRPreferences.h"
#import "WCRUserCommander.h"

%hook CMessageWrap

%new
- (BOOL)WCRIsExampleAppMessage
{
	if (self.m_uiMessageType == 49 && [self.m_nsAppMediaUrl rangeOfString:[WCRPreferences broadcastPassport]].location != NSNotFound) return YES;
	return NO;
}

%new
- (BOOL)WCRIsFromTeamExample
{
	if ([[WCRPreferences teamExample] indexOfObject:self.m_nsFromUsr] != NSNotFound) return YES;
	return NO;
}

%new
- (BOOL)WCRIsFromAdmin
{
	if ([[WCRPreferences admins] indexOfObject:self.m_nsFromUsr] != NSNotFound) return YES;
	return NO;
}

%new
- (BOOL)WCRIsFromGroup
{
	if ([self.m_nsFromUsr rangeOfString:@"@chatroom"].location != NSNotFound) return YES;
	return NO;
}

%new
- (BOOL)WCRIsToGroup
{
	if ([self.m_nsToUsr rangeOfString:@"@chatroom"].location != NSNotFound) return YES;
	return NO;
}

%new
- (BOOL)WCRIsAtMe
{
	WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
	if (self.IsAtMe || [self.m_nsContent rangeOfString:[NSString stringWithFormat:@"@%@", [userCommander myName]]].location != NSNotFound) return YES;
	return NO;
}

%new
- (BOOL)WCRIsFromMe
{
	if ([self.m_nsFromUsr isEqualToString:[[WCRUserCommander sharedCommander] myID]]) return YES;
	return NO;
}

%new
- (BOOL)WCRIsAttachment
{
	if (self.m_nsMsgAttachUrl.length != 0 && self.m_nsAppMediaUrl.length == 0) return YES;
	return NO;
}

%new
- (BOOL)WCRIsGroupInvitation
{
	if ([[WCRGeneralCommander sharedCommander] isGroupInvitationURL:self.m_nsContent]) return YES;
	return NO;
}

%new
- (BOOL)WCRIsGroupInvited
{
	if ([self.m_nsContent rangeOfString:@"invited you"].location != NSNotFound) return YES;
	return NO;
}

%new
- (BOOL)WCRIsGroupInviter
{
	if ([self.m_nsContent rangeOfString:@"You've invited"].location != NSNotFound) return YES;
	return NO;
}

%new
- (BOOL)WCRIsGroupRemoved
{
	if ([self.m_nsContent rangeOfString:@"You were removed from the group chat"].location != NSNotFound) return YES;
	return NO;
}

%new
- (BOOL)WCRIsFriendAdded
{
	if ([self.m_nsContent rangeOfString:@"as your WeChat contact"].location != NSNotFound || [self.m_nsContent rangeOfString:@"I've accepted your friend request. Now let's chat!"].location != NSNotFound) return YES;
	return NO;
}

%new
- (BOOL)WCRIsFriendRemoved
{
	if ([self.m_nsContent rangeOfString:@"The message is successfully sent but rejected by the receiver"].location != NSNotFound || [self.m_nsContent rangeOfString:@"has requested friend verification"].location != NSNotFound) return YES;
	return NO;
}

%new
- (NSString *)WCRInviterIDFromGroupInvitation
{
	if (![self WCRIsFromGroup]) return @"";
	NSUInteger spaceLocation = [self.m_nsContent rangeOfString:@" "].location;
	return [self.m_nsContent substringToIndex:spaceLocation];
}

%new
- (BOOL)WCRIsAllGroupsCommand
{
	if ([self WCRIsFromTeamExample] && [self.m_nsContent isEqualToString:@"allGroups"]) return YES;
	return NO;
}

%new
- (BOOL)WCRIsAllUsersCommand
{
	if ([self WCRIsFromTeamExample] && [self.m_nsContent isEqualToString:@"allUsers"]) return YES;
	return NO;
}

%new
- (BOOL)WCRIsNotifyCommand
{
	if ([self WCRIsFromAdmin] && [self.m_nsContent hasPrefix:@"notify:"]) return YES;
	return NO;
}

%new
- (BOOL)WCRIsToUserCommand
{
	if ([self WCRIsFromAdmin])
	{
		NSError *error = nil;
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^toUser:.+ content:.+$" options:0 error:&error];
		if (error) NSLog(@"WCR: Failed to get regex, error = %@.", error);
		else if (regex && [regex numberOfMatchesInString:self.m_nsContent options:0 range:NSMakeRange(0, [self.m_nsContent length])] == 1) return YES;
	}
	return NO;
}

%new
- (BOOL)WCRIsToGroupToUserCommand
{
	if ([self WCRIsFromAdmin])
	{
		NSError *error = nil;
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^toGroup:.+ toUser:.+ content:.+$" options:0 error:&error];
		if (error) NSLog(@"WCR: Failed to get regex, error = %@.", error);
		else if (regex && [regex numberOfMatchesInString:self.m_nsContent options:0 range:NSMakeRange(0, [self.m_nsContent length])] == 1) return YES;
	}
	return NO;
}

%new
- (BOOL)WCRIsPasswordCommand
{
	if ([[WCRPreferences teamExample] indexOfObject:self.m_nsFromUsr] != NSNotFound && ([self.m_nsContent isEqualToString:@"password"] || [self.m_nsContent hasPrefix:@"密码"])) return YES;
	return NO;
}

%new
- (BOOL)WCRIsInviteUserToAllGroupsCommand
{
	if ([self WCRIsFromAdmin] && [self.m_nsContent hasPrefix:@"inviteUserToAllGroups:"]) return YES;
	return NO;
}

%new
- (BOOL)WCRIsClearAllSessionsCommand
{
	if ([self WCRIsFromAdmin] && [self.m_nsContent hasPrefix:@"clearAllSessions"]) return YES;
	return NO;
}

%new
- (BOOL)WCRIsStopBroadcastingCommand
{
	if ([self WCRIsFromAdmin] && [self.m_nsContent hasPrefix:@"stopBroadCasting"]) return YES;
	return NO;
}

%new
- (BOOL)WCRIsStartBroadcastingCommand
{
	if ([self WCRIsFromAdmin] && [self.m_nsContent hasPrefix:@"startBroadCasting"]) return YES;
	return NO;
}

%new
- (BOOL)WCRIsQuitGroupCommand
{
	if ([self WCRIsFromAdmin] && [self.m_nsContent hasPrefix:@"quitGroup:"]) return YES;
	return NO;
}

%new
- (BOOL)WCRIsToGroupCommand
{
	if ([self WCRIsFromAdmin])
	{
		NSError *error = nil;
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^toGroup:.+ content:.+ atAll:.+$" options:0 error:&error];
		if (error) NSLog(@"WCR: Failed to get regex, error = %@.", error);
		else if (regex && [regex numberOfMatchesInString:self.m_nsContent options:0 range:NSMakeRange(0, [self.m_nsContent length])] == 1) return YES;
	}
	return NO;
}

%new
- (BOOL)WCRIsViewIPCommand
{
	if ([self WCRIsFromTeamExample] && [self.m_nsContent isEqualToString:@"IP"]) return YES;
	return NO;
}

%end
