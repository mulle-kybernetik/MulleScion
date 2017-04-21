/* NSData+ZLib.m created by nat on Fri 23-Jul-1999 */
//
// $Id: NSData+ZLib.m,v 1.2 1999/07/26 12:46:00 nat Exp $
// ---------------------------
// $Log: NSData+ZLib.m,v $
// Revision 1.2  1999/07/26 12:46:00  nat
// added dataWithZLibCompressedBytes:decompressedLength:
//
// Revision 1.1  1999/07/23 18:03:57  nat
// zLib support, some images inlined
//
// Revision 1.1.1.1  1999/07/23 16:24:06  nat
// Merciful release
//
//
#import "NSData+ZLib.h"

#ifndef DONT_HAVE_ZLIB

#include <zlib.h>


@implementation NSData( ZLib)


- (NSData *) compressedDataUsingZLib
{
   NSMutableData   *dst;
   uLongf          len;

   len = [self length] + [self length] / 500 + 128;
   dst = [NSMutableData dataWithLength:len];
   switch( compress( [dst mutableBytes], &len, [self bytes], [self length]))
   {
   case Z_MEM_ERROR :
      [NSException raise:NSMallocException
                  format:@"out of memory"];

   case Z_BUF_ERROR :
      return( nil);
   }
   if( len >= [self length])
      return( nil);
   [dst setLength:len];
   return( dst);
}


+ (NSData *) dataWithZLibCompressedBytes:(void *) buf
                      decompressedLength:(NSUInteger) decompressedSize
{
   NSMutableData      *dst;
   uLongf             len;

   len = decompressedSize * 2 + 8192;
   dst = [NSMutableData dataWithLength:len];
   switch( uncompress( [dst mutableBytes], &len, buf, decompressedSize))
   {
   case Z_DATA_ERROR :
      [NSException raise:NSInvalidArgumentException
                  format:@"Incoming ZLib data %@ was corrupted", self];

   case Z_MEM_ERROR :
      [NSException raise:NSMallocException
                  format:@"out of memory in decompression"];

   case Z_BUF_ERROR :
       return( nil);
   }
   [dst setLength:len];
   return( dst);
}


- (NSData *) decompressedDataUsingZLib:(NSUInteger) decompressedSize
{
   NSMutableData      *dst;
   uLongf             len;

   len = decompressedSize * 2 + 8192;
   dst = [NSMutableData dataWithLength:len];
   switch( uncompress( [dst mutableBytes], &len, [self bytes], [self length]))
   {
   case Z_DATA_ERROR :
      [NSException raise:NSInvalidArgumentException
                  format:@"Incoming ZLib data %@ was corrupted", self];

   case Z_MEM_ERROR :
      [NSException raise:NSMallocException
                  format:@"out of memory in decompression"];

   case Z_BUF_ERROR :
       return( nil);
   }
   [dst setLength:len];
   return( dst);
}


@end

#endif

