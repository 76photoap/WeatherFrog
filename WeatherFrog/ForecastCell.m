//
//  ForecastCell.m
//  WeatherFrog
//
//  Created by Libor Kučera on 14.09.13.
//  Copyright (c) 2013 IC Servis. All rights reserved.
//

#import "ForecastCell.h"
#import "Weather.h"
#import "CFGUnitConverter.h"
#import "AFNetworking.h"

@interface ForecastCell ()

@property (nonatomic, strong) NSDateFormatter* localDateFormatter;
@property (nonatomic, strong) CFGUnitConverter* unitsConverter;

@end

@implementation ForecastCell

- (void)setTimezone:(NSTimeZone *)timezone
{
    _timezone = timezone;
    [self.localDateFormatter setTimeZone:timezone];
}

- (void)setWeather:(Weather *)weather
{
    _weather = weather;
    
    NSNumber* precipitation;
    NSInteger hours = 0;
    if (weather.precipitation1h != nil) {
        precipitation = weather.precipitation1h;
        hours = 1;
    } else if (weather.precipitation2h != nil) {
        precipitation = weather.precipitation2h;
        hours = 2;
    } else if (weather.precipitation3h != nil) {
        precipitation = weather.precipitation3h;
        hours = 3;
    } else if (weather.precipitation6h != nil) {
        precipitation = weather.precipitation6h;
        hours = 6;
    }
    
    NSString* temp = [self.unitsConverter convertTemperature:weather.temperature];
    NSString* precip = [self.unitsConverter convertPrecipitation:precipitation period:hours];
    NSString* wind = [self.unitsConverter convertWindSpeed:weather.windSpeed];
    
    self.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.textLabel.text = [NSString stringWithFormat:@"%@, %@, %@", temp, precip, wind];
    self.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.detailTextLabel.text = [self.localDateFormatter stringFromDate:weather.timestamp];
    
    NSInteger symbol = 0;
    if (weather.symbol1h != nil) {
        symbol = [weather.symbol1h integerValue];
    } else if (weather.symbol2h != nil) {
        symbol = [weather.symbol2h integerValue];
    } else if (weather.symbol3h != nil) {
        symbol = [weather.symbol3h integerValue];
    } else if (weather.symbol6h != nil) {
        symbol = [weather.symbol6h integerValue];
    }
    BOOL isNight = [weather.isNight boolValue];
    
    NSString* imageName = [NSString stringWithFormat:@"weathericon-%i-%d-40", symbol, isNight];
    [self.imageView setImage:[UIImage imageNamed:imageName]];
}

- (NSDateFormatter*)localDateFormatter
{
    if (_localDateFormatter == nil) {
        _localDateFormatter = [[NSDateFormatter alloc] init];
        [_localDateFormatter setDateStyle:NSDateFormatterNoStyle];
        [_localDateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [_localDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    return _localDateFormatter;
}

- (CFGUnitConverter*)unitsConverter
{
    if (_unitsConverter == nil) {
        _unitsConverter = [[CFGUnitConverter alloc] init];
    }
    return _unitsConverter;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
    self.imageView.image = nil;
    //[self.imageView cancelImageRequestOperation];
}

@end
