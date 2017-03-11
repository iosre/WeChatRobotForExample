#import "WCRGlobalHeader.h"

static WCRSearchManager *defaultManager;

@implementation WCRSearchManager

@synthesize buildingSearchContext;

+ (void)initialize
{
	if (self == [WCRSearchManager class]) defaultManager = [[self alloc] init];
}

+ (instancetype)defaultManager
{
	return defaultManager;
}

- (instancetype)init
{
	if (self = [super init])
	{
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *filePath = [[WCRPreferences settingsPath] stringByAppendingPathComponent:@"buildingSearchContext.plist"];
		if (![fileManager fileExistsAtPath:filePath]) [@{} writeToFile:filePath atomically:YES];
		NSData *contextData = [[NSData alloc] initWithContentsOfFile:filePath];
#if !__has_feature(objc_arc)			
		[buildingSearchContext release];
#endif
		buildingSearchContext = nil;
		buildingSearchContext = [[NSMutableDictionary alloc] initWithDictionary:[NSKeyedUnarchiver unarchiveObjectWithData:contextData]];
#if !__has_feature(objc_arc)			
		[contextData release];
#endif
		contextData = nil;
	}
	return self;
}

- (void)setBuildingSearchContext:(NSArray *)buildings forUser:(NSString *)userID
{
	@autoreleasepool
	{
		self.buildingSearchContext[userID] = buildings;
		NSString *filePath = [[WCRPreferences settingsPath] stringByAppendingPathComponent:@"buildingSearchContext.plist"];
		NSData *contextData = [NSKeyedArchiver archivedDataWithRootObject:self.buildingSearchContext];
		[contextData writeToFile:filePath atomically:YES];
	}
}

- (NSArray *)buildingsWithName:(NSString *)buildingName forUser:(NSString *)userID
{
	@autoreleasepool
	{
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://api2.example.com.cn/api/building/searchList"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
		request.HTTPMethod = @"POST";
		NSError *error = nil;
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"buildingName" : buildingName, @"pageNO" : @1, @"pageSize" : @6666} options:NSJSONWritingPrettyPrinted error:&error];
		if (error)
		{
			NSLog(@"WCR: Failed to generate json from %@, error = %@.", buildingName, error);
			return @[];
		}
		request.HTTPBody = jsonData;
		NSURLResponse *response = nil;
		error = nil;
		NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		if (error)
		{
			NSLog(@"WCR: Failed to get data from %@, error = %@.", request.URL, error);
			return @[];
		}
		NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
		error = nil;
		NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&error];
		if (error)
		{
			NSLog(@"WCR: Failed to get dictionary from %@, error = %@.", responseString, error);
			return @[];
		}
#if !__has_feature(objc_arc)	
		[responseString release];
#endif
		responseString = nil;
		if (((NSNumber *)(responseDictionary[@"code"])).intValue == 200) return responseDictionary[@"data"][@"buildings"];
		NSLog(@"WCR: Failed to search %@, response = %@.", buildingName, responseDictionary);
		return @[];
	}
}

