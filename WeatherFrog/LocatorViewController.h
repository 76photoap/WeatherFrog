//
//  LocatorViewController.h
//  WeatherFrog
//
//  Created by Libor Kučera on 17.08.13.
//  Copyright (c) 2013 IC Servis. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LocatorViewControllerDelegate <NSObject>

@end

@interface LocatorViewController : UIViewController<MKMapViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<LocatorViewControllerDelegate> delegate;
@property (nonatomic, strong) CLLocation* selectedLocation;
@property (nonatomic, strong) CLPlacemark* selectedPlacemark;

@end
