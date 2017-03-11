#import "WCRGlobalHeader.h"

static WCRGroupCommander *sharedCommander;

@implementation WCRGroupCommander

@synthesize webView;

- (instancetype)init
{
	if (self = [super init])
	{
		webView = [[UIWebView alloc] init];
		webView.delegate = self;
	}
	return self;
}

+ (void)initialize
{
	if (self == [WCRGroupCommander class]) sharedCommander = [[self alloc] init];
}

+ (instancetype)sharedCommander
{
	return sharedCommander;
}

- (void)acceptGroupInvitationFromURL:(NSString *)URLString
{
	@autoreleasepool
	{
		NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
		[self.webView loadRequest:request];
#if !__has_feature(objc_arc)
		[request release];
#endif
		request = nil;
	}
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[self.webView stringByEvaluatingJavaScriptFromString:@"submit()"];
}

- (NSArray *)allGroups
{
	NSMutableArray *groupIDs = [[NSMutableArray alloc] initWithCapacity:66];
	for (CContact *contact in [self allContacts])
	{
		@autoreleasepool
		{
			NSString *userID = contact.m_nsUsrName;
			if ([userID rangeOfString:@"@chatroom"].location != NSNotFound)
			{
				if ([self memberCountsOfGroup:userID] > 2) [groupIDs addObject:userID];
				else [self quitGroup:userID];
			}
		}
	}
	return groupIDs;
}

- (NSString *)allGroupsDescription
{
	@autoreleasepool
	{
		NSArray *groupIDs = [self allGroups];
		NSMutableString *allGroupsDescription = [@"" mutableCopy];
		for (int i = 0; i < groupIDs.count; i++)
		{
			@autoreleasepool
			{
				[allGroupsDescription appendString:[NSString stringWithFormat:@"%d. %@（%@）（%tu人）\r", i + 1, [self nameOfUser:groupIDs[i]], groupIDs[i], [self memberCountsOfGroup:groupIDs[i]]]];
			}
		}
		if ([allGroupsDescription hasSuffix:@"\r"]) [allGroupsDescription deleteCharactersInRange:NSMakeRange(allGroupsDescription.length - 1, 1)];
#if !__has_feature(objc_arc)			
		return [allGroupsDescription autorelease];
#else
		return allGroupsDescription;
#endif
	}
}

- (NSArray *)membersOfGroup:(NSString *)groupID;
{
	CGroupMgr *manager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CGroupMgr") class]];
	return [manager GetGroupMember:groupID];
}

- (NSUInteger)memberCountsOfGroup:(NSString *)groupID
{
	return [self membersOfGroup:groupID].count;
}

- (void)inviteUserToRandomGroup:(NSString *)userID
{
	CGroupMgr *manager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CGroupMgr") class]];
	WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
	for (NSString *groupID in [self allGroups])
	{
		if ([userCommander amIInGroup:groupID] && ![manager IsUsrInChatRoom:groupID Usr:userID] && [[WCRPreferences invitationImmuneGroups] indexOfObject:groupID] == NSNotFound)
		{
			[globalQueue addOperationWithBlock:^{
				@autoreleasepool
				{
					if ([userCommander amIInGroup:groupID] && ![manager IsUsrInChatRoom:groupID Usr:userID] && [[WCRPreferences invitationImmuneGroups] indexOfObject:groupID] == NSNotFound)
					{
						[manager InviteGroupMember:groupID withMemberList:@[userID]];
						sleep(2);
					}
				}
			}];
			break;
		}
	}
}

- (void)inviteUserToAllGroups:(NSString *)userID
{
	NSArray *allGroups = [self allGroups];
	[self inviteUser:userID toGroups:allGroups];
}

- (void)inviteUser:(NSString *)userID toGroups:(NSArray *)groupIDs
{
	CGroupMgr *manager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CGroupMgr") class]];
	WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
	for (NSString *groupID in groupIDs)
	{
		[globalQueue addOperationWithBlock:^{
			@autoreleasepool
			{
				if ([userCommander amIInGroup:groupID] && ![manager IsUsrInChatRoom:groupID Usr:userID] && [[WCRPreferences invitationImmuneGroups] indexOfObject:groupID] == NSNotFound)
				{
					[manager InviteGroupMember:groupID withMemberList:@[userID]];
					sleep(2);
				}
			}
		}];
	}
}

