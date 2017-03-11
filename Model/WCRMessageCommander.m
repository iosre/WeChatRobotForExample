#import "WCRGlobalHeader.h"

static WCRMessageCommander *sharedCommander;

static WebViewA8KeyLogicImpl *globalKeyPoint;
static WebViewA8KeyLogicImpl *sharedGlobalKeyPoint(void)
{
	if (!globalKeyPoint) globalKeyPoint = [[objc_getClass("WebViewA8KeyLogicImpl") alloc] init];
	return globalKeyPoint;
}

@implementation WCRMessageCommander

@synthesize imageDownloadCallback;
@synthesize attachmentDownloadCallback;
@synthesize lastBroadcastDate;

- (instancetype)init
{
	if (self = [super init])
	{
		NSDictionary *miscellaneous = [[NSDictionary alloc] initWithContentsOfFile:[[WCRPreferences settingsPath] stringByAppendingPathComponent:@"miscellaneous.plist"]];
		lastBroadcastDate = miscellaneous[@"lastBroadcastDate"];
#if !__has_feature(objc_arc)	
		[miscellaneous release];
#endif
		miscellaneous = nil;
	}
	return self;
}

+ (void)initialize
{
	if (self == [WCRMessageCommander class]) sharedCommander = [[self alloc] init];
}

+ (instancetype)sharedCommander
{
	return sharedCommander;
}

- (NSString *)autoReplyForMessage:(CMessageWrap *)wrap
{
	return [self autoReplyForContent:wrap.m_nsContent];
}

- (NSString *)autoReplyForContent:(NSString *)content
{
	@autoreleasepool
	{
		WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];

		NSMutableString *tulingInfoString = [content mutableCopy];
		[tulingInfoString replaceOccurrencesOfString:[NSString stringWithFormat:@"@%@", [userCommander myName]] withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, tulingInfoString.length)];
		NSString *tulingURLString = [WCRPreferences tulingURLs][[userCommander myID]];
		if (!tulingURLString) tulingURLString = [WCRPreferences tulingURLs][@"miscellaneous"];
		tulingURLString = [tulingURLString stringByAppendingString:tulingInfoString];
#if !__has_feature(objc_arc)
		[tulingInfoString release];
#endif
		tulingInfoString = nil;
		tulingURLString = [tulingURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];	
		NSURL *tulingURL = [NSURL URLWithString:tulingURLString];
		NSError *error = nil;
		NSString *responseString = [[NSString alloc] initWithContentsOfURL:tulingURL encoding:NSUTF8StringEncoding error:&error];
		NSString *autoReply = @"☺️";
		if (!error)
		{
			NSString *textString = @"\"text\":\"";
			NSUInteger startLocation = [responseString rangeOfString:textString].location;
			if (startLocation != NSNotFound)
			{
				autoReply = [responseString substringFromIndex:startLocation + textString.length];
				NSUInteger endLocation = [autoReply rangeOfString:@"\""].location;
				if (endLocation != NSNotFound) autoReply = [autoReply substringToIndex:endLocation];
			}
		}
		else NSLog(@"WCR: Failed to get response from \"%@\", error = %@.", tulingURL, error);
#if !__has_feature(objc_arc)
		[responseString release];
#endif
		responseString = nil;
		return [[autoReply stringByReplacingOccurrencesOfString:@"<br>" withString:@""] stringByReplacingOccurrencesOfString:@"\\r" withString:@""];
	}
}

- (NSString *)URLStringFromMessageWrap:(CMessageWrap *)wrap
{
	@autoreleasepool
	{
		NSString *content = wrap.m_nsContent;
		NSString *startString = @"<url>";
		NSString *endString = @"</url>";
		NSUInteger startLocation = [content rangeOfString:startString].location;
		NSUInteger endLocation = [content rangeOfString:endString].location;
		NSString *URLString = @"";
		if (startLocation != NSNotFound && endLocation != NSNotFound)
		{
			URLString = [content substringWithRange:NSMakeRange(startLocation + [startString length], endLocation - startLocation - [startString length])];
			URLString = [URLString stringByAppendingString:@"&from=singlemessage&isappinstalled=0"];
		}
		return URLString;
	}
}

- (CMessageWrap *)wrapForExampleToUser:(NSString *)userID
{
	@autoreleasepool
	{
		CMessageWrap *wrap = [[objc_getClass("CMessageWrap") alloc] initWithMsgType:49];
		wrap.m_nsFromUsr = [objc_getClass("SettingUtil") getLocalUsrName:0];
		wrap.m_nsToUsr = userID;
		wrap.m_uiCreateTime = [objc_getClass("CUtility") genCurrentTime];
		wrap.m_uiStatus = 1;
		wrap.m_nsTitle = [WCRPreferences exampleWrapInfo][@"title"];
		wrap.m_nsDesc = [WCRPreferences exampleWrapInfo][@"description"];
		wrap.m_nsAppExtInfo = nil;
		NSData *wrapThumbNail = [[NSData alloc] initWithContentsOfFile:[WCRPreferences exampleWrapInfo][@"thumbNail"]];
		wrap.m_dtThumbnail = wrapThumbNail;
#if !__has_feature(objc_arc)
		[wrapThumbNail release];
#endif
		wrapThumbNail = nil;
		wrap.m_uiAppDataSize = 0;
		wrap.m_uiAppMsgInnerType = 5;
		wrap.m_nsAppMediaUrl = [WCRPreferences exampleWrapInfo][@"appMediaURL"];
		wrap.m_nsShareOriginUrl = [WCRPreferences exampleWrapInfo][@"shareOriginURL"];
		wrap.m_nsShareOpenUrl = [WCRPreferences exampleWrapInfo][@"shareOpenURL"];
		wrap.m_nsJsAppId = [WCRPreferences exampleWrapInfo][@"jsAppID"];
		wrap.m_nsPrePublishId = nil;
		wrap.m_nsAppID = nil;
		wrap.m_nsAppName = nil;
		wrap.m_nsThumbUrl = [WCRPreferences exampleWrapInfo][@"thumbURL"];
#if !__has_feature(objc_arc)
		return [wrap autorelease];
#else
		return wrap;
#endif
	}
}

