//
//  MulleScionObjectModel+Printing.m
//  MulleScionTemplates
//
//  Created by Nat! on 24.02.13.
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


#import "MulleScionObjectModel+Printing.h"

#import "MulleMutableLineNumber.h"
#import "MulleScionNull.h"
#import "MulleScionPrintingException.h"
#import "MulleScionDataSourceProtocol.h"
#import "NSObject+MulleScionDescription.h"
#if ! TARGET_OS_IPHONE
# import <Foundation/NSDebug.h>
# import <objc/objc-class.h>
#else
# import <objc/runtime.h>
#endif


NSString   *MulleScionRenderOutputKey         = @"__OUTPUT__";
NSString   *MulleScionCurrentFileKey          = @"__FILE__";
NSString   *MulleScionPreviousFilesKey        = @"__FILE_STACK__";
NSString   *MulleScionCurrentLineKey          = @"__LINE__";
NSString   *MulleScionCurrentFunctionKey      = @"__FUNCTION__";
NSString   *MulleScionCurrentFilterKey        = @"__FILTER__";
NSString   *MulleScionPreviousFiltersKey      = @"__FILTER_STACK__";
NSString   *MulleScionSelfReplacementKey      = @"__SELF_REPLACEMENT__";

NSString   *MulleScionForOpenerKey            = @"MulleScionForOpener";
NSString   *MulleScionForSeparatorKey         = @"MulleScionForSeparator";
NSString   *MulleScionForCloserKey            = @"MulleScionForCloser";
NSString   *MulleScionForSubdivisionLengthKey = @"MulleScionForSubdivisionLength";
NSString   *MulleScionForSubdivisionOpenerKey = @"MulleScionForSubdivisionOpener";
NSString   *MulleScionForSubdivisionCloserKey = @"MulleScionForSubdivisionCloser";

NSString   *MulleScionEvenKey                 = @"MulleScionEven";
NSString   *MulleScionOddKey                  = @"MulleScionOdd";


#if 0
# define TRACE_RENDER( self, s, locals, dataSource)   fprintf( stderr, "%ld: %s\n", (long) [self lineNumber], [self shortDescription] cString])
#else
# define TRACE_RENDER( self, s, locals, dataSource)
#endif


#if 0
# define TRACE_EVAL_BEGIN( self, value)               fprintf( stderr, "%s\n", [[NSString stringWithFormat:@"%ld: -->%@ (%@)", (long) [self lineNumber],[self shortDescription], value] cString])
# define TRACE_EVAL_END( self, value)                 fprintf( stderr, "%s\n", [[NSString stringWithFormat:@"%ld: <--%@ (%@)", (long) [self lineNumber],[self shortDescription], value] cString])
# define TRACE_EVAL_CONT( self, value)                fprintf( stderr, "%s\n", [[NSString stringWithFormat:@"%ld:    %@ (%@)", (long) [self lineNumber],[self shortDescription], value] cString])
# define TRACE_EVAL_BEGIN_END( self, value, result)   fprintf( stderr, "%s\n", [[NSString stringWithFormat:@"%ld: <->%@ (%@->%@)", (long) [self lineNumber],[self shortDescription], value, result] cString])
#else
# define TRACE_EVAL_BEGIN( self, value)
# define TRACE_EVAL_END( self, value)
# define TRACE_EVAL_CONT( self, value)
# define TRACE_EVAL_BEGIN_END( self, value, result)
#endif

@interface MulleScionExpression ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource;

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource;

@end


#pragma mark -

@implementation MulleScionObject ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   TRACE_RENDER( self, s, locals, dataSource);
   return( self->next_);
}


static void   pushFileName( NSMutableDictionary *locals, NSString *filename)
{
   NSMutableArray   *stack;
   NSString         *prev;
   
   prev = [locals objectForKey:MulleScionCurrentFileKey];
   NSCParameterAssert( prev);
   
   stack = [locals objectForKey:MulleScionPreviousFilesKey];
   if( ! stack)
   {
      stack = [NSMutableArray new];
      [locals setObject:stack
                 forKey:MulleScionPreviousFilesKey];
      [stack release];
   }
   [stack addObject:prev];

   [locals setObject:filename
              forKey:MulleScionCurrentFileKey];
}


static void   popFileName( NSMutableDictionary *locals)
{
   NSString         *prev;
   NSMutableArray   *stack;
   
   NSCParameterAssert( [locals objectForKey:MulleScionPreviousFilesKey] != nil);
   
   stack = [locals objectForKey:MulleScionPreviousFilesKey];
   NSCParameterAssert( stack);
   prev = [stack lastObject];
   [locals setObject:prev
              forKey:MulleScionCurrentFileKey];
   [stack removeLastObject];
}


static void   MulleScionRenderString( NSString *value,
                                      id <MulleScionOutput> output,
                                      NSMutableDictionary *locals,
                                      id <MulleScionDataSource> dataSource)
{
   MulleScionExpression  *filter;
   
   NSCParameterAssert( [value isKindOfClass:[NSString class]]);
   
   filter = [locals objectForKey:MulleScionCurrentFilterKey];
   if( filter)
   {
      if( [filter isIdentifier])
      {
         value = [dataSource mulleScionPipeString:value
                                    throughMethod:[(MulleScionVariable *) filter identifier]
                                   localVariables:locals];
      }
      else
      {
         value = [filter evaluateValue:(id) value
                        localVariables:locals
                            dataSource:dataSource];
      }
   }
   
   if( value)
   {
      NSCParameterAssert( [value isKindOfClass:[NSString class]]);
      [output appendString:value];
   }
}