- (NSArray *)localBuildingsWithName:(NSString *)buildingName forUser:(NSString *)userID
{
	@autoreleasepool
	{
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[[NSString stringWithFormat:@"http://192.168.0.66:6969?buildingName=%@", buildingName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
		request.HTTPMethod = @"GET";
		NSURLResponse *response = nil;
		NSError *error = nil;
		NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		if (error)
		{
			NSLog(@"WCR: Failed to get data from %@, error = %@.", request.URL, error);
			return @[];
		}
		NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
		NSArray *buildings = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&error];
		if (error)
		{
			NSLog(@"WCR: Failed to get array from %@, error = %@.", responseString, error);
			return @[];
		}
#if !__has_feature(objc_arc)	
		[responseString release];
#endif
		responseString = nil;
		return buildings;
	}
}

- (NSString *)buildingsDescriptionWithName:(NSString *)buildingName forUser:(NSString *)userID
{
	@autoreleasepool
	{
		// return [WCRPreferences noBuildingFound]; // temporary

		NSArray *buildings = [self buildingsWithName:buildingName forUser:userID];
		[self setBuildingSearchContext:buildings forUser:userID];	
		if (buildings.count == 1) return [self buildingDescriptionAtIndex:0 forUser:userID];
		NSMutableString *buildingsDescription = [NSMutableString stringWithString:@""];
		for (NSUInteger i = 0; i < buildings.count; i++) [buildingsDescription appendString:[NSString stringWithFormat:@"%tu. %@\r", i + 1, buildings[i][@"buildingNameCn"]]];
		if ([buildingsDescription hasSuffix:@"\r"]) buildingsDescription = [NSMutableString stringWithString:[buildingsDescription substringToIndex:buildingsDescription.length - 1]];
		if (buildings.count > 16) return [NSString stringWithFormat:@"我为您找到了%tu栋楼，都发出来的话有人又要说我刷屏了😥能告诉我更准确一点的楼名吗😝", buildings.count];
		if (buildingsDescription.length != 0) return [NSString stringWithFormat:@"我为您找到了%tu栋楼，您要看哪一栋？输入楼名前面的数字并@我就可以了哦😉\r%@", buildings.count, buildingsDescription];
		/*
		   else
		   {
		   buildings = [self localBuildingsWithName:buildingName forUser:userID];
		   [self setBuildingSearchContext:buildings forUser:userID];	
		   if (buildings.count == 1) return [self localBuildingDescriptionAtIndex:0 forUser:userID];
		   buildingsDescription = [NSMutableString stringWithString:@""];
		   for (NSUInteger i = 0; i < buildings.count; i++) [buildingsDescription appendString:[NSString stringWithFormat:@"%tu. %@\r", i + 1, buildings[i][@"楼盘名"]]];
		   if ([buildingsDescription hasSuffix:@"\r"]) buildingsDescription = [NSMutableString stringWithString:[buildingsDescription substringToIndex:buildingsDescription.length - 1]];
		   if (buildings.count > 16) return [NSString stringWithFormat:@"我为您找到了%tu栋楼，都发出来的话有人又要说我刷屏了😥能告诉我更准确一点的楼名吗😝", buildings.count];
		   if (buildingsDescription.length != 0) [NSString stringWithFormat:@"我为您找到了%tu栋楼，您要看哪一栋？输入楼名前面的数字并@我就可以了哦😉\r%@", buildings.count, buildingsDescription];		
		   }
		 */
		return [WCRPreferences noBuildingFound];
	}
}

- (NSString *)buildingDescriptionAtIndex:(NSUInteger)index forUser:(NSString *)userID
{
	@autoreleasepool
	{
		if (index >= ((NSArray *)(self.buildingSearchContext[userID])).count) return [WCRPreferences wrongCommand];

		NSDictionary *building = self.buildingSearchContext[userID][index];

		NSString *buildingNameCn = building[@"buildingNameCn"];
		buildingNameCn = buildingNameCn.length == 0 ? @"" : [NSString stringWithFormat:@"\r楼盘名：%@", buildingNameCn];

		NSString *buildingNameEn = building[@"buildingNameEn"];
		buildingNameEn = buildingNameEn.length == 0 ? @"" : [NSString stringWithFormat:@"\r英文名：%@", buildingNameEn];

		NSString *buildingAddress = building[@"buildingAddress"];
		buildingAddress = buildingAddress.length == 0 ? @"" : [NSString stringWithFormat:@"\r地址：%@", buildingAddress];

		NSString *availableArea = building[@"availableArea"];
		availableArea = availableArea.length == 0 ? @"" : [NSString stringWithFormat:@"\r空置面积：%@ ㎡", availableArea];

		NSString *ceilingHeight = building[@"ceilingHeight"];
		ceilingHeight = ceilingHeight.length == 0 ? @"" : [NSString stringWithFormat:@"\r层高：%@ m", ceilingHeight];

		NSString *managementFee = building[@"managementFee"];
		managementFee = managementFee.length == 0 ? @"" : [NSString stringWithFormat:@"\r物业费：%@ 元/㎡/月", managementFee];

		NSString *parkingFee = building[@"parkingFee"];
		parkingFee = parkingFee.length == 0 ? @"" : [NSString stringWithFormat:@"\r停车费：%@ 元/月", parkingFee];

		NSString *nearbySubways = building[@"nearbySubways"];
		nearbySubways = nearbySubways.length == 0 ? @"" : [NSString stringWithFormat:@"\r周边地铁：%@", [nearbySubways stringByReplacingOccurrencesOfString:@"," withString:@"、"]];

		NSString *businessDistrictName = building[@"businessDistrictName"];
		businessDistrictName = businessDistrictName.length == 0 ? @"" : [NSString stringWithFormat:@"\r所处商圈：%@", businessDistrictName];

		NSString *handoverStandard = building[@"handoverStandard"];
		handoverStandard = handoverStandard.length == 0 ? @"" : [NSString stringWithFormat:@"\r交房标准：%@", handoverStandard];

		NSString *majorTenants = building[@"majorTenants"];
		majorTenants = majorTenants.length == 0 ? @"" : [NSString stringWithFormat:@"\r现有租户：%@", majorTenants];

		NSString *description = [NSString stringWithFormat:@"您要的数据我已经为您准备好了😊%@%@%@%@%@%@%@%@%@%@%@\r就是这样啦~", buildingNameCn, buildingNameEn, buildingAddress, availableArea, ceilingHeight, managementFee, parkingFee, nearbySubways, businessDistrictName, handoverStandard, majorTenants];

		[self setBuildingSearchContext:[NSArray array] forUser:userID];

		return description;
	}
}

- (NSString *)localBuildingDescriptionAtIndex:(NSUInteger)index forUser:(NSString *)userID
{
	@autoreleasepool
	{
		if (index >= ((NSArray *)(self.buildingSearchContext[userID])).count) return [WCRPreferences wrongCommand];

		NSDictionary *building = self.buildingSearchContext[userID][index];

		NSString *buildingNameCn = building[@"楼盘名"];
		buildingNameCn = [buildingNameCn stringByReplacingOccurrencesOfString:@"(自用)" withString:@""];	
		buildingNameCn = [buildingNameCn stringByReplacingOccurrencesOfString:@" " withString:@""];	
		buildingNameCn = buildingNameCn.length == 0 ? @"" : [NSString stringWithFormat:@"\r楼盘名：%@", buildingNameCn];

		NSString *buildingNameEn = building[@"英文名"];
		buildingNameEn = buildingNameEn.length == 0 ? @"" : [NSString stringWithFormat:@"\r英文名：%@", buildingNameEn];

		NSString *buildingAddress = building[@"地址"];
		buildingAddress = [buildingAddress stringByReplacingOccurrencesOfString:@"(核心区)" withString:@""];
		buildingAddress = [buildingAddress stringByReplacingOccurrencesOfString:@" " withString:@""];
		buildingAddress = buildingAddress.length == 0 ? @"" : [NSString stringWithFormat:@"\r地址：%@", buildingAddress];

		NSString *adminDistrictName = building[@"行政区"];
		adminDistrictName = adminDistrictName.length == 0 ? @"" : [NSString stringWithFormat:@"\r行政区：%@", adminDistrictName];

		NSString *businessDistrictName = building[@"商圈"];
		businessDistrictName = businessDistrictName.length == 0 ? @"" : [NSString stringWithFormat:@"\r所处商圈：%@", businessDistrictName];

		NSString *buildingGrade = building[@"等级"];
		buildingGrade = buildingGrade.length == 0 ? @"" : [NSString stringWithFormat:@"\r等级：%@", buildingGrade];

		NSString *developer = building[@"开发商"];
		developer = developer.length == 0 ? @"" : [NSString stringWithFormat:@"\r开发商：%@", developer];

		NSString *floors = building[@"层数"];
		floors = floors.length == 0 ? @"" : [NSString stringWithFormat:@"\r层数：%@", floors];

		NSString *ceilingHeight = building[@"层高"];
		ceilingHeight = [ceilingHeight stringByReplacingOccurrencesOfString:@"m" withString:@""];
		ceilingHeight = [ceilingHeight stringByReplacingOccurrencesOfString:@"米" withString:@""];
		ceilingHeight = [ceilingHeight stringByReplacingOccurrencesOfString:@" " withString:@""];
		ceilingHeight = ceilingHeight.length == 0 ? @"" : [NSString stringWithFormat:@"\r层高：%@ m", ceilingHeight];

		NSString *area = building[@"标准层面积"];
		area = [area stringByReplacingOccurrencesOfString:@"㎡" withString:@""];
		area = [area stringByReplacingOccurrencesOfString:@" " withString:@""];
		area = [area stringByReplacingOccurrencesOfString:@"~" withString:@" - "];
		area = area.length == 0 ? @"" : [NSString stringWithFormat:@"\r标准层面积：%@ ㎡", area];

		NSString *efficiencyRate = building[@"得房率"];
		efficiencyRate = efficiencyRate.length == 0 ? @"" : [NSString stringWithFormat:@"\r得房率：%@", efficiencyRate];

		NSString *managementFee = building[@"物业费"];
		managementFee = [managementFee stringByReplacingOccurrencesOfString:@"￥" withString:@""];
		managementFee = [managementFee stringByReplacingOccurrencesOfString:@"元" withString:@""];
		managementFee = [managementFee stringByReplacingOccurrencesOfString:@"/" withString:@""];
		managementFee = [managementFee stringByReplacingOccurrencesOfString:@"m²" withString:@""];
		managementFee = [managementFee stringByReplacingOccurrencesOfString:@"月" withString:@""];
		managementFee = managementFee.length == 0 ? @"" : [NSString stringWithFormat:@"\r物业费：%@ 元/㎡/月", managementFee];

		NSString *managementFirm = building[@"物业公司"];
		managementFirm = managementFirm.length == 0 ? @"" : [NSString stringWithFormat:@"\r物业公司：%@", managementFirm];

		NSString *nearbySubways = building[@"周边地铁"];
		nearbySubways = [nearbySubways stringByReplacingOccurrencesOfString:@"(在建)" withString:@""];
		nearbySubways = [nearbySubways stringByReplacingOccurrencesOfString:@";" withString:@"、"];
		nearbySubways = [nearbySubways stringByReplacingOccurrencesOfString:@"," withString:@"、"];
		nearbySubways = [nearbySubways stringByReplacingOccurrencesOfString:@" " withString:@""];
		nearbySubways = nearbySubways.length == 0 ? @"" : [NSString stringWithFormat:@"\r周边地铁：%@", nearbySubways];

		NSString *handoverStandard = building[@"交房标准"];
		handoverStandard = handoverStandard.length == 0 ? @"" : [NSString stringWithFormat:@"\r交房标准：%@", handoverStandard];

		NSString *telephone = building[@"业主电话"];
		telephone = telephone.length == 0 ? @"" : [NSString stringWithFormat:@"\r业主电话：%@", telephone];

		NSString *askingRent = building[@"租金报价"];
		askingRent = [askingRent stringByReplacingOccurrencesOfString:@"￥" withString:@""];
		askingRent = [askingRent stringByReplacingOccurrencesOfString:@"/" withString:@""];
		askingRent = [askingRent stringByReplacingOccurrencesOfString:@"m²" withString:@""];
		askingRent = [askingRent stringByReplacingOccurrencesOfString:@"元" withString:@""];
		askingRent = [askingRent stringByReplacingOccurrencesOfString:@"天" withString:@""];
		askingRent = [askingRent stringByReplacingOccurrencesOfString:@"~" withString:@" - "];
		askingRent = askingRent.length == 0 ? @"" : [NSString stringWithFormat:@"\r租金报价：%@ 元/㎡/天", askingRent];

		NSString *completionTime = building[@"竣工时间"];
		completionTime = completionTime.length == 0 ? @"" : [NSString stringWithFormat:@"\r竣工时间：%@", completionTime];

		NSString *airConditioner = building[@"空调"];
		airConditioner = airConditioner.length == 0 ? @"" : [NSString stringWithFormat:@"\r空调：%@", airConditioner];

		NSString *elevator = building[@"电梯"];
		elevator = elevator.length == 0 ? @"" : [NSString stringWithFormat:@"\r电梯：%@", elevator];

		NSString *description = [NSString stringWithFormat:@"您要的数据我已经为您准备好了😊%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@\r就是这样啦~", buildingNameCn, buildingNameEn, buildingAddress, adminDistrictName, businessDistrictName, buildingGrade, developer, floors, ceilingHeight, area, efficiencyRate, managementFee, managementFirm, nearbySubways, handoverStandard, telephone, askingRent, completionTime, airConditioner, elevator];

		[self setBuildingSearchContext:[NSArray array] forUser:userID];

		return description;
	}
}
#if !__has_feature(objc_arc)
- (void)dealloc
{
	[buildingSearchContext release];
	buildingSearchContext = nil;

	[super dealloc];
}
#endif
@end
