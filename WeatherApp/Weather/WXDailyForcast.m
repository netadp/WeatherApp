//
//  WXDailyForcast.m
//  WeatherApp
//
//  Created by Jie Huo on 18/2/14.
//  Copyright (c) 2014 Jie Huo. All rights reserved.
//

#import "WXDailyForcast.h"

@implementation WXDailyForcast
+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    // 1
    NSMutableDictionary *paths = [[super JSONKeyPathsByPropertyKey] mutableCopy];
    // 2
    paths[@"tempHigh"] = @"temp.max";
    paths[@"tempLow"] = @"temp.min";
    // 3
    return paths;
}

@end
