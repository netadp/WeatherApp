//
//  WXManager.m
//  WeatherApp
//
//  Created by Jie Huo on 18/2/14.
//  Copyright (c) 2014 Jie Huo. All rights reserved.
//

#import "WXManager.h"
#import "WXClient.h"
#import <TSMessages/TSMessage.h>

@interface WXManager ()
@property (nonatomic, strong, readwrite) WXCondition *currentCondition;
@property (nonatomic, strong, readwrite) CLLocation *currentLocation;
@property (nonatomic, strong, readwrite) NSArray *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray *dailyForecast;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isFirstUpdate;
@property (nonatomic, strong) WXClient *client;
@end

@implementation WXManager

+(instancetype)sharedManager
{
	static id _sharedManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedManager = [[self alloc]init];
	});
	
	return _sharedManager;
}

-(id)init
{
	if (self = [super init]) {
		_locationManager = [[CLLocationManager alloc]init];
		_locationManager.delegate = self;
		
		// handles all networking and data parsing
		_client = [[WXClient alloc]init];
		
		[[[[RACObserve(self, currentLocation) ignore:nil]
		   // if flattens the values and returns one object containing all three signals
		   // in this way, three processes can be considered as a single unit of work.
		 flattenMap:^RACStream *(CLLocation *newLocation) {
			 NSLog(@"merge");
			 return [RACSignal merge:@[[self updateCurrentConditions],[self updateDailyForecast], [self updateHourlyForecast]]];
		 }]
		  // Deliver the signal to subscribers on the main thread.
		  deliverOn:[RACScheduler mainThreadScheduler]]
		 // It's not a good practice to interact with the UI from inside your model
		 subscribeError:^(NSError *error) {
			 [TSMessage showNotificationWithTitle:@"Error" subtitle:@"There was a problem fetching the latest weather" type:TSMessageNotificationTypeError];
		 }];
	}
	
	return self;
}

-(void)findCurrentLocation
{
	self.isFirstUpdate = YES;
	[self.locationManager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	// ignore the first location update because it is almost always cached
	if (self.isFirstUpdate) {
		self.isFirstUpdate = NO;
		return;
	}
	
	CLLocation *location = [locations lastObject];
	
	// once have a location with proper accuracy, stop further updates;
	if (location.horizontalAccuracy > 0) {
		// set the location key trrigers the RACObservable you set earlier in the init implementation.
		self.currentLocation = location;
		[self.locationManager stopUpdatingLocation];
	}
}

-(RACSignal *)updateCurrentConditions
{
	return [[self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate] doNext:^(WXCondition *condition){
		self.currentCondition = condition;
	}];
}

-(RACSignal*)updateHourlyForecast
{
	return [[self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions){
		self.hourlyForecast = conditions;
	}];
}

-(RACSignal*)updateDailyForecast
{
	return [[self.client fetchDailyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions){
		self.dailyForecast = conditions;
	}];
}
@end
