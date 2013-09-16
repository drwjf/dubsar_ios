/*
 Dubsar Dictionary Project
 Copyright (C) 2010-13 Jimmy Dee
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "DailyWord.h"
#import "DubsarNavigationController_iPad.h"
#import "DubsarViewController_iPad.h"
#import "Word.h"
#import "WordViewController_iPad.h"

@implementation DubsarViewController_iPad
@synthesize dailyWord;
@synthesize wotdButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Home";
        self.dailyWord = DailyWord.dailyWord;
        self.dailyWord.delegate = self;
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setViewSize) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [dailyWord load];
}

- (void)viewDidUnload
{
    [self setWotdButton:nil];
    [super viewDidUnload];
    // Release any stronged subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"In [DubsarViewController_iPad viewWillAppear:]");
#endif // DEBUG
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.wotdUnread = false;
    [dailyWord load];
    
    [self setViewSize];
}

- (void)setViewSize
{
    DubsarNavigationController_iPad* navController = (DubsarNavigationController_iPad*)self.navigationController;
    navController.originalFrame = self.view.bounds;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
#ifdef DEBUG
    NSLog(@"daily word load complete");
#endif // DEBUG
    DailyWord* theDailyWord = (DailyWord*)model;

    if (theDailyWord.error) {
        NSLog(@"request error: %@", theDailyWord.errorMessage);
        Word* word = [[Word alloc]init];
        word.error = word.complete = true;
        word.errorMessage = theDailyWord.errorMessage;
        theDailyWord.word = word;
    }    
    
    if (dailyWord.fresh) {
        // turn on the wotd indicator if we're starting fresh
        DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[UIApplication sharedApplication].delegate;
        appDelegate.wotdUrl = [NSString stringWithFormat:@"dubsar:///wotd/%d", dailyWord.word._id];
        // appDelegate.wotdUnread = true;
        // [appDelegate addWotdButton];
        
        // TODO: Display help the first time
    }
    
    NSString* title = dailyWord.word.nameAndPos;
    if (dailyWord.word.freqCnt > 0) {
        title = [title stringByAppendingFormat:@" freq. cnt.: %d", dailyWord.word.freqCnt];
    }
    
    [wotdButton setTitle:title forState:UIControlStateNormal];
    [wotdButton setTitle:title forState:UIControlStateHighlighted];
    [wotdButton setTitle:title forState:UIControlStateDisabled];
}

- (IBAction)showWotd:(id)sender 
{
    [dailyWord load];
    WordViewController_iPad* viewController = [[WordViewController_iPad alloc] initWithNibName:@"WordViewController_iPad" bundle:nil word:dailyWord.word title:@"Word of the Day"];
    [viewController load];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (bool)handleWotd
{
    // Update the wotd button live
    [dailyWord load]; // from user defaults
    return true;
}

@end
