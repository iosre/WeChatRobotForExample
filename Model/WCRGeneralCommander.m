#import "WCRGlobalHeader.h"

static WCRGeneralCommander *sharedCommander;

@implementation WCRGeneralCommander

@synthesize conversation;
@synthesize dailyPromotionIndex;
@synthesize qrCodeDownloadCallback;

- (instancetype)init
{
	if (self = [super init])
	{
		NSDictionary *miscellaneous = [[NSDictionary alloc] initWithContentsOfFile:[[WCRPreferences settingsPath] stringByAppendingPathComponent:@"miscellaneous.plist"]];
		dailyPromotionIndex = ((NSNumber *)(miscellaneous[@"dailyPromotionIndex"])).unsignedIntegerValue;
		NSString *filePath = [[WCRPreferences settingsPath] stringByAppendingPathComponent:@"示例对话.txt"];
		NSError *error = nil;
		conversation = [[NSMutableString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
		if (error)
		{
			NSLog(@"WCR: Failed to initialize conversation, error = %@.", error);
#if !__has_feature(objc_arc)	
			[conversation release];
#endif
			conversation = nil;
			conversation = [@"" mutableCopy];
		}
#if !__has_feature(objc_arc)	
		[miscellaneous release];
#endif
		miscellaneous = nil;
	}
	return self;
}

+ (void)initialize
{
	if (self == [WCRGeneralCommander class]) sharedCommander = [[self alloc] init];
}

+ (instancetype)sharedCommander
{
	return sharedCommander;
}

- (NSArray *)allContacts
{
	CContactMgr *manager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CContactMgr") class]];
	return [manager getContactList:1 contactType:0 domain:nil];
}

- (NSString *)nameOfUser:(NSString *)userID
{
	return [self nameOfUser:userID inGroup:nil];
}

- (NSString *)nameOfUser:(NSString *)userID inGroup:(NSString *)groupID
{
	@autoreleasepool
	{
		NSString *userName = @"";
		CContactMgr *contactManager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CContactMgr") class]];
		CGroupMgr *groupManager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CGroupMgr") class]];
		CContact *userContact = [contactManager getContactByName:userID];
		if (!groupID) userName = userContact.m_nsNickName;
		else
		{
			CContact *groupContact = [contactManager getContactByName:groupID];
			if (groupContact && [groupManager IsUsrInChatRoom:groupID Usr:userID])
			{
				userName = [groupContact getChatRoomMembrGroupNickName:userContact];
				if (userName.length == 0) userName = [groupContact getChatRoomMemberNickName:userContact];
			}
		}
		if (userName.length == 0) userName = userID;
		return userName;
	}
}

- (void)maskMyselfInGroup:(NSString *)groupID // Change my nickname and group remark
{
	@autoreleasepool
	{
		NSString *newNickName = [WCRPreferences randomName];
		NewSyncService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("NewSyncService") class]];
		WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
		if ([service respondsToSelector:@selector(StartOplog:Oplog:)])
		{
			ModChatRoomMemberDisplayName *groupName = [[objc_getClass("ModChatRoomMemberDisplayName") alloc] init];
			groupName.chatRoomName = groupID;
			groupName.displayName = newNickName;
			groupName.userName = [userCommander myID];
			[service StartOplog:48 Oplog:[groupName serializedData]];
#if !__has_feature(objc_arc)
			[groupName release];
#endif
			groupName = nil;
			ModSingleField *userName = [[objc_getClass("ModSingleField") alloc] init];
			userName.opType = 1;
			userName.value = newNickName;
			[service StartOplog:64 Oplog:[userName serializedData]];
#if !__has_feature(objc_arc)
			[userName release];
#endif
			userName = nil;
		}
		else
		{
			CGroupMgr *groupManager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CGroupMgr") class]];
			[groupManager SetDislayName:newNickName forGroup:groupID];

			CUsrInfo *usrInfo = [[objc_getClass("CUsrInfo") alloc] init];
			CContactMgr *contactManager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CContactMgr") class]];
			CContact *myself = [contactManager getSelfContact];
			usrInfo.m_nsNickName = newNickName;
			usrInfo.m_nsCity = myself.m_nsCity;
			usrInfo.m_nsCountry = myself.m_nsCountry;
			usrInfo.m_nsProvince = myself.m_nsProvince;
			usrInfo.m_nsSignature = myself.m_nsSignature;
			usrInfo.m_uiSex = myself.m_uiSex;
			[objc_getClass("UpdateProfileMgr") modifyUserInfo:usrInfo];
#if !__has_feature(objc_arc)
			[usrInfo release];
#endif
			usrInfo = nil;
		}
	}
}

