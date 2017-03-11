#import "../WeChatRobotForExample.h"

typedef void (^ImageDownloadCallback)(UIImage *downloadedImage);
typedef void (^AttachmentDownloadCallback)(NSString *path);

@interface WCRMessageCommander : NSObject

@property (nonatomic, copy) ImageDownloadCallback imageDownloadCallback;
@property (nonatomic, copy) AttachmentDownloadCallback attachmentDownloadCallback;
@property (nonatomic, retain) NSDate *lastBroadcastDate;

+ (instancetype)sharedCommander;
- (NSString *)autoReplyForMessage:(CMessageWrap *)wrap;
- (NSString *)autoReplyForContent:(NSString *)content;
- (NSString *)URLStringFromMessageWrap:(CMessageWrap *)wrap;
- (CMessageWrap *)wrapForExampleToUser:(NSString *)userID;
- (NSDictionary *)appMsgInfoFromURL:(NSString *)url;
- (CMessageWrap *)reWrapForWrap:(CMessageWrap *)wrap toUser:(NSString *)userID;
- (CMessageWrap *)wrapForURL:(NSString *)url toUser:(NSString *)userID;
- (void)sendMessage:(CMessageWrap *)wrap; // Use reWrapForWrap:toUser: and sendMessage: to forward messages.
- (void)waitWithMessage:(CMessageWrap *)wrap;
- (void)forwardMessage:(CMessageWrap *)wrap withReplyContent:(NSString *)content;
- (CMessageWrap *)welcomeMessageWrapForWrap:(CMessageWrap *)wrap;
- (void)replyToUser:(NSDictionary *)userInfo;
- (void)handleGroupMessageWrap:(CMessageWrap *)wrap;
- (void)handlePrivateMessageWrap:(CMessageWrap *)wrap;
- (void)handleVoiceMessageWithInfo:(NSDictionary *)voiceInfo;
- (void)handleTextMessageWrap:(CMessageWrap *)wrap;
- (void)handleAppMessageWrap:(CMessageWrap *)wrap;
- (void)handleImageMessageWrap:(CMessageWrap *)wrap;
- (void)handleUnknownMessageWrap:(CMessageWrap *)wrap;
- (void)handleSystemMessageWrap:(CMessageWrap *)wrap;
- (void)handleChitChatMessageWrap:(CMessageWrap *)wrap;
- (void)saveLastBroadcastDate;
- (void)downloadImageFromWrap:(CMessageWrap *)wrap withCompletion:(ImageDownloadCallback)completion;
- (void)downloadAttachmentFromWrap:(CMessageWrap *)wrap withCompletion:(AttachmentDownloadCallback)completion;

@end
