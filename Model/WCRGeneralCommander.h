#import "../WeChatRobotForExample.h"

typedef void (^QRCodeDownloadCallback)(NSString *path);

@interface WCRGeneralCommander : NSObject <UIAlertViewDelegate>

@property (nonatomic, retain) NSMutableString *conversation;
@property (nonatomic, assign) NSUInteger dailyPromotionIndex;
@property (nonatomic, copy) QRCodeDownloadCallback qrCodeDownloadCallback;

+ (instancetype)sharedCommander;
- (NSArray *)allContacts;
- (void)maskMyselfInGroup:(NSString *)groupID;
- (BOOL)amIInGroup:(NSString *)groupID;
- (NSString *)nameOfUser:(NSString *)userID;
- (NSString *)nameOfUser:(NSString *)userID inGroup:(NSString *)groupID;
- (BOOL)isGroupInvitationURL:(NSString *)URLString;
- (void)scheduleNotifications;
- (void)handleNotification:(UILocalNotification *)notification;
- (void)clearAllSessions;
- (void)promptDoNotDisturb;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)saveDailyPromotionIndex;
- (void)saveConversation;
- (void)downloadQRCodeOfUser:(NSString *)userID withCompletion:(QRCodeDownloadCallback)completion;
- (void)saveQRCodePathOfUser:(NSString *)userID;

@end
