//
//  NSFileHandle+MulleOpenWithInfo.m
//  MulleScionTemplates
//
//  Created by Nat! on 05.11.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "NSFileHandle+MulleOutputFileHandle.h"

@implementation NSFileHandle (MulleOutputFileHandle)

+ (NSFileHandle *) mulleOutputFileHandleWithFilename:(NSString *) outputName
                                            selector:(SEL) sel
{
   NSFileHandle   *stream;
   
   if( [outputName isEqualToString:@"-"])
      return( [NSFileHandle performSelector:sel]);
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
   return( stream);
}


+ (NSFileHandle *) mulleOutputFileHandleWithFilename:(NSString *) outputName
{
   return( [self mulleOutputFileHandleWithFilename:outputName
                                          selector:@selector( fileHandleWithStandardOutput)]);
}


+ (NSFileHandle *) mulleErrorFileHandleWithFilename:(NSString *) outputName
{
   return( [self mulleOutputFileHandleWithFilename:outputName
                                          selector:@selector( fileHandleWithStandardError)]);
}

@end
