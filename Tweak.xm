#import "WeChatRobotForExample.h"
#import "Model/WCRGlobalHeader.h"

%group WeChatHook

static NSUInteger sendFailureCount;
CMessageMgr *globalMessageMgr;

%hook CMessageMgr
- (void)AsyncOnAddMsg:(NSString *)msg MsgWrap:(CMessageWrap *)wrap
{
	%orig;
	// [[WCRDBManager defaultManager] recordChatHistoryWithWrap:wrap];
	WCRMessageCommander *messageCommander = [WCRMessageCommander sharedCommander];

	if (![wrap WCRIsFromMe])
	{
		switch (wrap.m_uiStatus)
		{
			case 3: // Receive personal messages
				{
					if (wrap.m_uiMessageType == 34) // Voice
					{
						// Ignore
					}
					else if ([wrap WCRIsFromGroup] && [wrap WCRIsAtMe]) // @ in groups
					{
						[messageCommander handleGroupMessageWrap:wrap];
					}
					else if (![wrap WCRIsFromGroup]) // PM
					{
						[messageCommander handlePrivateMessageWrap:wrap];
					}
					break;
				}
			case 4: // Receive system messages
				{
					[messageCommander handleSystemMessageWrap:wrap];
					break;
				}
		}
	}
}

- (void)AsyncOnModMsg:(NSString *)msg MsgWrap:(CMessageWrap *)wrap
{
	%orig;
	WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
	if (wrap.m_uiStatus == 2)
	{
		globalQueue.suspended = NO;

		switch (wrap.m_uiMessageType)
		{
			case 1:
				{
					NSLog(@"WCR: Successfully sent text message \"%@\" to %@.", wrap.m_nsContent, [userCommander nameOfUser:wrap.m_nsToUsr]);
					break;
				}
			case 3:
				{
					NSLog(@"WCR: Successfully sent image message to %@.", [userCommander nameOfUser:wrap.m_nsToUsr]);
					break;
				}
			case 49:
				{
					NSLog(@"WCR: Successfully sent app message \"%@\" to %@.", wrap.m_nsAppMediaUrl, [userCommander nameOfUser:wrap.m_nsToUsr]);
					break;
				}
			default:
				{
					NSLog(@"WCR: Successfully sent unknown message \"%@\" to %@.", wrap, [userCommander nameOfUser:wrap.m_nsToUsr]);
					break;
				}
		}
		sendFailureCount = 0;
	}
	else if (wrap.m_uiStatus == 5)
	{
		globalQueue.suspended = NO;

		sendFailureCount++;
		if (sendFailureCount < 3)
		{
			switch (wrap.m_uiMessageType)
			{
				case 1:
					{
						NSLog(@"WCR: Failed to send text message \"%@\" to %@.", wrap.m_nsContent, [userCommander nameOfUser:wrap.m_nsToUsr]);
						break;
					}
				case 3:
					{
						NSLog(@"WCR: Failed to send image message to %@.", [userCommander nameOfUser:wrap.m_nsToUsr]);
						break;
					}
				case 49:
					{
						NSLog(@"WCR: Failed to send app message \"%@\" to %@.", wrap.m_nsAppMediaUrl, [userCommander nameOfUser:wrap.m_nsToUsr]);
						break;
					}
				default:
					{
						NSLog(@"WCR: Failed to send unknown message \"%@\" to %@.", wrap, [userCommander nameOfUser:wrap.m_nsToUsr]);
						break;
					}
			}
			NSLog(@"WCR: Resend it.");
			WCRMessageCommander *messageCommander = [WCRMessageCommander sharedCommander];			
			[messageCommander sendMessage:wrap];
		}
		else
		{
			NSLog(@"WCR: Too many sending failures. Pass and head on to the next message.");
			sendFailureCount = 0;
		}
	}
}