- (NSDictionary *)appMsgInfoFromURL:(NSString *)url
{
	@autoreleasepool
	{
		NSLog(@"WCR: Start getting App message info from \"%@\".", url);
		NSString *title = @"";
		NSString *description = @"";
		NSData *coverImageData = nil;
		UIImage *coverImage = nil;

		NSError *error = nil;
		NSString *originWebsiteString = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:&error];
		NSString *subWebsiteString = @"";
		if (!error)
		{
			NSString *msgTitleString = @"var msg_title = \"";
			NSUInteger msgTitleLocation = [originWebsiteString rangeOfString:msgTitleString].location;
			NSString *msgDescString = @"var msg_desc = \"";
			NSUInteger msgDescLocation = [originWebsiteString rangeOfString:msgDescString].location;
			NSString *msgCdnString = @"var msg_cdn_url = \"";
			NSUInteger msgCdnLocation = [originWebsiteString rangeOfString:msgCdnString].location;
			NSString *endString = @"\"";
			NSUInteger endLocation;
			if (msgTitleLocation != NSNotFound)
			{
				subWebsiteString = [originWebsiteString substringFromIndex:msgTitleLocation + msgTitleString.length];
				endLocation = [subWebsiteString rangeOfString:endString].location;
				if (endLocation != NSNotFound)
				{
					subWebsiteString = [subWebsiteString substringToIndex:endLocation];
					title = subWebsiteString;
					if (title.length != 0) NSLog(@"WCR: There's msg title \"%@\" in the web page.", title);
				}
			}
			if (msgDescLocation != NSNotFound)
			{
				subWebsiteString = [originWebsiteString substringFromIndex:msgDescLocation + msgDescString.length];
				endLocation = [subWebsiteString rangeOfString:endString].location;
				if (endLocation != NSNotFound)
				{
					subWebsiteString = [subWebsiteString substringToIndex:endLocation];
					description = subWebsiteString;
					if (description.length != 0) NSLog(@"WCR: There's msg desc \"%@\" in the web page.", description);
				}
			}
			if (msgCdnLocation != NSNotFound)
			{
				subWebsiteString = [originWebsiteString substringFromIndex:msgCdnLocation + msgCdnString.length];
				endLocation = [subWebsiteString rangeOfString:endString].location;
				if (endLocation != NSNotFound)
				{
					subWebsiteString = [subWebsiteString substringToIndex:endLocation];
					coverImageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:subWebsiteString]];
					coverImage = [[UIImage alloc] initWithData:coverImageData];
					if (coverImage) NSLog(@"WCR: There's msg cdn \"%@\" in the web page.", subWebsiteString);
				}
			}

			NSString *titleString = @"title: '";
			NSUInteger titleLocation = [originWebsiteString rangeOfString:titleString].location;
			NSString *descString = @"desc: '";
			NSUInteger descLocation = [originWebsiteString rangeOfString:descString].location;
			NSString *imgUrlString = @"imgUrl: '";
			NSUInteger imgUrlLocation = [originWebsiteString rangeOfString:imgUrlString].location;
			endString = @"'";
			if (titleLocation != NSNotFound && title.length == 0)
			{
				subWebsiteString = [originWebsiteString substringFromIndex:titleLocation + titleString.length];
				endLocation = [subWebsiteString rangeOfString:endString].location;
				if (endLocation != NSNotFound)
				{
					subWebsiteString = [subWebsiteString substringToIndex:endLocation];
					title = subWebsiteString;
					if (title.length != 0) NSLog(@"WCR: There's title \"%@\" in the web page.", title);
				}
			}
			if (descLocation != NSNotFound && description.length == 0)
			{
				subWebsiteString = [originWebsiteString substringFromIndex:descLocation + descString.length];
				endLocation = [subWebsiteString rangeOfString:endString].location;
				if (endLocation != NSNotFound)
				{
					subWebsiteString = [subWebsiteString substringToIndex:endLocation];
					description = subWebsiteString;
					if (description.length != 0) NSLog(@"WCR: There's description \"%@\" in the web page.", description);
				}
			}
			if (imgUrlLocation != NSNotFound && !coverImage)
			{
				subWebsiteString = [originWebsiteString substringFromIndex:imgUrlLocation + imgUrlString.length];
				endLocation = [subWebsiteString rangeOfString:endString].location;
				if (endLocation != NSNotFound)
				{
					subWebsiteString = [subWebsiteString substringToIndex:endLocation];
#if !__has_feature(objc_arc)
					[coverImageData release];
#endif
					coverImageData = nil;
					coverImageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:subWebsiteString]];
#if !__has_feature(objc_arc)
					[coverImage release];
