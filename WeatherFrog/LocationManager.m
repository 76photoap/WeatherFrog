//
//  LocationManager.m
//  WeatherFrog
//
//  Created by Libor Kučera on 24.09.13.
//  Copyright (c) 2013 IC Servis. All rights reserved.
//

#import "AppDelegate.h"
#import "Location.h"
#import "LocationManager.h"
#import "Forecast+Additions.h"
#import "UserDefaultsManager.h"

@implementation LocationManager

- (Location*)locationWithName:(NSString*)name coordinate:(CLLocationCoordinate2D)coordinate altitude:(CLLocationDistance)altitude timezone:(NSTimeZone*)timezone placemark:(CLPlacemark*)placemark
{
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext* currentContext = appDelegate.managedObjectContext;
    
    Location* location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:currentContext];
    
    location.name = name;
    location.latitude = [NSNumber numberWithDouble:coordinate.latitude];
    location.longitude = [NSNumber numberWithDouble:coordinate.longitude];
    location.altitude = [NSNumber numberWithFloat:altitude];
    location.timezone = timezone;
    location.placemark = placemark;
    location.timestamp = [NSDate date];
    location.isMarked = [NSNumber numberWithBool:NO];
    
    DDLogVerbose(@"Location: %@", [location description]);
    
    return location;
}

- (Location*)locationforForecast:(Forecast*)forecast
{
    CLLocation* forecastLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake([forecast.latitude doubleValue], [forecast.longitude doubleValue]) altitude:[forecast.altitude floatValue] horizontalAccuracy:-1 verticalAccuracy:-1 timestamp:forecast.timestamp];
    
    Location* location = [self nearestLocationWith:forecastLocation];
    
    if (location == nil) {
        
        NSString* name = (forecast.name) ? forecast.name : [forecast.placemark title];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([forecast.latitude doubleValue], [forecast.longitude doubleValue]);
        CLLocationDistance altitude = [forecast.altitude floatValue];
        NSTimeZone* timezone = forecast.timezone;
        
        location = [self locationWithName:name coordinate:coordinate altitude:altitude timezone:timezone placemark:forecast.placemark];
        
    } else {
        
        location.timestamp = [NSDate date];
    }
    
    DDLogVerbose(@"Location: %@", [location description]);
    
    return location;
}

- (Location*)locationforPlacemark:(CLPlacemark*)placemark withTimezone:(NSTimeZone*)timezone
{
    Location* location = [self nearestLocationWith:placemark.location];
    
    if (location == nil) {
        
        NSString* name = [placemark title];
        CLLocationCoordinate2D coordinate = placemark.location.coordinate;
        CLLocationDistance altitude = placemark.location.altitude;
        
        location = [self locationWithName:name coordinate:coordinate altitude:altitude timezone:timezone placemark:placemark];
        
    } else {
        
        location.timestamp = [NSDate date];
    }
    
    DDLogVerbose(@"Location: %@", [location description]);
    
    return location;
}

- (Location*)nearestLocationWith:(CLLocation*)selectedLocation
{
    DDLogVerbose(@"nearestLocationWith");
    Location* location;
    
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext* currentContext = appDelegate.managedObjectContext;
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:currentContext];
    [fetchRequest setEntity:entity];
    NSError* error;
    NSArray* locations = [currentContext executeFetchRequest:fetchRequest error:&error];
    
    if (locations != nil) {
        
        NSArray* sortedLocations;
        sortedLocations = [locations sortedArrayUsingComparator:^NSComparisonResult(Location* a, Location* b) {
            
            CLLocation* locationFirst = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake([a.latitude doubleValue], [a.longitude doubleValue]) altitude:[a.altitude floatValue] horizontalAccuracy:-1 verticalAccuracy:-1 timestamp:a.timestamp];
            CLLocationDistance first = [locationFirst distanceFromLocation:selectedLocation];
            
            CLLocation* locationSecond = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake([b.latitude doubleValue], [b.longitude doubleValue]) altitude:[b.altitude floatValue] horizontalAccuracy:-1 verticalAccuracy:-1 timestamp:b.timestamp];
            CLLocationDistance second = [locationSecond distanceFromLocation:selectedLocation];
            
            if (first < second) {
                return NSOrderedAscending;
            } else if (first > second) {
                return NSOrderedDescending;
            } else {
                return  NSOrderedSame;
            }
            
        }];
        
        if (sortedLocations.count > 0) {
            Location* nearestLocation = [sortedLocations firstObject];
            CLLocation* nearestLocationLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake([nearestLocation.latitude doubleValue], [nearestLocation.longitude doubleValue]) altitude:[nearestLocation.altitude floatValue] horizontalAccuracy:-1 verticalAccuracy:-1 timestamp:nearestLocation.timestamp];
            CLLocationDistance nearestLocationDistance = [nearestLocationLocation distanceFromLocation:selectedLocation];
            
            if (nearestLocationDistance < kCLLocationAccuracyHundredMeters) {
                location = nearestLocation;
            }
        }
    }
    
    return location;
}

- (void)deleteLocation:(Location*)location
{
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext* currentContext = appDelegate.managedObjectContext;
    
    [currentContext deleteObject:location];
}

- (void)deleteObsoleteLocations
{
    DDLogInfo(@"deleteObsoleteLocations");
    
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext* currentContext = appDelegate.managedObjectContext;
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:currentContext];
    [fetchRequest setEntity:entity];
    NSTimeInterval timeinterval = [[[UserDefaultsManager sharedDefaults] forecastValidity] floatValue];
    NSPredicate* deletePredicate = [NSPredicate predicateWithFormat:@"timestamp < %@ AND isMarked = NO", [NSDate dateWithTimeIntervalSinceNow:-timeinterval]];
    [fetchRequest setPredicate:deletePredicate];
    NSError* error;
    NSArray* locations = [currentContext executeFetchRequest:fetchRequest error:&error];
    
    [locations enumerateObjectsUsingBlock:^(Location* obj, NSUInteger idx, BOOL *stop) {
        [currentContext deleteObject:obj];
    }];
}

@end
