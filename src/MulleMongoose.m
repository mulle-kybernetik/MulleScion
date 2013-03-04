//
//  MulleMongoose.m
//  mulle-mongoose
//
//  Created by Nat! on 02.03.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//
#ifndef DONT_HAVE_WEBSERVER

#import "MulleMongoose.h"

#import <Foundation/Foundation.h>
#import <MulleScionTemplates/MulleScionTemplates.h>
#import "MulleScionObjectModel+MulleMongoose.h"

#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <errno.h>
#include <limits.h>
#include <stddef.h>
#include <stdarg.h>
#include <ctype.h>

#include "mongoose.h"


/* this code is just for demo purposes */

static void   mulle_write_response( struct mg_connection *conn, void *buf, size_t len)
{
   NSString  *header;
   NSData    *utf8Header;
   
   header = [NSString stringWithFormat:@"HTTP/1.1 200 OK\r\n"
                    "Date: %@\r\n"
                    "Content-Type: text/html\r\n"
                    "Content-Length: %lu\r\n\r\n",
                    [NSDate date],
                    (unsigned long) len];
   
   utf8Header = [header dataUsingEncoding:NSUTF8StringEncoding];
   mg_write( conn, [utf8Header bytes], [utf8Header length]);
             
   if( strcmp(  mg_get_request_info( conn)->request_method, "HEAD") != 0)
      mg_write( conn, buf, len);
}


static int   _mulle_mongoose_begin_request( struct mg_connection *conn)
{
   NSURL                    *url;
   NSString                 *s;
   NSString                 *ext;
   NSString                 *query;
   NSDictionary             *plist;
   NSBundle                 *bundle;
   struct mg_request_info   *info;
   Class                    cls;
   MulleScionTemplate       *template;
   NSString                 *response;
   NSData                   *utf8Data;
   
   info = mg_get_request_info( conn);
   s    = [NSString stringWithCString:info->uri];
   if( [s hasPrefix:@"/"])
      s = [s substringFromIndex:1];
   url  = [NSURL URLWithString:s];
   ext  = [[url lastPathComponent] pathExtension];
   if( ! [ext hasSuffix:@"scion"])
      return( 0);


#if DONT_LINK_AGAINST_MULLE_SCION_TEMPLATES
   bundle   = [NSBundle bundleWithPath:@"/Library/Frameworks/MulleScionTemplates.framework"];
   if( ! [bundle load])
      response = @"mulle scion templates not installed";
   else
#endif
   {
      cls      = NSClassFromString( @"MulleScionTemplate");
      plist    = [NSDictionary dictionaryWithContentsOfFile:@"properties.plist"];
      if( ! plist)
         response = @"properties.plist not found";
      else
      {
         query    = [NSString stringWithCString:info->query_string ? info->query_string : ""];
         //NS_DURING
         template = [[[cls alloc] initWithContentsOfFile:[url path]
                                           optionsString:query] autorelease];
         response = [template descriptionWithDataSource:plist
                                         localVariables:nil];
         //      NS_HANDLER
         //         response = [localException description];
         //      NS_ENDHANDLER
         if( ! response)
            response = @"template not found";
      }
   }

   utf8Data = [response dataUsingEncoding:NSUTF8StringEncoding];
   mulle_write_response( conn, (void *) [utf8Data bytes], [utf8Data length]);
   
   return( 1);
}


static int   mulle_mongoose_begin_request( struct mg_connection *conn)
{
   NSAutoreleasePool   *pool;
   int                 rval;
   
   pool = [NSAutoreleasePool new];
   rval = _mulle_mongoose_begin_request( conn);
   [pool release];
   return( rval);
}


static void   mulle_mongoose_end_request( struct mg_connection *conn, int reply_status_code)
{
}


/*
 * stuff stolen from main.c of mongoose
 */
static struct   mg_context *ctx;      // Set by start_mongoose()
static int     exit_flag;
static char    server_name[ 40];        // Set by init_server_name()


static void init_server_name(void)
{
   snprintf(server_name, sizeof(server_name), "mulle-scion web server (mongoose v. %s)",
            mg_version());
}


static void signal_handler( int sig_num)
{
   exit_flag = sig_num;
}


static int log_message( const struct mg_connection *conn, const char *message)
{
   NSLog(@"%s", message);
   return( 0);
}


static void start_mongoose()
{
   struct mg_callbacks callbacks;
   static char *options[] =
   {
      "document_root",   "/tmp",
      "listening_ports", "127.0.0.1:18048",
      NULL
   };
   /* Setup signal handler: quit on Ctrl-C */
   signal(SIGTERM, signal_handler);
   signal(SIGINT, signal_handler);
   
   /* Start Mongoose */
   memset(&callbacks, 0, sizeof(callbacks));
   callbacks.log_message  = &log_message;
   callbacks.begin_request = mulle_mongoose_begin_request;
   callbacks.end_request   = (void *) mulle_mongoose_end_request;

   [[NSFileManager defaultManager] changeCurrentDirectoryPath:@"/tmp"];
   
   ctx = mg_start( &callbacks, NULL, (void *) options);
   if (ctx == NULL)
   {
      NSLog( @"Failed to start mulle-scion web server.");
      exit( 1);
   }
}


void    mulle_mongoose_main()
{
   init_server_name();

   start_mongoose();

   NSLog(@"%s started on port(s) %s",
          server_name, mg_get_option(ctx, "listening_ports"));

   while( exit_flag == 0)
      sleep( 1);

   NSLog(@"Exiting on signal %d, waiting for all threads to finish...",
          exit_flag);
   mg_stop( ctx);
   
   NSLog( @"%s", " done.\n");
}

#endif