#endif
					coverImage = nil;
					coverImage = [[UIImage alloc] initWithData:coverImageData];
					if (coverImage) NSLog(@"WCR: There's imgUrl \"%@\" in the web page.", subWebsiteString);							
				}
			}

			titleString = @"<title>";
			titleLocation = [originWebsiteString rangeOfString:titleString].location;
			endString = @"</title>";
			endLocation = [originWebsiteString rangeOfString:endString].location;
			if (titleLocation != NSNotFound && endLocation != NSNotFound && title.length == 0)
			{
				subWebsiteString = [originWebsiteString substringFromIndex:titleLocation + titleString.length];
				subWebsiteString = [subWebsiteString substringToIndex:endLocation];
				title = subWebsiteString;
				if (title.length != 0) NSLog(@"WCR: There's title \"%@\" in the web page.", title);
			}
		}
		else NSLog(@"WCR: Failed to generate string from \"%@\", error = %@.", url, error);
		if (title.length == 0) title = @"iOSRE";
		if (description.length == 0)
		{
			NSString *endString = @"/";
			NSUInteger endLocation = [url rangeOfString:endString].location;
			if (endLocation != NSNotFound)
			{
				subWebsiteString = [url substringToIndex:endLocation];
				description = subWebsiteString;
			}
			else description = url;
			if (description.length != 0) NSLog(@"WCR: There's description \"%@\" in the web page.", description);			
		}
		if (!coverImage)
		{
#if !__has_feature(objc_arc)
			[coverImageData release];
#endif
			coverImageData = nil;
			coverImageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[WCRPreferences exampleWrapInfo][@"thumbURL"]]];
#if !__has_feature(objc_arc)
			[coverImage release];
#endif
			coverImage = nil;
			coverImage = [[UIImage alloc] initWithData:coverImageData];
			if (coverImage) NSLog(@"WCR: Use our default cover image instead.");
		}

		CGFloat oldWidth = coverImage.size.width;
		CGFloat scaleFactor = 120 / oldWidth;
		CGFloat newHeight = coverImage.size.height * scaleFactor;
		CGFloat newWidth = oldWidth * scaleFactor;

		UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
		[coverImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
		UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
#if !__has_feature(objc_arc)		
		[coverImageData release];
		[coverImage release];
#endif
		coverImageData = nil;
		coverImage = nil;
		title = [@"业主" stringByAppendingString:title];
		title = [title stringByReplacingOccurrencesOfString:[[WCRUserCommander sharedCommander] myName] withString:@""];
		title = [title stringByReplacingOccurrencesOfString:@" - 楼盘推广助理" withString:@""];
		NSLog(@"WCR: We've got title \"%@\", description \"%@\"%@for broadcast.", title, description, newImage ? @" and image " : @" ");
#if !__has_feature(objc_arc)		
		[originWebsiteString release];
#endif
		originWebsiteString = nil;
		return @{@"title" : title, @"description" : description, @"coverImageData" : UIImageJPEGRepresentation(newImage, 1.0)};
	}
}

- (CMessageWrap *)reWrapForWrap:(CMessageWrap *)wrap toUser:(NSString *)userID
{
	CMessageWrap *reWrap = [self wrapForURL:wrap.m_nsAppMediaUrl toUser:userID];
	reWrap.m_nsTitle = wrap.m_nsTitle;
	reWrap.m_nsDesc = wrap.m_nsDesc;
	return reWrap;
}

- (CMessageWrap *)wrapForURL:(NSString *)url toUser:(NSString *)userID
{
	@autoreleasepool
	{
		NSDictionary *appMsgInfo = [self appMsgInfoFromURL:url];
		CMessageWrap *reWrap = [[objc_getClass("CMessageWrap") alloc] initWithMsgType:49];
		reWrap.m_nsFromUsr = [objc_getClass("SettingUtil") getLocalUsrName:0];
		reWrap.m_nsToUsr = userID;
		reWrap.m_uiCreateTime = [objc_getClass("CUtility") genCurrentTime];
		reWrap.m_uiStatus = 1;
		reWrap.m_nsTitle = appMsgInfo[@"title"];
		reWrap.m_nsDesc = appMsgInfo[@"description"];
		reWrap.m_nsAppExtInfo = nil;
		reWrap.m_dtThumbnail = [objc_getClass("OpenApiMgrHelper") checkAppMsgThumbData:appMsgInfo[@"coverImageData"]];
		reWrap.m_uiAppDataSize = 0;
		reWrap.m_uiAppMsgInnerType = 5;	
		reWrap.m_nsAppMediaUrl = url;
		reWrap.m_nsShareOriginUrl = url;
		reWrap.m_nsShareOpenUrl = url;
		reWrap.m_nsJsAppId = nil;
		reWrap.m_nsPrePublishId = nil;
		reWrap.m_nsAppID = nil;
		reWrap.m_nsAppName = [objc_getClass("CAppUtil") getCurrentLanguageAppName:nil];
#if !__has_feature(objc_arc)		
		return [reWrap autorelease];
#else
		return reWrap;
#endif
	}
}

- (void)sendMessage:(CMessageWrap *)wrap
{
	@autoreleasepool
	{
		WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
		NSString *receiver = wrap.m_nsToUsr;
		if (([wrap WCRIsToGroup] && [userCommander amIInGroup:receiver]) || (![wrap WCRIsToGroup] && [userCommander isContact:receiver]))
		{
			__unsafe_unretained __block WCRMessageCommander *weakSelf = self;
			[globalQueue addOperationWithBlock:^{
				@autoreleasepool
				{
					globalQueue.suspended = YES;
					[weakSelf waitWithMessage:wrap];
					switch (wrap.m_uiMessageType)
					{
						case 1:
							{
								NSLog(@"WCR: Prepare to send text message \"%@\" to %@.", wrap.m_nsContent, [userCommander nameOfUser:receiver]);
								[globalMessageMgr AddMsg:receiver MsgWrap:wrap];
								break;
							}
						case 3:
							{
								NSLog(@"WCR: Prepare to send image message to %@.", [userCommander nameOfUser:receiver]);
								[globalMessageMgr AddMsg:receiver MsgWrap:wrap];
								break;
							}
						case 49:
							{
								NSLog(@"WCR: Prepare to send app message \"%@\" to %@.", wrap.m_nsAppMediaUrl, [userCommander nameOfUser:receiver]);
								[globalMessageMgr AddAppMsg:receiver MsgWrap:wrap Data:nil Scene:3];
								break;
							}
						default:
							{
								NSLog(@"WCR: Prepare to send unknown message \"%@\" to %@.", wrap, [userCommander nameOfUser:receiver]);
								[globalMessageMgr AddMsg:receiver MsgWrap:wrap];
								break;
							}
					}
				}				
			}];
		}
		else NSLog(@"WCR: %@ is not from a contact so we're not sending anything.", [userCommander nameOfUser:receiver]);
	}
}