@end


#pragma mark -

@implementation MulleScionTemplate ( Printing)


static void   initLineNumber( NSMutableDictionary *locals)
{
   MulleMutableLineNumber   *nr;
   
   nr = [MulleMutableLineNumber new];
   [locals setObject:nr
              forKey:MulleScionCurrentLineKey];
   [nr release];
}


static void   updateLineNumber( MulleScionObject *self, NSMutableDictionary *locals)
{
   MulleMutableLineNumber   *nr;
   
   // linenumber is trusted and not funneled
   nr = [locals objectForKey:MulleScionCurrentLineKey];
   [nr setUnsignedInteger:self->lineNumber_];
}


- (NSMutableDictionary *) localVariablesWithDefaultValues:(NSDictionary *) defaults
{
   NSMutableDictionary   *locals;
   
   locals = [NSMutableDictionary dictionaryWithDictionary:defaults];

   initLineNumber( locals);

   // setup some often needed OS X constants
   [locals setObject:[NSNumber numberWithUnsignedLong:NSOrderedSame]
              forKey:@"NSOrderedSame"];
   [locals setObject:[NSNumber numberWithUnsignedLong:NSOrderedAscending]
              forKey:@"NSOrderedAscending"];
   [locals setObject:[NSNumber numberWithUnsignedLong:NSOrderedDescending]
              forKey:@"NSOrderedDescending"];

   [locals setObject:[NSNumber numberWithUnsignedLong:NSASCIIStringEncoding]
              forKey:@"NSASCIIStringEncoding"];
   [locals setObject:[NSNumber numberWithUnsignedLong:NSISOLatin1StringEncoding]
              forKey:@"NSISOLatin1StringEncoding"];
   [locals setObject:[NSNumber numberWithUnsignedLong:NSMacOSRomanStringEncoding]
              forKey:@"NSMacOSRomanStringEncoding"];
   [locals setObject:[NSNumber numberWithUnsignedLong:NSUnicodeStringEncoding]
              forKey:@"NSUnicodeStringEncoding"];
   [locals setObject:[NSNumber numberWithUnsignedLong:NSUTF8StringEncoding]
              forKey:@"NSUTF8StringEncoding"];
   [locals setObject:[NSNumber numberWithUnsignedLong:NSUTF32StringEncoding]
              forKey:@"NSUTF32StringEncoding"];

   [locals setObject:[NSNumber numberWithUnsignedLong:NSNotFound]
              forKey:@"NSNotFound"];
   return( locals);
}


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionObject   *curr;
   NSAutoreleasePool  *pool;
   
   NSAssert( [locals valueForKey:@"NSNotFound"], @"use -[MulleScionTemplate localVariablesWithDefaultValues:] to create the localVariables dictionary");

   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];
   
   //
   // expose everything to the dataSource for max. hackability
   // trusted (writing OK, reading ? your choice!)
   //
   updateLineNumber( self, locals);
   [locals setObject:s
              forKey:MulleScionRenderOutputKey];
   [locals setObject:value_
              forKey:MulleScionCurrentFileKey];

   // must be provided, because it's too painful to always set it here
   
   curr = self->next_;
   while( curr)
      curr = [curr renderInto:s
               localVariables:locals
                   dataSource:dataSource];
   
   [pool release];
   
   return( curr);
}

@end


#pragma mark -

@implementation MulleScionPlainText ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   TRACE_RENDER( self, s, locals, dataSource);

   updateLineNumber( self, locals);
   MulleScionRenderString( value_, s, locals, dataSource);
   return( self->next_);
}

@end


static id   MulleScionValueForKeyPath( NSString *keyPath,
                                       NSMutableDictionary * locals,
                                       id dataSource)
{
   id   value;
 
   if( [keyPath isEqualToString:@"self"])
   {
      id   replacement;
      
      replacement = [locals objectForKey:MulleScionSelfReplacementKey];
      if( replacement)
         return( replacement);
      return( dataSource);
   }
   
   value = [dataSource mulleScionValueForKeyPath:keyPath
                                inLocalVariables:locals];
   if( ! value)
      value = [dataSource mulleScionValueForKeyPath:keyPath
                                     localVariables:locals];
   if( ! value)
      value = MulleScionNull;
   
   return( value);
}


#pragma mark -

@implementation MulleScionVariable ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   return( MulleScionValueForKeyPath( value_, locals, dataSource));
}

   
- (void) evaluateSetValue:(id) valueToSet
       withLocalVariables:(NSMutableDictionary *) locals
               dataSource:(id <MulleScionDataSource>) dataSource
{
   // SECURITY HOLE: FUNNEL THROUGH DATASOURCE
   
   [locals takeValue:valueToSet
          forKeyPath:value_];
}
   
@end


#pragma mark -

@implementation MulleScionFunction ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   NSEnumerator           *rover;
   NSMutableArray         *array;
   MulleScionExpression   *expr;
   id                     value;
   id                     result;
   
   array = [NSMutableArray array];
   rover = [arguments_ objectEnumerator];
   while( expr = [rover nextObject])
   {
      value = [expr valueWithLocalVariables:locals
                                 dataSource:dataSource];
      if( ! value)
         value = MulleScionNull;
      [array addObject:value];
   }
   result = [dataSource mulleScionFunction:value_
                                 arguments:array
                           localVariables:locals];
   if( ! result)
      result = MulleScionNull;
   return( result);
}

