//
//  NSString+HTMLEscape.m
//  MulleScionTemplates
//
//  Created by Nat! on 04.03.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "NSString+HTMLEscape.h"


@implementation NSString (HTMLEscape)


static inline unichar   *copy( unichar *dst, char *src, NSUInteger len)
{
   char  *sentinel;
   
   sentinel = &src[ len];
   while( src < sentinel)
      *dst++ = *src++;
   return( dst);
}

// this is not a good idea, remove this before release
- (NSString *) htmlEscapedString;
{
   unichar         c;
   unichar         *src;
   unichar         *sentinel;
   unichar         *dst;
   unichar         *start;
   unichar         *buf;
   NSUInteger      len;
   NSUInteger      needed;
   NSMutableData   *data;
   
   len = [self length];
   buf = [[NSMutableData dataWithLength:len * sizeof( unichar)] mutableBytes];
   [self getCharacters:buf
                 range:NSMakeRange( 0, len)];
   
   needed   = len * 5;  // nbsp;
   data     = [NSMutableData dataWithLength:needed * sizeof( unichar)];
   start    = [data mutableBytes];
   src      = buf;
   dst      = start;
   sentinel = &src[ len];
   
   while( src < sentinel)
   {
      c = *src++;
      switch( c)
      {
      case '<' : dst = copy( dst, "&lt;", 4); break;
      case '>' : dst = copy( dst, "&gt;", 4); break;
      case '&' : dst = copy( dst, "&amp;", 5); break;
      default  : *dst++= c;
      }
   }
   
   len = dst - start;
   [data setLength:len * (sizeof( unichar))];
   return( [NSString stringWithCharacters:(unichar *) [data bytes]
                                   length:len]);
}

@end
