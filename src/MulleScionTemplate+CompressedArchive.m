//
//  MulleScionTemplate+CompressedArchive.m
//  MulleScionTemplates
//
//  Created by Nat! on 26.02.13.
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


#import "MulleScionTemplate+CompressedArchive.h"


#ifdef HAVE_ZLIB
# undef HAVE_ZLIB
#endif

#ifndef DONT_HAVE_ZLIB
# define HAVE_ZLIB  1
#else
# define HAVE_ZLIB  0
#endif


#if HAVE_ZLIB
# import "NSData+ZLib.h"
#endif


@implementation MulleScionTemplate ( NSCoding)

typedef struct
{
   char       version[ 16];
   uint64_t   size;
   uint8_t    bits;
   uint8_t    endian;
   uint8_t    unused[ 2];
} archive_header;


static char  current_version[]            = "mulle-noics1848";

#if HAVE_ZLIB
static char  current_compressed_version[] = "mulle-scion1848";
#endif


#ifndef HAVE_HTONQ_NTOHQ

typedef union
{
   uint64_t   q;
   uint32_t   l[ 2];
} mulle_swappable_uint64_t;


static inline uint64_t  _mulle_swap64( mulle_swappable_uint64_t v)
{
   mulle_swappable_uint64_t   x;
   
   x.l[ 1] = ntohl( v.l[ 0]);
   x.l[ 0] = ntohl( v.l[ 1]);
   return( x.q);
}


static inline uint64_t  mulle_swap64( uint64_t value)
{
   return( _mulle_swap64( (mulle_swappable_uint64_t) value));
}


static inline uint64_t  htonq( uint64_t value)
{
#ifdef LITTLE_ENDIAN
   return( mulle_swap64( value));
#else
   return( value);
#endif
}


static inline uint64_t  ntohq( uint64_t value)
{
#ifdef LITTLE_ENDIAN
   return( mulle_swap64( value));
#else
   return( value);
#endif
}
#endif


//
// write it down in compressed format. Should be good for large pages
// containing a lot of text
//
static id   _newWithContentsOfArchive( NSString *fileName, NSAutoreleasePool **pool)
{
   NSData              *data;
   archive_header      *header;
   uint64_t            length;
   NSRange             range;
   BOOL                isCompressed;
   
   data   = [NSData dataWithContentsOfMappedFile:fileName];
   length = [data length];
   if( length < sizeof( archive_header))
      return( nil);
   
   header = (archive_header *) [data bytes];
   isCompressed = ! strcmp( header->version, current_compressed_version);
   if( ! isCompressed && strcmp( header->version, current_version))
      return( nil);

   length = ntohq( header->size);
   if( (NSUInteger) length != length)
   {
      NSLog( @"archive too large for this machine");
      return( nil);
   }
   
   range = NSMakeRange( sizeof( archive_header), (NSUInteger) length - sizeof( archive_header));
   data  = [data subdataWithRange:range];
   if( isCompressed)
   {
#if HAVE_ZLIB
      data = [data decompressedDataUsingZLib:(NSUInteger) length];
      
      [data retain];
      [*pool release];
      *pool = [NSAutoreleasePool new];
      [data autorelease];
#else
      return( nil);
#endif
   }
   return( [[NSUnarchiver unarchiveObjectWithData:data] retain]);
}


- (id) initWithContentsOfArchive:(NSString *) fileName
{
   NSAutoreleasePool   *pool;
   MulleScionTemplate  *root;
   
   [self autorelease];
   
   pool = [NSAutoreleasePool new];
   root = _newWithContentsOfArchive( fileName, &pool);
   [pool release];

   return( root);
}


- (BOOL) writeArchive:(NSString *) fileName
{

   BOOL               flag;
   NSAutoreleasePool  *pool;
   NSData             *payload;
   NSMutableData      *data;
   NSUInteger         length;
   archive_header     *header;
   char               *version;
   
   pool    = [NSAutoreleasePool new];
   
   payload = [NSArchiver archivedDataWithRootObject:self];
   length  = [payload length];
#if HAVE_ZLIB
   payload = [payload compressedDataUsingZLib];
   version = current_compressed_version;
#else
   version = current_version;
#endif
   data    = [NSMutableData dataWithLength:sizeof( archive_header)];
   header  = (archive_header *) [data bytes];
   
   assert( strlen( version) < 16);
   strcpy( header->version, version);
   header->size   = htonq( length);
   header->bits   = sizeof( NSUInteger);  // memorize architecture
   header->endian = BYTE_ORDER == LITTLE_ENDIAN;
   
   [data appendData:payload];
   flag = [data writeToFile:fileName
                  atomically:YES];
   [pool release];
   
   return( flag);
}

@end

