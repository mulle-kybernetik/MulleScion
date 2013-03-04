//
//  MulleScionObjectModel+MulleMongoose.h
//  MulleScionTemplates
//
//  Created by Nat! on 03.03.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//
#import <MulleScionTemplates/MulleScionTemplates.h>


@interface MulleScionTemplate (MulleMongoose)

- (id) initWithContentsOfFile:(NSString *) fileName
                      options:(NSDictionary *) info;

- (id) initWithContentsOfFile:(NSString *) fileName
                optionsString:(NSString *) options;

+ (NSDictionary *) dependencyTableOfFile:(NSString *) fileName;

@end
