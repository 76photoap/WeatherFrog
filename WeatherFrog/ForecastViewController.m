//
//  ForecastViewController.m
//  WeatherFrog
//
//  Created by Libor Kučera on 17.08.13.
//  Copyright (c) 2013 IC Servis. All rights reserved.
//

#import "AppDelegate.h"
#import "Forecast+Additions.h"
#import "Location+Store.h"
#import "Weather.h"
#import "ForecastViewController.h"
#import "ForecastCell.h"
#import "MenuViewController.h"
#import "YrApiService.h"
#import "GoogleApiService.h"

static NSString* const imageLogo = @"logo";
static NSString* const imageWaitingFrogLandscape = @"waiting-frog-landscape";
static NSString* const imageWaitingFrogPortrait = @"waiting-frog-portrait";
static NSString* ForecastCellIdentifier = @"ForecastCell";

@class Forecast;

@interface ForecastViewController ()

@property (nonatomic, weak) IBOutlet UIBarButtonItem* revealButtonItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem* actionButtonItem;
@property (nonatomic, weak) IBOutlet UIView* loadingView;
@property (nonatomic, weak) IBOutlet UIView* headerBackground;
@property (nonatomic, weak) IBOutlet UILabel* statusInfo;
@property (nonatomic, weak) IBOutlet UIProgressView* progressBar;
@property (nonatomic, weak) IBOutlet UIImageView* loadingImage;
@property (nonatomic, weak) IBOutlet UIScrollView* scrollView;

- (IBAction)actionButtonTapped:(id)sender;

@end

@implementation ForecastViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - UIApplicationDelegate

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.title = NSLocalizedString(@"Forecast", nil);
    
    [self.revealButtonItem setTarget: self.revealViewController];
    [self.revealButtonItem setAction: @selector(revealToggle:)];
    [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    
    self.delegate = (MenuViewController*)self.revealViewController.rearViewController;
    
    [self displayDefaultScreen];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerUpdate:) name:LocationManagerUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reverseGeocoderUpdate:) name:ReverseGeocoderUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forecastUpdate:) name:ForecastUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forecastProgress:) name:ForecastProgressNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forecastError:) name:ForecastErrorNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.selectedForecast == nil) {
        
        Forecast* lastForecast = [Forecast findFirstOrderedByAttribute:@"timestamp" ascending:NO];
        
        if (lastForecast != nil) {
            
            DDLogInfo(@"forecast restored");
            self.selectedForecast = lastForecast;
            
        } else {
            
            if (self.selectedPlacemark == nil) {
                [self displayDefaultScreen];
            } else {
                DDLogInfo(@"placemark restored");
                [self displayLoadingScreen];
                [self forecast:_selectedPlacemark forceUpdate:NO];
            }
        }
        
    } else {
        
        [self displayForecast:_selectedForecast];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    _selectedForecast = nil;
    _selectedPlacemark = nil;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - UIDeviceDelegate

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self displayRotatingScreen];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self displayForecast:_selectedForecast];
}

#pragma mark - Shared objects

- (AppDelegate*)appDelegate
{
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

#pragma mark - IBActions

- (IBAction)actionButtonTapped:(id)sender
{
    NSString* shareString = NSLocalizedString(@"My current forecast", nil);
    UIImage* shareImage = [UIImage imageNamed:imageLogo];
    NSURL* shareUrl = [NSURL URLWithString:kAPIHost];
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareImage, shareUrl, nil];
    
    UIActivityViewController* activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - Setters and Getters

- (void)setUseSelectedLocationInsteadCurrenLocation:(BOOL)useSelectedLocationInsteadCurrenLocation
{
    DDLogVerbose(@"useSelectedLocationInsteadCurrenLocation: %d", useSelectedLocationInsteadCurrenLocation);
    _useSelectedLocationInsteadCurrenLocation = useSelectedLocationInsteadCurrenLocation;
}

- (void)setSelectedPlacemark:(CLPlacemark *)selectedPlacemark
{
    DDLogVerbose(@"selectedPlacemark: %@", [selectedPlacemark description]);
    _selectedPlacemark = selectedPlacemark;
    [self displayLoadingScreen];
    [self forecast:_selectedPlacemark forceUpdate:NO];
}

- (void)setSelectedForecast:(Forecast *)selectedForecast
{
    DDLogVerbose(@"setSelectedForecast: %@", [selectedForecast description]);
    _selectedForecast = selectedForecast;
    _selectedPlacemark = selectedForecast.placemark;
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground && [self isViewLoaded]) {
        [self displayForecast:_selectedForecast];
    }
}

