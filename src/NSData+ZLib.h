/* NSData+ZLib.h created by nat on Fri 23-Jul-1999 */
//
// $Id: NSData+ZLib.h,v 1.3 1999/07/29 16:18:24 nat Exp $
// ---------------------------
// $Log: NSData+ZLib.h,v $
// Revision 1.3  1999/07/29 16:18:24  nat
// Added comments
//
// Revision 1.2  1999/07/26 12:46:00  nat
// added dataWithZLibCompressedBytes:decompressedLength:
//
// Revision 1.1  1999/07/23 18:03:56  nat
// zLib support, some images inlined
//
// Revision 1.1.1.1  1999/07/23 16:24:06  nat
// Merciful release
//
//
#import "import.h"

#ifndef DONT_HAVE_ZLIB

//
// Simplistic Obj-C interface to Apple supplied Zip Library, which is zlib in a framework
//
@interface NSData( ZLib)

- (NSData *) compressedDataUsingZLib;
- (NSData *) decompressedDataUsingZLib:(NSUInteger) decompressedSize;
+ (NSData *) dataWithZLibCompressedBytes:(void *) buf
                      decompressedLength:(NSUInteger) decompressedSize;

@end

#endif
