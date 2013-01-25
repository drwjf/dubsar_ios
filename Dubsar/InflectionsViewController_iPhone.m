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

#import "InflectionsViewController_iPhone.h"
#import "Word.h"
#import "WordViewController_iPhone.h"

@interface InflectionsViewController_iPhone ()

@end

@implementation InflectionsViewController_iPhone
@synthesize webView;
@synthesize word;
@synthesize parent;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word *)theWord parent:(WordViewController_iPhone *)theParent
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.word = theWord;
        self.parent = theParent; // assign, not retain
    }
    return self;
}

- (void)dealloc
{
    [webView release];
    [word release];
    [super dealloc];
}

- (void)loadComplete
{
    [webView loadHTMLString:self.htmlInflections baseURL:nil];
}

- (IBAction)dismiss:(id)sender
{
    [parent dismissInflections];
}

- (NSString *)htmlInflections
{
    NSString* html = @"<!DOCTYPE html><html><body style='color:#f85400; background-color:#000; font: bold 12pt Trebuchet MS'><h3>Other forms for ";
    html = [html stringByAppendingFormat:@"%@", word.nameAndPos];
    
    if (word.freqCnt > 0) {
        html = [html stringByAppendingFormat:@" freq. cnt.: %d", word.freqCnt];
    }
    
    html = [html stringByAppendingString:@"</h3><ul style='list-style: none;'>"];
    
    int j;
    for (j=0;j<word.inflections.count; ++j) {
        NSString* inflection = [word.inflections objectAtIndex:j];
        html = [html stringByAppendingFormat:@"<li>%@</li>", inflection];
    }
    
    html = [html stringByAppendingString:@"</ul></body></html>"];
    return html;
}

@end