//
//  NSLineCountNumber.h
//  MulleScionTemplates
//
//  Created by Nat! on 25.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>


//
// this is a hack, because I don't want to create lots of NSNumber
// objects, just for storing the current line in the local Variables
//
@interface MulleMutableLineNumber : NSNumber
{
   NSUInteger   lineNumber_;
}

- (void) setUnsignedInteger:(NSUInteger) value;

@end
