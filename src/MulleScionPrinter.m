//
//  MulleScionPrinter.m
//  MulleScionTemplates
//
//  Created by Nat! on 24.02.13.
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


#import "MulleScionPrinter.h"
#import "MulleScionObjectModel.h"



@implementation MulleScionPrinter

- (id) initWithDataSource:(id) dataSource
{
   // NSLog( @"<%@ %p lives>", isa, self);

   if( ! dataSource)
   {
      [self autorelease];
      return( nil);
   }
   dataSource_  = dataSource;
   [dataSource retain];

   return( self);
}


- (void) dealloc
{
   [dataSource_ release];
   [defaultlocals_ release];

   // Instruments apparently lies cold blooded :)
   //NSLog( @"<%@ %p is dead>", isa, self);
   [super dealloc];
}


- (NSDictionary *) defaultlocals
{
   return( defaultlocals_);
}


- (void) setDefaultlocalVariables:(NSDictionary *) dictionary
{
   [defaultlocals_ autorelease];
   defaultlocals_ = [dictionary copy];
}


- (void) writeToOutput:(id <MulleScionOutput>) output
              template:(MulleScionTemplate *) template
{
   NSMutableDictionary   *locals;
   
   NSParameterAssert( [template isKindOfClass:[MulleScionTemplate class]]);

   locals = [NSMutableDictionary dictionaryWithDictionary:defaultlocals_];
   NSParameterAssert( locals);  // could raise if Apple starts hating on nil
   [template renderInto:output
         localVariables:locals
             dataSource:dataSource_];
}


- (NSString *) describeWithTemplate:(MulleScionTemplate *) template
{
   NSMutableString   *s;
   
   s = [NSMutableString stringWithCapacity:0x8000];
   [self writeToOutput:s
              template:template];
   return( s);
}

@end
