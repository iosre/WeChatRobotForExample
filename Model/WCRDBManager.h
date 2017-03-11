#import "../WeChatRobotForExample.h"

@interface WCRDBManager : NSObject

@property (nonatomic, retain) dispatch_queue_t databaseQueue;

+ (instancetype)defaultManager;
- (void)initializeDBFile;
- (void)initializeChatHistory;
- (void)recordChatHistoryWithWrap:(CMessageWrap *)wrap;
- (void)recordChatHistoryWithMessageInfo:(NSDictionary *)messageInfo;

@end
