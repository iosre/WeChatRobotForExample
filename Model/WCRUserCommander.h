#import "../WeChatRobotForExample.h"
#import "WCRGeneralCommander.h"

typedef void (^ContactSearchCallback)(CContact *searchedContact);

@interface WCRUserCommander : WCRGeneralCommander

@property (nonatomic, copy) ContactSearchCallback contactSearchCallback;
@property (nonatomic, retain) FindContactSearchViewCellInfo *cellInfo;
@property (nonatomic, retain) MMSearchBar *bar;
@property (nonatomic, retain) MMUISearchBar *uiBar;

+ (instancetype)sharedCommander;
- (NSString *)myName;
- (NSString *)myID;
- (void)encodeUserAlias:(NSString *)userID;
- (NSArray *)allUsers;
- (NSString *)allUsersDescription;
- (BOOL)isAdmin:(NSString *)userID;
- (void)deleteUserAndSession:(NSString *)userID;
- (BOOL)isContact:(NSString *)userID;
- (void)searchUser:(NSString *)userID completion:(ContactSearchCallback)completion;
- (void)tryAddingUser:(NSString *)userID withGreetings:(NSString *)greetings;

@end