@end


#pragma mark -

@implementation MulleScionMethod ( Printing)

static char   *_NSObjCSkipRuntimeTypeQualifier( char *type)
{
   char   c;
   
   assert( type != NULL);
   
   while( (c = *type) == _C_CONST
#ifdef _C_IN
         || c == _C_IN
#endif
#ifdef _C_INOUT
         || c == _C_INOUT
#endif
#ifdef _C_OUT
         || c == _C_OUT
#endif
#ifdef _C_BYCOPY
         || c == _C_BYCOPY
#endif
#ifdef _C_ONEWAY
         || c == _C_ONEWAY
#endif
         )
   {
      type++;
   }
   
   return( type);
}


static void   _pop( NSAutoreleasePool * NS_CONSUMED pool)
{
   [pool release];
}


static void   pop( NSAutoreleasePool *pool, id value)
{
   [value retain];
   _pop( pool);
   [value autorelease];
}


static void   *numberBuffer( char *type, NSNumber *value)
{
   NSUInteger          size;
   NSUInteger          alignment;
   void                *buf;
   char                *myType;
   
   if( value && ! [value isKindOfClass:[NSValue class]])
      return( NULL);
   
   NSGetSizeAndAlignment( type, &size, &alignment);
   
   buf = (void *) [[NSMutableData dataWithLength:size] mutableBytes];
   if( ! value)
      return( buf);
   
   switch( *type)
   {
   case _C_CHR      : *(char *) buf = [value charValue]; return( buf);
   case _C_UCHR     : *(unsigned char *) buf = [value unsignedCharValue]; return( buf);
   case _C_SHT      : *(short *) buf = [value shortValue]; return( buf);
   case _C_USHT     : *(unsigned short *) buf = [value unsignedShortValue]; return( buf);
   case _C_INT      : *(int *) buf = [value intValue]; return( buf);
   case _C_UINT     : *(unsigned int *) buf = [value unsignedIntValue]; return( buf);
   case _C_LNG      : *(long *) buf = [value longValue]; return( buf);
   case _C_ULNG     : *(unsigned long *) buf = [value unsignedLongValue]; return( buf);
   case _C_LNG_LNG  : *(long long *) buf = [value longLongValue]; return( buf);
   case _C_ULNG_LNG : *(unsigned long long *) buf = [value unsignedLongLongValue]; return( buf);
   case _C_FLT      : *(float *) buf = [value floatValue]; return( buf);
   case _C_DBL      : *(double *) buf = [value doubleValue]; return( buf);
   }
   
   myType = (char *) [value objCType];
   myType = _NSObjCSkipRuntimeTypeQualifier( myType);
   if( strcmp( myType, type))
      return( NULL);
   
   [value getValue:buf];
   return( buf);
}


