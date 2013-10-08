//
//  Banner.m
//  WeatherFrog
//
//  Created by Libor Kučera on 02.10.13.
//  Copyright (c) 2013 IC Servis. All rights reserved.
//

#import "AppDelegate.h"
#import "Banner.h"
#import "WeatherfrogInAppPurchaseHelper.h"
#import "DDLog.h"

static NSString* const BannerViewNib = @"BannerView";
static NSString* const BannerViewControllerNib = @"BannerViewController";

@interface Banner ()

@property (nonatomic) NSTimeInterval expirePeriod;
@property (nonatomic) NSUInteger alertsCount;
@property (nonatomic, strong) NSTimer* timer;
@property (nonatomic, strong) NSDateFormatter* localDateFormatter;

@end

@implementation Banner {
    NSArray* _products;
}

#pragma mark - logic

+ (Banner *)sharedBanner {
    
    static Banner* _sharedBanner = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedBanner = [[self alloc] init];
    });
    
    return _sharedBanner;
}

- (void)setupWithDemoPeriod:(NSTimeInterval)expirePeriod alertsCount:(NSUInteger)alertsCount
{
    NSDate* expiryDate = [[UserDefaultsManager sharedDefaults] expiryDate];
    DDLogVerbose(@"expiry date: %@", [self.localDateFormatter stringFromDate:expiryDate]);
    
    self.expirePeriod = expirePeriod;
    self.alertsCount = alertsCount;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
    
    if (expiryDate == nil) {
        
        [self setupExpirePeriod:self.expirePeriod alertsCount:self.alertsCount];
        self.bannerActive = YES;
        
    } else {
        
        if ([expiryDate compare:[NSDate date]] == NSOrderedAscending) {
            
            [self expireLimitedPerion];
            self.bannerActive = YES;
            
        } else {
            
            if ([[WeatherfrogInAppPurchaseHelper sharedInstance] productPurchased:IAP_fullmode]) {
                DDLogVerbose(@"IAP_fullmode activated");
                self.bannerActive = NO;
            } else {
                self.bannerActive = YES;
            }
            
            if ([[WeatherfrogInAppPurchaseHelper sharedInstance] productPurchased:IAP_advancedfeatures]) {
                DDLogVerbose(@"IAP_advancedfeatures activated");
                self.advancedFeaturesActive = YES;
            } else {
                self.advancedFeaturesActive = NO;
            }
        }
    }
    
    [self reloadProductsWithSuccess:^{
        DDLogVerbose(@"products loaded");
    } failure:^{
        DDLogError(@"products failed");
    }];
}

#pragma mark - getters and setters

