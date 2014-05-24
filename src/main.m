//
//  main.m
//  MulleScion
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
#import <Foundation/Foundation.h>

#import "MulleScion.h"
#import "MulleMongoose.h"
#import "MulleScionObjectModel+MulleMongoose.h"
#import "NSFileHandle+MulleOutputFileHandle.h"


static NSFileHandle  *outputStreamWithInfo( NSDictionary *info);
static NSDictionary  *getInfoFromArguments( void);
static id            acquirePropertyListOrDataSourceFromBundle( NSString *s);


@interface NSFileHandle ( MulleScionOutput) < MulleScionOutput >
   @end


@implementation NSFileHandle ( MulleScionOutput)
   
- (void) appendString:(NSString *) s
{
   NSData             *data;
      
   data = [s dataUsingEncoding:NSUTF8StringEncoding];
   [self writeData:data];
}
   
@end



/* #####
   ##### #####  CODE SPECIFIC FOR MULLE SCION
   ##### */

static NSDictionary  *localVariablesFromInfo( NSDictionary *info)
{
   NSMutableDictionary   *sanitize;
   
   sanitize = [NSMutableDictionary dictionary];
   [sanitize setObject:[info objectForKey:@"MulleScionRootTemplate"]
                forKey:@"MulleScionRootTemplate"];
   [sanitize setObject:[info objectForKey:@"MulleScionPropertyListName"]
                forKey:@"MulleScionPropertyListName"];
   [sanitize setObject:[info objectForKey:@"__ARGV__"]
                forKey:@"__ARGV__"];
   
   return( sanitize);
}


static int   run( NSString *fileName,
                  id <MulleScionDataSource> src,
                  id < MulleScionOutput> dst,
                  NSDictionary *locals)
{
   MulleScionTemplate   *template;
   
   //
   // if fileName stars with '{' assume, that it's a command line template
   //
   if( [fileName hasPrefix:@"{"]) //  on her milk white neck ... the devil's mark
   {
      template = [[[MulleScionTemplate alloc] initWithString:fileName] autorelease];
      if( template)
      {
         [template writeToOutput:dst
                      dataSource:src
                  localVariables:locals];
         return( 0);
      }
   }
   else
      if( [MulleScionTemplate writeToOutput:dst
                               templateFile:fileName
                                 dataSource:src
                             localVariables:locals])
         return( 0);
   
   NSLog( @"Template \"%@\" could not be read", fileName);
   return( -1);
}


/*       #####
   ##### #####
         ##### */
static id   acquireDataSourceFromBundle( NSString *s)
{
   NSBundle   *bundle;
   id         plist;
   Class      cls;
   
   bundle = [NSBundle bundleWithPath:s];
   cls    = [bundle principalClass];
   if( ! cls)
   {
      NSLog( @"bundle \"%@\" load failure", s);
      return( nil);
   }
   
   if( ! [cls respondsToSelector:@selector( mulleScionDataSource)])
   {
      NSLog( @"bundle's principal class \"%@\" does not respond to +mulleScionDataSource", cls);
      return( nil);
   }
   
   plist = [cls performSelector:@selector( mulleScionDataSource)];
   if( ! plist)
   {
      NSLog( @"bundle's principal class \"%@\" returned nil for +mulleScionDataSource", cls);
      return( nil);
   }
   
   if( ! [plist respondsToSelector:@selector( valueForKeyPath:)])
   {
      NSLog( @"bundle's dataSource\"%@\" does not respond to -valueForKeyPath:", [plist class]);
      return( nil);
   }
   return( plist);
}


static id   acquirePropertyListOrDataSourceFromBundle( NSString *s)
{
   NSData    *data;
   NSString  *error;
   id        plist;
   
   if( [s isEqualToString:@"none"])
      return( [NSDictionary dictionary]);
   
   if( [s isEqualToString:@"-"])
      data = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
   else
      if( [[s pathExtension] isEqualToString:@"plist"])
         data = [NSData dataWithContentsOfFile:s];
      else
         return( acquireDataSourceFromBundle( s));
   
   error = nil;
   plist = [NSPropertyListSerialization propertyListFromData:data
                                            mutabilityOption:NSPropertyListImmutable
                                                      format:NULL
                                            errorDescription:&error];
   if( ! plist)
      NSLog( @"property list failure: %@", error);
   
   return( plist);
}