- (id) evaluateValue:(id) target
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionExpression   *expr;
   NSAutoreleasePool      *pool;
   NSInvocation           *invocation;
   NSMethodSignature      *signature;
   NSUInteger             i, n, m;
   NSUInteger             length;
   char                   *returnType;
   char                   *type;
   id                     *buf;
   id                     value;
   id                     result;
   void                   *tmp;
   
   // static char         id_type[ 2] = { _C_ID, 0 };

   TRACE_EVAL_BEGIN( self, target);
   
   pool = [NSAutoreleasePool new];

   signature = [dataSource mulleScionMethodSignatureForSelector:action_
                                                         target:target];
   if( ! signature)
      MulleScionPrintingException( NSInvalidArgumentException, locals,
                  @"Method \"%@\" is unknown on \"%@\"", NSStringFromSelector( action_), [target class]);
   
   // remember varargs, there can be more arguments
   m = [signature numberOfArguments];
   n = [arguments_ count] + 2;
   if( m  != n)
      MulleScionPrintingException( NSInvalidArgumentException, locals,
                                  @"Method \"%@\" expects %ld arguments", NSStringFromSelector( action_), (long) n);
   
   
   invocation = [NSInvocation invocationWithMethodSignature:signature];
   [invocation setSelector:action_];
   
   for( i = 2; i < n; i++)
   {
      expr  = [arguments_ objectAtIndex:i - 2];
      value = [expr valueWithLocalVariables:locals
                                 dataSource:dataSource];

      if( value == MulleScionNull)
         value = nil;
      
      if( value == dataSource) // plug security hole
         MulleScionPrintingException( NSInvalidArgumentException, locals,
                                     @"You can't use the dataSource as an argument");
      
      
      // type = id_type;  // ok, varargs with non-objects won't work
      // if( i < m)
      {
         type = (char *) [signature getArgumentTypeAtIndex:i];
         type = _NSObjCSkipRuntimeTypeQualifier( type);
      }
      
      switch( *type)
      {
      case _C_ID       : buf = &value; break;
      case _C_CLASS    : buf = &value; break;
      case _C_SEL      : tmp = [value pointerValue]; buf = (id *) &tmp; break;
      default          : buf = numberBuffer( type, value); break;
      }
      
      if( ! buf)
         MulleScionPrintingException( NSInvalidArgumentException, locals,
                                     @"Method \"%@\" is not callable from MulleScion (argument #%ld)",
          NSStringFromSelector( action_), (long) i - 2);
      
      // unfortunately NSInvocation is too dumb for varargs
      [invocation setArgument:buf
                      atIndex:i];
   }
   
   // [invocation retainArguments];
   [invocation invokeWithTarget:target];
   
   result = nil;
   length = [signature methodReturnLength];
   if( length)
   {
      buf    = (id *) [[NSMutableData dataWithLength:length] mutableBytes];
      [invocation getReturnValue:buf];
      
      returnType =  (char *) [signature methodReturnType];
      returnType = _NSObjCSkipRuntimeTypeQualifier( returnType);
      
      switch( *returnType)
      {
      case _C_ID       : result = *buf; break;
      case _C_CLASS    : result = *buf; break;
      case _C_SEL      : result = [NSValue valueWithPointer:*(SEL *) buf]; break;
      case _C_CHARPTR  : result = [NSString stringWithCString:(char *) buf]; break;
      case _C_CHR      : result = [NSNumber numberWithChar:*(char *) buf]; break;
      case _C_UCHR     : result = [NSNumber numberWithUnsignedChar:*(unsigned char *) buf]; break;
      case _C_SHT      : result = [NSNumber numberWithShort:*(short *) buf]; break;
      case _C_USHT     : result = [NSNumber numberWithUnsignedShort:*(unsigned short *) buf]; break;
      case _C_INT      : result = [NSNumber numberWithInt:*(int *) buf]; break;
      case _C_UINT     : result = [NSNumber numberWithUnsignedInt:*(unsigned int *) buf]; break;
      case _C_LNG      : result = [NSNumber numberWithLong:*(long *) buf]; break;
      case _C_ULNG     : result = [NSNumber numberWithUnsignedLong:*(unsigned long *) buf]; break;
      case _C_LNG_LNG  : result = [NSNumber numberWithLongLong:*(long long *) buf]; break;
      case _C_ULNG_LNG : result = [NSNumber numberWithUnsignedLongLong:*(unsigned long long *) buf]; break;
      case _C_FLT      : result = [NSNumber numberWithFloat:*(float *) buf]; break;
      case _C_DBL      : result = [NSNumber numberWithDouble:*(double *) buf]; break;
#ifdef _C_LNG_DBL
            //   case _C_LNG_DBL  : result = [NSNumber numberWithLongDouble: *(long double *) buf]; break;
#endif
#ifdef _C_BOOL
      case _C_BOOL     : result = [NSNumber numberWithBool:*(BOOL *) buf]; break;
#endif
      default          : result = [NSNumber value:buf withObjCType:returnType]; break;
      }
   }
   pop( pool, result);
   
   if( ! result)
      result = MulleScionNull;
   
   TRACE_EVAL_END( self, result);
   return( result);
}


- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   id    original;
   id    target;
   
   NSParameterAssert( [locals isKindOfClass:[NSMutableDictionary class]]);
   
   original = nil;
   if( [value_ isIdentifier])
      original = [(MulleScionVariable *) value_ identifier];
   
   target = [value_ valueWithLocalVariables:locals
                                 dataSource:dataSource];
   
   if( target == MulleScionNull)
      target = nil;
   
   if( ! target && original)
      target = [dataSource mulleScionClassFromString:original];
   
   if( ! target)
      return( MulleScionNull);
   
   return( [self evaluateValue:target
                localVariables:locals
                    dataSource:dataSource]);
}

@end


#pragma mark -

@implementation MulleScionExpression ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   id   result;
   
   result = ! value ? MulleScionNull : value;
   TRACE_EVAL_BEGIN_END( self, value, result);
   return( result);
}


- (void) evaluateSetValue:(id) valueToSet
       withLocalVariables:(NSMutableDictionary *) locals
               dataSource:(id <MulleScionDataSource>) dataSource
{
   abort();
}
   

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   id   value;
   
   value = [value_ valueWithLocalVariables:locals
                                dataSource:dataSource];
   return( [self evaluateValue:value
                localVariables:locals
                    dataSource:dataSource]);
}


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   NSAutoreleasePool  *pool;
   id                 value;
   
   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];
   
   updateLineNumber( self, locals);
   value = [self valueWithLocalVariables:locals
                              dataSource:dataSource];
   
   value = [value mulleScionDescriptionWithLocalVariables:locals];
   MulleScionRenderString( value, s, locals, dataSource);

   [pool release];
   
   return( self->next_);
}

@end


#pragma mark -

@implementation MulleScionNumber ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   return( value_ ? value_ : MulleScionNull);
}

@end



#pragma mark -

@implementation MulleScionString ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   NSParameterAssert( value_ != nil);
   return( value_);
}

@end


#pragma mark -

@implementation MulleScionSelector ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   NSParameterAssert( value_ != nil);
   return( [NSValue valueWithPointer:NSSelectorFromString( value_)]);
}

@end


#pragma mark -

@implementation MulleScionArray ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   NSEnumerator          *rover;
   NSMutableArray        *array;
   id                    value;
   MulleScionExpression  *expr;
   
   array = [NSMutableArray array];
   
   rover = [value_ objectEnumerator];
   while( expr = [rover nextObject])
   {
      value = [expr valueWithLocalVariables:locals
                                 dataSource:dataSource];
      if( value == nil)
         value = MulleScionNull;
      [array addObject:value];
   }
   return( array);
}

@end



