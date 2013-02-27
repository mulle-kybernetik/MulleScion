//
//  NSValue+CheatAndHack.m
//  MulleScionTemplates
//
//  Created by Nat! on 26.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "NSValue+CheatAndHack.h"


// this is not very pretty, may screw up programs who depend on NSValue
// not responding to location/length (who codes like that ??)

@implementation NSValue ( CheatAndHack)

- (NSUInteger) location
{
   NSUInteger  size;
   NSUInteger  alignment;
   NSRange     range;
   
   NSGetSizeAndAlignment( [self objCType], &size, &alignment);
   if( size != sizeof( NSRange))
      return( NSNotFound);
   
   [self getValue:&range];
   return( range.location);
}

- (NSUInteger) length
{
   NSUInteger  size;
   NSUInteger  alignment;
   NSRange     range;
   
   NSGetSizeAndAlignment( [self objCType], &size, &alignment);
   if( size != sizeof( NSRange))
      return( 0);
   
   [self getValue:&range];
   return( range.length);
}

@end
