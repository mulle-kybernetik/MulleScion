//
//  NSObject+MulleScionDataSource.m
//  MulleScionTemplates
//
//  Created by Nat! on 27.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionDataSourceProtocol.h"

#import "MulleScionObjectModel+Printing.h"
#import "MulleScionPrintingException.h"


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
// here you can intercept all interpreted method calls
//
- (id) mulleScionMethodSignatureForSelector:(SEL) sel
                                     target:(id) target
{
   return( [target methodSignatureForSelector:sel]);
}


- (id) mulleScionPipeString:(NSString *) s
              throughMethod:(NSString *) identifier
             localVariables:(NSMutableDictionary *) locals
{
   SEL   sel;
   
   NSParameterAssert( [s isKindOfClass:[NSString class]]);
   NSParameterAssert( [identifier isKindOfClass:[NSString class]]);
   NSParameterAssert( [locals isKindOfClass:[NSMutableDictionary class]]);
   
   if( ! [identifier length])
      MulleScionPrintingException( NSInvalidArgumentException, @"empty pipe identifier is invalid", locals);
   
   sel = NSSelectorFromString( identifier);
   if( ! [s respondsToSelector:sel])
      MulleScionPrintingException( NSInvalidArgumentException, @"NSString does not respond to %@",
                          identifier, locals);
   
   // assume extra parameter is harmless...
   s = [s performSelector:sel
               withObject:locals];
   return( s);
}


- (id) mulleScionFunction:(NSString *) identifier
                arguments:(NSArray *) arguments
           localVariables:(NSMutableDictionary *) locals
{
   NSParameterAssert( [identifier isKindOfClass:[NSString class]]);
   NSParameterAssert( ! arguments || [arguments isKindOfClass:[NSArray class]]);
   NSParameterAssert( [locals isKindOfClass:[NSMutableDictionary class]]);
   
   [locals setObject:identifier
              forKey:MulleScionCurrentFunctionKey];
   
   if( [identifier isEqualToString:@"NSMakeRange"])
   {
      NSRange   range;
      
      MulleScionPrintingValidateArgumentCount( arguments, 2, locals);
      range.location = [MulleScionPrintingValidatedArgument( arguments, 0, [NSNumber class], locals) integerValue];
      range.length   = [MulleScionPrintingValidatedArgument( arguments, 1, [NSNumber class], locals) integerValue];
      
      return( [NSValue valueWithRange:range]);
   }
   
   [NSException raise:NSInvalidArgumentException
               format:@"%@ %@: unknown function %@",
    [locals valueForKey:MulleScionCurrentFileKey],
    [locals valueForKey:MulleScionCurrentLineKey],
    [locals valueForKey:MulleScionCurrentFunctionKey]];
   return( nil);
}

@end