#pragma mark -

@implementation MulleScionDictionary ( Printing)
   
- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   NSEnumerator          *rover;
   NSMutableDictionary   *result;
   id                    value;
   id                    key;
   MulleScionExpression  *expr;
   
   result = [NSMutableDictionary dictionary];
   
   rover = [value_ keyEnumerator];
   while( key = [rover nextObject])
   {
      expr  = [value_ objectForKey:key];
      value = [expr valueWithLocalVariables:locals
                                 dataSource:dataSource];
      if( value == nil)
         value = MulleScionNull;
      [result setObject:value
                 forKey:key];
   }
   return( result);
}

@end


#pragma mark -

@implementation MulleScionParameterAssignment ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   id   value;
   
   value = [expression_ valueWithLocalVariables:locals
                                     dataSource:dataSource];
   [locals setObject:value
              forKey:value_];
   return( value);
}


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   NSAutoreleasePool  *pool;
   id                 value;
   
   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];
   
   updateLineNumber( self, locals);
   value = [self valueWithLocalVariables:locals
                              dataSource:dataSource];

   value = [value mulleScionDescriptionWithLocalVariables:locals];
   MulleScionRenderString( value, s, locals, dataSource);

   [pool release];

   return( self->next_);
}

@end


#pragma mark -

@interface MulleScionCommand( Printing)

- (MulleScionObject *) renderBlock:(MulleScionObject *) curr
                              into:(id <MulleScionOutput>) s
                    localVariables:(NSMutableDictionary *) locals
                        dataSource:(id <MulleScionDataSource>) dataSource;
@end


#pragma mark -

@implementation MulleScionCommand ( Printing)

- (MulleScionObject *) renderBlock:(MulleScionObject *) curr
                              into:(id <MulleScionOutput>) s
                    localVariables:(NSMutableDictionary *) locals
                        dataSource:(id <MulleScionDataSource>) dataSource
{
   Class   terminatorCls;
   
   terminatorCls = [self terminatorClass];

   while( curr)
   {
      if( [curr isElse])
         return( curr);
      
      if( [curr class] == terminatorCls)
         return( curr);
      
      curr = [curr renderInto:s
               localVariables:locals
                   dataSource:dataSource];
   }
   return( curr);
}

@end


#pragma mark -

@implementation MulleScionAssignmentExpression ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   id   value;
   
   // lldb voodoo
   NSParameterAssert( [right_ isKindOfClass:[MulleScionExpression class]]);
   
   value = [right_ valueWithLocalVariables:locals
                                dataSource:dataSource];
   
   [value_ evaluateSetValue:value
         withLocalVariables:locals
                 dataSource:dataSource];
   return( value);
}

@end


@implementation MulleScionSet ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   id   value;
   
   value = [right_ valueWithLocalVariables:locals
                                dataSource:dataSource];
   
   [left_ evaluateSetValue:value
        withLocalVariables:locals
                dataSource:dataSource];
   return( value);
}


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   NSAutoreleasePool  *pool;
   
   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];
   
   updateLineNumber( self, locals);
   [self valueWithLocalVariables:locals
                      dataSource:dataSource];
   
   [pool release];
   
   return( self->next_);
}

@end


#pragma mark -

@implementation MulleScionTerminator ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   TRACE_RENDER( self, s, locals, dataSource);

   updateLineNumber( self, locals);
   MulleScionPrintingException( NSInternalInconsistencyException, locals, @"stray %@ in template", [self commandName]);
}

@end


#pragma mark -

@implementation MulleScionExpressionCommand ( Printing)

// just executes the expression, but discards the value
- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionObject   *curr;
   NSAutoreleasePool  *pool;
   
   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];
   
   updateLineNumber( self, locals);
   [expression_ valueWithLocalVariables:locals
                             dataSource:dataSource];
   curr = self->next_;
   
   [pool release];
   
   return( curr);
}

@end


#pragma mark -

@implementation MulleScionIf ( Printing)

static Class  _nsNumberClass;
static Class  _nsStringClass;


+ (void) load
{
   _nsNumberClass = [NSNumber class];
   _nsStringClass = [NSString class];
}


static BOOL  isTrue( id value)
{
   BOOL  flag;
   
   if( value == MulleScionNull)
      return( NO);

   flag = NO;
   if( [value respondsToSelector:@selector( boolValue)])
   {
      flag = [value boolValue];
      if( ! flag)
      {
         //
         // [@"foo" boolValue] gives NO, so check if
         // NSString really means it. we just know
         // NO and 0
         //
         if( [value isKindOfClass:_nsStringClass])
            flag  = ! ([value isEqualToString:@"0"] ||
                       [value isEqualToString:@"NO"]);
      }
   }
   
   return( flag);
}


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionObject   *curr;
   BOOL               flag;
   NSAutoreleasePool  *pool;
   id                 value;
   
   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];
   
   updateLineNumber( self, locals);
   value = [expression_ valueWithLocalVariables:locals
                                     dataSource:dataSource];

   curr = self->next_;

   flag = isTrue( value);
   if( flag)
      curr = [self renderBlock:curr
                          into:s
                localVariables:locals
                    dataSource:dataSource];

   // here curr is still pointing to else or endif or the first block
   curr = [self terminateToElse:curr];
   if( [curr isElse])
   {
      if( ! flag)
         curr = [self renderBlock:curr->next_
                             into:s
                   localVariables:locals
                       dataSource:dataSource];
      else
         curr = [self terminateToEnd:curr];
   }
   
   if( [curr isEndIf])
      curr = curr->next_;

   [pool release];
   
   return( curr);
}

