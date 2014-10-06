//
//  NSObject+MulleScionDataSource.m
//  MulleScion
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


#import "MulleScionDataSourceProtocol.h"

#import "MulleScionObjectModel+Printing.h"
#import "MulleScionPrintingException.h"
#import "NSObject+MulleScionDescription.h"


@interface NSObject ( OldMethods)

+ (void) poseAs:(Class) cls;

@end


//
// execution of arbitrary methods, can be a huge security hole if the template
// is writable for users
// Your dataSource can override this method and check if the keyPath is OK.
// If not, raise an exception otherwise call super.
//
@implementation NSObject ( MulleScionDataSource)

- (id) mulleScionValueForKeyPath:(NSString *) keyPath
                  localVariables:(NSMutableDictionary *) locals
{
   NSParameterAssert( [keyPath isKindOfClass:[NSString class]]);
   NSParameterAssert( [locals isKindOfClass:[NSMutableDictionary class]]);
   
   return( [self valueForKeyPath:keyPath]);
}


- (id) mulleScionValueForKeyPath:(NSString *) keyPath
                          target:(id) target
                  localVariables:(NSMutableDictionary *) locals
{
   NSParameterAssert( [keyPath isKindOfClass:[NSString class]]);
   NSParameterAssert( [locals isKindOfClass:[NSMutableDictionary class]]);

   if( target == self)
      return( [self mulleScionValueForKeyPath:keyPath
                               localVariables:locals]);
   return( [target valueForKeyPath:keyPath]);
}

//
// you can protect local variables too, but why ?
//
- (id) mulleScionValueForKeyPath:(NSString *) keyPath
                inLocalVariables:(NSMutableDictionary *) locals
{
   NSParameterAssert( [keyPath isKindOfClass:[NSString class]]);
   NSParameterAssert( [locals isKindOfClass:[NSMutableDictionary class]]);
   
   return( [locals valueForKeyPath:keyPath]);
}


//
// here you can intercept all method calls
//
- (id) mulleScionMethodSignatureForSelector:(SEL) sel
                                     target:(id) target
{
   if( sel == @selector( poseAs:))
      [NSException raise:NSInvalidArgumentException
                  format:@"death to all posers :)"];
   
   return( [target methodSignatureForSelector:sel]);
}

//
// here you can intercept factory calls like [NSDate date]
//
- (Class) mulleScionClassFromString:(NSString *) s
{
   return( NSClassFromString( s));
}


- (id) mulleScionPipeString:(NSString *) s
              throughMethod:(NSString *) identifier
             localVariables:(NSMutableDictionary *) locals
{
   SEL   sel;
   
   NSParameterAssert( ! s || [s isKindOfClass:[NSString class]]);
   NSParameterAssert( [identifier isKindOfClass:[NSString class]]);
   NSParameterAssert( [locals isKindOfClass:[NSMutableDictionary class]]);
   
   if( ! [identifier length])
      MulleScionPrintingException( NSInvalidArgumentException, locals, @"empty pipe identifier is invalid");
   
   sel = NSSelectorFromString( identifier);
   if( ! [s respondsToSelector:sel] && s)
      MulleScionPrintingException( NSInvalidArgumentException, locals, @"NSString does not respond to %@",
                                  identifier);;
   
   // assume extra parameter is harmless...
   s = [s performSelector:sel
               withObject:locals];
   return( s);
}

    
- (id) mulleScionFunction:(NSString *) identifier
                arguments:(NSArray *) arguments
           localVariables:(NSMutableDictionary *) locals
{
   id             (*f)( id self, NSArray *arguments, NSMutableDictionary *locals);
   NSDictionary   *functions;
   
   NSParameterAssert( [identifier isKindOfClass:[NSString class]]);
   NSParameterAssert( ! arguments || [arguments isKindOfClass:[NSArray class]]);
   NSParameterAssert( [locals isKindOfClass:[NSMutableDictionary class]]);
   
   [locals setObject:identifier
              forKey:MulleScionCurrentFunctionKey];
   
   functions = [locals objectForKey:@"__FUNCTION_TABLE__"];
   f = [[functions objectForKey:identifier] pointerValue];
   if( f)
      return( (*f)( self, arguments, locals));

   [NSException raise:NSInvalidArgumentException
               format:@"\"%@\" %@: unknown function \"%@\"",
    [locals valueForKey:MulleScionCurrentFileKey],
    [locals valueForKey:MulleScionCurrentLineKey],
    [locals valueForKey:MulleScionCurrentFunctionKey]];
   
   return( nil);
}

@end
