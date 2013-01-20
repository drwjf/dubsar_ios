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
#import "JSONkit.h"
#import "LoadDelegate.h"
#import "Word.h"

#define DubsarDailyWordIdKey @"com.dubsar-dictionary.Dubsar.wotdId"

@implementation DailyWord

@synthesize word;

+ (id)dailyWord
{
    return [[[DailyWord alloc] init] autorelease];
}

+ (void)updateWotdId:(int)wotdId
{
    DailyWord* wotd = [DailyWord dailyWord];
    wotd.word = [Word wordWithId:wotdId name:nil partOfSpeech:POSUnknown];
    [wotd saveToUserDefaults];   
}

- (id)init
{
    self = [super init];
    if (self) {
        [self set_url:@"/wotd"];
        word = nil;
    }
    
    return self;
}

- (void)dealloc
{
    [word release];
    [super dealloc];
}

- (void)load
{
    if (![self loadFromUserDefaults]) {
        [self loadFromServer];
        return;
    }
    
    self.complete = true;
    self.error = false;
    self.errorMessage = nil;
    
    [self.delegate loadComplete:self withError:self.errorMessage];
}

- (void)parseData
{
    NSArray* wotd = [[self decoder] objectWithData:[self data]];
    NSNumber* numericId = [wotd objectAtIndex:0];
    
    word = [[Word wordWithId:numericId.intValue name:[wotd objectAtIndex:1] posString:[wotd objectAtIndex:2]]retain];
    
    NSNumber* fc = [wotd objectAtIndex:3];
    word.freqCnt = fc.intValue;
    
    word.inflections = [wotd objectAtIndex:4];
    
    [self saveToUserDefaults];
}

- (bool) loadFromUserDefaults
{
    int wotdId = [[[NSUserDefaults standardUserDefaults] valueForKey:DubsarDailyWordIdKey] intValue];

    if (wotdId <= 0) {
        return false;
    }
    
    word = [Word wordWithId:wotdId name:nil partOfSpeech:POSUnknown];
    [word load];
    return true;
}

- (void) saveToUserDefaults
{
    [[NSUserDefaults standardUserDefaults] setInteger:word._id forKey:DubsarDailyWordIdKey];
}

@end
