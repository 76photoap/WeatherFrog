//
//  WeatherProtocol.h
//  WeatherFrog
//
//  Created by Libor Kučera on 28.08.13.
//  Copyright (c) 2013 IC Servis. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WeatherProtocol <NSObject>

@property (nonatomic, retain) NSNumber * temperature;
@property (nonatomic, retain) NSNumber * windDirection;
@property (nonatomic, retain) NSNumber * windSpeed;
@property (nonatomic, retain) NSNumber * windScale;
@property (nonatomic, retain) NSNumber * humidity;
@property (nonatomic, retain) NSNumber * pressure;
@property (nonatomic, retain) NSNumber * cloudiness;
@property (nonatomic, retain) NSNumber * fog;
@property (nonatomic, retain) NSNumber * lowClouds;
@property (nonatomic, retain) NSNumber * mediumClouds;
@property (nonatomic, retain) NSNumber * highClouds;
@property (nonatomic, retain) NSNumber * precipitation1h;
@property (nonatomic, retain) NSNumber * precipitationMin1h;
@property (nonatomic, retain) NSNumber * precipitationMax1h;
@property (nonatomic, retain) NSNumber * precipitation2h;
@property (nonatomic, retain) NSNumber * precipitationMin2h;
@property (nonatomic, retain) NSNumber * precipitationMax2h;
@property (nonatomic, retain) NSNumber * precipitation3h;
@property (nonatomic, retain) NSNumber * precipitationMin3h;
@property (nonatomic, retain) NSNumber * precipitationMax3h;
@property (nonatomic, retain) NSNumber * precipitation6h;
@property (nonatomic, retain) NSNumber * precipitationMin6h;
@property (nonatomic, retain) NSNumber * precipitationMax6h;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * isNight;
@property (nonatomic, retain) NSNumber * symbol1h;
@property (nonatomic, retain) NSNumber * symbol2h;
@property (nonatomic, retain) NSNumber * symbol3h;
@property (nonatomic, retain) NSNumber * symbol6h;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSDate * validTill;

@end
