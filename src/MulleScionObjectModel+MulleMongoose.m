//
//  MulleScionObjectModel+MulleMongoose.m
//  MulleScion
//
//  Created by Nat! on 03.03.13.
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

#import "MulleScionObjectModel+MulleMongoose.h"


@implementation MulleScionTemplate ( MulleMongoose)

static BOOL fileExists( NSString *fileName)
{
   NSFileManager  *manager;
   NSString       *dir;
   NSString       *path;
   
   manager = [NSFileManager defaultManager];
   dir     = [manager currentDirectoryPath];
   path    = [dir stringByAppendingPathComponent:fileName];
   path    = [path stringByResolvingSymlinksInPath];
   path    = [path stringByStandardizingPath];
   return( [manager fileExistsAtPath:path]);
}

- (id) initWithContentsOfFile:(NSString *) fileName
                      options:(NSDictionary *) info
{
   NSString          *wrapper;
   MulleScionParser  *parser;
   NSMutableData     *data;
   NSData            *search;
   NSData            *replace;
   NSRange           range;

   wrapper = [info objectForKey:@"wrapper"];
   if( ! wrapper)
      return( [self initWithContentsOfFile:fileName]);

   // be sure, that users ain't spoofing us
   if( ! fileExists( fileName))
   {
      [self autorelease];
      return( nil);
   }

   data = [NSMutableData dataWithContentsOfMappedFile:wrapper];
   if( ! data)
   {
      [self autorelease];
      return( nil);
   }

   search  = [@"{$ WRAPPED_TEMPLATE $}" dataUsingEncoding:NSUTF8StringEncoding];
   replace = [fileName dataUsingEncoding:NSUTF8StringEncoding];
   
   for(;;)
   {
      range = NSMakeRange( 0, [data length]);
      range = [data rangeOfData:search
                        options:0
                          range:range];
      if( range.length == 0)
         break;
      
      [data replaceBytesInRange:range
                      withBytes:[replace bytes]
                         length:[replace length]];
   }

   // no caching :)
   parser = [[[MulleScionParser alloc] initWithData:data
                                           fileName:wrapper] autorelease];
   [self autorelease];
   self = [[parser template] retain];
   
   return( self);
   
}


- (id) initWithContentsOfFile:(NSString *) fileName
                optionsString:(NSString *) options
{
   NSArray               *components;
   NSString              *key;
   NSString              *value;
   NSString              *pair;
   NSEnumerator          *rover;
   NSMutableDictionary   *info;
   
   info = nil;
   if( [options length])
   {
      info       = [NSMutableDictionary dictionary];
      components = [options componentsSeparatedByString:@"?"];
      
      rover = [components objectEnumerator];
      while( pair = [rover nextObject])
      {
         components = [options componentsSeparatedByString:@"="];
         key        = [components objectAtIndex:0];
         value      = @"";
         
         // need to deescape stuff
         if( [components count] > 1)
            value = [components objectAtIndex:1];
         
         [info setObject:value
                  forKey:key];
      }
   }
   return( [self initWithContentsOfFile:fileName
                                options:info]);
}


+ (NSDictionary *) dependencyTableOfFile:(NSString *) fileName
{
   NSDictionary       *dictionary;
   NSData             *data;
   MulleScionParser   *parser;
   
   data = [NSMutableData dataWithContentsOfMappedFile:fileName];
   if( ! data)
      return( nil);

   parser     = [[[MulleScionParser alloc] initWithData:data
                                               fileName:fileName] autorelease];
   dictionary = [parser dependencyTable];
   
   return( dictionary);
   
}


#pragma mark -
#pragma mark Convenience for mulle-scion
   
- (id) initWithString:(NSString *) s
{
   MulleScionParser    *parser;
   NSData              *data;
   MulleScionTemplate  *template;
   
   data     = [s dataUsingEncoding:NSUTF8StringEncoding];
   parser   = [[[MulleScionParser alloc] initWithData:data
                                             fileName:@"inline"] autorelease];
   template = [[parser template] retain];
   [self autorelease];
   return( template);
}
   
@end
