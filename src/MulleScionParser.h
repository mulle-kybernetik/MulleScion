//
//  MulleScionParser.h
//  MulleScionTemplates
//
//  Created by Nat! on 24.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>


@class MulleScionTemplate;


@interface MulleScionParser : NSObject
{
   NSData     *data_;
   NSString   *fileName_;
}

+ (MulleScionParser *) parserWithContentsOfFile:(NSString *) fileName;

- (id) initWithData:(NSData *) data
           fileName:(NSString *) fileName;

- (MulleScionTemplate *) template;
- (NSDictionary *) dependencyTable;

- (void) parserErrorInFileName:(NSString *) fileName
                    lineNumber:(NSUInteger) lineNumber
                        reason:(NSString *) reason;
- (NSString *) fileName;



@end
