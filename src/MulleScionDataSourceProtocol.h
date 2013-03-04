//
//  MulleScionOutputProtocol.h
//  MulleScionTemplates
//
//  Created by Nat! on 27.02.13.
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

#import <Foundation/Foundation.h>

//
// You use these methods if you want to control, what a template
// can access from your dataSource (e.g. a customer writing his own templates).
// You probably want to call super afterwards. NSObject has default
// implementations for all. If you don't like the input, raise an exception.
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
// control class method calls
//
- (Class) mulleScionClassFromString:(NSString *) s;

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