- (void)waitWithMessage:(CMessageWrap *)wrap
{
	switch (wrap.m_uiMessageType)
	{
		case 1: // Text
			{
				sleep(1);
				break;
			}
		case 3: // Image
			{
				sleep(2);						
				break;
			}
		case 49: // App message
			{
				sleep(2);						
				break;
			}
		default:
			{
				sleep(1);						
				break;
			}
	}
}

- (void)forwardMessage:(CMessageWrap *)wrap withReplyContent:(NSString *)replyContent
{
	@autoreleasepool
	{
		WCRGroupCommander *groupCommander = [WCRGroupCommander sharedCommander];
		WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
		WCRGeneralCommander *generalCommander = [WCRGeneralCommander sharedCommander];
		NSString *message = @"";
		NSString *messageWithDate = @"";
		NSString *groupID = @"";
		NSString *groupName = @"";
		NSString *userID = @"";
		NSString *userName = @"";
		NSString *content = wrap.m_nsContent;
		NSString *reply = @"";
		NSString *replyWithDate = @"";
		if ([wrap WCRIsFromGroup])
		{
			groupID = wrap.m_nsFromUsr;
			groupName = [groupCommander nameOfUser:groupID];
			userID = wrap.m_nsRealChatUsr;
			userName = [groupCommander nameOfUser:userID inGroup:groupID];
			message = [NSString stringWithFormat:@"@%@（%@）在%@（%@）里说：\"%@\"", userName, userID, groupName, groupID, content];
			messageWithDate = [NSString stringWithFormat:@"%@ %@\r\n", [NSDate date], message];
			reply = [NSString stringWithFormat:@"@%@（%@）在%@（%@）说：\"%@\"", [userCommander myName], [userCommander myID], groupName, groupID, replyContent];
			replyWithDate = [NSString stringWithFormat:@"%@ %@\r\n", [NSDate date], reply];
		}
		else
		{
			userID = wrap.m_nsFromUsr;
			userName = [userCommander nameOfUser:userID];
			message = [NSString stringWithFormat:@"@%@（%@）说：\"%@\"", userName, userID, content];
			messageWithDate = [NSString stringWithFormat:@"%@ %@\r\n", [NSDate date], message];
			reply = [NSString stringWithFormat:@"@%@（%@）说：\"%@\"", [userCommander myName], [userCommander myID], replyContent];
			replyWithDate = [NSString stringWithFormat:@"%@ %@\r\n", [NSDate date], reply];
		}

		[generalCommander.conversation appendString:messageWithDate];
		[generalCommander.conversation appendString:replyWithDate];
		NSMutableArray *forwardees = [[WCRPreferences messageForwardees] mutableCopy];
		[forwardees removeObject:userID];
		for (NSString *forwardeeID in forwardees)
		{
			CMessageWrap *outsideWrap = [logicController FormTextMsg:forwardeeID withText:message];
			[self sendMessage:outsideWrap];
			CMessageWrap *insideWrap = [logicController FormTextMsg:forwardeeID withText:reply];
			[self sendMessage:insideWrap];
		}
#if !__has_feature(objc_arc)		
		[forwardees release];
#endif
		forwardees = nil;
	}
}

- (CMessageWrap *)welcomeMessageWrapForWrap:(CMessageWrap *)wrap
{
	@autoreleasepool
	{
		NSString *senderID = wrap.m_nsFromUsr;
		NSString *content = wrap.m_nsContent;			
		NSString *startString = @" invited ";
		NSString *endString = @" to the group chat";
		NSUInteger startLocation = [content rangeOfString:startString].location;
		NSUInteger endLocation = [content rangeOfString:endString].location;
		if (startLocation == NSNotFound || endLocation == NSNotFound)
		{
			startString = @"";
			endString = @" joined the group chat ";
			startLocation = 0;
			endLocation = [content rangeOfString:endString].location;
		}
		NSString *userName = [content substringWithRange:NSMakeRange(startLocation + startString.length, endLocation - startLocation - startString.length)];
		NSString *welcomeMessage = [NSString stringWithFormat:[WCRPreferences welcomeMessageInfo][senderID], userName];
		if (welcomeMessage.length == 0) welcomeMessage = [WCRPreferences welcomeMessageInfo][@"miscellaneous"];
		CMessageWrap *newWrap = [logicController FormTextMsg:senderID withText:welcomeMessage];
		return newWrap;
	}
}

- (void)replyToUser:(NSDictionary *)userInfo
{
	@autoreleasepool
	{
		WCRVoiceProcessor *voiceProcessor = [WCRVoiceProcessor sharedProcessor];
		[voiceProcessor convertVoiceWrap:userInfo[@"wrap"] completion:^(NSString *text)
		{
			NSString *userID = userInfo[@"userID"];
			CMessageWrap *wrap = [logicController FormTextMsg:userID withText:text];
			wrap.m_nsFromUsr = userID;
			wrap.m_nsToUsr = [[WCRUserCommander sharedCommander] myID];
			[self handleTextMessageWrap:wrap];
		}];
	}
}