- (void)MessageReturn:(NSUInteger)flag MessageInfo:(NSDictionary *)info Event:(NSUInteger)arg3
{
	%orig;
	if (flag == 227) // Received message w/o attachments, including images, voices, etc.
	{
		CMessageWrap *wrap = info[@"18"];
		if (wrap.m_uiMessageType == 34 && ![wrap WCRIsFromGroup])
		{
			WCRVoiceProcessor *voiceProcessor = [WCRVoiceProcessor sharedProcessor];
			WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
			NSString *userID = wrap.m_nsFromUsr;
			NSString *userName = [userCommander nameOfUser:userID];
			voiceProcessor.voiceDownloadInfo[@(wrap.m_uiMesLocalID)] = @{@"userID" : userID, @"userName" : userName, @"wrap" : wrap};
		}
	}
	else if (flag == 332) // Friend request
	{
		SayHelloViewController *controller = [[%c(SayHelloViewController) alloc] init];
		[controller initData];
		NSArray *wraps = info[@"27"];
		for (CMessageWrap *wrap in wraps)
		{
			CPushContact *contact = [%c(SayHelloDataLogic) getContactFrom:wrap];
			[controller verifyContactWithOpCode:contact opcode:3];
		}
#if !__has_feature(objc_arc)
		[controller release];
#endif
		controller = nil;
	}
}

- (CMessageMgr *)init
{
	CMessageMgr *result = %orig;
	globalMessageMgr = result;
	return result;
}

%end

%hook WebViewA8KeyLogicImpl

- (void)handleGetA8KeyResp:(ProtobufCGIWrap *)arg1 EventID:(NSUInteger)arg2 // Join groups via invitation automatically
{
	%orig;
	WCRGroupCommander *groupCommander = [WCRGroupCommander sharedCommander];
	WXPBGeneratedMessage *message = arg1.m_pbResponse;
	if ([message isKindOfClass:NSClassFromString(@"GetA8KeyResp")])
	{
		NSString *realURL = ((GetA8KeyResp *)message).fullUrl;
		if ([groupCommander isGroupInvitationURL:realURL]) [groupCommander acceptGroupInvitationFromURL:realURL];
	}
}

%end

%hook OpenDownloadCDNMgr
- (void)OnCdnDownload:(CdnDownloadTaskInfo *)arg1
{
	@autoreleasepool
	{
		CdnTaskInfo *taskInfo = MSHookIvar<CdnTaskInfo *>(self, "_curTaskInfo");
		CMessageWrap *wrap = taskInfo.m_wrapMsg;
		%orig;
		if (arg1.m_uiFileLength != 0 && [wrap WCRIsAttachment])
		{
			WCRMessageCommander *messageCommander = [WCRMessageCommander sharedCommander];
			if (arg1.m_nRetCode == 0)
			{
				NSString *oldPath;
				[%c(CMessageWrap) GetPathOfAppDataByUserName:wrap.m_nsFromUsr andMessageWrap:wrap retStrPath:&oldPath];
				NSMutableString *newPath = [oldPath mutableCopy];
				NSString *fileName = wrap.m_nsTitle;
				[newPath replaceOccurrencesOfString:[oldPath lastPathComponent] withString:fileName options:NSLiteralSearch range:NSMakeRange(0, newPath.length)];
				if ([WCRUtils moveFile:oldPath toPath:newPath])	messageCommander.attachmentDownloadCallback(newPath);
				else messageCommander.attachmentDownloadCallback(oldPath);
#if !__has_feature(objc_arc)
				[newPath release];
#endif
				newPath = nil;
			}
			else
			{
				NSLog(@"WCR: Failed to download attachment, error code = %ld.", arg1.m_nRetCode);
				messageCommander.attachmentDownloadCallback(nil);
			}
		}
	}
}
%end

%hook ImageAutoDownloadMgr

- (void)OnDownloadImageOk:(CMessageWrap *)wrap
{
	%orig;
	WCRMessageCommander *messageCommander = [WCRMessageCommander sharedCommander];
	if (![wrap WCRIsFromGroup])
	{
		UIImage *image = [wrap GetImg];
		messageCommander.imageDownloadCallback(image);
	}
}

- (void)OnDownloadImageExpired:(CMessageWrap *)wrap
{
	%orig;
	WCRMessageCommander *messageCommander = [WCRMessageCommander sharedCommander];
	if (![wrap WCRIsFromGroup])
	{
		UIImage *image = [UIImage imageWithContentsOfFile:[[WCRPreferences bundlePath] stringByAppendingPathComponent:@"iosre.png"]];
		messageCommander.imageDownloadCallback(image);
	}
}

- (void)OnDownloadImageFail:(CMessageWrap *)wrap
{
	%orig;
	WCRMessageCommander *messageCommander = [WCRMessageCommander sharedCommander];
	if (![wrap WCRIsFromGroup])
	{
		[messageCommander downloadImageFromWrap:wrap withCompletion:^(UIImage *image)
		{
			return;
		}];	
	}
}

