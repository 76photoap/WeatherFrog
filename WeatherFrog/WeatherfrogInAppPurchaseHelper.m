//
//  LeyterInAppPurchaseHelper.m
//  WeatherFrog.info
//
//  Created by Libor Kučera on 03.06.13.
//  Copyright (c) 2013 IC Servis, s.r.o. All rights reserved.
//

#import "WeatherfrogInAppPurchaseHelper.h"


@implementation WeatherfrogInAppPurchaseHelper

+ (WeatherfrogInAppPurchaseHelper *)sharedInstance {
    static dispatch_once_t once;
    static WeatherfrogInAppPurchaseHelper * sharedInstance;
    dispatch_once(&once, ^{
        
        NSSet * productIdentifiers = [NSSet setWithObjects:
                                      IAP_fullmode,
                                      IAP_advancedfeatures,
                                      nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

@end
