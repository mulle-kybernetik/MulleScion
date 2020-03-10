//
//  NSString+HTMLEscape.m
//  MulleScion
//
//  Created by Nat! on 04.03.13.
//
//  Copyright (c) 2013 Nat! - Mulle kybernetiK
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//


#import "NSString+HTMLEscape.h"
#import "GTMNSString+HTML.h"


@implementation NSString (HTMLEscape)

#ifdef __MULLE_OBJC__

- (NSString *) htmlEscapedString
{
   return( [self mulleStringByEscapingHTMLForASCII]);
}

#else

# ifndef  NO_APACHE_LICENSE

- (NSString *) htmlEscapedString
{
   return( [self gtm_stringByEscapingForAsciiHTML]);
}

# else

static inline unichar   *copy( unichar *dst, char *src, NSUInteger len)
{
   char  *sentinel;
   
   sentinel = &src[ len];
   while( src < sentinel)
      *dst++ = *src++;
   return( dst);
}


// this is not a good idea, remove this before release
- (NSString *) htmlEscapedString
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

# endif
#endif


- (NSString *) urlEscapedString
{
   return( [self stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
}

@end
