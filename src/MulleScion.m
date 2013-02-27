//
//  MulleScion.m
//  MulleTwigLikeObjCTemplates
//
//  Created by Nat! on 25.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScion.h"
#import "MulleScionPrinter.h"
#import "MulleScionParser.h"
#import "MulleScionTemplate+CompressedArchive.h"


@implementation MulleScionTemplate ( Convenience)

+ (BOOL) writeToOutput:(id <MulleScionOutput>) output
          templateFile:(NSString *) fileName
            dataSource:(id <MulleScionDataSource>) dataSource
        localVariables:(NSDictionary *) locals
{
   MulleScionTemplate   *template;
   
   template = [[[MulleScionTemplate alloc] initWithContentsOfFile:fileName] autorelease];
   if( ! template)
      return( NO);
   
   [template writeToOutput:output
                dataSource:dataSource
            localVariables:locals];
   
   return( YES);
}


+ (NSString *) descriptionWithTemplateFile:(NSString *) fileName
                                dataSource:(id <MulleScionDataSource>) dataSource
                            localVariables:(NSDictionary *) locals
{
   MulleScionTemplate   *template;
   
   template = [[[MulleScionTemplate alloc] initWithContentsOfFile:fileName] autorelease];
   if( ! template)
      return( nil);
   
   return( [template descriptionWithDataSource:dataSource
                                localVariables:(NSDictionary *) locals]);
}


- (id) initWithContentsOfFile:(NSString *) fileName
{
   MulleScionParser   *parser;
#ifndef DONT_HAVE_MULLE_SCION_CACHING
   BOOL               isCaching;
   NSString           *cacheDir;
   NSString           *cachePath;
   NSString           *name;
   
   isCaching = [isa isCacheEnabled];
   
   if( isCaching)
   {
      name      = [[fileName lastPathComponent] stringByDeletingPathExtension];
      cacheDir  = [isa cacheDirectory];
      if( ! cacheDir)
         cacheDir = [fileName stringByDeletingLastPathComponent];
      
      if( ! [cacheDir length])
         cacheDir = @".";
      cachePath = [cacheDir stringByAppendingPathComponent:name];
      cachePath = [cachePath stringByAppendingPathExtension:@"scionz"];
      
      self = [self initWithContentsOfArchive:cachePath];
      if( self)
         return( self);
   }
   else
#endif
   {
      [self autorelease];
      // self = nil;
   }
   
   parser = [MulleScionParser parserWithContentsOfFile:fileName];
   self   = [[parser template] retain];
   
#ifndef DONT_HAVE_MULLE_SCION_CACHING
   if( isCaching)
   {
      if( ! [self writeArchive:cachePath])
      {
         NSLog( @"Cache write to %@ failed, caching turned off", cachePath);
         [isa setCacheEnabled:NO];
      }
   }
#endif
   return( self);
}


- (NSString *) descriptionWithDataSource:(id) dataSource
                          localVariables:(NSDictionary *) locals
{
   MulleScionPrinter   *printer;
   
   printer = [[[MulleScionPrinter alloc] initWithDataSource:dataSource] autorelease];
   [printer setDefaultlocalVariables:locals];
   return( [printer describeWithTemplate:self]);
}


- (void) writeToOutput:(id <MulleScionOutput>) output
            dataSource:(id <MulleScionDataSource>) dataSource
        localVariables:(NSDictionary *) locals
{
   MulleScionPrinter   *printer;
   
   printer = [[[MulleScionPrinter alloc] initWithDataSource:dataSource] autorelease];
   [printer setDefaultlocalVariables:locals];
   [printer writeToOutput:output
                 template:self];
}

@end


#ifndef DONT_HAVE_MULLE_SCION_CACHING

#define MulleScionCacheDirectoryKey   @"MulleScionCacheDirectory"

@implementation MulleScionTemplate ( Caching)

static BOOL       cacheEnabled_;
static NSString   *cacheDirectory_;


static BOOL  checkCacheDirectory( NSString *path)
{
   NSFileManager      *manager;

   manager = [NSFileManager defaultManager];
   if( ! [manager createDirectoryAtPath:path
            withIntermediateDirectories:YES
                             attributes:nil
                                  error:NULL])
   {
      NSLog( @"can't create cache directory %@", path);
      return( NO);;
   }
   if( ! [manager isWritableFileAtPath:path])
   {
      NSLog( @"can't write to cache directory %@", path);
      return( NO);;
   }
   return( YES);
}


+ (void) load
{
   NSAutoreleasePool  *pool;
   NSString           *s;
   
   pool = [NSAutoreleasePool new];
   s = [[NSUserDefaults standardUserDefaults] stringForKey:MulleScionCacheDirectoryKey];
   if( ! s)
      s = [[[NSProcessInfo processInfo] environment] objectForKey:MulleScionCacheDirectoryKey];
   if( s)
      if( checkCacheDirectory( s))
      {
         [self setCacheDirectory:s];
         [self setCacheEnabled:YES];
      }
   [pool release];
}


+ (void) setCacheDirectory:(NSString *) directory
{
   [cacheDirectory_ autorelease];
   cacheDirectory_ = [directory copy];
}


+ (NSString *) cacheDirectory
{
   return( cacheDirectory_);
}


+ (void) setCacheEnabled:(BOOL) flag;
{
   cacheEnabled_ = flag;
}


+ (BOOL) isCacheEnabled
{
   return( cacheEnabled_);
}

@end

#endif

