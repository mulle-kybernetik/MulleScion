//
//  MulleScionObjectModel+Parsing.h
//  MulleScionTemplates
//
//  Created by Nat! on 01.03.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//
#ifndef MULLE_SCION_OBJECT_NEXT_POINTER_VISIBILITY
# define MULLE_SCION_OBJECT_NEXT_POINTER_VISIBILITY  @public
#endif

#import "MulleScionObjectModel.h"


@interface MulleScionObject( Parsing)

- (id) appendRetainedObject:(MulleScionObject *) NS_CONSUMED obj;

// hackish stuff for the parser
- (MulleScionObject *) behead;
- (MulleScionObject *) tail;
- (NSUInteger) count;

@end
