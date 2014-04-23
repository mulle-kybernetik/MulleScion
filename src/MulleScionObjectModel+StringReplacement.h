//
//  MulleScionObjectModel+StringReplacement.h
//  MulleScionTemplates
//
//  Created by Nat! on 03.03.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//
#import "MulleScionObjectModel.h"



// kind of a zombie source file, that's not being used at the moment
@interface MulleScionObject (StringReplacement)

- (void) replaceOccurrencesOfString:(NSString *) s
                         withString:(NSString *) other
                            options:(NSStringCompareOptions) options
                    templateOptions:(unsigned int) flags;

@end
