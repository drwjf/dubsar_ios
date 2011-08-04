/*
 Dubsar Dictionary Project
 Copyright (C) 2010-11 Jimmy Dee
 
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

#import "Search.h"
#import "JSONKit.h"
#import "URLEncoding.h"
#import "Word.h"

static int _seqNum = 0;

@implementation Search

@synthesize results;
@synthesize term;
@synthesize matchCase;
@synthesize currentPage;
@synthesize totalPages;
@synthesize seqNum;
@synthesize isWildCard;
@synthesize title;


+(id)searchWithTerm:(id)theTerm matchCase:(BOOL)mustMatchCase
{
    return [[[self alloc]initWithTerm:theTerm matchCase:mustMatchCase seqNum:_seqNum++]autorelease];
}

+(id)searchWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase page:(int)page
{
    return [[[self alloc]initWithTerm:theTerm matchCase:mustMatchCase page:page seqNum:_seqNum++]autorelease];
}

+(id)searchWithWildcard:(NSString *)regexp page:(int)page title:(NSString *)theTitle
{
    return [[[self alloc]initWithWildcard:regexp page:page title:theTitle seqNum:_seqNum++]autorelease];
}

-(id)initWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase seqNum:(int)theSeqNum
{
    NSLog(@"constructing search for \"%@\"", theTerm);
    
    self = [super init];
    if (self) {   
        matchCase = mustMatchCase;
        term = [theTerm retain];
        isWildCard = false;
        title = [term copy];
        results = nil;
        currentPage = 1;
        totalPages = 0;
        seqNum = theSeqNum;
        
        NSString* __url = [NSString stringWithFormat:@"/?term=%@", [term urlEncodeUsingEncoding:NSUTF8StringEncoding]];
        if (matchCase) __url = [__url stringByAppendingString:@"&match=case"];
        [self set_url:__url];
    }
    return self;
}

-(id)initWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase page:(int)page seqNum:(int)theSeqNum
{
    NSLog(@"constructing search for \"%@\"", theTerm);
    
    self = [super init];
    if (self) {   
        matchCase = mustMatchCase;
        term = [theTerm retain];
        isWildCard = false;
        title = [term copy];
        results = nil;
        seqNum = theSeqNum;
        currentPage = page;
        
        // totalPages is set by the server in the response
        totalPages = 0;
        
        NSString* __url = [NSString stringWithFormat:@"/?term=%@", [term urlEncodeUsingEncoding:NSUTF8StringEncoding]];
        if (matchCase) __url = [__url stringByAppendingString:@"&match=case"];
        if (page > 1) __url = [__url stringByAppendingFormat:@"&page=%d", page];
        [self set_url:__url];
    }
    return self;
}

-(id)initWithWildcard:(NSString *)regexp page:(int)page title:(NSString*)theTitle seqNum:(int)theSeqNum
{
    NSLog(@"constructing search for \"%@\"", regexp);
    
    self = [super init];
    if (self) {   
        matchCase = false;
        term = [regexp retain];
        isWildCard = true;
        title = [theTitle retain];
        results = nil;
        seqNum = theSeqNum;
        currentPage = page;
        
        // totalPages is set by the server in the response
        totalPages = 0;
        
        NSString* __url = [NSString stringWithFormat:@"/?term=%@", [term urlEncodeUsingEncoding:NSUTF8StringEncoding]];
        __url = [__url stringByAppendingString:@"&match=regexp"];
        if (page > 1) __url = [__url stringByAppendingFormat:@"&page=%d", page];
        [self set_url:__url];
    }
    return self;
    
}

-(void)dealloc
{    
    [title release];
    [term release];
    [results release];

    [super dealloc];
}

- (void)parseData
{        
    NSArray* response = [[self decoder] objectWithData:[self data]];
    NSArray* list = [response objectAtIndex:1];
    NSNumber* pages = [response objectAtIndex:2];
    totalPages = pages.intValue;
    
    results = [[NSMutableArray arrayWithCapacity:list.count]retain];
    NSLog(@"search request for \"%@\" returned %d results", [response objectAtIndex:0], list.count);
    NSLog(@"(%d total pages)", totalPages);
    int j;
    for (j=0; j<list.count; ++j) {
        NSArray* entry = [list objectAtIndex:j];
        
        NSNumber* numericId = [entry objectAtIndex:0];
        NSString* name = [entry objectAtIndex:1];
        NSString* posString = [entry objectAtIndex:2];
        NSNumber* numericFc = [entry objectAtIndex:3];
        NSString* otherForms = [entry objectAtIndex:4];
        
        Word* word = [Word wordWithId:numericId.intValue name:name posString:posString];
        word.freqCnt = numericFc.intValue;
        word.inflections = otherForms;
        
        [results insertObject:word atIndex:j];
    }
    
    /* This looks odd when browsing long lists. */
    /* [results sortUsingSelector:@selector(compareFreqCnt:)]; */
}

- (Search*)newSearchForPage:(int)page
{
    Search* search;
    
    if (isWildCard) {
        search = [Search searchWithWildcard:term page:page title:title];
    }
    else {
        search = [Search searchWithTerm:term matchCase:matchCase page:page];
    }
    
    return search;
}

@end
