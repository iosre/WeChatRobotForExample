#import "WCRGlobalHeader.h"

@implementation WCRTempGenerator

+ (void)generateDataForFeiWen
{
	@autoreleasepool
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{		
			WCRGroupCommander *groupCommander = [WCRGroupCommander sharedCommander];
			WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
			NSArray *allGroupIDs = [groupCommander allGroups];
			NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"allUsersInAllGroups.csv"];
			NSMutableString *groupInfoString = [@"Group ID,Group Name,User ID,User Name,Godson's Contact\r\n" mutableCopy];
			for (NSString *groupID in allGroupIDs)
			{
				for (CContact *member in [groupCommander membersOfGroup:groupID])
				{
					NSString *userID = member.m_nsUsrName;
					[groupInfoString appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\",\"%@\"\r\n", groupID, [[userCommander nameOfUser:groupID] stringByReplacingOccurrencesOfString:@"\"" withString:@"'"], userID, [[userCommander nameOfUser:userID] stringByReplacingOccurrencesOfString:@"\"" withString:@"'"], @([userCommander isContact:userID])];
				}
			}
			NSError *error = nil;
			[groupInfoString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
			if (error) NSLog(@"WCR: Failed to write file to %@, error = %@.", filePath, error);
#if !__has_feature(objc_arc)			
			[groupInfoString release];
#endif
			groupInfoString = nil;
		});
	}		
}

+ (void)generateAllUsersFromAllGroups
{
	@autoreleasepool
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{		
			WCRGroupCommander *groupCommander = [WCRGroupCommander sharedCommander];
			NSMutableString *allUsersFromAllGroups = [@"ID,user_name\r\n" mutableCopy];
			NSMutableSet *allUniqueUsers = [NSMutableSet setWithCapacity:9999];
			NSArray *allGroups = [groupCommander allGroups];
			for (NSString *groupID in allGroups)
			{
				NSArray *membersOfGroup = [groupCommander membersOfGroup:groupID];
				for (CContact *member in membersOfGroup)
				{
					NSString *userID = member.m_nsUsrName;
					[allUniqueUsers addObject:userID];
					[allUsersFromAllGroups appendFormat:@"%@,\"%@\"\r\n", userID, [[groupCommander nameOfUser:userID inGroup:groupID] stringByReplacingOccurrencesOfString:@"\"" withString:@"'"]];
				}
			}
			NSLog(@"WCR: %tu users in all groups.", allUniqueUsers.count);
			NSError *error;
			[allUsersFromAllGroups writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"allUsersFromAllGroups.csv"] atomically:YES encoding:NSUTF8StringEncoding error:&error];
			if (error) NSLog(@"WCR: Failed to write file to allUsersFromAllGroups.csv, error = %@.", error);
#if !__has_feature(objc_arc)			
			[allUsersFromAllGroups release];
			[allUniqueUsers release];
#endif
			allUsersFromAllGroups = nil;
			allUniqueUsers = nil;
		});
	}
}

+ (void)testVoiceTrans
{
	CMessageWrap *wrap = [globalMessageMgr GetLastMsgFromUsr:@"wxid_4193851938311"];
	WCRVoiceProcessor *voiceProcessor = [WCRVoiceProcessor sharedProcessor];
	[voiceProcessor convertVoiceWrap:wrap completion:^(NSString *text)
	{
		NSLog(@"WCRDebug: %@", text);
	}];
}

@end