- (void)introduceGroup:(NSString *)groupID toUsers:(NSArray *)userIDs
{
	@autoreleasepool
	{
		WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
		if ([userCommander amIInGroup:groupID] && [[WCRPreferences invitationImmuneGroups] indexOfObject:groupID] == NSNotFound)
		{
			CGroupMgr *manager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CGroupMgr") class]];	
			NSMutableArray *realUserIDs = [NSMutableArray arrayWithArray:userIDs];
			NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
			for (NSUInteger i = 0; i < userIDs.count; i++)
				if ([userCommander amIInGroup:groupID] && [manager IsUsrInChatRoom:groupID Usr:userIDs[i]])
					[indexSet addIndex:i];
			[realUserIDs removeObjectsAtIndexes:indexSet];

			if (realUserIDs.count <= 9) [manager InviteGroupMember:groupID withMemberList:realUserIDs];
			else
			{
				for (NSString *userID in realUserIDs)
				{
					[globalQueue addOperationWithBlock:^{
						@autoreleasepool
						{
							if ([userCommander amIInGroup:groupID] && ![manager IsUsrInChatRoom:groupID Usr:userID] && [[WCRPreferences invitationImmuneGroups] indexOfObject:groupID] == NSNotFound)
							{						
								[manager InviteGroupMember:groupID withMemberList:@[userID]];
								sleep(2);
							}
						}
					}];
				}
			}
		}
	}
}

- (void)introduceGroupToAllUsers:(NSString *)groupID
{
	WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
	NSArray *allUsers = [userCommander allUsers];
	[self introduceGroup:groupID toUsers:allUsers];
}

- (void)muteGroup:(NSString *)groupID
{
	@autoreleasepool
	{
		WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
		if ([userCommander amIInGroup:groupID])
		{	
			DelaySwitchSettingLogic *logic = [[objc_getClass("DelaySwitchSettingLogic") alloc] init];
			[logic chatProfileSwitchSetting:groupID withType:2 andValue:0];
#if !__has_feature(objc_arc)		
			[logic release];
#endif
			logic = nil;
		}
	}
}

- (void)saveGroup:(NSString *)groupID;
{
	@autoreleasepool
	{
		WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
		if ([userCommander amIInGroup:groupID])
		{	
			DelaySwitchSettingLogic *logic = [[objc_getClass("DelaySwitchSettingLogic") alloc] init];
			[logic chatProfileSwitchSetting:groupID withType:3 andValue:1];
#if !__has_feature(objc_arc)		
			[logic release];
#endif
			logic = nil;
		}
	}
}

- (void)saveAllGroups
{
	@autoreleasepool
	{
		MMNewSessionMgr *sessionManager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("MMNewSessionMgr") class]];
		NSMutableArray *m_arrSession;
#if !__has_feature(objc_arc)		
		object_getInstanceVariable(sessionManager, "m_arrSession", (void **)&m_arrSession);
#else
		Ivar ivar = class_getInstanceVariable(objc_getClass("MMNewSessionMgr"), "m_arrSession");
		m_arrSession = object_getIvar(sessionManager, ivar);
#endif
		for (MMSessionInfo *sessionInfo in m_arrSession)
		{
			NSString *groupID = sessionInfo.m_nsUserName;
			if ([groupID rangeOfString:@"@chatroom"].location != NSNotFound) [self saveGroup:groupID];
		}
	}
}

- (void)muteAllGroups
{
	for (NSString *groupID in [self allGroups]) [self muteGroup:groupID];
}

- (void)quitGroup:(NSString *)groupID
{
	WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
	CGroupMgr *groupMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CGroupMgr") class]];
	[groupMgr QuitGroup:groupID withUsrName:[userCommander myID]];
}

- (void)inviteGodsonToAllGroups
{
	[self inviteUserToAllGroups:[WCRPreferences robots][@"godson"]];	
}

#if !__has_feature(objc_arc)		
- (void)dealloc
{
	[webView release];
	webView = nil;

	[super dealloc];
}
#endif

@end