@end


#pragma mark -

@implementation MulleScionFor ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   BOOL                  isEven;
   BOOL                  isFirst;
   BOOL                  isLast;
   BOOL                  isSubdivisionStart;
   BOOL                  isSubdivisionEnd;
   MulleScionObject      *curr;
   MulleScionObject      *memo;
   NSAutoreleasePool     *pool;
   NSEnumerator          *rover;
   NSMutableDictionary   *info;
   NSString              *closer;
   NSString              *even;
   NSString              *infoKey;
   NSString              *key;
   NSString              *identifier;
   NSString              *next;
   NSString              *odd;
   NSString              *opener;
   NSString              *separator;
   NSString              *subdivisionOpener;
   NSString              *subdivisionCloser;
   NSUInteger            i;
   NSInteger             division;
   NSNumber              *yes, *no;
   id                    value;
   
   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];
   
   updateLineNumber( self, locals);
   
   opener    = [locals objectForKey:MulleScionForOpenerKey];
   separator = [locals objectForKey:MulleScionForSeparatorKey];
   closer    = [locals objectForKey:MulleScionForCloserKey];

   if( ! opener)
      opener = @"";
   if( ! separator)
      separator = @", ";
   if( ! closer)
      closer = @"";

   division  = [[locals objectForKey:MulleScionForSubdivisionLengthKey] integerValue];
   if( division <= 0)
      division = 1;

   subdivisionOpener = @"";
   subdivisionCloser = separator;

   if( division > 1)
   {
      subdivisionOpener = [locals objectForKey:MulleScionForSubdivisionOpenerKey];
      subdivisionCloser = [locals objectForKey:MulleScionForSubdivisionCloserKey];
   }
   
   even = [locals objectForKey:MulleScionEvenKey];
   odd  = [locals objectForKey:MulleScionOddKey];
   
   if( ! even)
      even = @"even";
   if( ! odd)
      odd = @"odd";

   value = [right_ valueWithLocalVariables:locals
                                dataSource:dataSource];

   if( [value isKindOfClass:[NSEnumerator class]])
      rover = value;
   else
   {
      if( [value respondsToSelector:@selector( keyEnumerator)])
         rover = [value keyEnumerator];
      else
      {
         if( ! [value respondsToSelector:@selector( objectEnumerator)])
            value = [[[NSArray alloc] initWithObjects:value, nil] autorelease];
         rover = [value objectEnumerator];
      }
   }

   NSParameterAssert( ! left_ || [left_ isIdentifier]);
   
   identifier = [(MulleScionVariable *) left_ identifier];
   
   curr    = self->next_;
   memo    = curr;

   // NOT SURE ABOUT THIS
   if( ! identifier)
      return( curr);
   
   info    = [NSMutableDictionary dictionary];
   infoKey = [NSString stringWithFormat:@"%@#", identifier];
   [locals setObject:info
              forKey:infoKey];
   
   yes  = [NSNumber numberWithBool:YES];
   no   = [NSNumber numberWithBool:NO];

   i    = 0;
   next = [rover nextObject];
   while( key = next)
   {
      next               = [rover nextObject];
      
      isFirst            = i == 0;
      isLast             = ! next;
      isEven             = !(i & 1);
      isSubdivisionEnd   = (i % division) == division - 1;
      isSubdivisionStart = ! (i % division);

      [info setObject:[NSNumber numberWithInteger:i]
               forKey:@"i"];
      [info setObject:[NSNumber numberWithInteger:i % division]
               forKey:@"modulo"];
      [info setObject:[NSNumber numberWithInteger:i / division]
               forKey:@"division"];
      
      [info setObject:isFirst ? opener : (isSubdivisionStart ? subdivisionOpener : @"")
               forKey:@"header"];
      [info setObject:isLast ? closer : (isSubdivisionEnd ? subdivisionCloser : separator)
               forKey:@"footer"];

      [info setObject:isEven ? even : odd
               forKey:@"evenOdd"];
      [info setObject:isFirst ? yes : no
               forKey:@"isFirst"];
      [info setObject:isLast ? yes : no
               forKey:@"isLast"];
      [info setObject:isEven ? yes : no
               forKey:@"isEven"];
      
      [locals setObject:key
                 forKey:identifier];

      curr = [self renderBlock:memo
                          into:s
                localVariables:locals
                    dataSource:dataSource];
      ++i;
   }

   if( i == 0)
   {
      curr = [self terminateToElse:curr];
      if( [curr isElse])
         [self renderBlock:curr->next_
                      into:s
            localVariables:locals
                dataSource:dataSource];
   }
   
   curr = [self terminateToEnd:curr];
   if( [curr isEndFor])
      curr = curr->next_;
   
   [locals removeObjectForKey:infoKey];
   [locals removeObjectForKey:identifier];   // always nil anyway
   
   [pool release];
   
   return( curr);
}

@end


#pragma mark -

