//
//  MulleScionParser.m
//  MulleTwigLikeObjCTemplates
//
//  Created by Nat! on 24.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionParser.h"

#import "MulleScionParser+Parsing.h"
#import "MulleScionObjectModel.h"
#import <Foundation/NSDebug.h>


@implementation MulleScionParser

- (id) initWithData:(NSData *) data
           fileName:(NSString *) fileName
{
   NSParameterAssert( [data isKindOfClass:[NSData class]]);
   NSParameterAssert( [fileName isKindOfClass:[NSString class]] && [fileName length]);
   
   data_       = [data retain];
   fileName_   = [[fileName lastPathComponent] retain];

   return( self);
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

- (id) autorelease
{
   return( [super autorelease]);
}


- (void) dealloc
{
   [fileName_ release];
   [data_ release];
   
   [super dealloc];
}


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
      NSLog( @"Parsed Template:\n%@", [template count] <= 1848 ? template : @"too large to print");
   
   pool = [NSAutoreleasePool new];
   [template expandBlocksUsingTable:blockTable];
   [pool release];
   
#ifndef DEBUG
   if( NSDebugEnabled)
#endif
      NSLog( @"Template after block expansion:\n%@", [template count] <= 1848 ? template : @"too large to print");
   [outer release];
   return( [template autorelease]);
}


- (void) parserErrorInFileName:(NSString *) fileName
                    lineNumber:(NSUInteger) lineNumber
                        reason:(NSString *) reason
{
   [NSException raise:NSInvalidArgumentException
               format:@"%@ %lu: %@", fileName ? fileName : @"template", lineNumber, reason];
}

@end
