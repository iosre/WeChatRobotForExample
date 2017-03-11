#import "WCRGlobalHeader.h"

static WCRDBManager *defaultManager;

@implementation WCRDBManager

@synthesize databaseQueue;

+ (void)initialize
{
	if (self == [WCRDBManager class]) defaultManager = [[self alloc] init];
}

- (instancetype)init
{
	if (self = [super init])
	{
		databaseQueue = dispatch_queue_create("com.naken.wechatrobotforexample.database", 0);
		[self initializeChatHistory];
	}
	return self;
}

+ (instancetype)defaultManager
{
	return defaultManager;
}

- (void)initializeDBFile
{
	@autoreleasepool
	{
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *chatHistoryPath = [WCRPreferences chatHistoryPath];
		if (![fileManager fileExistsAtPath:chatHistoryPath]) [fileManager createFileAtPath:chatHistoryPath contents:[NSData data] attributes:nil];
	}
}

- (void)initializeChatHistory
{
	@autoreleasepool
	{
		NSString *chatHistoryPath = [WCRPreferences chatHistoryPath];

		[self initializeDBFile];

		sqlite3 *database;
		int openResult = sqlite3_open([chatHistoryPath UTF8String], &database);
		if (openResult == SQLITE_OK)
		{
			NSString *sql = @"CREATE TABLE IF NOT EXISTS MESSAGE (ID INTEGER PRIMARY KEY NOT NULL, TEXT TEXT, IS_FROM_ME INTEGER NOT NULL, DATE INTEGER NOT NULL, HANDLE_USER TEXT NOT NULL, HANDLE_GROUP TEXT NOT NULL, MESSAGE_TYPE INTEGER NOT NULL)";
			int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
			if (execResult != SQLITE_OK) NSLog(@"WCR: Failed to create table MESSAGE, sql error code = %d.", execResult);
			sqlite3_close(database);
		}
		else NSLog(@"WCR: Failed to open %@, sql error code = %d.", chatHistoryPath, openResult);
	}
}

- (void)recordChatHistoryWithWrap:(CMessageWrap *)wrap
{
	@autoreleasepool
	{	
		dispatch_async(self.databaseQueue, ^{
			NSNumber *isFromMe = wrap.m_uiStatus == 1 ? @YES : @NO;
			NSString *handleUser = @"";
			NSString *handleGroup = @"";
			if (isFromMe.boolValue) handleUser = wrap.m_nsToUsr;
			else handleUser = wrap.m_nsFromUsr;
			if ([handleUser rangeOfString:@"@chatroom"].location != NSNotFound)
			{
				handleGroup = handleUser;
				handleUser = wrap.m_nsRealChatUsr;
			}
			else handleGroup = @"";
			NSNumber *messageType = @(wrap.m_uiMessageType);
			NSNumber *date = @([NSDate date].timeIntervalSince1970);
			NSString *text = nil;
			switch (wrap.m_uiMessageType)
			{
				case 1: // 普通文字消息
				{
					text = wrap.m_nsContent;
					text = [text stringByReplacingOccurrencesOfString:@"'" withString:@"\""];
					break;
				}
				case 34: // 语音
				{
					text = @"";
					break;
				}
				case 49: // App message
				{
					text = wrap.m_nsAppMediaUrl;
					break;
				}
			}
			if (text)
			{
				NSDictionary *messageInfo = @{@"text" : text, @"isFromMe": isFromMe, @"date" : date, @"handleUser" : handleUser, @"handleGroup" : handleGroup, @"messageType" : messageType};
				[self recordChatHistoryWithMessageInfo:messageInfo];
			}
		});
	}
}

- (void)recordChatHistoryWithMessageInfo:(NSDictionary *)messageInfo
{
	@autoreleasepool
	{	
		NSString *chatHistoryPath = [WCRPreferences chatHistoryPath];
		sqlite3 *database;
		int openResult = sqlite3_open([chatHistoryPath UTF8String], &database);
		if (openResult == SQLITE_OK)
		{
			NSString *sql = [[NSString alloc] initWithFormat:@"INSERT INTO MESSAGE (TEXT, IS_FROM_ME, DATE, HANDLE_USER, HANDLE_GROUP, MESSAGE_TYPE) VALUES ('%@', '%@', '%@', '%@', '%@', '%@')", messageInfo[@"text"], messageInfo[@"isFromMe"], messageInfo[@"date"], messageInfo[@"handleUser"], messageInfo[@"handleGroup"], messageInfo[@"messageType"]];
			int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
			if (execResult != SQLITE_OK) NSLog(@"WCR: Failed to exec %@, sql error code = %d.", sql, execResult);
			sqlite3_close(database);
#if !__has_feature(objc_arc)			
			[sql release];
#endif
			sql = nil;
		}
		else NSLog(@"WCR: Failed to open %@, sql error code = %d.", chatHistoryPath, openResult);
	}
}

@end
