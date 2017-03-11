#import "../WeChatRobotForExample.h"

@interface WCRSearchManager : NSObject

@property (nonatomic, retain) NSMutableDictionary *buildingSearchContext;
+ (instancetype)defaultManager;
- (void)setBuildingSearchContext:(NSArray *)buildings forUser:(NSString *)userID;
- (NSArray *)buildingsWithName:(NSString *)buildingName forUser:(NSString *)userID;
- (NSArray *)localBuildingsWithName:(NSString *)buildingName forUser:(NSString *)userID;
- (NSString *)buildingsDescriptionWithName:(NSString *)buildingName forUser:(NSString *)userID;
- (NSString *)buildingDescriptionAtIndex:(NSUInteger)index forUser:(NSString *)userID;
- (NSString *)localBuildingDescriptionAtIndex:(NSUInteger)index forUser:(NSString *)userID;

@end
