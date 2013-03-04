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
   id  value;
   
   NSParameterAssert( [identifier isKindOfClass:[NSString class]]);
   NSParameterAssert( ! arguments || [arguments isKindOfClass:[NSArray class]]);
   NSParameterAssert( [locals isKindOfClass:[NSMutableDictionary class]]);
   
   [locals setObject:identifier
              forKey:MulleScionCurrentFunctionKey];

   if( [identifier isEqualToString:@"defined"])
   {
      MulleScionPrintingValidateArgumentCount( arguments, 1, locals);
      value  = MulleScionPrintingValidatedArgument( arguments, 0, [NSString class], locals);
      return( [NSNumber numberWithBool: [locals objectForKey:value] ? YES : NO]);
   }

   if( [identifier isEqualToString:@"NSMakeRange"])
   {
      NSRange   range;
      
      MulleScionPrintingValidateArgumentCount( arguments, 2, locals);
      range.location = [MulleScionPrintingValidatedArgument( arguments, 0, [NSNumber class], locals) integerValue];
      range.length   = [MulleScionPrintingValidatedArgument( arguments, 1, [NSNumber class], locals) integerValue];
      
      return( [NSValue valueWithRange:range]);
   }
   
   [NSException raise:NSInvalidArgumentException
               format:@"\"%@\" %@: unknown function \"%@\"",
    [locals valueForKey:MulleScionCurrentFileKey],
    [locals valueForKey:MulleScionCurrentLineKey],
    [locals valueForKey:MulleScionCurrentFunctionKey]];
   return( nil);
}

@end
