//
//  NSString+TrimTextFromExamples.h
//  MulleScion
//
//  Created by Nat! on 18.02.15.
//  Copyright (c) 2015 Mulle kybernetiK. All rights reserved.
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
#import "NSString+TrimTextFromExamples.h"


@implementation NSString (NonExamplesStripped)

- (NSString *) stringByTrimmingTextFromExamples
{
   NSMutableString   *buf;
   NSRange           range;
   NSString          *s;
   NSScanner         *scanner;
   
   // grab all stuff until # Example$
   // throw it away, keep the header snarf up code until ```` has been
   // encountered a second time
   
   buf     = [NSMutableString string];
   scanner = [[[NSScanner alloc] initWithString:self] autorelease];
   
   for( ;;)
   {
      if( ! [scanner scanUpToString:@"# Example"
                         intoString:&s])
         break;
      
      // dial back to preceeding \n + 1
      range = [s rangeOfString:@"\n"
                       options:NSBackwardsSearch|NSLiteralSearch];
      if( range.length)
         s = [s substringFromIndex:range.location + 1];
      [buf appendString:s];
      
      // scan up to first ```` and copy (including ````)
      if( ! [scanner scanUpToString:@"````"
                         intoString:&s])
         break;
      [buf appendString:s];
      [scanner scanString:@"````"
               intoString:NULL];
      [buf appendString:@"````"];
      
      // scan up to second ```` and copy (including ````)
      // weirdly code, because the NSScanner API is weird...
      if( ! [scanner scanUpToString:@"````"
                         intoString:&s])
         s = @"";
      if( ! [scanner scanString:@"````"
                     intoString:NULL])
         break;
      
      [buf appendString:s];
      [buf appendString:@"````\n"];
   }
   
   return( buf);
}

@end


@implementation NSData (StrippedToExamples)

- (NSData *) trimmedTextFromExamplesData
{
   NSString   *s;
   
   s = [[[NSString alloc] initWithData:self
                              encoding:NSUTF8StringEncoding] autorelease];
   s = [s stringByTrimmingTextFromExamples];
   return( [s dataUsingEncoding:NSUTF8StringEncoding]);
}

@end
