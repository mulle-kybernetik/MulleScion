//
//  MulleScionObjectModel+Debug.h
//  MulleScionTemplates
//
//  Created by Nat! on 25.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionObjectModel.h"


#ifndef DONT_HAVE_MULLE_SCION_DESCRIPTION
//
// OPTIONAL: sometimes useful for debugging
//
@interface MulleScionObject ( Description)

- (NSString *) description;
- (NSString *) shortDescription;

@end

#endif
