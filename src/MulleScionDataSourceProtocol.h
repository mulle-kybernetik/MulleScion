//
//  MulleScionOutputProtocol.h
//  MulleScionTemplates
//
//  Created by Nat! on 27.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//
#import <Foundation/Foundation.h>

//
// You use these methods if you want to control, what a template
// can access from your dataSource (e.g. a customer writing his own templates).
// You probably want to call super afterwards. NSObject has default
// implementations for all.
//
// You can also override this to add KVC functionality (':' is available :))
//

@protocol MulleScionDataSource

// your object must implement KVC (well at least this method)
- (id) valueForKeyPath:(NSString *) keyPath;

//
// control access to your dataSource
//
- (id) mulleScionValueForKeyPath:(NSString *) keyPath
                  localVariables:(NSMutableDictionary *) locals;

//
// control access to any other object, except those in localVariables
//
- (id) mulleScionValueForKeyPath:(NSString *) keyPath
                          target:(id) target
                  localVariables:(NSMutableDictionary *) locals;

//
// control access to localVariables (just for completeness)
//
- (id) mulleScionValueForKeyPath:(NSString *) keyPath
                inLocalVariables:(NSMutableDictionary *) locals;

//
// control access to methods
//
- (id) mulleScionMethodSignatureForSelector:(SEL) sel
                                     target:(id) target;

//
// control access to pipes
//
- (id) mulleScionPipeString:(NSString *) s
              throughMethod:(NSString *) identifier
             localVariables:(NSMutableDictionary *) locals;

//
// implement and control access to built in functions
//
- (id) mulleScionFunction:(NSString *) identifier
                arguments:(NSArray *) arguments
           localVariables:(NSMutableDictionary *) locals;

@end


// 
// NSObject has default implementations for all methods (also KVC)
//
@interface NSObject ( MulleScionDataSource) < MulleScionDataSource >

@end
