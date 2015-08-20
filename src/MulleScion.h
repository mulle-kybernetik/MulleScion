//
//  MulleScion.h
//  MulleScion
//
//  Created by Nat! on 25.02.13.
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

#import "MulleScionObjectModel.h"
#import "MulleScionObjectModel+TraceDescription.h"

#import "MulleScionDataSourceProtocol.h"
#import "MulleScionOutputProtocol.h"
#import "MulleScionPrinter.h"
#import "MulleScionParser.h"
#import "MulleScionPrintingException.h"


@protocol MulleScionStringOrURL
@end

@interface NSString (MulleScionStringOrURL) <MulleScionStringOrURL>
@end

@interface NSURL (MulleScionStringOrURL) <MulleScionStringOrURL>
@end

/*
 * The convenience interface. If you don't want to think, use this:
 * 
 * --------------snip------------------------
 // [MulleScionTemplate setCacheEnabled:YES];
 output = [MulleScionTemplate descriptionWithTemplateFile:pathToTemplate
                                               dataSource:propertListOrYourDataSource];
 printf( "%s", [output UTF8String]);
 * --------------snip------------------------
 */
@interface MulleScionTemplate ( Convenience)

- (id) initWithFile:(NSString *) fileName;            // template or archive

- (id) initWithContentsOfFile:(NSObject <MulleScionStringOrURL> *) fileName;

- (NSString *) descriptionWithDataSource:(id) dataSource
                          localVariables:(NSDictionary *) locals;

+ (NSString *) descriptionWithTemplateFile:(NSObject <MulleScionStringOrURL> *) location
                                dataSource:(id <MulleScionDataSource>) dataSource;

+ (NSString *) descriptionWithTemplateFile:(NSObject <MulleScionStringOrURL> *) location
                                dataSource:(id <MulleScionDataSource>) dataSource
                            localVariables:(NSDictionary *) locals;

+ (NSString *) descriptionWithTemplateFile:(NSObject <MulleScionStringOrURL> *) fileName
                          propertyListFile:(NSObject <MulleScionStringOrURL> *) plistFileName
                            localVariables:(NSDictionary *) locals;

+ (NSString *) descriptionWithTemplateFile:(NSObject <MulleScionStringOrURL> *) fileName
                          propertyListFile:(NSObject <MulleScionStringOrURL> *) plistFileName;


+ (BOOL) writeToOutput:(id <MulleScionOutput>) output
          templateFile:(NSObject <MulleScionStringOrURL> *) fileName
            dataSource:(id <MulleScionDataSource>) dataSource
        localVariables:(NSDictionary *) locals;

- (void) writeToOutput:(id <MulleScionOutput>) output
            dataSource:(id <MulleScionDataSource>) dataSource
        localVariables:(NSDictionary *) locals;

@end

//
// caching and keyed encoding is not useful on iOS
//
#ifdef TARGET_OS_IPHONE
# define DONT_HAVE_MULLE_SCION_CACHING
#endif

#ifndef DONT_HAVE_MULLE_SCION_CACHING

@interface MulleScionTemplate ( Caching)

// Easier to use environment variable: MulleScionCacheDirectory
+ (void) setCacheDirectory:(NSString *) directory;
+ (NSString *) cacheDirectory;
+ (void) setCacheEnabled:(BOOL) flag;
+ (BOOL) isCacheEnabled;

@end

#endif


extern char   MulleScionFrameworkVersion[];