- (BOOL)amIInGroup:(NSString *)groupID
{
	@autoreleasepool
	{
		WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
		CGroupMgr *groupMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CGroupMgr") class]];
		if ([groupMgr IsUsrInChatRoom:groupID Usr:[userCommander myID]]) return YES;
		return NO;
	}
}


- (void)saveConversation
{
	@autoreleasepool
	{
		NSError *error = nil;
		NSString *filePath = [[WCRPreferences settingsPath] stringByAppendingPathComponent:@"示例对话.txt"];
		[self.conversation writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
		if (error) NSLog(@"WCR: Failed to save conversation locally, error = %@.", error);
		{
			KxSMBProvider *provider = [KxSMBProvider sharedSmbProvider];
			KxSMBAuth *auth = [KxSMBAuth smbAuthWorkgroup:nil username:@"smb" password:[WCRUtils password]];
			NSString *destinationPath = [WCRPreferences exampleConversation];
			[provider copyLocalPath:filePath smbPath:destinationPath overwrite:YES auth:auth block:^(id result)
			{
				if ([result isKindOfClass:[NSError class]]) NSLog(@"WCR: Failed to copy %@ to %@, error = %@.", filePath, destinationPath, result);
			}];
		}
	}	
}

- (BOOL)isGroupInvitationURL:(NSString *)URLString
{
	if ([URLString rangeOfString:@".weixin.qq.com/cgi-bin/mmsupport-bin/addchatroombyinvite"].location != NSNotFound) return YES;
	return NO;
}

- (void)scheduleNotifications
{
	@autoreleasepool
	{
		[[UIApplication sharedApplication] cancelAllLocalNotifications];
		[[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeNone categories:nil]];

		NSCalendar *calendar = [NSCalendar currentCalendar];
		calendar.timeZone = [NSTimeZone systemTimeZone];
		NSDateComponents *components = [[NSCalendar currentCalendar] components:(kCFCalendarUnitDay | kCFCalendarUnitMonth | kCFCalendarUnitYear) fromDate:[NSDate date]];
		NSInteger day = components.day;
		NSInteger month = components.month;
		NSInteger year = components.year;
		components.day = day;
		components.month = month;
		components.year = year;
		components.second = 0;
		components.minute = 0;

		components.hour = 2;
		NSDate *dateToFire = [calendar dateFromComponents:components];
		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
		localNotification.timeZone = [NSTimeZone systemTimeZone];
		localNotification.repeatInterval = kCFCalendarUnitDay;
		localNotification.fireDate = dateToFire;
		localNotification.userInfo = @{@"WCREvent" : @"saveConversation"};
		[[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
#if !__has_feature(objc_arc)		
		[localNotification release];
#endif
		localNotification = nil;
		components.hour = 8;
		dateToFire = [calendar dateFromComponents:components];
		localNotification = [[UILocalNotification alloc] init];
		localNotification.timeZone = [NSTimeZone systemTimeZone];
		localNotification.repeatInterval = kCFCalendarUnitDay;
		localNotification.fireDate = dateToFire;
		localNotification.userInfo = @{@"WCREvent" : @"weather"};
		[[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
#if !__has_feature(objc_arc)		
		[localNotification release];
#endif
		localNotification = nil;
		components.hour = 9;
		dateToFire = [calendar dateFromComponents:components];
		localNotification = [[UILocalNotification alloc] init];
		localNotification.timeZone = [NSTimeZone systemTimeZone];
		localNotification.repeatInterval = kCFCalendarUnitDay;
		localNotification.fireDate = dateToFire;
		localNotification.userInfo = @{@"WCREvent" : @"morning"};
		[[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
#if !__has_feature(objc_arc)		
		[localNotification release];
#endif
		localNotification = nil;
		components.hour = 22;
		dateToFire = [calendar dateFromComponents:components];
		localNotification = [[UILocalNotification alloc] init];
		localNotification.timeZone = [NSTimeZone systemTimeZone];
		localNotification.repeatInterval = kCFCalendarUnitDay;
		localNotification.fireDate = dateToFire;
		localNotification.userInfo = @{@"WCREvent" : @"goodNight"};
		[[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
#if !__has_feature(objc_arc)		
		[localNotification release];
#endif
		localNotification = nil;
	}
}

- (void)handleNotification:(UILocalNotification *)notification
{
	@autoreleasepool
	{
		if ([notification.userInfo[@"WCREvent"] isEqualToString:@"clearAllSessions"]) [self clearAllSessions];
		else if ([notification.userInfo[@"WCREvent"] isEqualToString:@"saveConversation"]) [self saveConversation];
		else
		{
			WCRMessageCommander *messageCommander = [WCRMessageCommander sharedCommander];
			NSString *messageContent = nil;
			if ([notification.userInfo[@"WCREvent"] isEqualToString:@"weather"])
			{
				NSMutableString *weather = [[NSMutableString alloc] initWithString:[messageCommander autoReplyForContent:@"上海天气"]];
				[weather replaceOccurrencesOfString:@":" withString:@"：" options:NSCaseInsensitiveSearch range:NSMakeRange(0, weather.length)];
				[weather replaceOccurrencesOfString:@"," withString:@"，" options:NSCaseInsensitiveSearch range:NSMakeRange(0, weather.length)];
				[weather replaceOccurrencesOfString:@";" withString:@"；" options:NSCaseInsensitiveSearch range:NSMakeRange(0, weather.length)];
				messageContent = [NSString stringWithFormat:@"早上好！本周天气早知道~\n%@今天也要加油哦~", weather];
#if !__has_feature(objc_arc)		
				[weather release];
#endif
				weather = nil;
			}
			else if ([notification.userInfo[@"WCREvent"] isEqualToString:@"goodNight"]) messageContent = [WCRPreferences goodNight];
			else if ([notification.userInfo[@"WCREvent"] isEqualToString:@"morning"])
			{
				messageContent = [WCRPreferences promotionLinks][self.dailyPromotionIndex];
				[messageCommander saveLastBroadcastDate];
			}
			if (messageContent.length != 0)
			{
				WCRGroupCommander *groupCommander = [WCRGroupCommander sharedCommander];
				WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
				NSArray *groups = [groupCommander allGroups];
				for (NSString *groupID in groups)
				{
					if ([userCommander amIInGroup:groupID])
					{
						CMessageWrap *newWrap = nil;
						if ([messageContent hasPrefix:@"http://"] || [messageContent hasPrefix:@"https://"]) newWrap = [messageCommander wrapForURL:messageContent toUser:groupID];
						else newWrap = [logicController FormTextMsg:groupID withText:messageContent];

						if ([[WCRPreferences broadcastImmuneGroups] indexOfObject:groupID] != NSNotFound)
						{
							if ([notification.userInfo[@"WCREvent"] isEqualToString:@"weather"]) newWrap = [logicController FormTextMsg:groupID withText:@"早上好！今天也要加油哦~"];
							else if ([notification.userInfo[@"WCREvent"] isEqualToString:@"morning"]) newWrap = nil;
						}

						if (newWrap) [messageCommander sendMessage:newWrap];
					}
				}
				self.dailyPromotionIndex = (self.dailyPromotionIndex + 1) % [WCRPreferences promotionLinks].count;
				[self saveDailyPromotionIndex];
			}
		}
	}
}

- (void)promptDoNotDisturb
{
	@autoreleasepool
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"正在工作" message:@"请勿触碰" delegate:self cancelButtonTitle:@"好的，我保证不碰☺️" otherButtonTitles:nil];
		[alertView show];
#if !__has_feature(objc_arc)		
		[alertView release];
#endif
		alertView = nil;
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
		[WCRPreferences initSettings];
	});
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[self promptDoNotDisturb];
	});
}

- (void)clearAllSessions
{
	@autoreleasepool
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{		
			if (globalQueue.operationCount == 0)
			{
				MMNewSessionMgr *manager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("MMNewSessionMgr") class]];
				[manager DeleteAllSession];
				globalQueue.suspended = NO;
				NSLog(@"WCR: Queue is unsuspended by clearAllSessions.");
			}
		});
	}	
}