- (void)handleGroupMessageWrap:(CMessageWrap *)wrap
{
	NSLog(@"WCR: Handle group message from %@", [[WCRUserCommander sharedCommander] nameOfUser:wrap.m_nsFromUsr]);
	switch (wrap.m_uiMessageType)
	{
		case 1:
			{
				[self handleTextMessageWrap:wrap];
				break;
			}
		default:
			{
				[self handleUnknownMessageWrap:wrap];
				break;
			}
	}
}

- (void)handlePrivateMessageWrap:(CMessageWrap *)wrap
{
	NSLog(@"WCR: Handle private message from %@", [[WCRUserCommander sharedCommander] nameOfUser:wrap.m_nsFromUsr]);
	switch (wrap.m_uiMessageType)
	{
		case 1: // Text
			{
				[self handleTextMessageWrap:wrap];
				break;
			}
		case 3: // Image
			{
				[self handleImageMessageWrap:wrap];
				break;
			}
		case 49: // App message
			{
				[self handleAppMessageWrap:wrap];
				break;
			}
		default: // Unknown
			{
				[self handleUnknownMessageWrap:wrap];
				break;
			}
	}
}

- (void)handleVoiceMessageWithInfo:(NSDictionary *)voiceInfo
{
	NSLog(@"WCR: Handle voice message from %@", [[WCRUserCommander sharedCommander] nameOfUser:voiceInfo[@"senderID"]]);

	NSString *audioPath = voiceInfo[@"audioPath"];
	NSNumber *localID = voiceInfo[@"localID"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:audioPath])
	{
		WCRVoiceProcessor *voiceProcessor = [WCRVoiceProcessor sharedProcessor];
		[self replyToUser:voiceProcessor.voiceDownloadInfo[localID]];
		[voiceProcessor.voiceDownloadInfo removeObjectForKey:localID];
	}
	else NSLog(@"WCR: Audio file not downloaded yet.");
}

