//
//  MulleScionTemplate+CompressedArchive.h
//  MulleScionTemplates
//
//  Created by Nat! on 26.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionObjectModel.h"


@interface MulleScionTemplate ( CompressedArchive)

- (id) initWithContentsOfArchive:(NSString *) fileName;
- (BOOL) writeArchive:(NSString *) fileName;

@end