- (BannerView*)bannerViewLandscape
{
    if (_bannerViewLandscape == nil) {
        NSString* nibName = [NSString stringWithFormat:@"%@-Landscape", BannerViewNib];
        NSArray* nibs = [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
        _bannerViewLandscape = nibs[0];
        _bannerViewLandscape.delegate = self;
        [_bannerViewLandscape setupContent];
    }
    return _bannerViewLandscape;
}

- (BannerView*)bannerViewPortrait
{
    if (_bannerViewPortrait == nil) {
        NSString* nibName = [NSString stringWithFormat:@"%@-Portrait", BannerViewNib];
        NSArray* nibs = [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
        _bannerViewPortrait = nibs[0];
        _bannerViewPortrait.delegate = self;
        [_bannerViewPortrait setupContent];
    }
    return _bannerViewPortrait;
}

- (BannerViewController*)bannerViewController
{
    if (_bannerViewController == nil) {
        _bannerViewController = [[BannerViewController alloc] initWithNibName:BannerViewControllerNib bundle:nil];
        _bannerViewController.delegate = self;
    }
    return _bannerViewController;
}

- (void)setBannerActive:(BOOL)bannerActive
{
    _bannerActive = bannerActive;
    
    if (bannerActive == YES)
        [self.delegate bannerChangedStatus:BannerModeVisible];
    else
        [self.delegate bannerChangedStatus:BannerModeInvisible];
}

- (NSDateFormatter*)localDateFormatter
{
    if (_localDateFormatter == nil) {
        _localDateFormatter = [[NSDateFormatter alloc] init];
        [_localDateFormatter setDateStyle:NSDateFormatterShortStyle];
        [_localDateFormatter setTimeStyle:NSDateFormatterLongStyle];
        [_localDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    return _localDateFormatter;
}

#pragma mark - StoreKit

- (void)storeKitRestorePurchases
{
    DDLogVerbose(@"storeKitRestorePurchases");
    
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if ([appDelegate isInternetActive]) {
        
        [[WeatherfrogInAppPurchaseHelper sharedInstance] restoreCompletedTransactions];
        
    } else {
        
        [self.delegate bannerErrorMessage:NSLocalizedString(@"Can not connect to iTunes Store", nil)];
        
    }
}

- (void)storeKitPerformAction:(NSString*)productIdentifier
{
    DDLogVerbose(@"storeKitPerformAction: %@", productIdentifier);
    
    if (_products == nil) {
        [self.delegate bannerErrorMessage:NSLocalizedString(@"Can not connect to iTunes Store", nil)];
        return;
    }
    
    __block SKProduct* product;
    [_products enumerateObjectsUsingBlock:^(SKProduct* availableProduct, NSUInteger idx, BOOL *stop) {
        
        if ([availableProduct.productIdentifier isEqualToString:productIdentifier]) {
            product = availableProduct;
            *stop = YES;
        }
    }];
    
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if ([appDelegate isInternetActive]) {
       
            DDLogVerbose(@"product requested: %@", product.productIdentifier);
            [[WeatherfrogInAppPurchaseHelper sharedInstance] buyProduct:product];
        
    } else {
        [self.delegate bannerErrorMessage:NSLocalizedString(@"Can not connect to iTunes Store", nil)];
    }
}

- (void)productPurchased:(NSNotification *)notification
{
    NSString * productIdentifier = notification.object;
    DDLogVerbose(@"productIdentifier: %@", productIdentifier);
    
    if ([productIdentifier isEqualToString:IAP_fullmode]) {
        
        [self activateFullOperation];
        self.bannerViewController.mode = BannerViewControllerModeStatic;
        [self.delegate bannerPresentModalViewController:self.bannerViewController];
    }
}

- (void)reloadProductsWithSuccess:(void (^)())success failure:(void (^)())failure
{
    DDLogVerbose(@"reloadProducts");
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if ([appDelegate isInternetActive]) {
        
        [[WeatherfrogInAppPurchaseHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL scs, NSArray *products) {
            if (scs) {
                _products = products;
                success();
            } else {
                failure();
            }
        }];
        
    } else {
        
        failure();
    }
}

#pragma mark - actions

- (void)setupExpirePeriod:(NSTimeInterval)timeinterval alertsCount:(NSUInteger)alertsCount
{
    DDLogVerbose(@"setupExpirePeriod: %f, count: %d", timeinterval, alertsCount);
    [[UserDefaultsManager sharedDefaults] setLimitedMode:NO];
    
    NSDate* expiryDate = [NSDate dateWithTimeIntervalSinceNow:timeinterval];
    [[UserDefaultsManager sharedDefaults] setExpiryDate:expiryDate];
    
    NSDate* nextExpireAlertDate = [NSDate dateWithTimeIntervalSinceNow:timeinterval/alertsCount];
    [[UserDefaultsManager sharedDefaults] setNextExpiryAlertDate:nextExpireAlertDate];
}

- (void)expireLimitedPerion
{
    DDLogVerbose(@"expireLimitedPerion");
    
    [[UserDefaultsManager sharedDefaults] setLimitedMode:YES];
    [[UserDefaultsManager sharedDefaults] setFetchForecastInBackground:NO];
    
    [[UserDefaultsManager sharedDefaults] setExpiryDate:nil];
    [[UserDefaultsManager sharedDefaults] setNextExpiryAlertDate:nil];
}

- (void)setNextExpiryAlertDate
{
    DDLogVerbose(@"setNextExpiryAlertDate");
    NSDate* nextExpiryAlertDate = [[UserDefaultsManager sharedDefaults] nextExpiryAlertDate];
    NSTimeInterval nextExpiryAlertPeriod = self.expirePeriod/self.alertsCount;
    
    [[UserDefaultsManager sharedDefaults] setNextExpiryAlertDate:[NSDate dateWithTimeInterval:nextExpiryAlertPeriod sinceDate:nextExpiryAlertDate]];
}

- (void)activateFullOperation
{
    DDLogVerbose(@"activateFullOperation");
    
    [[UserDefaultsManager sharedDefaults] setLimitedMode:NO];
    [[UserDefaultsManager sharedDefaults] setFetchForecastInBackground:YES];
    
    [[UserDefaultsManager sharedDefaults] setExpiryDate:[NSDate distantFuture]];
    [[UserDefaultsManager sharedDefaults] setNextExpiryAlertDate:[NSDate distantFuture]];
    
    self.bannerActive = NO;
}

- (void)checkAlertPeriod
{
    DDLogVerbose(@"checkAlertPeriod");
    NSDate* todayDate = [NSDate date];
    
    NSDate* expiryDate = [[UserDefaultsManager sharedDefaults] expiryDate];
    DDLogVerbose(@"expiryDate: %@", [self.localDateFormatter stringFromDate:expiryDate]);
    
    NSDate* nextExpiryAlertDate = [[UserDefaultsManager sharedDefaults] nextExpiryAlertDate];
    DDLogVerbose(@"nextExpiryAlertDate: %@", [self.localDateFormatter stringFromDate:nextExpiryAlertDate]);
    
    if (expiryDate != nil && [expiryDate compare:todayDate] == NSOrderedAscending) {
        
        [self expireLimitedPerion];
        [self alertExpireIn:0];
        
    } else if (nextExpiryAlertDate != nil && [nextExpiryAlertDate compare:todayDate] == NSOrderedAscending) {
        
        [self setNextExpiryAlertDate];
        float countOfSecondsToExpire = [expiryDate timeIntervalSinceDate:nextExpiryAlertDate];
        [self alertExpireIn:countOfSecondsToExpire];
    }
}

- (void)applicationDidBecomeActive:(NSNotification*)notification
{
    DDLogVerbose(@"applicationDidBecomeActive");
    self.timer = [NSTimer scheduledTimerWithTimeInterval:kExpiryAlertTimerPeriod target:self selector:@selector(checkAlertPeriod) userInfo:nil repeats:YES];
}

- (void)applicationWillResignActive:(NSNotification*)notification
{
    DDLogVerbose(@"applicationWillResignActive");
    [self.timer invalidate];
}

#pragma mark - BannerViewDelegate

- (void)bannerViewTapped:(UIView *)view
{
    self.bannerViewController.products = _products;
    self.bannerViewController.mode = BannerViewControllerModeDynamic;
    [self.delegate bannerPresentModalViewController:self.bannerViewController];
}

- (void)bannerView:(UIView *)view performAction:(id)sender
{
    if (_products != nil) {
        
        [self storeKitPerformAction:IAP_fullmode];
        
    } else {
        
        [self reloadProductsWithSuccess:^{
            
            [self bannerViewTapped:nil];
            
        } failure:^{
            
            [self.delegate bannerErrorMessage:NSLocalizedString(@"Can not connect to iTunes Store", nil)];
        }];
        
    }
}

#pragma mark - BannerViewControlerDelegate

- (void)bannerViewController:(UIViewController *)controller performAction:(id)sender
{
    UIButton* button = (UIButton*)sender;
    if (button.tag == 3) {
        [self storeKitPerformAction:IAP_advancedfeatures];
    }
    if (button.tag == 2) {
        [self storeKitPerformAction:IAP_fullmode];
    }
    if (button.tag == 1) {
        [self storeKitRestorePurchases];
    }
    [self.delegate bannerDismisModalViewController];
}

- (void)closeBannerViewController:(UIViewController *)controller
{
    [self.delegate bannerDismisModalViewController];
}

- (void)bannerViewController:(UIViewController *)controller reloadProductsWithSuccess:(void (^)())success2 failure:(void (^)())failure2
{
    [self reloadProductsWithSuccess:^{
        BannerViewController* bannerViewController = (BannerViewController*)controller;
        bannerViewController.products = _products;
        success2();
    } failure:^{
        failure2();
    }];
}

#pragma mark - UIAlertView actions

- (void)alertExpireIn:(float)secondsToExpire
{
    DDLogVerbose(@"secondsToExpire: %.2f", secondsToExpire);
    NSString* message;
    
    if (secondsToExpire > 0) {
        message = [NSString stringWithFormat:@"%@ %.2f %@", NSLocalizedString(@"Evaluating period is going to expire in", nil), secondsToExpire/3600, NSLocalizedString(@"hours, please see more details about.", nil)];
    } else {
        message = NSLocalizedString(@"Evaluating period expired, plase see more details about.", nil);
    }
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Background notifications", nil) message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:NSLocalizedString(@"More…", nil), nil];
    [alertView show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self bannerViewTapped:nil];
    }
}

#pragma mark - formatters

- (NSString*)timeRemainingFormatted:(BOOL)shortFormat
{
    NSDate* expiryDate = [[UserDefaultsManager sharedDefaults] expiryDate];
    NSDate* todayDate = [NSDate date];
    
    if ([todayDate compare:expiryDate] == NSOrderedDescending || expiryDate == nil) {
        if (shortFormat == YES) {
            return NSLocalizedString(@"expired", nil);
        } else {
            return NSLocalizedString(@"Period expired", nil);
        }
    }
    
    NSCalendar* sysCalendar = [NSCalendar currentCalendar];
    unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit;
    NSDateComponents* conversionInfo = [sysCalendar components:unitFlags fromDate:todayDate  toDate:expiryDate  options:0];
    
    if (shortFormat == YES) {
        if ([conversionInfo day] > 0) {
            return [NSString stringWithFormat:@"%d %@", [conversionInfo day], NSLocalizedString(@"days", nil)];
        } else {
            return [NSString stringWithFormat:@"%02i:%02i", [conversionInfo hour], [conversionInfo minute]];
        }
    } else {
        if ([conversionInfo day] > 0) {
            return [NSString stringWithFormat:@"%@ %d %@", NSLocalizedString(@"Remaining", nil), [conversionInfo day], NSLocalizedString(@"days", nil)];
        } else {
            return [NSString stringWithFormat:@"%@: %02i:%02i", NSLocalizedString(@"Remaining time", nil), [conversionInfo hour], [conversionInfo minute]];
        }
    }
}

@end
