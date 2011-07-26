//
//  SearchViewController_iPad.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "LoadDelegate.h"
#import "Search.h"
#import "SearchViewController_iPad.h"
#import "Word.h"
#import "WordViewController_iPad.h"


@implementation SearchViewController_iPad

@synthesize search;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil text:(NSString *)text matchCase:(BOOL)matchCase
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        search = [Search searchWithTerm:text matchCase:matchCase];
        search.delegate = self;
        [search load];
        
        self.title = [NSString stringWithFormat:@"Search: \"%@\"", text];
    }
    return self;
}

- (void)dealloc
{
    [search release];
    [super dealloc];
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSLog(@"1 section in tableView");
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (!search.complete) {
        return 1;  
    }
    
    NSLog(@"%d rows in tableView", search.results.count);
    
    return search.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"search";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    
    if (!search.complete) {
        CGRect frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
        UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]autorelease];
        indicator.frame = frame;
        [indicator startAnimating];
        [cell.contentView addSubview:indicator];
    }
    else {
        Word* word = [search.results objectAtIndex:indexPath.row];
        cell.textLabel.text = word.nameAndPos;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Word* word = [search.results objectAtIndex:indexPath.row];
    WordViewController_iPad* wordViewController = [[[WordViewController_iPad alloc] initWithNibName:@"WordViewController_iPad" bundle:nil word:word]autorelease];
    [self.navigationController pushViewController:wordViewController animated:YES];
}

- (void)loadComplete:(Model*)model
{
    if (model != search) return;
    
    [(UITableView*)self.view reloadData];
}

- (void)loadRootController
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end