#pragma mark - Notifications

- (void)locationManagerUpdate:(NSNotification*)notification
{
    DDLogVerbose(@"notification: %@", [notification description]);
}

- (void)reverseGeocoderUpdate:(NSNotification*)notification
{
    DDLogVerbose(@"notification: %@", [notification description]);
}

- (void)forecastUpdate:(NSNotification*)notification
{
    DDLogVerbose(@"notification: %@", [notification description]);
    NSDictionary* userInfo = notification.userInfo;
    if (_useSelectedLocationInsteadCurrenLocation == NO) {
        self.selectedForecast = [userInfo objectForKey:@"currentForecast"];
        
        MenuViewController* menuViewController = (MenuViewController*)self.revealViewController.rearViewController;
        [menuViewController updateCurrentPlacemark:YES];
    }
}

- (void)forecastProgress:(NSNotification*)notification
{
    NSDictionary* userInfo = notification.userInfo;
    if (_useSelectedLocationInsteadCurrenLocation == NO) {
        [self updateProgress:[userInfo objectForKey:@"forecastProgress"]];
    }
}

- (void)forecastError:(NSNotification*)notification
{
    NSDictionary* userInfo = notification.userInfo;
    if (_useSelectedLocationInsteadCurrenLocation == NO) {
        [self updateProgressWithError:[userInfo objectForKey:@"forecastError"]];
    }
}

#pragma mark - User Interface

- (void)showLoadingLayout
{
    self.loadingView.hidden = NO;
    self.scrollView.hidden = YES;
}

- (void)showForecastLayout
{
    self.loadingView.hidden = YES;
    self.scrollView.hidden = NO;
}

- (void)displayForecast:(Forecast*)forecast
{
    if (forecast.name == nil && forecast.timezone == nil) {
        [self displayDefaultScreen];
        return;
    }
    
    DDLogInfo(@"displayForecast");
    
    self.title = forecast.name;
    [self showForecastLayout];
    
    if (isLandscape) {
        [self setupViewsForLandscape:forecast];
    } else {
        [self setupViewsForPortrait:forecast];
    }
}

- (void)displayDefaultScreen
{
    DDLogInfo(@"displayDefaultScreen");
    
    self.title = NSLocalizedString(@"Location not determined", nil);
    [self showLoadingLayout];
    [self updateProgressViewWithValue:0.0f message:NSLocalizedString(@"Location service disabled", nil)];
}

- (void)displayLoadingScreen
{
    DDLogInfo(@"displayLoadingScreen");
    
    self.title = NSLocalizedString(@"Fetchning forecast…", nil);
    [self showLoadingLayout];
    [self updateProgressViewWithValue:0.0f message:nil];
    
    if (isLandscape) {
        self.loadingImage.image = [UIImage imageNamed:imageWaitingFrogLandscape];
    } else {
        self.loadingImage.image = [UIImage imageNamed:imageWaitingFrogPortrait];
    }
}

- (void)displayRotatingScreen
{
    DDLogInfo(@"displayRotatingScreen");
    [self showLoadingLayout];
    [self updateProgressViewWithValue:0.0f message:NSLocalizedString(@"Rotating…", nil)];
    
    if (isLandscape) {
        self.loadingImage.image = [UIImage imageNamed:imageWaitingFrogLandscape];
    } else {
        self.loadingImage.image = [UIImage imageNamed:imageWaitingFrogPortrait];
    }
}

