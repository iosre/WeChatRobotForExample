#import "WCRGlobalHeader.h"

static WCRUserCommander *sharedCommander;

@implementation WCRUserCommander

@synthesize contactSearchCallback;
@synthesize cellInfo;
@synthesize bar;
@synthesize uiBar;

- (instancetype)init
{
	if (self = [super init])
	{
		cellInfo = [[objc_getClass("FindContactSearchViewCellInfo") alloc] init];
		bar = [[objc_getClass("MMSearchBar") alloc] init];
		uiBar = [[objc_getClass("MMUISearchBar") alloc] init];
	}
	return self;
}

+ (void)initialize
{
	if (self == [WCRUserCommander class]) sharedCommander = [[self alloc] init];
}

+ (instancetype)sharedCommander
{
	return sharedCommander;
}

- (NSString *)myName
{
	CContactMgr *manager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CContactMgr") class]];
	CContact *myself = [manager getSelfContact];
	return myself.m_nsNickName;
}

- (NSString *)myID
{
	return [objc_getClass("SettingUtil") getLocalUsrName:0];
}

- (void)encodeUserAlias:(NSString *)userID // Change contact's remark to userID
{
	@autoreleasepool
	{
		CContactMgr *contactManager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CContactMgr") class]];
		CContact *userContact = [contactManager getContactByName:userID];
		userContact.m_nsRemark = userContact.m_nsUsrName;
		[contactManager setContact:userContact remark:userContact.m_nsRemark hideHashPhone:NO];
	}
}

- (NSArray *)allUsers
{
	NSMutableArray *userIDs = [NSMutableArray arrayWithCapacity:66];
	for (CContact *contact in [self allContacts])
	{
		@autoreleasepool
		{
			NSString *userID = contact.m_nsUsrName;
			BOOL isStockContact = contact.m_uiType == 3 ? YES : NO;
			if (!isStockContact && [userID rangeOfString:@"@chatroom"].location == NSNotFound) [userIDs addObject:userID];
		}
	}
	return userIDs;
}

- (NSString *)allUsersDescription
{
	NSArray *userIDs = [self allUsers];
	NSMutableString *allUsersDescription = [@"" mutableCopy];
	for (int i = 0; i < userIDs.count; i++)
	{
		@autoreleasepool
		{
			[allUsersDescription appendString:[NSString stringWithFormat:@"%d. %@（%@）\r", i + 1, [self nameOfUser:userIDs[i]], userIDs[i]]];
		}
	}
	if ([allUsersDescription hasSuffix:@"\r"]) [allUsersDescription deleteCharactersInRange:NSMakeRange(allUsersDescription.length - 1, 1)];
#if !__has_feature(objc_arc)			
	return [allUsersDescription autorelease];
#else
	return allUsersDescription;
#endif
}

- (BOOL)isAdmin:(NSString *)userID
{
	@autoreleasepool
	{
		if ([[WCRPreferences admins] indexOfObject:userID] != NSNotFound) return YES;
		return NO;
	}
}

- (void)deleteUserAndSession:(NSString *)userID
{
	@autoreleasepool
	{
		CContactMgr *contactManager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CContactMgr") class]];
		CContact *userContact = [contactManager getContactByName:userID];
		[contactManager deleteContact:userContact listType:3];
		MMNewSessionMgr *sessionManager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("MMNewSessionMgr") class]];
		[sessionManager DeleteSessionOfUser:userID];
	}
}

- (BOOL)isContact:(NSString *)userID
{
	@autoreleasepool
	{
		CContactMgr *contactManager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CContactMgr") class]];
		if (![contactManager getContactByName:userID]) return NO;
		return YES;
	}
}

- (void)searchUser:(NSString *)userID completion:(ContactSearchCallback)completion
{
	@autoreleasepool
	{
		self.uiBar.text = userID;
		bar.m_searchBar = self.uiBar;
		Ivar m_searchBar = class_getInstanceVariable(objc_getClass("FindContactSearchViewCellInfo"), "m_searchBar");
		object_setIvar(cellInfo, m_searchBar, bar);
		[self.cellInfo doSearch];
		[self.cellInfo stopLoading];
		self.contactSearchCallback = nil;
		self.contactSearchCallback = completion;
	}
}

- (void)tryAddingUser:(NSString *)userID withGreetings:(NSString *)greetings
{
	__unsafe_unretained __block WCRUserCommander *weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{			
		__block CContact *resultContact;
		__block NSCondition *condition = [[NSCondition alloc] init];
		[condition lock];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{		
			[weakSelf searchUser:userID completion:^(CContact *contact)
			{
				[condition lock];
				resultContact = contact;
				[condition signal];
				[condition unlock];
			}];
		});
		[condition wait];
		[condition unlock];
#if !__has_feature(objc_arc)
		[condition release];
#endif
		condition = nil;
		if (resultContact)
		{
			CVerifyContactWrap *wrap = [[objc_getClass("CVerifyContactWrap") alloc] init];
			wrap.m_oVerifyContact = resultContact;
			wrap.m_nsUsrName = wrap.m_oVerifyContact.m_nsUsrName;
			if ([wrap.m_nsUsrName rangeOfString:@"@stranger"].location == NSNotFound) NSLog(@"WCR: Already added %@ as a contact, ignore it.", resultContact);
			else
			{
				wrap.m_uiScene = wrap.m_oVerifyContact.m_uiFriendScene;
				wrap.m_uiWCFlag = wrap.m_oVerifyContact.m_iWCFlag;
				CContactVerifyLogic *logic = [[objc_getClass("CContactVerifyLogic") alloc] init];

				Ivar m_arrVerifyContactWrap = class_getInstanceVariable(objc_getClass("CContactVerifyLogic"), "m_arrVerifyContactWrap");
				object_setIvar(logic, m_arrVerifyContactWrap, @[wrap]);

				Ivar m_nsVerifyValue = class_getInstanceVariable(objc_getClass("CContactVerifyLogic"), "m_nsVerifyValue");
				object_setIvar(logic, m_nsVerifyValue, greetings);

				Ivar m_uiOpCode = class_getInstanceVariable(objc_getClass("CContactVerifyLogic"), "m_uiOpCode");
				CFTypeRef logicRef = CFBridgingRetain(logic);
				NSUInteger *ivarPtr = (NSUInteger *)(logicRef + ivar_getOffset(m_uiOpCode));
				*ivarPtr = 2;

				Ivar m_uiFriendScene = class_getInstanceVariable(objc_getClass("CContactVerifyLogic"), "m_uiFriendScene");
				ivarPtr = (NSUInteger *)(logicRef + ivar_getOffset(m_uiFriendScene));
				*ivarPtr = wrap.m_uiScene;
				CFBridgingRelease(logicRef);

				[logic doVerify:greetings];
				NSLog(@"WCR: Sent friend request to %@.", resultContact);
#if !__has_feature(objc_arc)		
				[logic release];
#endif
				logic = nil;
			}
#if !__has_feature(objc_arc)		
			[wrap release];
#endif
			wrap = nil;
		}
		else NSLog(@"WCR: No contacts found for %@.", userID);
	});			
}

#if !__has_feature(objc_arc)		
- (void)dealloc
{
	[cellInfo release];
	cellInfo = nil;

	[bar release];
	bar = nil;

	[uiBar release];
	uiBar = nil;

	[super dealloc];
}
#endif

@end