@implementation MulleScionWhile ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionObject   *curr;
   MulleScionObject   *memo;
   NSAutoreleasePool  *pool;
   id                 value;
   
   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];
   
   updateLineNumber( self, locals);

   curr = self->next_;
   memo = curr;
   
   for(;;)
   {
      value = [expression_ valueWithLocalVariables:locals
                                        dataSource:dataSource];
   
      if( ! isTrue( value))
         break;
      
      curr = [self renderBlock:memo
                          into:s
                localVariables:locals
                    dataSource:dataSource];
   }
   
   curr = [self terminateToEnd:curr];
   if( [curr isEndWhile])
      curr = curr->next_;
   
   [pool release];
   
   return( curr);
}

@end


#pragma mark -

@implementation MulleScionBlock ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionObject   *curr;
   NSAutoreleasePool  *pool;
   
   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];
   
   updateLineNumber( self, locals);
   pushFileName( locals, fileName_);
   
   curr = [self renderBlock:self->next_
                       into:s
             localVariables:locals
                 dataSource:dataSource];
   if( [curr isEndBlock])
      curr = curr->next_;
   
   [pool release];
   
   return( curr);
}

@end


#pragma mark -

@implementation MulleScionEndBlock ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   TRACE_RENDER( self, s, locals, dataSource);

   popFileName( locals);
   
   return( self->next_);
}

@end


#pragma mark -

@implementation MulleScionComparison ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   id                   otherValue;
   BOOL                 flag;
   NSComparisonResult   comparisonResult;
   id                   result;

   TRACE_EVAL_BEGIN( self, value);
   
   if( value == MulleScionNull)
      value = nil;
   
   otherValue = [self->right_ valueWithLocalVariables:locals
                                           dataSource:dataSource];
   if( otherValue == MulleScionNull)
      otherValue = nil;
   switch( comparison_)
   {
      case MulleScionEqual    : flag =   [value isEqual:otherValue]; break;
      case MulleScionNotEqual : flag = ! [value isEqual:otherValue]; break;

      default                 :
         comparisonResult = [value compare:otherValue];
         flag = NO;
         switch( comparisonResult)
         {
         case NSOrderedSame       :
            flag = (comparison_ == MulleScionLessThanOrEqualTo ||
                    comparison_ == MulleScionGreaterThanOrEqualTo);
            break;
               
         case NSOrderedAscending  :
            flag = (comparison_ == MulleScionLessThan ||
                    comparison_ == MulleScionLessThanOrEqualTo);
            break;
         case NSOrderedDescending :
            flag = (comparison_ == MulleScionGreaterThan ||
                    comparison_ == MulleScionGreaterThanOrEqualTo);
            break;
         }
   }
   result = [NSNumber numberWithBool:flag];

   TRACE_EVAL_END( self, result);
   return( result);
}

@end


#pragma mark -

@implementation MulleScionNot ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   id   result;
   
   result = [NSNumber numberWithBool:! isTrue( value)];

   TRACE_EVAL_BEGIN_END( self, value, result);
   return( result);
}

@end


#pragma mark -

@implementation MulleScionAnd ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   id     otherValue;
   id     result;
   BOOL   flag;

   TRACE_EVAL_BEGIN( self, value);
   flag = isTrue( value);
   if( flag)
   {
      otherValue = [self->right_ valueWithLocalVariables:locals
                                              dataSource:dataSource];
      TRACE_EVAL_CONT( self, otherValue);
      
      flag = isTrue( otherValue);
   }
   result = [NSNumber numberWithBool:flag];

   TRACE_EVAL_END( self, result);
   return( result);
}

@end


#pragma mark -

@implementation MulleScionOr ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   id     otherValue;
   id     result;
   BOOL   flag;
   
   TRACE_EVAL_BEGIN( self, value);
   
   flag = isTrue( value);
   if( ! flag)
   {
      otherValue = [self->right_ valueWithLocalVariables:locals
                                              dataSource:dataSource];
      TRACE_EVAL_CONT( self, otherValue);
      flag = isTrue( otherValue);
   }
   
   result = [NSNumber numberWithBool:flag];
   
   TRACE_EVAL_END( self, result);
   
   return( result);
}

@end


#pragma mark -

@implementation MulleScionIndexing ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   id   otherValue;
   id   result;

   TRACE_EVAL_BEGIN( self, value);
   
   if( value == MulleScionNull)
      return( value);
   
   otherValue = [self->right_ valueWithLocalVariables:locals
                                           dataSource:dataSource];
   if( [value respondsToSelector:@selector( objectAtIndex:)])
      result = [value objectAtIndex:[otherValue integerValue]]; // must be a NSNumber or NSString (?)
   else
      result = [value valueForKeyPath:[otherValue description]];

   if( ! result)
      result = MulleScionNull;
   
   TRACE_EVAL_END( self, result);

   return( result);
}

   
- (void) evaluateSetValue:(id) valueToSet
       withLocalVariables:(NSMutableDictionary *) locals
               dataSource:(id <MulleScionDataSource>) dataSource
{
   id           otherValue;
   NSUInteger   index;
   NSUInteger   n;
   id           value;
   
   // grab index
   //
   // SECURITY HOLE: setters need to be funneled through dataSource
   //
   value      = [self->value_ valueWithLocalVariables:locals
                                           dataSource:dataSource];
   otherValue = [self->right_ valueWithLocalVariables:locals
                                           dataSource:dataSource];
   
   if( [value respondsToSelector:@selector( objectAtIndex:)])
   {
      index = [otherValue integerValue];
      n     = [value count];
      while( index > n)
      {
         [value addObject:MulleScionNull];
         ++n;
      }
      
      if( n == index)
         [value addObject:valueToSet];
      else
         [value replaceObjectAtIndex:index
                          withObject:valueToSet];
      return;
   }
   
   [value setValue:valueToSet
        forKeyPath:[otherValue description]];
}

