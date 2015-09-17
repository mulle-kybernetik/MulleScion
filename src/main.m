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
#import "MulleScionTemplate+CompressedArchive.h"
#import "NSFileHandle+MulleOutputFileHandle.h"


static NSFileHandle  *outputStreamWithInfo( NSDictionary *info);
static NSDictionary  *getInfoFromArguments( void);
static id            acquirePropertyListOrDataSourceFromBundle( NSString *s);


@interface NSFileHandle ( MulleScionOutput) < MulleScionOutput >
@end


@implementation NSFileHandle ( MulleScionOutput)
   
- (void) appendString:(NSString *) s
{
   NSData   *data;
      
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


static MulleScionTemplate   *acquireTemplateFromPath( NSString *fileName)
{
   MulleScionTemplate   *template;
   NSData               *data;
   NSString             *string;
   NSURL                *url;
   
   template = nil;
   //
   // if fileName stars with '{' assume, that it's a command line template
   //
   if( [fileName hasPrefix:@"{"]) //  on her milk white neck ... the devil's mark
      template = [[[MulleScionTemplate alloc] initWithString:fileName] autorelease];
   else
      if( [fileName isEqualToString:@"-"])
      {
         data   = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
         string = [[[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding] autorelease];
         template = [[[MulleScionTemplate alloc] initWithString:string] autorelease];
         
      }
      else
      {
         if( [fileName rangeOfString:@"://"].length)
         {
            url      = [NSURL URLWithString:fileName];
            template = [[[MulleScionTemplate alloc] initWithContentsOfFile:url] autorelease];
         }
         else
            template = [[[MulleScionTemplate alloc] initWithFile:fileName] autorelease];
      }

   if( ! template)
      NSLog( @"Template \"%@\" could not be read", fileName);

   return( template);
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


static id   acquirePropertyListFromArgs( NSArray *args)
{
   NSMutableDictionary   *plist;
   NSEnumerator          *rover;
   NSString              *arg;
   id                    components;
   NSString              *key;
   NSString              *value;
   
   plist = [NSMutableDictionary dictionary];
   
   rover = [args objectEnumerator];
   while( arg = [rover nextObject])
   {
      components = [arg componentsSeparatedByString:@"="];

      key = [components objectAtIndex:0];
      if( ! [key length])
         continue;
      
      switch( [components count])
      {
      default :
         components = [[components mutableCopy] autorelease];
         [components removeObjectAtIndex:0];
         value = [components componentsJoinedByString:@"="];
         break;
         
      case 2 :
         value = [components objectAtIndex:1];
         break;
      
      case 1 :
         value = @"1";
         break;
      }

      // quote stuff will have been removed by shell
      [plist setObject:value
                forKey:key];
   }
   return( plist);
}


static id   acquirePropertyListOrDataSourceFromBundle( NSString *s)
{
   NSData     *data;
   NSString   *error;
   NSURL      *url;
   id         plist;
   
   if( [s isEqualToString:@"none"])
      return( [NSDictionary dictionary]);
   
   if( [s isEqualToString:@"-"])
      data = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
   else
   {
      if( [[s pathExtension] isEqualToString:@"plist"])
      {
         if( [s rangeOfString:@"://"].length)
         {
            url  = [NSURL URLWithString:s];
            data = [NSData dataWithContentsOfURL:url];
         }
         else
            data = [NSData dataWithContentsOfFile:s];
      }
      else
         return( acquireDataSourceFromBundle( s));
   }
   error = nil;
   plist = [NSPropertyListSerialization propertyListFromData:data
                                            mutabilityOption:NSPropertyListImmutable
                                                      format:NULL
                                            errorDescription:&error];
   if( ! plist)
      NSLog( @"property list failure: %@", error);
   
   return( plist);
}


static NSString  *processName( void)
{
   NSArray        *arguments;
   NSEnumerator   *rover;

   arguments = [[NSProcessInfo processInfo] arguments];
   rover     = [arguments objectEnumerator];
   return( [[rover nextObject] lastPathComponent]);
}


static void   usage( void)
{
   fprintf( stderr, "%s [-w|-z] <-|template> [bundle|plist|-|keyvalue|none] [-|outputfile] [argv|<key>[=value]]*\n", [processName() cString]);
   fprintf( stderr, "v%s\n", MulleScionFrameworkVersion);
   fprintf( stderr,
   "\t-w       : start webserver for /tmp/MulleScionDox\n"
   "\t-z       : write compressed archive to outputfile\n"
   "\t-Z       : write compressed keyed archive to outputfile (for IOS)\n"
   "\n"
   "\ttemplate : a MulleScion template\n\n"
   "\tbundle   : a NSBundle. It's NSPrincipalClass will be used as the datasource\n"
   "\tplist    : any kind of property list as datasouece, see: plist(5)\n"
   "\tkeyvalue : use keyvalue arguments as datasource (see below)\n"
   "\targv     : arguments made available to the template via __ARGV__ (default)\n"
   "\tkey      : key values as datasource contents (only with keyvalue)\n"
   "\n"
   "example:\n"
   "echo '***{{ VALUE }}***' | mulle-scion - args - VALUE=\"VfL Bochum 1848\"\n"
   );
}


static NSDictionary  *getInfoFromEnumerator( NSEnumerator *rover)
{
   NSArray               *argv;
   NSMutableDictionary   *info;
   NSString              *outputName;
   NSString              *plistName;
   NSString              *templateName;
   id                    plist;
   
   [rover nextObject];  // skip

   info         = [NSMutableDictionary dictionary];
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
   
   if( [plistName isEqualToString:@"keyvalue"])
   {
      plist = acquirePropertyListFromArgs( argv);
      argv  = [NSArray array];
   }
   else
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
   usage();
   return( nil);
}


static NSDictionary  *getInfoFromArguments( void)
{
   NSArray   *arguments;
   
   arguments = [[NSProcessInfo processInfo] arguments];
   return( getInfoFromEnumerator( [arguments objectEnumerator]));
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


static int   _archive_main( int argc, const char * argv[], int keyed)
{
   MulleScionTemplate   *template;
   NSArray              *arguments;
   NSDictionary         *info;
   NSEnumerator         *rover;
   NSString             *archiveName;
   NSString             *fileName;
   
   arguments = [[NSProcessInfo processInfo] arguments];
   rover     = [arguments objectEnumerator];
   [rover nextObject];  // skip -z

   info = getInfoFromEnumerator( rover);
   if( ! info)
      return( -3);

   archiveName = [info objectForKey:@"output"];
   if( [archiveName isEqualToString:@"-"])
      return( -3);
   
   template = acquireTemplateFromPath( fileName);
   if( ! template)
      return( -1);
   
   if( ! [template writeArchive:archiveName
                          keyed:keyed])
   {
      NSLog( @"Archive \"%@\" could not be written", archiveName);
      return( -1);
   }
   
   return( 0);
}


static int   _main(int argc, const char * argv[])
{
   NSDictionary   *info;
   NSFileHandle   *stream;
   MulleScionTemplate   *template;
   
   info = getInfoFromArguments();
   if( ! info)
      return( -3);
   
   template = acquireTemplateFromPath( [info objectForKey:@"MulleScionRootTemplate"]);
   if( ! template)
      return( -1);

   stream = outputStreamWithInfo( info);
   if( ! stream)
      return( -2);

   [template writeToOutput:stream
                dataSource:[info objectForKey:@"dataSource"]
            localVariables:localVariablesFromInfo( info)];
   return( 0);
}


int main( int argc, const char * argv[])
{
   NSAutoreleasePool   *pool;
   int                 rval;

   if( argc > 1)
   {
#ifndef DONT_HAVE_WEBSERVER
      if( ! strcmp( argv[ 1], "-w"))
      {
         int   main_www( int argc, const char * argv[]);
         
         return( main_www( argc, argv));
      }
#endif

      if( ! strcmp( argv[ 1], "-z"))
         return( _archive_main( argc, argv, NO));

      if( ! strcmp( argv[ 1], "-Z"))
         return( _archive_main( argc, argv, YES));

      if( ! strcmp( argv[ 1], "-h") || ! strcmp( argv[ 1], "--help"))
      {
         usage();
         return( 0);
      }
   }
   
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


/*
 *
 */
#ifndef DONT_HAVE_WEBSERVER

 static char    *default_options[] =
{
   "document_root",   "/tmp/MulleScionDox",
   "listening_ports", "127.0.0.1:18048",
   "num_threads", "1",
   "index_files", "index.scion,index.html,index.htm,index.cgi,index.shtml,index.php,index.lp",
   NULL
};


int   main_www( int argc, const char * argv[])
{
   id         plist;
   char       *s;
   NSString   *path;
   NSURL      *url;
   
   loadBundles();
   
   // hack to get something else going
   s = getenv( "MulleScionServerRoot");
   if( s)
      default_options[ 1] = s;
   
   s = getenv( "MulleScionServerPort");
   if( s)
      default_options[ 3] = s;
   
   path = @"/tmp/MulleScionDox/properties.plist";
   s = getenv( "MulleScionServerPlist");
   if( s)
      path = [NSString stringWithCString:s];
   
   plist = acquirePropertyListOrDataSourceFromBundle( path);
   if( ! plist)
      plist = [NSDictionary dictionary];
   
   mulle_mongoose_main( plist, default_options);
   return( 0);
}
#endif



