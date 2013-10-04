//
//  BannerViewController.m
//  WeatherFrog
//
//  Created by Libor Kučera on 01.10.13.
//  Copyright (c) 2013 IC Servis. All rights reserved.
//

#import "BannerViewController.h"

@interface BannerViewController ()

@property (nonatomic, weak) IBOutlet UIButton* closeButton;
@property (nonatomic, weak) IBOutlet UIButton* fullModeButton;
@property (nonatomic, weak) IBOutlet UIButton* advancedFeaturesButton;
@property (nonatomic, weak) IBOutlet UIButton* reloadProductsButton;
@property (nonatomic, weak) IBOutlet UIButton* restoreButton;
@property (nonatomic, weak) IBOutlet UIView* staticView;
@property (nonatomic, weak) IBOutlet UILabel* infoLabel;
@property (nonatomic, weak) IBOutlet UIScrollView* scrollView;
@property (nonatomic, weak) IBOutlet UIPageControl* pageConroll;

- (IBAction)fullModeButtonTapped:(id)sender;
- (IBAction)advancedFeaturesButtonTapped:(id)sender;
- (IBAction)reloadProductsButtonTapped:(id)sender;
- (IBAction)restoreButtonTapped:(id)sender;
- (IBAction)closeButtonTapped:(id)sender;
- (IBAction)pageControllValueChanged:(id)sender;

@end

@implementation BannerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    DDLogVerbose(@"viewDidLoad");
    if (self.mode == BannerViewControllerModeDynamic) {
        [self dynamicMode];
    } else {
        [self staticMode];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - setters and getters

- (void)setMode:(BannerViewControllerMode)mode
{
    DDLogVerbose(@"mode: %d", mode);
    _mode = mode;
    
    if ([self isViewLoaded]) {
        
        if (mode == BannerViewControllerModeDynamic) {
            [self dynamicMode];
        } else {
            [self staticMode];
        }
    }
}

- (void)setProducts:(NSArray *)products
{
    DDLogVerbose(@"_products: %@", [products description]);
    _products = products;
}

#pragma mark - modes

- (void)dynamicMode
{
    self.scrollView.hidden = NO;
    self.fullModeButton.hidden = NO;
    self.pageConroll.hidden = NO;
    self.staticView.hidden = YES;
    
    self.infoLabel.text = nil;
}

- (void)staticMode
{
    self.scrollView.hidden = YES;
    self.fullModeButton.hidden = YES;
    self.pageConroll.hidden = YES;
    self.staticView.hidden = NO;
    
    self.infoLabel.text = NSLocalizedString(@"Thank you for supporting us", nil);
}

- (IBAction)fullModeButtonTapped:(id)sender
{
    [self.delegate bannerViewController:self performAction:sender];
}

- (IBAction)advancedFeaturesButtonTapped:(id)sender
{
    [self.delegate bannerViewController:self performAction:sender];
}

- (IBAction)reloadProductsButtonTapped:(id)sender
{
    self.reloadProductsButton.enabled = NO;
    [self.delegate bannerViewController:self reloadProductsWithSuccess:^{
        self.reloadProductsButton.enabled = YES;
    } failure:^{
        self.reloadProductsButton.enabled = YES;
    }];
}

- (IBAction)restoreButtonTapped:(id)sender
{
    [self.delegate bannerViewController:self performAction:sender];
}

- (IBAction)closeButtonTapped:(id)sender
{
    [self.delegate closeBannerViewController:self];
}

- (IBAction)pageControllValueChanged:(id)sender
{
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
}

@end
