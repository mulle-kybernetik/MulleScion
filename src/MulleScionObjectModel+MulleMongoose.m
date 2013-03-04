//
//  MulleScionObjectModel+MulleMongoose.m
//  MulleScionTemplates
//
//  Created by Nat! on 03.03.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
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

@end