@end


#pragma mark -

@implementation MulleScionPipe ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   NSString        *identifier;
   MulleScionPipe  *next;
   id              result;
   
   TRACE_EVAL_BEGIN( self, value);

   if( value == MulleScionNull)
      return( value);

   // make it string
   value = [value mulleScionDescriptionWithLocalVariables:locals];
   
   if( ! [self->right_ isPipe])
   {
      if( [self->right_ isMethod])
      {
         [locals setObject:value
                    forKey:MulleScionSelfReplacementKey];
         result = [(MulleScionMethod *) self->right_ valueWithLocalVariables:locals
                                                                 dataSource:dataSource];
         [locals removeObjectForKey:MulleScionSelfReplacementKey];

         TRACE_EVAL_END( self, result);
         return( result);
      }

      identifier = [(MulleScionVariable *) self->right_ identifier];
      result     = [dataSource mulleScionPipeString:value
                                      throughMethod:identifier
                                     localVariables:locals];
      TRACE_EVAL_END( self, result);
      return( result);
   }

   next = (MulleScionPipe *) self->right_;
   NSParameterAssert( [next->value_ isKindOfClass:[MulleScionVariable class]]);
   
   identifier = [(MulleScionVariable *) next->value_ identifier];
   value      = [dataSource mulleScionPipeString:value
                                   throughMethod:identifier
                                  localVariables:locals];
   result     = [self->right_ evaluateValue:value
                             localVariables:locals
                                 dataSource:dataSource];
   TRACE_EVAL_END( self, result);
   
   return( result);
}

@end


#pragma mark -

@implementation MulleScionDot ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   NSString        *identifier;
   MulleScionDot   *next;
   id              result;
   
   NSParameterAssert( value);
   
   TRACE_EVAL_BEGIN( self, value);
   
   if( value == MulleScionNull)
      return( value);
   
   if( ! [self->right_ isDot])
   {
      if( [self->right_ isMethod])
      {
         [locals setObject:value
                    forKey:MulleScionSelfReplacementKey];
         result = [(MulleScionMethod *) self->right_ valueWithLocalVariables:locals
                                                                 dataSource:dataSource];
         [locals removeObjectForKey:MulleScionSelfReplacementKey];

         if( ! result)
            result = MulleScionNull;
         TRACE_EVAL_END( self, result);
         return( result);
      }
      
      identifier = [(MulleScionVariable *) self->right_ identifier];
      result     = [value mulleScionValueForKeyPath:identifier
                                     localVariables:locals];
      if( ! result)
         result = MulleScionNull;
      TRACE_EVAL_END( self, result);
      return( result);
   }
   
   next = (MulleScionDot *) self->right_;
   if( [next->value_ isIdentifier])
   {
      identifier = [(MulleScionVariable *) next->value_ identifier];
      value      = [value mulleScionValueForKeyPath:identifier
                                     localVariables:locals];
      if( ! value)
         value = MulleScionNull;
   }
   
   result = [self->right_ evaluateValue:value
                         localVariables:locals
                             dataSource:dataSource];
   TRACE_EVAL_END( self, result);
   return( result);
}

@end


#pragma mark -

@implementation MulleScionConditional ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionExpression   *choice;
   id                     result;
   
   TRACE_EVAL_BEGIN( self, value);
   
   choice = self->middle_;
   if( ! isTrue( value))
      choice = self->right_;

   result = [choice valueWithLocalVariables:locals
                                dataSource:dataSource];
   TRACE_EVAL_END( self, result);
   return( result);
}

@end


#pragma mark -

@implementation MulleScionFilter ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionExpression  *prev;
   NSMutableArray        *stack;
   NSAutoreleasePool     *pool;
   
   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];
   
   updateLineNumber( self, locals);
   
   prev = [locals objectForKey:MulleScionCurrentFilterKey];
   if( prev)
   {
      stack = [locals objectForKey:MulleScionPreviousFiltersKey];
      if( ! stack)
      {
         stack = [NSMutableArray new];
         [locals setObject:stack
                    forKey:MulleScionPreviousFiltersKey];
         [stack release];
      }
      [stack addObject:prev];
   }
   
   // filters don't stack ( sorry)
   [locals setObject:self->expression_
              forKey:MulleScionCurrentFilterKey];
   
   [pool release];
   
   return( self->next_);
}

@end


#pragma mark -

@implementation MulleScionEndFilter ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   NSMutableArray       *stack;
   NSAutoreleasePool    *pool;
   MulleScionEndFilter  *filter;
   
   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];
      
   updateLineNumber( self, locals);

   if( ! [locals objectForKey:MulleScionCurrentFilterKey])
      MulleScionPrintingException( NSInvalidArgumentException, locals, @"stray endfilter");
   
   stack = [locals objectForKey:MulleScionPreviousFiltersKey];
   filter = [stack lastObject];
   if( filter)
   {
      [locals setObject:filter
                 forKey:MulleScionCurrentFilterKey];
      [stack removeLastObject];
   }
   else
      [locals removeObjectForKey:MulleScionCurrentFilterKey];
   
   [pool release];
   
   return( self->next_);
}

@end
