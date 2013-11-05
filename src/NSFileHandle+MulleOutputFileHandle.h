//
//  NSFileHandle+MulleOpenWithInfo.h
//  MulleScionTemplates
//
//  Created by Nat! on 05.11.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileHandle (MulleOutputFileHandle)

+ (NSFileHandle *) mulleOutputFileHandleWithFilename:(NSString *) outputName;

@end