- (void)handleTextMessageWrap:(CMessageWrap *)wrap
{
	@autoreleasepool
	{
		WCRGroupCommander *groupCommander = [WCRGroupCommander sharedCommander];
		WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
		WCRSearchManager *searchManager = [WCRSearchManager defaultManager];
		NSString *sender = wrap.m_nsFromUsr;

		NSLog(@"WCR: Handle text message \"%@\" from %@ to %@.", wrap.m_nsContent, [userCommander nameOfUser:sender], [userCommander nameOfUser:wrap.m_nsToUsr]);

		if ([wrap WCRIsAllGroupsCommand] || [wrap WCRIsAllUsersCommand])
		{
			NSString *allContactsDescription = [wrap WCRIsAllGroupsCommand] ? [groupCommander allGroupsDescription] : [userCommander allUsersDescription];
			while (allContactsDescription.length != 0)
			{
				NSString *content = nil;
				if (allContactsDescription.length >= 8888)
				{
					content = [allContactsDescription substringToIndex:8887];
					allContactsDescription = [allContactsDescription substringFromIndex:8887];
				}
				else
				{
					content = allContactsDescription;
					allContactsDescription = nil;
				}
				CMessageWrap *newWrap = [logicController FormTextMsg:sender withText:content];
				[self sendMessage:newWrap];
			}
		}
		else if ([wrap WCRIsNotifyCommand])
		{
			for (NSString *userID in [userCommander allUsers])
			{
				NSString *content = [wrap.m_nsContent stringByReplacingOccurrencesOfString:@"notify:" withString:@""];
				if (content.length != 0)
				{
					CMessageWrap *newWrap = [logicController FormTextMsg:userID withText:content];
					[self sendMessage:newWrap];
				}
			}
		}
		else if ([wrap WCRIsToUserCommand])
		{
			NSUInteger userStartLocation = [wrap.m_nsContent rangeOfString:@"toUser:"].location + @"toUser:".length;
			NSUInteger userEndLocation = [wrap.m_nsContent rangeOfString:@" "].location;
			NSString *userID = [wrap.m_nsContent substringWithRange:NSMakeRange(userStartLocation, userEndLocation - userStartLocation)];
			NSUInteger contentStartLocation = [wrap.m_nsContent rangeOfString:@"content:"].location + @"content:".length;
			NSString *content = [wrap.m_nsContent substringFromIndex:contentStartLocation];
			if ((([userID rangeOfString:@"@chatroom"].location != NSNotFound && [groupCommander amIInGroup:userID]) || ([userID rangeOfString:@"@chatroom"].location == NSNotFound && [userCommander isContact:userID])) && content.length != 0)
			{
				CMessageWrap *newWrap = [logicController FormTextMsg:userID withText:content];
				[self sendMessage:newWrap];
			}
		}
		else if ([wrap WCRIsToGroupToUserCommand])
		{
			NSUInteger groupStartLocation = [wrap.m_nsContent rangeOfString:@"toGroup:"].location + @"toGroup:".length;
			NSUInteger groupEndLocation = [wrap.m_nsContent rangeOfString:@" toUser:"].location;
			NSString *groupID = [wrap.m_nsContent substringWithRange:NSMakeRange(groupStartLocation, groupEndLocation - groupStartLocation)];
			NSUInteger userStartLocation = [wrap.m_nsContent rangeOfString:@"toUser:"].location + @"toUser:".length;
			NSUInteger userEndLocation = [wrap.m_nsContent rangeOfString:@" content:"].location;
			NSString *userID = [wrap.m_nsContent substringWithRange:NSMakeRange(userStartLocation, userEndLocation - userStartLocation)];
			NSUInteger contentStartLocation = [wrap.m_nsContent rangeOfString:@"content:"].location + @"content:".length;
			NSString *content = [wrap.m_nsContent substringFromIndex:contentStartLocation];
			if ([groupID rangeOfString:@"@chatroom"].location != NSNotFound && [userID rangeOfString:@"@chatroom"].location == NSNotFound && content.length != 0)
			{
				CMessageWrap *newWrap = [logicController FormTextMsg:groupID withText:content];
				newWrap.m_nsMsgSource = [NSString stringWithFormat:@"<msgsource><atuserlist>%@</atuserlist><membercount>%tu</membercount></msgsource>", userID, [groupCommander memberCountsOfGroup:groupID]];
				[self sendMessage:newWrap];
			}
		}
		else if ([wrap WCRIsPasswordCommand])
		{
			CMessageWrap *newWrap = [logicController FormTextMsg:sender withText:[WCRUtils password]];
			[self sendMessage:newWrap];
		}
		else if ([wrap WCRIsInviteUserToAllGroupsCommand])
		{
			NSString *userID = [wrap.m_nsContent stringByReplacingOccurrencesOfString:@"inviteUserToAllGroups:" withString:@""];
			[groupCommander inviteUserToAllGroups:userID];
		}
		else if ([wrap WCRIsClearAllSessionsCommand])
		{
			[userCommander clearAllSessions];
		}
		else if ([wrap WCRIsStopBroadcastingCommand])
		{
			[globalQueue cancelAllOperations];
			globalQueue.suspended = YES;
		}
		else if ([wrap WCRIsStartBroadcastingCommand])
		{
			[globalQueue cancelAllOperations];										
			globalQueue.suspended = NO;
		}
		else if ([wrap WCRIsQuitGroupCommand])
		{
			NSString *groupID = [wrap.m_nsContent stringByReplacingOccurrencesOfString:@"quitGroup:" withString:@""];
			if ([groupCommander amIInGroup:groupID]) [groupCommander quitGroup:groupID];
		}
		else if ([wrap WCRIsToGroupCommand])
		{
			NSUInteger groupStartLocation = [wrap.m_nsContent rangeOfString:@"toGroup:"].location + @"toGroup:".length;
			NSUInteger groupEndLocation = [wrap.m_nsContent rangeOfString:@" content:"].location;
			NSString *groupID = [wrap.m_nsContent substringWithRange:NSMakeRange(groupStartLocation, groupEndLocation - groupStartLocation)];
			NSUInteger contentStartLocation = [wrap.m_nsContent rangeOfString:@"content:"].location + @"content:".length;
			NSUInteger contentEndLocation = [wrap.m_nsContent rangeOfString:@" atAll:"].location;
			NSString *content = [wrap.m_nsContent substringWithRange:NSMakeRange(contentStartLocation, contentEndLocation - contentStartLocation)];
			NSUInteger atAllStartLocation = [wrap.m_nsContent rangeOfString:@"atAll:"].location + @"atAll:".length;
			NSString *atAll = [wrap.m_nsContent substringFromIndex:atAllStartLocation];
			if ([groupID rangeOfString:@"@chatroom"].location != NSNotFound && content.length != 0)
			{
				CMessageWrap *newWrap = [logicController FormTextMsg:groupID withText:content];
				if (atAll.intValue != 0)
				{
					NSArray *groupMembers = [groupCommander membersOfGroup:groupID];
					NSMutableString *members = [@"" mutableCopy];
					for (CContact *contact in groupMembers)
					{
						NSString *userID = contact.m_nsUsrName;
						[members appendString:userID];
						[members appendString:@","];
					}
					[members deleteCharactersInRange:NSMakeRange(members.length - 1, 1)];
					NSString *msgSource = [[NSString alloc] initWithFormat:@"<msgsource><atuserlist>%@</atuserlist><membercount>%tu</membercount></msgsource>", members, [groupCommander memberCountsOfGroup:groupID]];
					newWrap.m_nsMsgSource = msgSource;
#if !__has_feature(objc_arc)		
					[members release];
					[msgSource release];
#endif
					members = nil;
					msgSource = nil;
				}
				[self sendMessage:newWrap];
			}			
		}
		else if ([wrap WCRIsFriendAdded])
		{
			[groupCommander inviteUserToRandomGroup:sender];
			CMessageWrap *exchangeWrap = [logicController FormTextMsg:sender withText:[WCRPreferences groupExchange]];
			[self sendMessage:exchangeWrap];
			[WCRPreferences saveUserWithMessageWrap:wrap];
			CMessageWrap *newWrap = [logicController FormTextMsg:sender withText:[WCRPreferences greetingsWhenFriendsAdded]];
			UIImage *qrCode = [UIImage imageWithContentsOfFile:[[WCRPreferences bundlePath] stringByAppendingPathComponent:@"QRCode.jpg"]];
			CMessageWrap *imageWrap = [logicController FormImageMsg:sender withImage:qrCode];
			[userCommander encodeUserAlias:sender];
			[self sendMessage:newWrap];
			[self sendMessage:imageWrap];
		}
		else if ([wrap WCRIsViewIPCommand])
		{
			NSString *IPAddress = [WCRUtils LANIP];
			CMessageWrap *newWrap = [logicController FormTextMsg:sender withText:IPAddress];
			[self sendMessage:newWrap];
		}
		else
		{
			switch (wrap.m_nsContent.intValue)
			{
				case 1:
					{
						if (((NSArray *)((searchManager.buildingSearchContext)[sender])).count == 0)
						{
							CMessageWrap *newWrap = [logicController FormTextMsg:sender withText:[WCRPreferences exampleManual]];
							CMessageWrap *appWrap = [self wrapForExampleToUser:sender];
							[self sendMessage:newWrap];
							[self sendMessage:appWrap];
							break;
						}
					}
				case 2:
				case 3:
					{
						if (((NSArray *)((searchManager.buildingSearchContext)[sender])).count == 0)
						{	
							CMessageWrap *newWrap = [logicController FormTextMsg:sender withText:[WCRPreferences promoteOfficialAccount]];
							[self sendMessage:newWrap];
							UIImage *qrCode = [UIImage imageWithContentsOfFile:[[WCRPreferences bundlePath] stringByAppendingPathComponent:@"QRCode.jpg"]];
							CMessageWrap *imageWrap = [logicController FormImageMsg:sender withImage:qrCode];
							[self sendMessage:imageWrap];
							break;
						}
					}
				default:
					{
						[self handleChitChatMessageWrap:wrap];
						break;
					}
			}
		}
	}
}

