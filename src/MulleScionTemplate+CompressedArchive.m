//
//  MulleScionTemplate+CompressedArchive.m
//  MulleScion
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

#include <fcntl.h>
#include <unistd.h>


#ifdef HAVE_ZLIB
# import "NSData+ZLib.h"
#endif


@implementation MulleScionTemplate( CompressedArchive)

typedef struct
{
   char       version[ 16];
   uint64_t   size;
   uint8_t    bits;
   uint8_t    endian;
   uint8_t    coding;  // 1: keyed encoding  0: archive
   uint8_t    unused[ 1];
} archive_header;


static char  current_version[]            = "mulle-noics1848";
static char  current_compressed_version[] = "mulle-scion1848";


#ifndef HAVE_HTONQ_NTOHQ

typedef union
{
   uint64_t   q;
   uint32_t   l[ 2];
} mulle_swappable_uint64_t;



#ifndef ntohl
extern uint32_t   ntohl( uint32_t value);
#endif

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
#if __LITTLE_ENDIAN__
   return( mulle_swap64( value));
#else
   return( value);
#endif
}


static inline uint64_t  ntohq( uint64_t value)
{
#if __LITTLE_ENDIAN__
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
static BOOL   get_archive_metadata( archive_header *header, uint64_t length, BOOL *isCompressed,  BOOL *isKeyed, NSUInteger *p_length)
{
   if( length < sizeof( archive_header))
      return( NO);

   *isCompressed = ! strcmp( header->version, current_compressed_version);
   if( ! *isCompressed && strcmp( header->version, current_version))
      return( NO);
   *isKeyed  = header->coding;
   length    = ntohq( header->size);
   *p_length = (NSUInteger) length;
   if( *p_length != length)
   {
      NSLog( @"archive too large for this machine");
      return( NO);
   }
   return( YES);
}


static inline BOOL   get_archive_metadata_from_data( NSData *data, BOOL *isCompressed, BOOL *isKeyed, NSUInteger *p_length)
{
   return( get_archive_metadata( (archive_header *) [data bytes], [data length], isCompressed, isKeyed, p_length));
}


static id   _newWithContentsOfArchive( NSString *fileName, NSAutoreleasePool **pool)
{
   NSData     *data;
   NSUInteger length;
   NSRange    range;
   BOOL       isCompressed;
   BOOL       isKeyed;

   data = [NSData dataWithContentsOfMappedFile:fileName];
   if( ! get_archive_metadata_from_data( data, &isCompressed, &isKeyed, &length))
      return( nil);

   range = NSMakeRange( sizeof( archive_header), length - sizeof( archive_header));
   data  = [data subdataWithRange:range];

   if( isCompressed)
   {
#ifdef HAVE_ZLIB
      data = [data decompressedDataUsingZLib:length];

      [data retain];
      [*pool release];
      *pool = [NSAutoreleasePool new];
      [data autorelease];
#else
      return( nil);
#endif
   }

   if( isKeyed)
      return( [[NSKeyedUnarchiver unarchiveObjectWithData:data] retain]);

#if TARGET_OS_IPHONE  // much slower...
   NSLog( @"unsupported archive");
   return( nil);
#else
   return( [[NSUnarchiver unarchiveObjectWithData:data] retain]);
#endif
}


+ (BOOL) isArchivedTemplatePath:(NSString *) path
                   isCompressed:(BOOL *) isCompressed
{
   archive_header   header;
   NSUInteger       dummy2;
   int              fd;
   BOOL             dummy;
   BOOL             rval;

   if( ! isCompressed)
      isCompressed = &dummy;

   rval = NO;
   fd = open( [path fileSystemRepresentation], O_RDONLY);
   if( fd < 0)
      return( rval);

   rval = read( fd, &header, sizeof( archive_header)) == sizeof( archive_header);
   if( rval)
      rval = get_archive_metadata( &header, sizeof( archive_header), isCompressed, &dummy, &dummy2);
   close( fd);

   return( rval);
}


+ (BOOL) isArchivedTemplatePath:(NSString *) path
{
   NSString  *extension;

   extension = [path pathExtension];
   if( [extension isEqualToString:@"scion"])
      return( NO);
   if( [extension isEqualToString:@"scionz"])
      return( YES);

   return( [self isArchivedTemplatePath:path
                           isCompressed:NULL]);
}


- (id) initWithContentsOfArchive:(NSString *) fileName
{
   NSAutoreleasePool   *pool;

   pool = [NSAutoreleasePool new];

   [self release];
   self = _newWithContentsOfArchive( fileName, &pool);

   [pool release];

   return( self);
}


- (BOOL) writeArchive:(NSString *) fileName
                keyed:(BOOL) keyed
{
   BOOL               flag;
   NSAutoreleasePool  *pool;
   NSData             *payload;
   NSMutableData      *data;
   NSUInteger         length;
   archive_header     *header;
   char               *version;

   pool = [NSAutoreleasePool new];

#if TARGET_OS_IPHONE  // probably much slower...
   NSParameterAssert( keyed);
   payload = [NSKeyedArchiver archivedDataWithRootObject:self];
#else
   if( keyed)
      payload = [NSKeyedArchiver archivedDataWithRootObject:self];
   else
      payload = [NSArchiver archivedDataWithRootObject:self];
#endif

   length  = [payload length];
#ifdef HAVE_ZLIB
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
   header->endian = NSHostByteOrder() == NS_LittleEndian;
   header->coding = keyed;

   [data appendData:payload];
   flag = [data writeToFile:fileName
                  atomically:YES];
   [pool release];

   return( flag);
}


- (BOOL) writeArchive:(NSString *) fileName
{
#if TARGET_OS_IPHONE
   return( [self writeArchive:fileName
                        keyed:YES]);
#else
   return( [self writeArchive:fileName
                        keyed:NO]);
#endif
}

@end

