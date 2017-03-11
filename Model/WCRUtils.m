#import "WCRGlobalHeader.h"
#import "KxSMBProvider.h"
#import <CommonCrypto/CommonDigest.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

@implementation WCRUtils

+ (NSString *)md5OfData:(NSData *)data
{
	@autoreleasepool
	{
		unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
		CC_MD5(data.bytes, (CC_LONG)(data.length), md5Buffer);
		NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
		for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) [output appendFormat:@"%02x",md5Buffer[i]];
		return output;
	}
}

+ (NSString *)password
{
	@autoreleasepool
	{
		NSString *lastNameString = @"iOSRE";
		lastNameString = [lastNameString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		lastNameString = [lastNameString lowercaseString];
		NSString *company = @"Naken! Inc.";
		NSString *building = @"6";
		NSString *room = @"666";
		NSString *today = @"2016.6.6";
		NSMutableString *longString = [NSMutableString stringWithFormat:@"%@%@%@%@%@", lastNameString, company, building, room, today];
		[longString replaceOccurrencesOfString:@"%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, longString.length)];
		longString = [NSMutableString stringWithString:[longString lowercaseString]];
		longString = [NSMutableString stringWithString:[self md5OfData:[longString dataUsingEncoding:NSUTF8StringEncoding]]];
		[longString replaceOccurrencesOfString:@"E" withString:@"3" options:NSLiteralSearch range:NSMakeRange(0, longString.length)];
		[longString replaceOccurrencesOfString:@"0" withString:@"O" options:NSLiteralSearch range:NSMakeRange(0, longString.length)];
		[longString replaceOccurrencesOfString:@"c" withString:@"C" options:NSLiteralSearch range:NSMakeRange(0, longString.length)];
		[longString replaceOccurrencesOfString:@"a" withString:@"@" options:NSLiteralSearch range:NSMakeRange(0, longString.length)];
		[longString replaceOccurrencesOfString:@"i" withString:@"!" options:NSLiteralSearch range:NSMakeRange(0, longString.length)];
		[longString replaceOccurrencesOfString:@"1" withString:@"!" options:NSLiteralSearch range:NSMakeRange(0, longString.length)];
		NSString *finalString = [longString substringWithRange:NSMakeRange(6, 16)];
		return finalString;
	}
}

+ (BOOL)copyFile:(NSString *)filePath toPath:(NSString *)destinationPath
{
	NSError *error = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:destinationPath])
	{
		[fileManager copyItemAtPath:filePath toPath:destinationPath error:&error];
		if (error)
		{
			NSLog(@"WCR: Failed to copy %@ to %@, error = %@.", filePath, destinationPath, error);
			return NO;
		}
	}
	return YES;
}

+ (BOOL)moveFile:(NSString *)filePath toPath:(NSString *)destinationPath
{
	NSError *error = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:destinationPath])
	{
		[fileManager moveItemAtPath:filePath toPath:destinationPath error:&error];
		if (error)
		{
			NSLog(@"WCR: Failed to move %@ to %@, error = %@.", filePath, destinationPath, error);
			return NO;
		}
	}
	return YES;
}

+ (BOOL)isNumber:(NSString *)string
{
	NSScanner* scanner = [NSScanner scannerWithString:string];
	int val;
	return [scanner scanInt:&val] && [scanner isAtEnd];
}

+ (NSString *)today
{
	@autoreleasepool
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"yyyy.MM.dd";
		NSString *today = [dateFormatter stringFromDate:[NSDate date]];
#if !__has_feature(objc_arc)		
		[dateFormatter release];
#endif
		dateFormatter = nil;
		return today;
	}
}

+ (NSString *)LANIP
{
	NSString *address = @"";
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;
	success = getifaddrs(&interfaces);
	if (success == 0)
	{
		temp_addr = interfaces;
		while (temp_addr != NULL)
		{
			if (temp_addr->ifa_addr->sa_family == AF_INET)
			{
				if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
				{
					address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
					break;
				}
			}
			temp_addr = temp_addr->ifa_next;
		}
	}
	freeifaddrs(interfaces);
	return address;	
}

@end