- (void)updateProgress:(NSNumber*)progressNumber
{
    float progress = [progressNumber floatValue];
    [self updateProgressViewWithValue:progress message:nil];
}

- (void)updateProgressWithError:(NSError*)error
{
    DDLogError(@"Error: %@", [error description]);
    [self updateProgressViewWithValue:0.0f message:[error localizedDescription]];
}

#pragma mark - Progress view

- (void)updateProgressViewWithValue:(float)progress message:(NSString*)message
{
    if (message != nil) {
        self.statusInfo.text = message;
    } else {
        self.statusInfo.text = [NSString stringWithFormat:@"%.0f%%", 100*progress];
    }
    [self.progressBar setProgress:progress animated:YES];
}

#pragma mark - Helpers for Views

- (void)purgeSubViews
{
    for (UIView* subview in [self.scrollView subviews]) {
        [subview removeFromSuperview];
    }
}

#pragma mark - Views for Portrait

- (void)setupViewsForPortrait:(Forecast*)forecast
{
    DDLogInfo(@"setupViewsForPortrait");
    [self purgeSubViews];
    
    UITableView* tableView = [[UITableView alloc] initWithFrame:self.scrollView.bounds style:UITableViewStylePlain];
    
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.rowHeight = 44;
    tableView.sectionFooterHeight = 22;
    tableView.sectionHeaderHeight = 22;
    tableView.scrollEnabled = YES;
    tableView.showsVerticalScrollIndicator = YES;
    tableView.userInteractionEnabled = YES;
    tableView.bounces = YES;
    tableView.delegate = self;
    tableView.dataSource = self;
    
    UINib *cellNib = [UINib nibWithNibName:ForecastCellIdentifier bundle:nil];
    [tableView registerNib:cellNib forCellReuseIdentifier:ForecastCellIdentifier];
    
    [self.scrollView addSubview:tableView];
    
}

#pragma mark - Views for Landscape

- (void)setupViewsForLandscape:(Forecast*)forecast
{
    DDLogInfo(@"setupViewsForLandscape");
    [self purgeSubViews];
    
    UITextView* textView = [[UITextView alloc] initWithFrame:self.scrollView.bounds];
    [textView setText:[forecast description]];
    [textView setEditable:NO];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:textView];
}

#pragma mark - UIEvent

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake) {
        DDLogInfo(@"shake gesture");
        if (_selectedPlacemark != nil) {
            [self displayLoadingScreen];
            [self forecast:_selectedPlacemark forceUpdate:YES];
        }
    }
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake) {
        if (_selectedForecast != nil) {
            [self displayForecast:_selectedForecast];
        }
    }
}

#pragma mark - ForecastManager

- (void)forecast:(CLPlacemark*)placemark forceUpdate:(BOOL)force
{
    DDLogInfo(@"forceUpdate: %d", force);
    DDLogVerbose(@"placemark: %@", [placemark description]);
    ForecastManager* forecastManager = [[ForecastManager alloc] init];
    forecastManager.delegate = self;
    [forecastManager forecastWithPlacemark:placemark timezone:nil forceUpdate:force];
}

#pragma mark - ForecastManagerDelegate

- (void)forecastManager:(id)manager didFinishProcessingForecast:(Forecast *)forecast
{
    DDLogInfo(@"didFinishProcessingForecast");
    self.selectedForecast = forecast;
}

- (void)forecastManager:(id)manager didFailProcessingForecast:(Forecast *)forecast error:(NSError *)error
{
    DDLogError(@"Error: %@", [error description]);
    [self updateProgressWithError:error];
}

- (void)forecastManager:(id)manager updatingProgressProcessingForecast:(float)progress
{
    [self updateProgress:[NSNumber numberWithFloat:progress]];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _selectedForecast.weather.count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section
{
    return 44.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0f;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ForecastCell* cell = (ForecastCell *)[tableView dequeueReusableCellWithIdentifier:ForecastCellIdentifier];
    
    cell.timezone = _selectedForecast.timezone;
    cell.weather = [_selectedForecast.weather objectAtIndex:indexPath.row];
    
    return cell;
}

@end
