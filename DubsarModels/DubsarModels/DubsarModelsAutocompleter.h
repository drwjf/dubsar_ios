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

#import "DubsarModels/DubsarModelsModel.h"

@interface DubsarModelsAutocompleter : DubsarModelsModel {
    NSString* term;
    NSMutableArray* _results;    
}

@property (nonatomic) BOOL matchCase;
@property (nonatomic) NSInteger seqNum;
@property (nonatomic, copy) NSString* term;
@property (nonatomic, strong) NSMutableArray* results;
@property (nonatomic) int max;
@property (atomic) bool aborted;

+ (instancetype)autocompleterWithTerm:(NSString*)theTerm matchCase:(BOOL)mustMatchCase;

- (instancetype)initWithTerm:(NSString*)theTerm seqNum:(NSInteger)theSeqNum matchCase:(BOOL)mustMatchCase NS_DESIGNATED_INITIALIZER;

- (void)cancel;

@end
