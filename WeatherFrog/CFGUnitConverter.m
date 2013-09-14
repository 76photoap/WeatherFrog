//
//  CFGUnitConverter.m
//  WeatherFrog
//
//  Created by Kučera Libor on 18.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CFGUnitConverter.h"
#import "UserDefaultsManager.h"

@implementation CFGUnitConverter

- (NSString*)formatedNumberString:(float)floatNumber
{
    static NSNumberFormatter* numberFormatter = nil;
    if (numberFormatter == nil) {
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [numberFormatter setMaximumFractionDigits:1];
        [numberFormatter setRoundingMode: NSNumberFormatterRoundUp];
    }
    return [numberFormatter stringFromNumber:[NSNumber numberWithFloat:floatNumber]];
}

- (NSString*)convertTemperature:(NSNumber*)temperatureCelsius
{
    NSString* tempUnit = [[UserDefaultsManager sharedDefaults] forecastUnitTemperature];
    float floatCelsiusTemperature = [temperatureCelsius floatValue];
    
    if ([tempUnit isEqualToString:@"K"]) {
        return [NSString stringWithFormat:@"%@ K", [self formatedNumberString:roundf(floatCelsiusTemperature+273.2)]];
    } else if ([tempUnit isEqualToString:@"F"]) {
        return [NSString stringWithFormat:@"%@ F", [self formatedNumberString:roundf(1.8*floatCelsiusTemperature)+32]];
    } else {
        return [NSString stringWithFormat:@"%@°C", [self formatedNumberString:roundf(floatCelsiusTemperature)]];
    }
}

- (NSString*)convertWindDirection:(NSNumber*)windDirectionRadius
{
    float floatWindDirectionRadius = [windDirectionRadius floatValue];
    return [NSString stringWithFormat:@"%@°", [self formatedNumberString:roundf(floatWindDirectionRadius)]];
}

- (NSString*)convertPercent:(NSNumber*)percentValue
{
    float floatPercentValue = [percentValue floatValue];
    return [NSString stringWithFormat:@"%@%%", [self formatedNumberString:floatPercentValue]];
}

- (NSString*)convertWindSpeed:(NSNumber*)windSpeedMetresPerSecond
{
    NSString* speedUnit = [[UserDefaultsManager sharedDefaults] forecastUnitWindspeed];
    float floatWindSpeedMetresPerSecond = [windSpeedMetresPerSecond floatValue];
    
    if ([speedUnit isEqualToString:@"knots"]) {
        return [NSString stringWithFormat:@"%@ k", [self formatedNumberString:(1.94386*floatWindSpeedMetresPerSecond)]];
    } else if ([speedUnit isEqualToString:@"mph"]) {
        return [NSString stringWithFormat:@"%@ mph", [self formatedNumberString:(2.23693*floatWindSpeedMetresPerSecond)]];
    } else {
        return [NSString stringWithFormat:@"%@ m/s", [self formatedNumberString:floatWindSpeedMetresPerSecond]];
    }
}

- (NSString*)convertWindScale:(NSNumber*)windScaleBeaufort
{
    float floatWindScaleBeaufort = [windScaleBeaufort floatValue];
    return [self formatedNumberString:floatWindScaleBeaufort];
}

- (NSString*)convertPrecipitation:(NSNumber*)precipitationMilimetresPerhour
{
    NSString* precipitation = [[UserDefaultsManager sharedDefaults] forecastUnitPrecipitation];
    float floatPrecipitationMilimetresPerhour = [precipitationMilimetresPerhour floatValue];
    
    if ([precipitation isEqualToString:@"in24h"]) {
        return [NSString stringWithFormat:@"%@ in", [self formatedNumberString:(24/25.4*floatPrecipitationMilimetresPerhour)]];
    } else {
        return [NSString stringWithFormat:@"%@ mm", [self formatedNumberString:floatPrecipitationMilimetresPerhour]];
    }
}

- (NSString*)convertPressure:(NSNumber*)presureHectoPascals
{
    NSString* precipitation = [[UserDefaultsManager sharedDefaults] forecastUnitPressure];
    float floatPresureHectoPascals = [presureHectoPascals floatValue];
    
    if ([precipitation isEqualToString:@"mbar"]) {
        return [NSString stringWithFormat:@"%@ mbar", [self formatedNumberString:(floatPresureHectoPascals)]];
    } else {
        return [NSString stringWithFormat:@"%@ hPa", [self formatedNumberString:floatPresureHectoPascals]];
    }
}

- (NSString*)convertAltitude:(NSNumber*)altitudeMetres
{
    NSString* altitude = [[UserDefaultsManager sharedDefaults] forecastUnitAltitude];
    float floatAltitudeMetres = [altitudeMetres floatValue];
    
    if ([altitude isEqualToString:@"ft"]) {
        return [NSString stringWithFormat:@"%@ ft", [self formatedNumberString:(3.28084*floatAltitudeMetres)]];
    } else {
        return [NSString stringWithFormat:@"%@ m", [self formatedNumberString:floatAltitudeMetres]];
    }
}

@end
