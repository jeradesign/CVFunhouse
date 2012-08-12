//
//  CVFFlipsideViewController.m
//  CVFunhouse
//
//  Created by John Brewer on 3/7/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

#import "CVFFlipsideViewController.h"

static NSString *SwitchCellIdentifier = @"SwitchCell";

#define kSliderHeight 7.0
// for tagging our embedded controls for removal at cell recycle time
#define kViewTag 1

@interface CVFFlipsideViewController () {
    int _demoNumber;    
}
@end

@implementation CVFFlipsideViewController
@synthesize menuTable = _menuTable;
@synthesize delegate = _delegate;
@synthesize navBar = _navBar;
@synthesize flipsidePopoverArray = _flipsidePopoverArray;
@synthesize switchCtl = _switchCtl;

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.flipsidePopoverArray = [[NSMutableArray alloc] initWithObjects:
                             @"Canny Edge Detector",
                             @"Face Detector",
                             @"Farneback",
                             @"Laplace",
                             @"Lukas-Kanade",
                             @"Motion Templates",
                             @"Sepia Filter",
                             @"Pass Thru",
                             NULL];

    shouldShowFPS = [[NSUserDefaults standardUserDefaults] boolForKey:@"showFPS"];
    
    [self reloadViewHeight];
}

- (void)viewDidUnload
{
    [self setNavBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void) viewWillAppear:(BOOL)animated {
    _demoNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"demoNumber"];
}

-(void) reloadViewHeight
{
    float currentTotal = 0;

    currentTotal += self.navBar.bounds.size.height;
    
    //Need to total each section
    for (int i = 0; i < [self.menuTable numberOfSections]; i++) 
    {
        CGRect sectionRect = [self.menuTable rectForSection:i];
        currentTotal += sectionRect.size.height;
    }
    
    //Set the contentSizeForViewInPopover
    self.contentSizeForViewInPopover = CGSizeMake(320, currentTotal);
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0) {
        return [_flipsidePopoverArray count];
    } else {
        return 1;
    }
}

- (void)createSwitchCell:(UITableViewCell **)cell_p {
    *cell_p = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:SwitchCellIdentifier];
    CGRect frame = CGRectMake(220.0, 16.0, 0.0, 0.0);
    
    UISwitch *switchCtl = [[UISwitch alloc] initWithFrame:frame];
    [switchCtl addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
    
    // in case the parent view draws with a custom color or gradient, use a transparent color
    switchCtl.backgroundColor = [UIColor clearColor];
    
    switchCtl.on = shouldShowFPS;
    
    // Add an accessibility label that describes the switch.
    [switchCtl setAccessibilityLabel:NSLocalizedString(@"StandardSwitch", @"")];
    
    switchCtl.tag = kViewTag;	// tag this view for later so we can remove it from recycled table cells
    
    (*cell_p).textLabel.text = @"Show FPS";
    
    self.switchCtl = switchCtl;
    
    [(*cell_p).contentView addSubview:switchCtl];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell;
    if ([indexPath section] == 1 && [indexPath row] == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
        if (cell == nil) {
            [self createSwitchCell:&cell];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                          reuseIdentifier:CellIdentifier] ;
        }
        
        if(indexPath.row < [_flipsidePopoverArray count]) {
            cell.textLabel.text = [_flipsidePopoverArray objectAtIndex:indexPath.row];
        }
        
        if (indexPath.row == _demoNumber) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 1) {
        return;
    }
    
    NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:_demoNumber inSection:0];
    
    [[tableView cellForRowAtIndexPath:oldIndexPath] setAccessoryType:UITableViewCellAccessoryNone];
    [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    _demoNumber = [indexPath row];
    [[NSUserDefaults standardUserDefaults] setInteger:_demoNumber forKey:@"demoNumber"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"demoNumber" object:nil];
    [self.delegate flipsideViewControllerDidFinish:self];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

#pragma mark Switch methods

- (void)switchAction:(id)sender {
    UISwitch *senderAsSwitch = (UISwitch *)sender;
    shouldShowFPS = [senderAsSwitch isOn];
    [[NSUserDefaults standardUserDefaults] setBool:shouldShowFPS forKey:@"showFPS"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showFPS" object:nil];
}

@end