static NSDictionary  *getInfoFromArguments( void)
{
   NSArray               *arguments;
   NSString              *plistName;
   NSEnumerator          *rover;
   NSString              *processName;
   NSString              *templateName;
   NSString              *outputName;
   id                    plist;
   NSMutableDictionary   *info;
   NSArray               *argv;
   
   info         = [NSMutableDictionary dictionary];
   arguments    = [[NSProcessInfo processInfo] arguments];
   rover        = [arguments objectEnumerator];
   processName  = [[rover nextObject] lastPathComponent];
   templateName = [rover nextObject];
   plistName    = [rover nextObject];
   outputName   = [rover nextObject];
   argv         = [rover allObjects];

   if( ! [templateName length])
      goto usage;
   if( ! [plistName length])
      plistName = @"none";
   if( ! [outputName length])
      outputName = @"-";
   
   plist = acquirePropertyListOrDataSourceFromBundle( plistName);
   if( ! plist)
      goto usage;
   [info setObject:plist
            forKey:@"dataSource"];
   
   [info setObject:templateName
            forKey:@"MulleScionRootTemplate"];
   [info setObject:plistName
            forKey:@"MulleScionPropertyListName"];
   [info setObject:outputName
            forKey:@"output"];
   if( argv)
      [info setObject:argv
               forKey:@"__ARGV__"];
   
   return( info);
   
usage:
   fprintf( stderr, "%s [-w] <template> [bundle|propertylist|-|none] [-|outputfile] [arguments]\n", [processName cString]);
   fprintf( stderr, "v%s", MulleScionFrameworkVersion);
   return( nil);
}


static NSFileHandle   *outputStreamWithInfo( NSDictionary *info)
{
   NSString       *outputName;
   NSFileHandle   *stream;
   
   outputName = [info objectForKey:@"output"];
   stream     = [NSFileHandle mulleOutputFileHandleWithFilename:outputName];
   if( ! stream)
      NSLog( @"failed to create output file \"%@\"", outputName);
   return( stream);
}


static void  loadBundles( void)
{
   NSEnumerator   *rover;
   NSBundle       *bundle;
   NSString       *argument;
   
   rover = [[[NSProcessInfo processInfo] arguments] objectEnumerator];
   [rover nextObject];
   
   while( argument = [rover nextObject])
   {
      if( [argument hasPrefix:@"-"])
         continue;
      
      bundle = [NSBundle bundleWithIdentifier:argument];
      if( ! bundle)
         bundle = [NSBundle bundleWithPath:argument];
      if( ! [bundle load])
      {
         NSLog( @"Couldn't load bundle %@", argument);
         exit( 1);
      }
   }
}


static int _main(int argc, const char * argv[])
{
   NSFileHandle        *stream;
   NSDictionary        *info;
   
   info = getInfoFromArguments();
   if( ! info)
      return( -3);
   
   stream = outputStreamWithInfo( info);
   if( ! stream)
      return( -2);
   
   return( run( [info objectForKey:@"MulleScionRootTemplate"],
               [info objectForKey:@"dataSource"],
               stream,
               localVariablesFromInfo( info)));
}


static char    *default_options[] =
{
   "document_root",   "/tmp/MulleScionDox",
   "listening_ports", "127.0.0.1:18048",
   "num_threads", "1",
   "index_files", "index.scion,index.html,index.htm,index.cgi,index.shtml,index.php,index.lp",
   NULL
};


int main( int argc, const char * argv[])
{
   NSAutoreleasePool   *pool;
   int                 rval;
#ifndef DONT_HAVE_WEBSERVER
   id                  plist;

   if( argc > 1 && ! strcmp( argv[ 1], "-w"))
   {
      loadBundles();
      plist = [NSDictionary dictionaryWithContentsOfFile:@"/tmp/MulleScionDox/properties.plist"];
      if( ! plist)
      {
         NSLog( @"/tmp/MulleScionDox/properties.plist not found");
         return( -5);
      }
      mulle_mongoose_main( plist, default_options);
      return( 0);
   }
#endif
   
   pool = [NSAutoreleasePool new];
NS_DURING
   rval = _main( argc, argv);
NS_HANDLER
   NSLog( @"%@", localException);
   rval = -4;
NS_ENDHANDLER
#if defined( DEBUG) || defined( PROFILE)
   [pool release];
#endif
# ifdef PROFILE
   // sleeping for the sampler to hit stuff
   sleep( 2);
# endif
   return( rval);
}