- (void)handleAppMessageWrap:(CMessageWrap *)wrap
{
	WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
	NSLog(@"WCR: Handle app message \"%@\" from %@ to %@.", wrap.m_nsAppMediaUrl, [userCommander nameOfUser:wrap.m_nsFromUsr], [userCommander nameOfUser:wrap.m_nsToUsr]);

	if ([wrap WCRIsAttachment])
	{
		__unsafe_unretained __block WCRMessageCommander *weakSelf = self;	
		[self downloadAttachmentFromWrap:wrap withCompletion:^(NSString *path)
		{
			NSLog(@"WCR: This is a message with attachments at %@.", path.length != 0 ? path : @"nowhere");
			[weakSelf handleUnknownMessageWrap:wrap];
		}];
	}
	else if ([wrap WCRIsGroupInvitation])
	{
		NSMutableString *URLString = [[self URLStringFromMessageWrap:wrap] mutableCopy];
		[URLString replaceOccurrencesOfString:@"<![CDATA[" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, URLString.length)];
		[URLString replaceOccurrencesOfString:@"]]>" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, URLString.length)];
		[sharedGlobalKeyPoint() getA8Key:URLString Reason:0];
#if !__has_feature(objc_arc)
		[URLString release];
#endif
		URLString = nil;
	}
	else if ([wrap WCRIsExampleAppMessage])
	{
		WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
		WCRGroupCommander *groupCommander = [WCRGroupCommander sharedCommander];
		NSString *userID = wrap.m_nsFromUsr;
		NSLog(@"WCR: %@ (%@) is trying to send a broadcast.", [userCommander nameOfUser:userID], userID);
		if ((![WCRPreferences isUserLimited:userID] && ![WCRPreferences isBroadcastTooFrequent] && ![WCRPreferences isTooLate]) || [userCommander isAdmin:userID])
		{
			NSLog(@"WCR: Let's send it.");
			self.lastBroadcastDate = [NSDate date];
			[self saveLastBroadcastDate];
			[WCRPreferences reachUserLimitation:userID];
			NSArray *groups = [groupCommander allGroups];
			for (NSString *groupID in groups)
			{
				if ([[WCRPreferences broadcastImmuneGroups] indexOfObject:groupID] == NSNotFound && [userCommander amIInGroup:groupID])
				{
					CMessageWrap *newWrap = [self reWrapForWrap:wrap toUser:groupID];
					[self sendMessage:newWrap];
				}
			}
		}
		else if ([WCRPreferences isTooLate])
		{
			NSLog(@"WCR: It's too late to broadcast now.");
			CMessageWrap *newWrap = [logicController FormTextMsg:userID withText:[WCRPreferences tooLate]];
			[self sendMessage:newWrap];
		}
		else if ([WCRPreferences isUserLimited:userID])
		{
			NSLog(@"WCR: The guy is limited.");
			CMessageWrap *newWrap = [logicController FormTextMsg:userID withText:[WCRPreferences reachedDailyBroadcastLimit]];
			[self sendMessage:newWrap];
		}
		else if ([WCRPreferences isBroadcastTooFrequent])
		{
			NSLog(@"WCR: We're broadcasting too frequently.");
			CMessageWrap *newWrap = [logicController FormTextMsg:userID withText:[WCRPreferences pleaseSendLater]];
			[self sendMessage:newWrap];
		}
	}
	else [self handleUnknownMessageWrap:wrap];
}

- (void)handleImageMessageWrap:(CMessageWrap *)wrap
{
	WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
	NSLog(@"WCR: Handle image message from %@ to %@.", [userCommander nameOfUser:wrap.m_nsFromUsr], [userCommander nameOfUser:wrap.m_nsToUsr]);

	__unsafe_unretained __block WCRMessageCommander *weakSelf = self;	
	[self downloadImageFromWrap:wrap withCompletion:^(UIImage *image)
	{
		NSLog(@"WCR: This is a message with images.");
		[weakSelf handleUnknownMessageWrap:wrap];
	}];
}

- (void)handleUnknownMessageWrap:(CMessageWrap *)wrap
{
	WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
	NSLog(@"WCR: Handle unknown message \"%@\" from %@ to %@.", wrap.m_nsContent, [userCommander nameOfUser:wrap.m_nsFromUsr], [userCommander nameOfUser:wrap.m_nsToUsr]);

	NSString *sender = wrap.m_nsFromUsr;
	CMessageWrap *newWrap = [logicController FormTextMsg:sender withText:[WCRPreferences unrecognizedMessage]];
	[self sendMessage:newWrap];
	CMessageWrap *appWrap = [self wrapForExampleToUser:sender];
	[self sendMessage:appWrap];
}

