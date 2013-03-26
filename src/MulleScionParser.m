//
//  MulleScionParser.m
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


#import "MulleScionParser.h"

#import "MulleScionParser+Parsing.h"
#import "MulleScionObjectModel+Parsing.h"
#import "MulleScionObjectModel+BlockExpansion.h"
#if ! TARGET_OS_IPHONE
# import <Foundation/NSDebug.h>
#endif

@implementation MulleScionParser

- (id) initWithData:(NSData *) data
           fileName:(NSString *) fileName
{
   NSParameterAssert( [data isKindOfClass:[NSData class]]);
   NSParameterAssert( [fileName isKindOfClass:[NSString class]] && [fileName length]);
   
   data_     = [data retain];
   fileName_ = [fileName copy];

   return( self);
}


- (void) dealloc
{
   [fileName_ release];
   [data_ release];
   
   [super dealloc];
}


+ (MulleScionParser *) parserWithContentsOfFile:(NSString *) path
{
   NSData            *data;
   MulleScionParser  *parser;
   
   data = [NSData dataWithContentsOfMappedFile:path];
   if( ! data)
   {
      [self autorelease];
      return( nil);
   }
   
   parser = [[[self alloc] initWithData:data
                               fileName:path] autorelease];
   return( parser);
}


#if DEBUG
- (id) autorelease
{
   return( [super autorelease]);
}
#endif


- (NSString *) fileName
{
   return( fileName_);
}


- (MulleScionTemplate *) template
{
   MulleScionTemplate      *template;
   NSMutableDictionary     *blockTable;
   NSAutoreleasePool       *pool;
   NSAutoreleasePool       *outer;
   
   outer      = [NSAutoreleasePool new];
   blockTable = [NSMutableDictionary dictionary];

   pool = [NSAutoreleasePool new];
   template = [[self templateParsedWithBlockTable:blockTable] retain];
   [pool release];

#ifndef DEBUG
   if( NSDebugEnabled)
#endif
      if( [template respondsToSelector:@selector( mulleScionDescription)])
         NSLog( @"Parsed Template:\n%@", [template count] <= 1848 ? template : @"too large to print");
   
   pool = [NSAutoreleasePool new];
   [template expandBlocksUsingTable:blockTable];
   [pool release];
   
#ifndef DEBUG
   if( NSDebugEnabled)
#endif
      if( [template respondsToSelector:@selector( mulleScionDescription)])
         NSLog( @"Template after block expansion:\n%@", [template count] <= 1848 ? template : @"too large to print");
   
   [outer release];
   return( [template autorelease]);
}


- (MulleScionTemplate *) templateParsedWithBlockTable:(NSMutableDictionary *) blockTable
{
   NSMutableDictionary   *definitonsTable;
   NSMutableDictionary   *macroTable;
   MulleScionTemplate    *template;
   NSAutoreleasePool     *pool;
   
   pool            = [NSAutoreleasePool new];
   
   definitonsTable = [NSMutableDictionary dictionary];
   macroTable      = [NSMutableDictionary dictionary];
   template        = [[self templateParsedWithBlockTable:blockTable
                                         definitionTable:definitonsTable
                                              macroTable:macroTable
                                         dependencyTable:nil] retain];
   [pool release];
   return( [template autorelease]);
}


- (NSDictionary *) dependencyTable
{
   NSMutableDictionary   *dependencyTable;
   NSMutableDictionary   *definitonsTable;
   NSMutableDictionary   *macroTable;
   NSMutableDictionary   *blockTable;
   NSAutoreleasePool     *pool;
   
   dependencyTable = [NSMutableDictionary dictionary];
   
   pool = [NSAutoreleasePool new];
   
   definitonsTable = [NSMutableDictionary dictionary];
   macroTable      = [NSMutableDictionary dictionary];
   blockTable      = [NSMutableDictionary dictionary];

   [self templateParsedWithBlockTable:blockTable
                      definitionTable:definitonsTable
                           macroTable:macroTable
                      dependencyTable:dependencyTable];
   [pool release];
   
   return( dependencyTable);
}


- (void) parserErrorInFileName:(NSString *) fileName
                    lineNumber:(NSUInteger) lineNumber
                        reason:(NSString *) reason
{
   [NSException raise:NSInvalidArgumentException
               format:@"%@,%lu: %@", fileName ? fileName : @"template", (long) lineNumber, reason];
}

@end
