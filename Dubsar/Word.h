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

#import "Dubsar.h"
#import "Model.h"

@interface Word : Model {
}

@property (nonatomic) int _id;
@property (nonatomic, copy) NSString* name;
@property (nonatomic) PartOfSpeech partOfSpeech;
@property (nonatomic) int freqCnt;

@property (nonatomic, strong) NSMutableArray* inflections;
@property (nonatomic, strong) NSMutableArray* senses;

+(instancetype)wordWithId:(int)theId name:(NSString*)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech;
+(instancetype)wordWithId:(int)theId name:(NSString*)theName posString:(NSString*)posString;
-(instancetype)initWithId:(int)theId name:(NSString*)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(instancetype)initWithId:(int)theId name:(NSString*)theName posString:(NSString*)posString;
-(NSString*)pos;
-(NSString*)nameAndPos;

-(void)parseData;
-(void)initUrl;
-(void)addInflection:(NSString*)inflection;

- (NSComparisonResult)compareFreqCnt:(Word*)word;

- (void)load:(bool)mainThread;

@end
