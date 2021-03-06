//
//  Astro.h
//  WeatherFrog
//
//  Created by Libor Kučera on 21.08.13.
//  Copyright (c) 2013 IC Servis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Forecast;

@interface Astro : NSManagedObject

@property (nonatomic, retain) NSDate * sunRise;
@property (nonatomic, retain) NSDate * sunSet;
@property (nonatomic, retain) NSNumber * sunNeverRise;
@property (nonatomic, retain) NSNumber * sunNeverSet;
@property (nonatomic, retain) NSNumber * dayLength;
@property (nonatomic, retain) NSNumber * noonAltitude;
@property (nonatomic, retain) NSString * moonPhase;
@property (nonatomic, retain) NSDate * moonRise;
@property (nonatomic, retain) NSDate * moonSet;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) Forecast *forecast;

@end
