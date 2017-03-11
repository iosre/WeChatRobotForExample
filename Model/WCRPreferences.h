#import "../WeChatRobotForExample.h"

@interface WCRPreferences : NSObject

// Initialization
+ (void)initSettings;

// Paths
+ (NSString *)settingsPath;
+ (NSString *)usersPath;
+ (NSString *)bundlePath;
+ (NSString *)chatHistoryPath;

// Info
+ (NSDictionary *)tulingURLs;
+ (NSMutableDictionary *)qrCodePathInfo;
+ (NSDictionary *)exampleWrapInfo;
+ (NSDictionary *)welcomeMessageInfo;
+ (NSDictionary *)robots;

// Replies
+ (NSString *)greetingsWhenFriendsAdded;
+ (NSString *)unrecognizedMessage;
+ (NSString *)exampleManual;
+ (NSString *)wrongCommand;
+ (NSString *)reachedDailyBroadcastLimit;
+ (NSString *)tooLate;
+ (NSString *)groupExchange;
+ (NSString *)noBuildingFound;
+ (NSString *)promoteOfficialAccount;
+ (NSString *)pleaseSendLater;
+ (NSString *)goodNight;

// Miscellaneous
+ (NSArray *)invitationImmuneGroups;
+ (NSArray *)broadcastImmuneGroups;
+ (NSArray *)messageForwardees;
+ (NSArray *)teamExample;
+ (NSArray *)admins;
+ (NSArray *)IFTKeywords;
+ (NSArray *)blackForwardKeywords;
+ (NSArray *)whiteForwardKeywords;
+ (NSArray *)promotionLinks;
+ (NSTimeInterval)broadcastInterval;
+ (NSString *)randomName;
+ (NSString *)broadcastPassport;
+ (NSString *)exampleConversation;
+ (int)onDutyTime;
+ (int)offDutyTime;
+ (int)dailyBroadcastLimit;
+ (void)saveUserWithMessageWrap:(CMessageWrap *)wrap;
+ (void)saveAllUsers;
+ (void)reachUserLimitation:(NSString *)userID;
+ (BOOL)isUserLimited:(NSString *)userID;
+ (BOOL)isBroadcastTooFrequent;
+ (BOOL)isTooLate;

@end
