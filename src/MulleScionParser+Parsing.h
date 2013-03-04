//
//  MulleScionParser+Parsing.h
//  MulleScionTemplates
//
//  Created by Nat! on 26.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//
#import "MulleScionParser.h"


@class MulleScionObject;


@interface MulleScionParser ( Parsing)

- (void) parseData:(NSData *) data
    intoRootObject:(MulleScionObject *) root
          fileName:(NSString *) fileName
        blockTable:(NSMutableDictionary *) blockTable
   definitionTable:(NSMutableDictionary *) definitionTable
        macroTable:(NSMutableDictionary *) macroTable
   dependencyTable:(NSMutableDictionary *) dependencyTable;

- (MulleScionTemplate *) templateParsedWithBlockTable:(NSMutableDictionary *) blockTable
                                      definitionTable:(NSMutableDictionary *) definitionsTable
                                           macroTable:(NSMutableDictionary *) macroTable
                                      dependencyTable:(NSMutableDictionary *) dependencyTable;

- (MulleScionTemplate *) templateWithContentsOfFile:(NSString *) fileName
                                         blockTable:(NSMutableDictionary *) blockTable
                                    definitionTable:(NSMutableDictionary *) definitionTable
                                         macroTable:(NSMutableDictionary *) macroTable
                                    dependencyTable:(NSMutableDictionary *) dependencyTable;
@end
