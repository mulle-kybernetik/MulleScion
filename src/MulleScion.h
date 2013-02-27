//
//  MulleScion.h
//  MulleTwigLikeObjCTemplates
//
//  Created by Nat! on 25.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionObjectModel.h"

#import "MulleScionDataSourceProtocol.h"
#import "MulleScionOutputProtocol.h"


/*
 * The convenience interface. If you don't want to think use it.
 * 
 * --------------snip------------------------
 // [MulleScionTemplate setCacheEnabled:YES];
 output = [MulleScionTemplate descriptionWithTemplateFile:pathToTemplate
                                               dataSource:propertListOrYourDataSource];
 printf( "%s", [output UTF8String]);
 * --------------snip------------------------
 */
@interface MulleScionTemplate ( Convenience)

- (id) initWithContentsOfFile:(NSString *) fileName;

- (NSString *) descriptionWithDataSource:(id) dataSource
                          localVariables:(NSDictionary *) locals;

+ (NSString *) descriptionWithTemplateFile:(NSString *) fileName
                                dataSource:(id <MulleScionDataSource>) dataSource
                            localVariables:(NSDictionary *) locals;

+ (BOOL) writeToOutput:(id <MulleScionOutput>) output
          templateFile:(NSString *) fileName
            dataSource:(id <MulleScionDataSource>) dataSource
        localVariables:(NSDictionary *) locals;

- (void) writeToOutput:(id <MulleScionOutput>) output
            dataSource:(id <MulleScionDataSource>) dataSource
        localVariables:(NSDictionary *) locals;

@end


#ifndef DONT_HAVE_MULLE_SCION_CACHING

@interface MulleScionTemplate ( Caching)

// Easier to use environment variable: MulleScionCacheDirectory
+ (void) setCacheDirectory:(NSString *) directory;
+ (NSString *) cacheDirectory;
+ (void) setCacheEnabled:(BOOL) flag;
+ (BOOL) isCacheEnabled;

@end

#endif
