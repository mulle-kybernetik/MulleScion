//
//  main.m
//  MulleScionTemplates
//
//  Created by Nat! on 24.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MulleScion.h"


static NSFileHandle  *outputStreamWithInfo( NSDictionary *info);
static NSDictionary  *getInfoFromArguments( void);
static id            acquirePropertyList( NSString *s);


/* #####
   ##### #####  CODE SPECIFIC FOR MULLE SCION
   ##### */

static NSDictionary  *localVariablesFromInfo( NSDictionary *info)
{
   NSMutableDictionary   *sanitize;
   
   sanitize = [NSMutableDictionary dictionary];
   [sanitize setObject:[info objectForKey:@"MulleScionRootTemplate"]
                forKey:@"MulleScionRootTemplate"];
   [sanitize setObject:[info objectForKey:@"MulleScionPropertyList"]
                forKey:@"MulleScionPropertyList"];
   return( sanitize);
}


@interface NSFileHandle ( MulleScionOutput) < MulleScionOutput >
@end


@implementation NSFileHandle ( MulleScionOutput)

- (void) appendString:(NSString *) s
{
   [self writeData:[s dataUsingEncoding:NSUTF8StringEncoding]];
}

@end



static int   run( NSString *template,
                  id <MulleScionDataSource> src,
                  id < MulleScionOutput> dst,
                  NSDictionary *locals)
{
   if( ! [MulleScionTemplate writeToOutput:dst
                              templateFile:template
                                dataSource:src
                            localVariables:locals])
   {
      NSLog( @"Template file \"%@\" could not be read", template);
      return( -1);
   }

   return( 0);
}


/*       #####
   ##### #####
         ##### */

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
                [info objectForKey:@"plist"],
                stream,
                localVariablesFromInfo( info)));
}


int main(int argc, const char * argv[])
{
   NSAutoreleasePool   *pool;
   int                 rval;
   
   pool = [NSAutoreleasePool new];
   rval = _main( argc, argv);
   
#if DEBUG
   [pool release];
#endif
   return( rval);
}


static id   acquirePropertyList( NSString *s)
{
   NSData    *data;
   NSString  *error;
   id        plist;
   
   if( [s isEqualToString:@"none"])
      return( [NSDictionary dictionary]);
   
   if( [s isEqualToString:@"-"])
      data = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
   else
      data = [NSData dataWithContentsOfFile:s];
   
   error = nil;
   plist = [NSPropertyListSerialization propertyListFromData:data
                                            mutabilityOption:NSPropertyListImmutable
                                                      format:NULL
                                            errorDescription:&error];
   if( ! plist)
   {
      NSLog( @"property list failure: %@", error);
      exit( -1);
   }
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
   
   info         = [NSMutableDictionary dictionary];
   arguments    = [[NSProcessInfo processInfo] arguments];
   rover        = [arguments objectEnumerator];
   processName  = [[rover nextObject] lastPathComponent];
   templateName = [rover nextObject];
   plistName    = [rover nextObject];
   outputName   = [rover nextObject];
   
   if( ! [templateName length])
      goto usage;
   if( ! [plistName length])
      goto usage;
   if( ! [outputName length])
      outputName = @"-";
   
   plist = acquirePropertyList( plistName);
   if( plist)
      [info setObject:plist
               forKey:@"plist"];
   
   [info setObject:templateName
            forKey:@"MulleScionRootTemplate"];
   [info setObject:plistName
            forKey:@"MulleScionPropertyList"];
   [info setObject:outputName
            forKey:@"output"];
   
   return( info);
   
usage:
   fprintf( stderr, "%s <template> <propertylist|-|none> [output|-]", [processName cString]);
   return( nil);
}


static NSFileHandle   *outputStreamWithInfo( NSDictionary *info)
{
   NSString       *outputName;
   NSFileHandle   *stream;
   
   outputName = [info objectForKey:@"output"];
   if( [outputName isEqualToString:@"-"])
      return( [NSFileHandle fileHandleWithStandardOutput]);
   [[NSFileManager defaultManager] createFileAtPath:outputName
                                           contents:[NSData data]
                                         attributes:nil];
   stream = [NSFileHandle fileHandleForWritingAtPath:outputName];
   if( ! stream)
      [[NSFileManager defaultManager] createFileAtPath:outputName
                                              contents:[NSData data]
                                            attributes:nil];
   else
      [stream truncateFileAtOffset:0];

   stream = [NSFileHandle fileHandleForWritingAtPath:outputName];
   if( ! stream)
      NSLog( @"failed to create output file \"%@\"", outputName);
   return( stream);
}

