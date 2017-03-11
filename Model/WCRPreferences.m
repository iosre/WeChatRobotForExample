#import "WCRGlobalHeader.h"

static NSDictionary *replies;
static NSArray *messageForwardees;
static NSDictionary *immuneGroups;
static NSArray *teamExample;
static NSArray *IFTKeywords;
static NSDictionary *forwardKeywords;
static NSMutableArray *promotionLinks;
static NSDictionary *miscellaneous;
static NSArray *names;
static NSDictionary *tulingURLs;
static NSDictionary *exampleWrapInfo;
static NSDictionary *welcomeMessageInfo;
static NSArray *admins;
static NSDictionary *robots;

@implementation WCRPreferences

+ (void)initSettings
{
	@autoreleasepool
	{
		NSString *settingsPath = [self settingsPath];
		NSString *bundlePath = [self bundlePath];
		NSString *usersPath = [self usersPath];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if (![fileManager fileExistsAtPath:usersPath])
		{
			NSError *error = nil;
			[fileManager createDirectoryAtPath:usersPath withIntermediateDirectories:YES attributes:nil error:&error];
			if (error) NSLog(@"WCR: Failed to create %@, error = %@.", usersPath, error);
		}
		for (NSString *fileName in @[@"admins.plist", @"IFTKeywords.plist", @"forwardKeywords.plist", @"immuneGroups.plist", @"messageForwardees.plist", @"miscellaneous.plist", @"names.plist", @"replies.plist", @"robots.plist", @"teamExample.plist", @"exampleWrap.plist", @"welcomeMessageInfo.plist", @"tulingURLs.plist", @"promotionLinks.plist"]) [WCRUtils copyFile:[bundlePath stringByAppendingPathComponent:fileName] toPath:[settingsPath stringByAppendingPathComponent:fileName]];
		[self saveAllUsers];

#if !__has_feature(objc_arc)			
		[replies release];
		[messageForwardees release];
		[immuneGroups release];
		[teamExample release];
		[IFTKeywords release];
		[forwardKeywords release];
		[promotionLinks release];
		[miscellaneous release];
		[names release];
		[tulingURLs release];
		[exampleWrapInfo release];
		[welcomeMessageInfo release];
		[admins release];
		[robots release];
#endif
		replies = nil;
		messageForwardees = nil;
		immuneGroups = nil;
		teamExample = nil;
		IFTKeywords = nil;
		forwardKeywords = nil;
		promotionLinks = nil;
		miscellaneous = nil;
		names = nil;
		tulingURLs = nil;
		exampleWrapInfo = nil;
		welcomeMessageInfo = nil;
		admins = nil;
		robots = nil;

		replies = [[NSDictionary alloc] initWithContentsOfFile:[settingsPath stringByAppendingPathComponent:@"replies.plist"]];
		messageForwardees = [[NSArray alloc] initWithContentsOfFile:[settingsPath stringByAppendingPathComponent:@"messageForwardees.plist"]];
		immuneGroups = [[NSDictionary alloc] initWithContentsOfFile:[settingsPath stringByAppendingPathComponent:@"immuneGroups.plist"]];
		teamExample = [[NSArray alloc] initWithContentsOfFile:[settingsPath stringByAppendingPathComponent:@"teamExample.plist"]];
		IFTKeywords = [[NSArray alloc] initWithContentsOfFile:[settingsPath stringByAppendingPathComponent:@"IFTKeywords.plist"]];
		forwardKeywords = [[NSDictionary alloc] initWithContentsOfFile:[settingsPath stringByAppendingPathComponent:@"forwardKeywords.plist"]];
		promotionLinks = [[NSMutableArray alloc] initWithContentsOfFile:[settingsPath stringByAppendingPathComponent:@"promotionLinks.plist"]];
		miscellaneous = [[NSDictionary alloc] initWithContentsOfFile:[settingsPath stringByAppendingPathComponent:@"miscellaneous.plist"]];
		names = [[NSArray alloc] initWithContentsOfFile:[settingsPath stringByAppendingPathComponent:@"names.plist"]];
		tulingURLs = [[NSDictionary alloc] initWithContentsOfFile:[settingsPath stringByAppendingPathComponent:@"tulingURLs.plist"]];
		exampleWrapInfo = [[NSDictionary alloc] initWithContentsOfFile:[settingsPath stringByAppendingPathComponent:@"exampleWrap.plist"]];
		welcomeMessageInfo = [[NSDictionary alloc] initWithContentsOfFile:[settingsPath stringByAppendingPathComponent:@"welcomeMessageInfo.plist"]];
		admins = [[NSArray alloc] initWithContentsOfFile:[settingsPath stringByAppendingPathComponent:@"admins.plist"]];
		robots = [[NSDictionary alloc] initWithContentsOfFile:[settingsPath stringByAppendingPathComponent:@"robots.plist"]];
	}
}

+ (NSString *)settingsPath
{
	NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	return [documentsPath stringByAppendingPathComponent:@"WCRSettings"];
}

+ (NSString *)usersPath
{
	return [[self settingsPath] stringByAppendingPathComponent:@"Users"];
}

+ (NSString *)bundlePath
{
	return @"/Library/Application Support/WeChatRobotForExample/WeChatRobotForExample.bundle";
}

+ (NSString *)chatHistoryPath
{
	return [[self settingsPath] stringByAppendingPathComponent:@"chatHistory.db"];
}

+ (NSDictionary *)tulingURLs
{
	return tulingURLs;
}

+ (NSMutableDictionary *)qrCodePathInfo
{
	return [@{} mutableCopy];
}

+ (NSDictionary *)exampleWrapInfo
{
	return exampleWrapInfo;
}	

+ (NSDictionary *)welcomeMessageInfo
{
	return welcomeMessageInfo;
}