- (void)handleSystemMessageWrap:(CMessageWrap *)wrap
{
	if (wrap.m_n64MesSvrID != 0 && wrap.m_uiMessageType == 10000)
	{	
		WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
		WCRGroupCommander *groupCommander = [WCRGroupCommander sharedCommander];
	
		if ([wrap.m_nsContent isEqualToString:@"Too many attempts. Try again later."])
		{
			NSLog(@"WCR: Seems WeChat has detected our frequent messages.");
			[globalQueue cancelAllOperations];
			globalQueue.suspended = NO;
		}
		else if ([wrap WCRIsFromGroup])
		{	
			NSString *groupID = wrap.m_nsFromUsr;
			if ([wrap WCRIsGroupInvited])
			{
				NSString *userID = [wrap WCRInviterIDFromGroupInvitation];
				[groupCommander inviteUserToRandomGroup:userID];
				CMessageWrap *exchangeWrap = [logicController FormTextMsg:userID withText:[WCRPreferences groupExchange]];
				[self sendMessage:exchangeWrap];
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
					[groupCommander muteGroup:groupID];
					[groupCommander saveGroup:groupID];
				});
			}
			else if ([wrap WCRIsGroupRemoved]) [groupCommander quitGroup:groupID];
		}
		else if (![wrap WCRIsFromGroup])
		{
			NSString *userID = wrap.m_nsFromUsr;
			if ([wrap WCRIsFriendAdded])
			{
				[groupCommander inviteUserToRandomGroup:userID];
				CMessageWrap *exchangeWrap = [logicController FormTextMsg:userID withText:[WCRPreferences groupExchange]];
				[self sendMessage:exchangeWrap];
				[WCRPreferences saveUserWithMessageWrap:wrap];
				CMessageWrap *newWrap = [logicController FormTextMsg:userID withText:[WCRPreferences greetingsWhenFriendsAdded]];
				[self sendMessage:newWrap];
				UIImage *qrCode = [UIImage imageWithContentsOfFile:[[WCRPreferences bundlePath] stringByAppendingPathComponent:@"QRCode.jpg"]];
				CMessageWrap *imageWrap = [logicController FormImageMsg:userID withImage:qrCode];
				[userCommander encodeUserAlias:userID];
				[self sendMessage:imageWrap];
			}
			else if ([wrap WCRIsFriendRemoved]) [userCommander deleteUserAndSession:userID];
		}
	}
}

- (void)handleChitChatMessageWrap:(CMessageWrap *)wrap
{
	WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
	WCRGroupCommander *groupCommander = [WCRGroupCommander sharedCommander];
	WCRSearchManager *searchManager = [WCRSearchManager defaultManager];

	NSString *groupID = wrap.m_nsFromUsr;
	NSString *userID = [wrap WCRIsFromGroup] ? wrap.m_nsRealChatUsr : wrap.m_nsFromUsr;
	NSString *userName = [groupCommander nameOfUser:userID inGroup:groupID];
	NSMutableString *content = [NSMutableString stringWithString:wrap.m_nsContent];
	[content replaceOccurrencesOfString:[userCommander myName] withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
	[content replaceOccurrencesOfString:@"@" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
	[content replaceOccurrencesOfString:@" " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
	[content replaceOccurrencesOfString:@" " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];					
	if ([WCRUtils isNumber:content] && content.intValue <= ((NSArray *)((searchManager.buildingSearchContext)[userID])).count)
	{
		NSUInteger index = content.intValue - 1;
		content = (NSMutableString *)[searchManager buildingDescriptionAtIndex:index forUser:userID];
	}
	else
	{
		content = (NSMutableString *)[searchManager buildingsDescriptionWithName:content forUser:userID];
	}
	if ([content isEqualToString:[WCRPreferences noBuildingFound]]) content = (NSMutableString *)[self autoReplyForMessage:wrap];
	CMessageWrap *newWrap;
	if ([wrap WCRIsFromGroup])
	{
		content = (NSMutableString *)[NSString stringWithFormat:@"@%@ %@", userName, content];
		newWrap = [logicController FormTextMsg:groupID withText:content];
		newWrap.m_nsMsgSource = [NSString stringWithFormat:@"<msgsource><atuserlist>%@</atuserlist><membercount>%tu</membercount></msgsource>", userID, [groupCommander memberCountsOfGroup:groupID]];
	}
	else newWrap = [logicController FormTextMsg:userID withText:content];
	[self sendMessage:newWrap];
	[self forwardMessage:wrap withReplyContent:content];
}

- (void)saveLastBroadcastDate
{
	@autoreleasepool
	{
		NSString *filePath = [[WCRPreferences settingsPath] stringByAppendingPathComponent:@"miscellaneous.plist"];
		NSMutableDictionary *miscellaneous = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
		miscellaneous[@"lastBroadcastDate"] = self.lastBroadcastDate;
		[miscellaneous writeToFile:filePath atomically:YES];
#if !__has_feature(objc_arc)		
		[miscellaneous release];
#endif
		miscellaneous = nil;
	}
}

- (void)downloadImageFromWrap:(CMessageWrap *)wrap withCompletion:(ImageDownloadCallback)completion
{
	@autoreleasepool
	{
		if ([globalMessageMgr GetDownloadThumbStatus:wrap] != 2) [globalMessageMgr StartDownloadThumb:wrap];
		self.imageDownloadCallback = nil;
		self.imageDownloadCallback = completion;
	}
}

- (void)downloadAttachmentFromWrap:(CMessageWrap *)wrap withCompletion:(AttachmentDownloadCallback)completion
{
	@autoreleasepool
	{
		[globalMessageMgr StartDownloadAppAttach:wrap.m_nsFromUsr MsgWrap:wrap];
		self.attachmentDownloadCallback = nil;
		self.attachmentDownloadCallback = completion;
	}
}

@end
