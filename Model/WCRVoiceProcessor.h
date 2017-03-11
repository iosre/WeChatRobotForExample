#import "../WeChatRobotForExample.h"

typedef void (^VoiceToTextCallback)(NSString *text);

@interface WCRVoiceProcessor : NSObject

@property (nonatomic, copy) VoiceToTextCallback voiceToTextCallback;
@property (nonatomic, retain) NSMutableDictionary *voiceDownloadInfo;
@property (nonatomic, retain) VoiceTransHelper *helper;
@property (nonatomic, retain) NSString *lastVoiceID;

+ (instancetype)sharedProcessor;
- (void)convertVoiceWrap:(CMessageWrap *)wrap completion:(VoiceToTextCallback)completion;

@end
