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
#import "PartOfSpeechDictionary.h"
#import "URLEncoding.h"
#import "Word.h"

static int _seqNum = 0;
#define NUM_PER_PAGE 30

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
        
        /*
        NSString* __url = [NSString stringWithFormat:@"/?term=%@", [term urlEncodeUsingEncoding:NSUTF8StringEncoding]];
        if (matchCase) __url = [__url stringByAppendingString:@"&match=case"];
        [self set_url:__url];
         */
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
        
        /*
        NSString* __url = [NSString stringWithFormat:@"/?term=%@", [term urlEncodeUsingEncoding:NSUTF8StringEncoding]];
        if (matchCase) __url = [__url stringByAppendingString:@"&match=case"];
        if (page > 1) __url = [__url stringByAppendingFormat:@"&page=%d", page];
        [self set_url:__url];
         */
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
        
        /*
        NSString* __url = [NSString stringWithFormat:@"/?term=%@", [term urlEncodeUsingEncoding:NSUTF8StringEncoding]];
        __url = [__url stringByAppendingString:@"&match=regexp"];
        if (page > 1) __url = [__url stringByAppendingFormat:@"&page=%d", page];
        [self set_url:__url];
         */
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

- (void)load
{
    [NSThread detachNewThreadSelector:@selector(databaseThread) toTarget:self withObject:nil];
}

- (void)loadResults:(DubsarAppDelegate*)appDelegate
{    
    NSCharacterSet* set = [NSCharacterSet characterSetWithCharactersInString:@"%_"];
    NSRange range = [term rangeOfCharacterFromSet:set];
    NSString* sql = @"SELECT w.id, w.name, w.part_of_speech, w.freq_cnt, i.name "
        @"FROM words w INNER JOIN inflections i ON w.id = i.word_id ";
    if (range.location != NSNotFound) {
        NSLog(@"found wildcard character at location %d", range.location);
        
        /* wild card search */
        NSRange baseRange;
        baseRange.location = 0;
        baseRange.length = range.location;
        NSString* base = [term substringWithRange:baseRange];
        NSLog(@"base is \"%@\"", base);
        
        NSString* countSql = @"SELECT COUNT(*) FROM words w ";
        
        NSString* where;
        
        if (base.length > 0) {
            where = 
                [NSString stringWithFormat:@"WHERE (w.name >= '%@' AND w.name < '%@' AND w.name LIKE '%@') ",
                               [base uppercaseString], [[self.class incrementString:base]lowercaseString], term];
        }
        else {
            where = [NSString stringWithFormat:@"WHERE w.name LIKE '%@' ", term];
        }
        sql = [sql stringByAppendingString:where];
        countSql = [countSql stringByAppendingString:where];
        
        /* execute countSql to get number of rows */
        sqlite3_stmt* countStmt;
        int rc;
        if ((rc=sqlite3_prepare_v2(appDelegate.database, [countSql cStringUsingEncoding:NSUTF8StringEncoding], -1, &countStmt, NULL))
            != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error preparing count statement, error %d", rc];
            return;
        }
        
        NSLog(@"executing \"%@\"", countSql);
        if (sqlite3_step(countStmt) == SQLITE_ROW) {
            int totalRows = sqlite3_column_int(countStmt, 0);
            NSLog(@"count statement returned %d total matching rows", totalRows);
            totalPages = totalRows/NUM_PER_PAGE;
            if (totalRows % NUM_PER_PAGE != 0) {
                ++ totalPages;
            }
        }
        sqlite3_finalize(countStmt);
    }
    else {
        sql = [sql stringByAppendingFormat:
                @"WHERE w.id IN (SELECT word_id FROM inflections WHERE name = '%@') ", term];
    }
    sql = [sql stringByAppendingString:@"ORDER BY w.name ASC, w.part_of_speech ASC "];
    
    if (range.location != NSNotFound) {
        /* wildcard, add offset and limit */
        sql = [sql stringByAppendingFormat:@"LIMIT %d ", NUM_PER_PAGE];
        if (currentPage > 1) {
            sql = [sql stringByAppendingFormat:@"OFFSET %d ", (currentPage-1)*NUM_PER_PAGE];
        }
    }

    NSLog(@"preparing SQL statement \"%@\"", sql);

    sqlite3_stmt* statement;
    int rc;
    if ((rc=sqlite3_prepare_v2(appDelegate.database,
        [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error preparing statement, error %d", rc];
        return;
    }
    else {
        NSLog(@"prepared statement successfully");
    }
    
    self.results = [NSMutableArray array];

    while (sqlite3_step(statement) == SQLITE_ROW && results.count < NUM_PER_PAGE) {
        NSLog(@"found matching row");
        int _id = sqlite3_column_int(statement, 0);
        char const* _name = (char const*)sqlite3_column_text(statement, 1);
        char const* _part_of_speech = (char const*)sqlite3_column_text(statement, 2);
        int freqCnt = sqlite3_column_int(statement, 3);
        char const* _inflection = (char const*)sqlite3_column_text(statement, 4);
        
        NSLog(@"ID=%d, NAME=%s, PART_OF_SPEECH=%s, FREQ_CNT=%d, INFLECTION=%s",
              _id, _name, _part_of_speech, freqCnt, _inflection);
        
        PartOfSpeech partOfSpeech = [PartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];   
        NSString* name = [NSString stringWithCString:_name encoding:NSUTF8StringEncoding];
        NSString* inflection = [NSString stringWithCString:_inflection encoding:NSUTF8StringEncoding];
        
        Word* currentWord = [results lastObject];
        
        if (currentWord == nil || _id != currentWord._id) {
            currentWord = [Word wordWithId:_id name:name partOfSpeech:partOfSpeech];
            currentWord.freqCnt = freqCnt;
            [results addObject:currentWord];
        }
        [currentWord addInflection:inflection];
    }
    
    sqlite3_finalize(statement);
    
    NSLog(@"completed database search (delegate is %@)", (self.delegate == nil ? @"nil" : @"not nil"));
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
