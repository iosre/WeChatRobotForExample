#import "../WeChatRobotForExample.h"
#import "WCRGeneralCommander.h"

@interface WCRGroupCommander : WCRGeneralCommander <UIWebViewDelegate>

@property (nonatomic, retain) UIWebView *webView;

+ (instancetype)sharedCommander;

- (void)acceptGroupInvitationFromURL:(NSString *)URLString;
- (void)webViewDidFinishLoad:(UIWebView *)webView;
- (NSArray *)allGroups;
- (NSString *)allGroupsDescription;
- (NSArray *)membersOfGroup:(NSString *)groupID;
- (NSUInteger)memberCountsOfGroup:(NSString *)groupID;
- (void)inviteUserToRandomGroup:(NSString *)userID;
- (void)inviteUserToAllGroups:(NSString *)userID;
- (void)inviteUser:(NSString *)userID toGroups:(NSArray *)groupIDs;
- (void)introduceGroup:(NSString *)groupID toUsers:(NSArray *)userIDs;
- (void)introduceGroupToAllUsers:(NSString *)groupID;
- (void)muteGroup:(NSString *)groupID;
- (void)muteAllGroups;
- (void)saveGroup:(NSString *)groupID;
- (void)saveAllGroups;
- (void)quitGroup:(NSString *)groupID;
- (void)inviteGodsonToAllGroups;

@end
