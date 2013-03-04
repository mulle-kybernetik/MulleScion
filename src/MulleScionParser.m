//
//  MulleScionParser.m
//  MulleScionTemplates
//
//  Created by Nat! on 24.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionParser.h"

#import "MulleScionParser+Parsing.h"
#import "MulleScionObjectModel+Parsing.h"
#import "MulleScionObjectModel+BlockExpansion.h"
#import <Foundation/NSDebug.h>


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