+ (NSDictionary *)robots
{
	return robots;
}

+ (NSString *)greetingsWhenFriendsAdded
{
	return replies[@"greetingsWhenFriendsAdded"];
}

+ (NSString *)unrecognizedMessage
{
	return replies[@"unrecognizedMessage"];
}

+ (NSString *)exampleManual
{
	return replies[@"exampleManual"];
}

+ (NSString *)wrongCommand
{
	return replies[@"wrongCommand"];
}

+ (NSString *)reachedDailyBroadcastLimit
{
	return replies[@"reachedDailyBroadcastLimit"];
}

+ (NSString *)tooLate
{
	return replies[@"tooLate"];
}

+ (NSString *)groupExchange
{
	return replies[@"groupExchange"];
}

+ (NSString *)noBuildingFound
{
	return replies[@"noBuildingFound"];
}

+ (NSString *)promoteOfficialAccount
{
	return replies[@"promoteOfficialAccount"];
}

+ (NSString *)pleaseSendLater
{
	@autoreleasepool
	{
		NSDate *lastBroadcastDate = [[WCRMessageCommander sharedCommander] lastBroadcastDate];
		return [[NSString alloc] initWithFormat:replies[@"pleaseSendLater"], (int)([self broadcastInterval] - [[NSDate date] timeIntervalSinceDate:lastBroadcastDate]) / 60];
	}
}

+ (NSString *)goodNight
{
	return replies[@"goodNight"];
}

+ (NSArray *)invitationImmuneGroups
{
	return immuneGroups[@"invitation"];
}

+ (NSArray *)broadcastImmuneGroups
{
	return immuneGroups[@"broadcast"];
}

+ (NSArray *)messageForwardees
{
	return messageForwardees;
}

+ (NSArray *)teamExample
{
	return teamExample;
}

+ (NSArray *)admins
{
	return admins;
}

+ (NSArray *)IFTKeywords
{
	return IFTKeywords;
}

+ (NSArray *)blackForwardKeywords
{
	return forwardKeywords[@"blacklist"];
}

+ (NSArray *)whiteForwardKeywords
{
	return forwardKeywords[@"whitelist"];
}

+ (NSTimeInterval)broadcastInterval
{
	return ((NSNumber *)(miscellaneous[@"broadcastInterval"])).doubleValue;
}

+ (NSArray *)promotionLinks
{
	[promotionLinks removeObject:@""];
	return promotionLinks;
}

+ (NSString *)randomName
{
	return names[arc4random_uniform(names.count + 1) - 1];
}

+ (NSString *)broadcastPassport
{
	return miscellaneous[@"broadcastPassport"];
}

+ (NSString *)exampleConversation
{
	return miscellaneous[@"exampleConversation"];
}

+ (int)onDutyTime
{
	return ((NSNumber *)miscellaneous[@"onDutyTime"]).intValue;
}

+ (int)offDutyTime
{
	return ((NSNumber *)miscellaneous[@"offDutyTime"]).intValue;
}

+ (int)dailyBroadcastLimit
{
	return ((NSNumber *)miscellaneous[@"dailyBroadcastLimit"]).intValue;
}

+ (void)saveUserWithMessageWrap:(CMessageWrap *)wrap
{
	@autoreleasepool
	{
		NSString *userID = wrap.m_nsFromUsr;
		NSString *usersPath = [[self usersPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", userID]];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if (![fileManager fileExistsAtPath:usersPath]) [@{} writeToFile:usersPath atomically:YES];
	}
}

+ (void)saveAllUsers
{
	WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
	for (NSString *userID in [userCommander allUsers])
	{
		@autoreleasepool
		{
			NSString *usersPath = [[self usersPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", userID]];
			NSFileManager *fileManager = [NSFileManager defaultManager];
			if (![fileManager fileExistsAtPath:usersPath]) [@{} writeToFile:usersPath atomically:YES];
		}
	}
}

+ (void)reachUserLimitation:(NSString *)userID
{
	@autoreleasepool
	{
		NSString *usersPath = [[self usersPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", userID]];
		NSMutableDictionary *userSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:usersPath];
		NSString *key = [WCRUtils today];
		int count = ((NSNumber *)userSettings[key]).intValue;
		userSettings[key] = @(count + 1);
		[userSettings writeToFile:usersPath atomically:YES];
#if !__has_feature(objc_arc)
		[userSettings release];
#endif
		userSettings = nil;
	}
}

+ (BOOL)isUserLimited:(NSString *)userID
{
	@autoreleasepool
	{
		NSString *usersPath = [[self usersPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", userID]];
		NSDictionary *userSettings = [[NSDictionary alloc] initWithContentsOfFile:usersPath];
		NSString *key = [WCRUtils today];
		int count = ((NSNumber *)userSettings[key]).intValue;
#if !__has_feature(objc_arc)
		[userSettings release];
#endif
		userSettings = nil;
		if (count >= [self dailyBroadcastLimit]) return YES;
		return NO;
	}	
}

+ (BOOL)isBroadcastTooFrequent
{
	@autoreleasepool
	{
		NSDate *lastBroadcastDate = [[WCRMessageCommander sharedCommander] lastBroadcastDate];
		if ([[NSDate date] timeIntervalSinceDate:lastBroadcastDate] < [self broadcastInterval]) return YES;
		return NO;
	}
}

+ (BOOL)isTooLate
{
	@autoreleasepool
	{
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		formatter.dateFormat = @"HH";
		NSString *currentDate = [formatter stringFromDate:[NSDate date]];		
#if !__has_feature(objc_arc)			
		[formatter release];
#endif
		formatter = nil;
		if (currentDate.intValue >= [self offDutyTime] || currentDate.intValue <= [self onDutyTime]) return YES;
		return NO;
	}
}

@end
