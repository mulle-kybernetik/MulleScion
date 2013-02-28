//
//  MulleScionObjectModel+NSCoding.h
//  MulleScionTemplates
//
//  Created by Nat! on 25.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//
#import "MulleScionObjectModel.h"


@interface MulleScionObject ( NSCoding) < NSCoding, NSCopying >

- (id) initWithCoder:(NSCoder *) decoder;
- (void) encodeWithCoder:(NSCoder *) encoder;

- (id) copyWithZone:(NSZone *) zone;

@end


