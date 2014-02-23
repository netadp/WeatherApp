//
//  WXClient.m
//  WeatherApp
//
//  Created by Jie Huo on 18/2/14.
//  Copyright (c) 2014 Jie Huo. All rights reserved.
//

#import "WXClient.h"
#import "WXCondition.h"
#import "WXDailyForcast.h"

@interface WXClient ()
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation WXClient

- (id)init
{
	if (self = [super init]) {
		NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
		_session = [NSURLSession sessionWithConfiguration:config];
	}
	return self;
}

- (RACSignal *)fetchJSONFromURL:(NSURL *)url
{
	NSLog(@"Fetching: %@", url.absoluteString);
	
	// Returns the signal.
	// This method creates an object for other methods and objects to use; This method is sometimes called the
	// factory pattern.
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			// TODO:Handle retrieved data
			if (!error) {
				NSError *jsonError = nil;
				id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
				if (!jsonError) {
					[subscriber sendNext:json];
				}
				else{
					[subscriber sendError:jsonError];
				}
			}
			else{
				[subscriber sendError:error];
			}
			
			[subscriber sendCompleted];
		}];
		
		// starts the network request once someone subscribes to the signal.
		[dataTask resume];
		
		// Creates and returns an RACDisposable object which handles any cleanup when the signal is destroyed.
		return [RACDisposable disposableWithBlock:^{
			[dataTask cancel];
		}];
	}] doError:^(NSError *error) {
		// Add a side effect to log any errors that occur. Sidde effects don't subscribe to the signal;
		// Rather, they return the signal to which they're attached for method chaining.
		NSLog(@"%@",error);
	}];
}

- (RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D)coordinate
{
	NSString *string = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&units=imperial",coordinate.latitude, coordinate.longitude];
	NSURL *url = [NSURL URLWithString:string];
	
	return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
		return [MTLJSONAdapter modelOfClass:[WXCondition class] fromJSONDictionary:json error:nil];
	}];
}

- (RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate {
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast?lat=%f&lon=%f&units=imperial&cnt=12",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
	
    // 1
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // 2
        RACSequence *list = [json[@"list"] rac_sequence];
		
        // 3
        return [[list map:^(NSDictionary *item) {
            // 4
            return [MTLJSONAdapter modelOfClass:[WXCondition class] fromJSONDictionary:item error:nil];
			// 5
        }] array];
    }];
}

- (RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate {
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast/daily?lat=%f&lon=%f&units=imperial&cnt=7",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
	
    // Use the generic fetch method and map results to convert into an array of Mantle objects
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // Build a sequence from the list of raw JSON
        RACSequence *list = [json[@"list"] rac_sequence];
		
        // Use a function to map results from JSON to Mantle objects
        return [[list map:^id (NSDictionary *item) {
            return [MTLJSONAdapter modelOfClass:[WXDailyForcast class] fromJSONDictionary:item error:nil];
        }] array];
    }];
}

@end
