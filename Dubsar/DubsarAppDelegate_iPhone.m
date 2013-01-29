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

#import "DubsarAppDelegate_iPhone.h"
#import "DubsarNavigationController_iPhone.h"
#import "DubsarViewController_iPhone.h"
#import "Sense.h"
#import "SenseViewController_iPhone.h"
#import "Synset.h"
#import "SynsetViewController_iPhone.h"
#import "Word.h"
#import "WordViewController_iPhone.h"

@implementation DubsarAppDelegate_iPhone

@synthesize navigationController=_navigationController;
@synthesize wotdUrl;
@synthesize wotdUnread;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    DubsarViewController_iPhone *rootViewController = [[DubsarViewController_iPhone alloc]
                                              initWithNibName:@"DubsarViewController_iPhone" bundle:nil];
    _navigationController = [[[DubsarNavigationController_iPhone alloc]initWithRootViewController:rootViewController]autorelease];
    [rootViewController release];
    
    UIColor* tint = [UIColor colorWithRed:0.110 green:0.580 blue:0.769 alpha:1.0];
    _navigationController.navigationBar.tintColor = tint;
    _navigationController.toolbar.tintColor = tint;
   
    [self.window setRootViewController:_navigationController];

    [super application:application didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}

- (void)addWotdButton
{
    [_navigationController addWotdButton];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    UIViewController* controller = _navigationController.topViewController;
    if ([controller respondsToSelector:@selector(load)]) {
        [controller load];
    }
    [super applicationWillEnterForeground:application];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([url.scheme compare:@"dubsar"] != NSOrderedSame) {
        return [super application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    }
    
    if ([url.path hasPrefix:@"/wotd/"]) {
        NSLog(@"Opening %@", url);
        
        int wordId = [[url lastPathComponent] intValue];
        Word* word = [Word wordWithId:wordId name:nil partOfSpeech:POSUnknown];
        [_navigationController dismissViewControllerAnimated:NO completion:nil];
        WordViewController_iPhone* viewController = [[[WordViewController_iPhone alloc]initWithNibName:@"WordViewController_iPhone" bundle:nil word:word title:@"Word of the Day"]autorelease];
        [viewController load];
        [_navigationController pushViewController:viewController animated:YES];
        
        self.wotdUnread = false;
        return YES;
    }
    
    if ([url.path hasPrefix:@"/words/"]) {
        NSLog(@"Opening %@", url);
        
        int wordId = [[url lastPathComponent] intValue];
        Word* word = [Word wordWithId:wordId name:nil partOfSpeech:POSUnknown];
        [_navigationController dismissViewControllerAnimated:NO completion:nil];
        WordViewController_iPhone* viewController = [[[WordViewController_iPhone alloc]initWithNibName:@"WordViewController_iPhone" bundle:nil word:word title:nil]autorelease];
        [viewController load];
        [_navigationController pushViewController:viewController animated:YES];
        return YES;
    }
    
    if ([url.path hasPrefix:@"/senses/"]) {
        NSLog(@"Opening %@", url);
        
        int senseId = [[url lastPathComponent] intValue];
        Sense* sense = [Sense senseWithId:senseId name:nil partOfSpeech:POSUnknown];
        [_navigationController dismissViewControllerAnimated:NO completion:nil];
        SenseViewController_iPhone* viewController = [[[SenseViewController_iPhone alloc]initWithNibName:@"SenseViewController_iPhone" bundle:nil sense:sense] autorelease];
        [viewController load];
        [_navigationController pushViewController:viewController animated:YES];
        return YES;
    }
    
    if ([url.path hasPrefix:@"/synsets/"]) {
        NSLog(@"Opening %@", url);
        
        int synsetId = [[url lastPathComponent] intValue];
        Synset* synset = [Synset synsetWithId:synsetId partOfSpeech:POSUnknown];
        [_navigationController dismissViewControllerAnimated:NO completion:nil];
        SynsetViewController_iPhone* viewController = [[[SynsetViewController_iPhone alloc]initWithNibName:@"SynsetViewController_iPhone" bundle:nil synset:synset] autorelease];
        [viewController load];
        [_navigationController pushViewController:viewController animated:YES];
        return YES;
    }
    
    return NO;
}

- (void)prepareDatabase:(bool)recreateFTSTables
{
    [super prepareDatabase:recreateFTSTables];

    sqlite3_stmt* statement;
    int rc = 0;
    if ((rc=sqlite3_prepare_v2(super.database,
                               "CREATE TABLE IF NOT EXISTS bookmarks (id INTEGER PRIMARY KEY ASC, page INTEGER)", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"sqlite3 error %d", rc);
        return;
    }
    sqlite3_step(statement);
    sqlite3_finalize(statement);
}

- (void)dealloc
{
    [_navigationController release];
	[super dealloc];
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
;
}

@end