%end

%hook CDownloadVoiceMgr

- (BOOL)WriteAudioFile:(NSString *)senderID LocalID:(NSUInteger)arg2 Offset:(NSUInteger)arg3 Len:(NSUInteger)arg4 Data:(NSData *)arg5
{
	BOOL result = %orig;
	if ([senderID rangeOfString:@"@chatroom"].location == NSNotFound)
	{
		NSString *audioPath = [%c(CUtility) GetPathOfMesAudio:senderID LocalID:arg2 DocPath:[%c(CUtility) GetDocPath]];
		WCRMessageCommander *messageCommander = [WCRMessageCommander sharedCommander];
		[messageCommander handleVoiceMessageWithInfo:@{@"localID" : @(arg2), @"senderID" : senderID, @"audioPath" : audioPath}];
	}
	return result;
}

%end

%hook VoiceTransHelper

- (void)MessageReturn:(ProtobufCGIWrap *)arg1 Event:(NSUInteger)arg2
{
	%orig;
	if ([arg1.m_pbResponse isKindOfClass:%c(GetVoiceTransResResponse)] && ((GetVoiceTransResResponse *)(arg1.m_pbResponse)).transRes.endFlag == 1)
	{
		WCRVoiceProcessor *voiceProcessor = [WCRVoiceProcessor sharedProcessor];
		NSString *voiceID = ((GetVoiceTransResRequest *)arg1.m_pbRequest).voiceId;
		if (![voiceProcessor.lastVoiceID isEqualToString:voiceID])
		{
			voiceProcessor.lastVoiceID = voiceID;
			voiceProcessor.voiceToTextCallback(((GetVoiceTransResResponse *)(arg1.m_pbResponse)).transRes.result);		
		}
	}
}

%end

%hook VoiceMessageNodeView

- (BOOL)canShowVoiceTransMenu
{
	%orig;
	return YES;
}

%end

%hook FindContactSearchViewCellInfo

- (void)MessageReturn:(ProtobufCGIWrap *)arg1 Event:(NSUInteger)arg2
{
	%orig;
	if ([arg1.m_pbResponse isKindOfClass:%c(SearchContactResponse)])
	{
		WCRUserCommander *userCommander = [WCRUserCommander sharedCommander];
		userCommander.contactSearchCallback(self.foundContact);
	}
}

%end

%hook MMQRCodeMgr

- (void)handleGetQRCodeResponse:(ProtobufCGIWrap *)wrap
{
	%orig;
	WCRGeneralCommander *generalCommander = [WCRGeneralCommander sharedCommander];
	GetQRCodeRequest *request = (GetQRCodeRequest *)wrap.m_pbRequest;
	MMQRCodeMgr *qrCodeManager = [[%c(MMServiceCenter) defaultCenter] getService:[%c(MMQRCodeMgr) class]];
	NSString *qrCodePath = [qrCodeManager getQRCodeImagePath:request.userName.string];
	generalCommander.qrCodeDownloadCallback(qrCodePath);
}

%end

%hook MMTabBarController

- (void)viewDidAppear:(BOOL)arg1
{
	%orig;
	[self setSelectedIndex:3];
}

%end

%hook MicroMessengerAppDelegate

- (BOOL)application:(UIApplication *)arg1 didFinishLaunchingWithOptions:(NSDictionary *)arg2
{
	BOOL result = %orig;
	[WCRPreferences initSettings];	
	[self WCRInitSettings];
	return result;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	%orig;
	if (notification.userInfo[@"WCREvent"])
	{
		NSLog(@"WCR: Received local notification %@.", notification.userInfo);
		WCRGeneralCommander *generalCommander = [WCRGeneralCommander sharedCommander];
		[generalCommander handleNotification:notification];
	}
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	%orig;
	NSLog(@"WCR: Received memory warning. Need further operation.");
}

%end

%hook UIApplication

- (void)cancelAllLocalNotifications
{
	%orig;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		WCRGeneralCommander *generalCommander = [WCRGeneralCommander sharedCommander];
		[generalCommander scheduleNotifications];
	});
}

%end

%end

%ctor
{
	if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"WeChat"])
	{
		if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"][0] hasPrefix:@"en"])
		{
			NSLog(@"WCR: Non-English environment, bye bye.");
			exit(66);
		}
		else %init(WeChatHook);
	}
}
