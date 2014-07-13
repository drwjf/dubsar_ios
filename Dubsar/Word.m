/*
 Dubsar Dictionary Project
 Copyright (C) 2010-14 Jimmy Dee
 
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
@import UIKit;

#import <sqlite3.h>

#import "DatabaseWrapper.h"
#import "Dubsar-Swift.h"
#import "PartOfSpeechDictionary.h"
#import "Sense.h"
#import "Word.h"

@implementation Word

@synthesize _id;
@synthesize name;
@synthesize partOfSpeech;
@synthesize freqCnt;

@synthesize inflections;
@synthesize senses;

+(instancetype)wordWithId:(int)theId name:(id)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    return [[self alloc] initWithId:theId name:theName partOfSpeech:thePartOfSpeech];
}

+(instancetype)wordWithId:(int)theId name:(NSString *)theName posString:(NSString *)posString
{
    return [[self alloc] initWithId:theId name:theName posString:posString];
}

-(instancetype)initWithId:(int)theId name:(NSString *)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    self = [super init];
    if (self) {
        _id = theId;
        name = theName;
        partOfSpeech = thePartOfSpeech;
        inflections = nil;
        [self initUrl];
    }
    return self;
}

-(instancetype)initWithId:(int)theId name:(NSString *)theName posString:(NSString *)posString
{
    self = [super init];
    if (self) {
        _id = theId;
        name = theName;
        
        partOfSpeech = [PartOfSpeechDictionary partOfSpeechFromPOS:posString];
        [self initUrl];
    }
    return self;
}

-(NSString*)pos
{
    return [PartOfSpeechDictionary posFromPartOfSpeech:partOfSpeech];
}

-(NSString *)nameAndPos
{
    return [NSString stringWithFormat:@"%@ (%@.)", name, self.pos];
}

- (void)load:(bool)mainThread
{
    // either way, [delegate loadComplete:withError:] is called on the main thread
    if (mainThread) {
        // dispatch on the main thread in the background
        dispatch_async(dispatch_get_main_queue(), ^{
            [self databaseThread:UIApplication.sharedApplication.delegate];
        });
    }
    else {
        [self performSelectorInBackground:@selector(databaseThread:) withObject:UIApplication.sharedApplication.delegate];
    }
}

- (void)load
{
    [self load:true];
}

-(void)loadResults:(AppDelegate *)appDelegate
{
    NSString* sql = [NSString stringWithFormat:
                     @"SELECT DISTINCT w.name, w.part_of_speech, w.freq_cnt, i.name "
                     @"FROM words w "
                     @"INNER JOIN inflections i ON w.id = i.word_id "
                     @"WHERE w.id = %d "
                     @"ORDER BY i.name ASC ", _id];
    int rc;
    sqlite3_stmt* statement;
#ifdef DEBUG
    NSLog(@"preparing statement \"%@\"", sql);
#endif // DEBUG
    if ((rc=sqlite3_prepare_v2(appDelegate.database.dbptr, sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
        NSLog(@"%@", self.errorMessage);
        return;
    }
    
    self.inflections = nil;
    while ((rc=sqlite3_step(statement)) == SQLITE_ROW) {
        char const* _name = (char const*)sqlite3_column_text(statement, 0);
        char const* _part_of_speech = (char const*)sqlite3_column_text(statement, 1);
        freqCnt = sqlite3_column_int(statement, 2);
        char const* _inflection = (char const*)sqlite3_column_text(statement, 3);
        
        self.name = [NSString stringWithCString:_name encoding:NSUTF8StringEncoding];
        
        NSString* inflection = [NSString stringWithCString:_inflection encoding:NSUTF8StringEncoding];
        [self addInflection:inflection];
#ifdef DEBUG
        NSLog(@"added inflection %@", inflection);
#endif // DEBUG
        
        if (partOfSpeech == POSUnknown) {
            partOfSpeech = [PartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];
        }
    }

#ifdef DEBUG
    NSLog(@"%d inflections", inflections.count);
#endif // DEBUG
    
    sqlite3_finalize(statement);

    sql = [NSString stringWithFormat:@"SELECT se.id, sy.definition, sy.lexname, se.freq_cnt, se.marker, sy.id "
           @"FROM senses se "
           @"INNER JOIN synsets sy ON se.synset_id = sy.id "
           @"WHERE se.word_id = %d "
           @"ORDER BY se.freq_cnt DESC ", _id];

#ifdef DEBUG
    NSLog(@"preparing statement \"%@\"", sql);
#endif // DEBUG
    if ((rc=sqlite3_prepare_v2(appDelegate.database.dbptr, sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
        NSLog(@"%@", self.errorMessage);
        return;
    }
    
    self.senses = [NSMutableArray array];
    
    while (sqlite3_step(statement) == SQLITE_ROW) {
        int senseId = sqlite3_column_int(statement, 0);
        char const* _definition = (char const*)sqlite3_column_text(statement, 1);
        char const* _lexname = (char const*)sqlite3_column_text(statement, 2);
        int senseFC = sqlite3_column_int(statement, 3);
        char const* _marker = (char const*)sqlite3_column_text(statement, 4);
        int synsetId = sqlite3_column_int(statement, 5);
        
        NSMutableArray* synonyms = [NSMutableArray array];
        
        NSString* synSql = [NSString stringWithFormat:@"SELECT s.id, w.name "
                            @"FROM senses s "
                            @"INNER JOIN words w ON w.id = s.word_id "
                            @"WHERE s.synset_id = %d AND w.name != ? "
                            @"ORDER BY w.name ASC ", synsetId];
        
        sqlite3_stmt* synStatement;
#ifdef DEBUG
        NSLog(@"preparing statement \"%@\"", synSql);
#endif // DEBUG
        if ((rc=sqlite3_prepare_v2(appDelegate.database.dbptr, synSql.UTF8String, -1, &synStatement, NULL))
            != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
            sqlite3_finalize(statement);
            return;
        }
        
        if ((rc=sqlite3_bind_text(synStatement, 1, name.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(synStatement);
            sqlite3_finalize(statement);
            return;
        }
        
        while (sqlite3_step(synStatement) == SQLITE_ROW) {
            int synonymSenseId = sqlite3_column_int(synStatement, 0);
            char const* _synonym = (char const*)sqlite3_column_text(synStatement, 1);
#ifdef DEBUG
            NSLog(@"synonym %s (%d)", _synonym, synonymSenseId);
#endif // DEBUG
    
            Sense* synonym = [Sense senseWithId:synonymSenseId name:[NSString stringWithCString:_synonym encoding:NSUTF8StringEncoding] partOfSpeech:partOfSpeech];
            [synonyms addObject:synonym];
        }
        
        NSString* definition = [NSString stringWithCString:_definition encoding:NSUTF8StringEncoding];
        NSString* gloss = [[definition componentsSeparatedByString:@"; \""]objectAtIndex:0];
        
        Sense* sense = [Sense senseWithId:senseId gloss:gloss synonyms:synonyms word:self];
        sense.lexname = [NSString stringWithCString:_lexname encoding:NSUTF8StringEncoding];
        sense.freqCnt = senseFC;
        sense.marker = _marker == NULL ? nil : [NSString stringWithCString:_marker encoding:NSUTF8StringEncoding];
        [senses addObject:sense];
#ifdef DEBUG
        NSLog(@"added sense ID %d, gloss \"%@\", lexname \"%@\", freq. cnt. %d", senseId, gloss, sense.lexname, senseFC);
#endif // DEBUG
    }
    
    sqlite3_finalize(statement);
#ifdef DEBUG
    NSLog(@"completed word query");
#endif // DEBUG
}

-(void)parseData
{
    NSArray* response =[NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];
    
    inflections = [[[response objectAtIndex:3] componentsSeparatedByString:@", "] mutableCopy];

    NSNumber* _freqCnt;
    NSArray* _senses = [response objectAtIndex:4];
    senses = [NSMutableArray arrayWithCapacity:_senses.count];
    for (int j=0; j<_senses.count; ++j) {
        NSArray* _sense = [_senses objectAtIndex:j];
        NSArray* _synonyms = [_sense objectAtIndex:1];
        NSNumber* numericId = nil;
        NSMutableArray* synonyms = [NSMutableArray arrayWithCapacity:_synonyms.count];
        for (int k=0; k<_synonyms.count; ++k) {
            NSArray* _synonym = [_synonyms objectAtIndex:k];
            numericId = [_synonym objectAtIndex:0];
            Sense* sense = [Sense senseWithId:numericId.intValue name:[_synonym objectAtIndex:1] partOfSpeech:partOfSpeech];
            [synonyms insertObject:sense atIndex:k];
        }
        
        numericId = [_sense objectAtIndex:0];
        Sense* sense = [Sense senseWithId:numericId.intValue gloss:[_sense objectAtIndex:2] synonyms:synonyms word:self];
        NSString* lexname = [_sense objectAtIndex:3];
        id marker = [_sense objectAtIndex:4];
        _freqCnt = [_sense objectAtIndex:5];
        sense.lexname = lexname;
        if (marker != NSNull.null) {
            sense.marker = marker;
        }
        sense.freqCnt = _freqCnt.intValue;
        
        [senses insertObject:sense atIndex:j];
    }
    [senses sortUsingSelector:@selector(compareFreqCnt:)];
    _freqCnt = [response objectAtIndex:5];
    freqCnt = _freqCnt.intValue;
}

-(void)initUrl
{
    // [self set_url: [NSString stringWithFormat:@"/words/%d", _id]];
}

- (NSComparisonResult)compareFreqCnt:(Word*)word
{
    return freqCnt < word.freqCnt ? NSOrderedDescending : 
        freqCnt > word.freqCnt ? NSOrderedAscending : 
        NSOrderedSame;
}

- (void)addInflection:(NSString*)inflection
{
    if ([inflection compare:name options:NSCaseInsensitiveSearch] == NSOrderedSame) return;
    
    if (!inflections) self.inflections = [NSMutableArray array];

    [inflections addObject:inflection];
}

@end
