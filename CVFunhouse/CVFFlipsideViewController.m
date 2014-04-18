//
//  CVFFlipsideViewController.m
//  CVFunhouse
//
//  Created by John Brewer on 3/7/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

#import "CVFFlipsideViewController.h"

static NSString *SwitchCellIdentifier = @"SwitchCell";
static NSString *ShowDescriptionCellIdentifier = @"ShowDescription";
static NSString *ShowDescriptionHintCellIdentifier = @"ShowDescriptionHint";

#define kSliderHeight 7.0
// for tagging our embedded controls for removal at cell recycle time
#define kViewTag 1

@interface CVFFlipsideViewController () {
    NSInteger _demoNumber;
}
@end

@implementation CVFFlipsideViewController
@synthesize menuTable = _menuTable;
@synthesize delegate = _delegate;
@synthesize navBar = _navBar;
@synthesize switchCtl = _switchCtl;

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    shouldShowFPS = [[NSUserDefaults standardUserDefaults] boolForKey:@"showFPS"];
    shouldShowDescription = [[NSUserDefaults standardUserDefaults] boolForKey:@"showDescription"];
    
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
#pragma unused(animated)
    _demoNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"demoNumber"];
    if (_demoNumber >= (int)_demoList.count) {
        _demoNumber = _demoList.count - 1;
    }
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
    
    currentTotal += self.menuTable.tableFooterView.bounds.size.height;
    
    //Set the contentSizeForViewInPopover
    self.contentSizeForViewInPopover = CGSizeMake(320, currentTotal);
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#pragma unused(tableView)
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#pragma unused(tableView)
    // Return the number of rows in the section.
    if (section == 1) {
        return [self.demoList count];
    } else {
        return 2;
    }
}

- (void)createSwitchCell:(UITableViewCell **)cell_p
               withLabel:(NSString *)labelString
         reuseIdentifier:(NSString *)reuseIdentifier
                selector:(SEL)selector
            initialValue:(bool) value {
    *cell_p = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:reuseIdentifier];
    CGRect frame = CGRectMake(220.0, 16.0, 0.0, 0.0);
    
    UISwitch *switchCtl = [[UISwitch alloc] initWithFrame:frame];
    [switchCtl addTarget:self action:selector forControlEvents:UIControlEventValueChanged];
    
    // in case the parent view draws with a custom color or gradient, use a transparent color
    switchCtl.backgroundColor = [UIColor clearColor];
    
    switchCtl.on = value;
    
    // Add an accessibility label that describes the switch.
    [switchCtl setAccessibilityLabel:NSLocalizedString(@"StandardSwitch", @"")];
    
    switchCtl.tag = kViewTag;	// tag this view for later so we can remove it from recycled table cells
    
    (*cell_p).textLabel.text = labelString;
    
    self.switchCtl = switchCtl;
    
    [(*cell_p).contentView addSubview:switchCtl];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell;
    if ([indexPath section] == 0 && [indexPath row] == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:ShowDescriptionCellIdentifier];
        if (cell == nil) {
            [self createSwitchCell:&cell
                         withLabel:@"Show Description"
                   reuseIdentifier:ShowDescriptionCellIdentifier
                          selector:@selector(showHideDescription:)
                      initialValue:shouldShowDescription];
        }
    } else if ([indexPath section] == 0 && [indexPath row] == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
        if (cell == nil) {
            [self createSwitchCell:&cell
                         withLabel:@"Show Frame Rate"
                   reuseIdentifier:SwitchCellIdentifier
                          selector:@selector(switchAction:)
                      initialValue:shouldShowFPS];
        }
    } else if ([indexPath section] == 0 && [indexPath row] == 2) {
        cell = [tableView dequeueReusableCellWithIdentifier:ShowDescriptionHintCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:ShowDescriptionHintCellIdentifier] ;
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                          reuseIdentifier:CellIdentifier] ;
        }
        
        if(indexPath.row < (NSInteger)[self.demoList count]) {
            NSArray *demoInfo = (self.demoList)[indexPath.row];
            cell.textLabel.text = demoInfo[0];
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

    if (indexPath.section == 0) {
        return;
    }
    
    NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:_demoNumber inSection:1];
    
    [[tableView cellForRowAtIndexPath:oldIndexPath] setAccessoryType:UITableViewCellAccessoryNone];
    [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    _demoNumber = [indexPath row];
    [[NSUserDefaults standardUserDefaults] setInteger:_demoNumber forKey:@"demoNumber"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"demoNumber" object:nil];
    [self.delegate flipsideViewControllerDidFinish:self];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
#pragma unused(tableView)
#pragma unused(indexPath)
    return 60;
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
#pragma unused(sender)
    [self.delegate flipsideViewControllerDidFinish:self];
}

#pragma mark Switch methods

- (void)switchAction:(id)sender {
    UISwitch *senderAsSwitch = (UISwitch *)sender;
    shouldShowFPS = [senderAsSwitch isOn];
    [[NSUserDefaults standardUserDefaults] setBool:shouldShowFPS forKey:@"showFPS"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showFPS" object:nil];
}

- (void)showHideDescription:(id)sender {
    UISwitch *senderAsSwitch = (UISwitch *)sender;
    shouldShowDescription = [senderAsSwitch isOn];
    [[NSUserDefaults standardUserDefaults] setBool:shouldShowDescription forKey:@"showDescription"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showDescription" object:nil];
}

@end
