#import "../WeChatRobotForExample.h"

@interface WCRUtils : NSObject <UIAlertViewDelegate>

+ (NSString *)md5OfData:(NSData *)data;
+ (NSString *)password;
+ (BOOL)copyFile:(NSString *)filePath toPath:(NSString *)destinationPath;
+ (BOOL)moveFile:(NSString *)filePath toPath:(NSString *)destinationPath;
+ (BOOL)isNumber:(NSString *)string;
+ (NSString *)today;
+ (NSString *)LANIP;

@end
