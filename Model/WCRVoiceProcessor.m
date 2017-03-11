#import "WCRGlobalHeader.h"

static WCRVoiceProcessor *sharedProcessor;

@implementation WCRVoiceProcessor

@synthesize voiceToTextCallback;
@synthesize voiceDownloadInfo;
@synthesize helper;
@synthesize lastVoiceID;

+ (void)initialize
{
	if (self == [WCRVoiceProcessor class]) sharedProcessor = [[self alloc] init];
}

- (instancetype)init
{
	if (self = [super init])
	{
#if !__has_feature(objc_arc)
		[voiceDownloadInfo release];
#endif
		voiceDownloadInfo = nil;
		voiceDownloadInfo = [@{} mutableCopy];
	}
	return self;
}

+ (instancetype)sharedProcessor
{
	return sharedProcessor;
}

- (void)convertVoiceWrap:(CMessageWrap *)wrap completion:(VoiceToTextCallback)completion
{
	@autoreleasepool
	{
		VoiceTransFloatPreview *preview = [[objc_getClass("VoiceTransFloatPreview") alloc] init];
		NSString *voiceID = [preview getVoiceIDFromMsg:wrap];
		self.helper = nil;
		self.helper = [[objc_getClass("VoiceTransHelper") alloc] initWithVoiceMsg:wrap VoiceID:voiceID];
		[self.helper startVoiceTrans];
#if !__has_feature(objc_arc)			
		[preview release];
#endif
		preview = nil;
		self.voiceToTextCallback = nil;
		self.voiceToTextCallback = completion;
	}
}

#if !__has_feature(objc_arc)		
- (void)dealloc
{
	[lastVoiceID release];
	lastVoiceID = nil;

	[helper release];
	helper = nil;

	[voiceDownloadInfo release];
	voiceDownloadInfo = nil;

	[super dealloc];
}
#endif

@end
