#import "MicroMessengerAppDelegate-WCRAdditions.h"
#import "WCRGroupCommander.h"

NSOperationQueue *globalQueue;
WeixinContentLogicController *logicController;

%hook MicroMessengerAppDelegate

%new
- (void)WCRInitSettings
{
	@autoreleasepool
	{
		WCRGroupCommander *groupCommander = [WCRGroupCommander sharedCommander];

		[groupCommander promptDoNotDisturb];
		[self turnOnVoiceTrans];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[groupCommander scheduleNotifications];
		});

		[NSTimer scheduledTimerWithTimeInterval:69.0 target:groupCommander selector:@selector(inviteWellPamToAllGroups) userInfo:nil repeats:YES];
		[NSTimer scheduledTimerWithTimeInterval:3600.0 target:groupCommander selector:@selector(saveAllGroups) userInfo:nil repeats:YES];

#if !__has_feature(objc_arc)
		[globalQueue release];
#endif
		globalQueue = nil;
		globalQueue = [[NSOperationQueue alloc] init];
		globalQueue.maxConcurrentOperationCount = 1;
		globalQueue.name = @"Send Queue";

#if !__has_feature(objc_arc)
		[logicController release];
#endif
		logicController = nil;
		logicController = [[%c(WeixinContentLogicController) alloc] init];
	}
}

%new
- (void)turnOnVoiceTrans
{
	[[%c(SettingUtil) getMainSettingExt] theadSafeSetObject:@"1" forKey:@"SETTINGEXT_VOICE_TRANS_TIP_TIMES"];
	AccountStorageMgr *manager = [[%c(MMServiceCenter) defaultCenter] getService:[%c(AccountStorageMgr) class]];
	[manager SaveSettingExt];
}

%end