- (void)saveDailyPromotionIndex
{
	@autoreleasepool
	{
		NSString *filePath = [[WCRPreferences settingsPath] stringByAppendingPathComponent:@"miscellaneous.plist"];
		NSMutableDictionary *miscellaneous = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
		miscellaneous[@"dailyPromotionIndex"] = @(self.dailyPromotionIndex);
		[miscellaneous writeToFile:filePath atomically:YES];
#if !__has_feature(objc_arc)		
		[miscellaneous release];
#endif
		miscellaneous = nil;
	}
}

- (void)downloadQRCodeOfUser:(NSString *)userID withCompletion:(QRCodeDownloadCallback)completion
{
	@autoreleasepool
	{
		MMQRCodeMgr *qrCodeManager = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("MMQRCodeMgr") class]];
		[qrCodeManager getQRCodeFromServer:userID withStyle:6];
		self.qrCodeDownloadCallback = nil;
		self.qrCodeDownloadCallback = completion;
	}
}

- (void)saveQRCodePathOfUser:(NSString *)userID
{
	@autoreleasepool
	{
		[self downloadQRCodeOfUser:userID withCompletion:^(NSString *path)
		{
		}];
	}
}

#if !__has_feature(objc_arc)		
- (void)dealloc
{
	[conversation release];
	conversation = nil;

	[super dealloc];
}
#endif

@end
