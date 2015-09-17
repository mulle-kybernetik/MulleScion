//
//  Hoedown.m
//  MulleScion
//
//  Created by Nat! on 17.02.15.
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
#import "Hoedown.h"
#import "NSData+Hoedown.h"


#define READ_UNIT     1024
#define OUTPUT_UNIT   256


//
// stupid hoedown lib can't do incremental rendering, so we have to
// buffer everything
//
@implementation Hoedown

- (id) init
{
   _buf = [NSMutableString new];
   return( self);
}

- (id) initWithHTMLEscaping:(BOOL) flag
{
   self = [self init];
   if( self)
      self->_htmlEscape = flag;
   return( self);
}


+ (id) regularFilter
{
   return( [[[self alloc] initWithHTMLEscaping:NO] autorelease]);
}


+ (id) htmlEscapedFilter
{
   return( [[[self alloc] initWithHTMLEscaping:YES] autorelease]);
}


- (void) dealloc
{
   [_buf release];
   
   [super dealloc];
}


- (NSString *) hoedownedString
{
   return( [_buf hoedownedString]);
}


- (void) appendString:(NSString *) s
{
   [_buf appendString:s];
}

@end
