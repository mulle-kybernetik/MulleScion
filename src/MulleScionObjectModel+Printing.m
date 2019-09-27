//
//  MulleScionObjectModel+Printing.m
//  MulleScion
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

#import "MulleScionObjectModel+TraceDescription.h"
#import "MulleMutableLineNumber.h"
#import "MulleScionNull.h"
#import "MulleScionPrintingException.h"
#import "NSObject+MulleScionDescription.h"
#import "MulleCommonObjCRuntime.h"
#if ! TARGET_OS_IPHONE
# import <Foundation/NSDebug.h>
# ifndef __MULLE_OBJC__
#  import <objc/objc-class.h>
# endif
#else
# import <objc/runtime.h>
# import "NSObject+KVC_Compatibility.h"
#endif

#ifndef NO_TRACE
# undef HAVE_TRACE
# define HAVE_TRACE
#endif

#if defined( HAVE_TRACE) & ! defined( NO_TRACE_EVAL)
# undef HAVE_TRACE_EVAL
# define HAVE_TRACE_EVAL
#endif

#if defined( HAVE_TRACE) & ! defined( NO_TRACE_RENDER)
# undef HAVE_TRACE_RENDER
# define HAVE_TRACE_RENDER
#endif

NSString   *MulleScionArgumentsKey            = @"__ARGV__";
NSString   *MulleScionCurrentFileKey          = @"__FILE__";
NSString   *MulleScionPreviousFilesKey        = @"__FILE_STACK__";
NSString   *MulleScionCurrentFilterKey        = @"__FILTER__";
NSString   *MulleScionCurrentFilterModeKey    = @"__FILTER_MODE__";
NSString   *MulleScionPreviousFiltersKey      = @"__FILTER_STACK__";
NSString   *MulleScionPreviousFilterModesKey  = @"__FILTER_MODE_STACK__";
NSString   *MulleScionFoundationKey           = @"__FOUNDATION__";
NSString   *MulleScionCurrentFunctionKey      = @"__FUNCTION__";
NSString   *MulleScionFunctionTableKey        = @"__FUNCTION_TABLE__";
NSString   *MulleScionCurrentLineKey          = @"__LINE__";
NSString   *MulleScionRenderOutputKey         = @"__OUTPUT__";
NSString   *MulleScionSelfReplacementKey      = @"__SELF_REPLACEMENT__";
NSString   *MulleScionTraceKey                = @"__TRACE__";
NSString   *MulleScionVersionKey              = @"__VERSION__";

NSString   *MulleScionForOpenerKey            = @"MulleScionForOpener";
NSString   *MulleScionForSeparatorKey         = @"MulleScionForSeparator";
NSString   *MulleScionForCloserKey            = @"MulleScionForCloser";
NSString   *MulleScionForSubdivisionLengthKey = @"MulleScionForSubdivisionLength";
NSString   *MulleScionForSubdivisionOpenerKey = @"MulleScionForSubdivisionOpener";
NSString   *MulleScionForSubdivisionCloserKey = @"MulleScionForSubdivisionCloser";

NSString   *MulleScionEvenKey                 = @"MulleScionEven";
NSString   *MulleScionOddKey                  = @"MulleScionOdd";

static BOOL   isTracing;

// THIS IS NOT REALLY WORKING WELL BUT BETTER THAN NOTHING I GUESS

#ifdef HAVE_TRACE_RENDER
# define TRACE_RENDER( self, s, locals, dataSource)  if( isTracing) fprintf( stderr, "%ld: %s\n", (long) [self lineNumber], [[self traceDescription] UTF8String])
#else
# define TRACE_RENDER( self, s, locals, dataSource)
#endif


#ifdef HAVE_TRACE_EVAL

static void   _TRACE_EVAL_BEGIN( MulleScionObject *self, id value)
{
   NSString   *s;

   s = [NSString stringWithFormat:@"%ld: -->%@ :: %@",
        (long) [self lineNumber],
        [self traceDescription],
        mulleLinefeedEscapedShortenedString( [value traceValueDescription], 64)];
   fprintf( stderr, "%s\n", [s UTF8String]);
}



static inline void   _TRACE_EVAL_END( MulleScionObject *self, id value)
{
   NSString   *s;


   s = [NSString stringWithFormat:@"%ld: <--%@ :: %@",
                (long) [self lineNumber],
                [self traceDescription],
                mulleLinefeedEscapedShortenedString( [value traceValueDescription], 64)];
   fprintf( stderr, "%s\n", [s UTF8String]);
}


static inline void   _TRACE_EVAL_CONT( MulleScionObject *self, id value)
{
   NSString   *s;

   if( ! isTracing)
      return;

   s = [NSString stringWithFormat:@"%ld:    %@ :: %@",
        (long) [self lineNumber],
        [self traceDescription],
        mulleLinefeedEscapedShortenedString( [value traceValueDescription], 64)];
   fprintf( stderr, "%s\n", [s UTF8String]);
}



static inline void   _TRACE_EVAL_BEGIN_END( MulleScionObject *self, id value, id result)
{
   NSString   *s;

   s = [NSString stringWithFormat:@"%ld: <->%@ :: %@->%@",
        (long) [self lineNumber],
        [self traceDescription],
        mulleLinefeedEscapedShortenedString( [value traceValueDescription], 64),
        mulleLinefeedEscapedShortenedString( [result traceValueDescription], 64)];
   fprintf( stderr, "%s\n", [s UTF8String]);
}


static inline void   TRACE_EVAL_BEGIN( MulleScionObject *self, id value)
{
   if( ! isTracing)
      return;
   _TRACE_EVAL_BEGIN( self, value);
}


static inline void   TRACE_EVAL_END( MulleScionObject *self, id value)
{
   if( ! isTracing)
      return;
   _TRACE_EVAL_END( self, value);
}


static inline void   TRACE_EVAL_CONT( MulleScionObject *self, id value)
{
   if( ! isTracing)
      return;
   _TRACE_EVAL_CONT( self, value);
}

static inline void   TRACE_EVAL_BEGIN_END( MulleScionObject *self, id value, id result)
{
   if( ! isTracing)
      return;
   _TRACE_EVAL_BEGIN_END( self, value, result);
}

#else
# define TRACE_EVAL_BEGIN( self, value)
# define TRACE_EVAL_END( self, value)
# define TRACE_EVAL_CONT( self, value)
# define TRACE_EVAL_BEGIN_END( self, value, result)
#endif

@interface MulleScionExpression( Printing)

// this should never return nil, but MulleScionNull instead
// should also never receive nil as value
- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource;

// this should never return nil, but MulleScionNull instead
- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource;

@end


#pragma mark -

@implementation MulleScionObject( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
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


NSString  *MulleScionFilteredString( NSString *value,
                                     NSMutableDictionary *locals,
                                     id <MulleScionDataSource> dataSource,
                                     NSUInteger bit)
{
   id             filter;
   NSString       *filtered;
   NSEnumerator   *rover;
   NSEnumerator   *modeRover;
   NSUInteger     mask;

   NSCParameterAssert( ! value || [value isKindOfClass:[NSString class]]);

   filter = [locals objectForKey:MulleScionCurrentFilterKey];
   if( ! filter)
      return( value);

   // if turned off, don't filter
   mask = [[locals objectForKey:MulleScionCurrentFilterModeKey] integerValue];
   if( mask & bit)
   {
      filtered = [filter evaluateValue:(id) value
                        localVariables:locals
                            dataSource:dataSource];
      NSCParameterAssert( filtered);
      if( filtered == MulleScionNull)
         return( nil);

      value = filtered;
   }

   //
   // if FilterApplyStackedFilters we execute all nested filters
   // too, this is less suprising but also less compatible to how it was before
   //
   if( bit & FilterApplyStackedFilters)
   {
      rover     = [[locals objectForKey:MulleScionPreviousFiltersKey] reverseObjectEnumerator];
      modeRover = [[locals objectForKey:MulleScionPreviousFilterModesKey] reverseObjectEnumerator];
      while( filter = [rover nextObject])
      {
         mask = [[modeRover nextObject] integerValue];
         if( mask & bit)
         {
            filtered = [filter evaluateValue:value
                              localVariables:locals
                                  dataSource:dataSource];

            NSCParameterAssert( filtered);
            if( filtered == MulleScionNull)
               return( nil);

            value = filtered;
         }
      }
   }

   return( value);
}


void   MulleScionRenderString( NSString *value,
                               id <MulleScionOutput> output,
                               NSMutableDictionary *locals,
                               id <MulleScionDataSource> dataSource)
{
   NSString   *s;

   s = MulleScionFilteredString( value, locals, dataSource, FilterOutput|FilterApplyStackedFilters);
   if( ! s)
      return;

   NSCParameterAssert( [s isKindOfClass:[NSString class]]);
   [output appendString:s];
}


void   MulleScionRenderPlaintextString( NSString *value,
                                        id <MulleScionOutput> output,
                                        NSMutableDictionary *locals,
                                        id <MulleScionDataSource> dataSource)
{
   NSString   *s;

   s = MulleScionFilteredString( value, locals, dataSource, FilterPlaintext|FilterApplyStackedFilters);
   if( ! s)
      return;

   NSCParameterAssert( [s isKindOfClass:[NSString class]]);
   [output appendString:s];
}

@end


#pragma mark -

@implementation MulleScionTemplate( Printing)

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




static id  f_filter( id self, NSArray *arguments, NSMutableDictionary *locals)
{
   NSString   *string;
   id         value;

   MulleScionPrintingValidateArgumentCount( arguments, 1, locals);
   value  = MulleScionPrintingValidatedArgument( arguments, 0, Nil, locals);
   string = [value mulleScionDescriptionWithLocalVariables:locals];
   string = MulleScionFilteredString( string, locals, self, FilterOutput);
   return( string);
}


static id  f_defined( id self, NSArray *arguments, NSMutableDictionary *locals)
{
   id     value;
   BOOL   flag;

   MulleScionPrintingValidateArgumentCount( arguments, 1, locals);
   value = MulleScionPrintingValidatedArgument( arguments, 0, [NSString class], locals);
   flag  = [self mulleScionValueForKeyPath:value
                            localVariables:locals] != nil;
   if( ! flag)
      flag = [locals valueForKeyPath:value] != nil;
   return( [NSNumber numberWithBool:flag]);
}


static id  f_NSMakeRange( id self, NSArray *arguments, NSMutableDictionary *locals)
{
   NSRange   range;

   MulleScionPrintingValidateArgumentCount( arguments, 2, locals);
   range.location = [MulleScionPrintingValidatedArgument( arguments, 0, [NSNumber class], locals) unsignedIntegerValue];
   range.length   = [MulleScionPrintingValidatedArgument( arguments, 1, [NSNumber class], locals) unsignedIntegerValue];

   return( [NSValue valueWithRange:range]);
}


static id  f_NSStringFromRange( id self, NSArray *arguments, NSMutableDictionary *locals)
{
   NSRange   range;

   MulleScionPrintingValidateArgumentCount( arguments, 1, locals);
   range = [MulleScionPrintingValidatedArgument( arguments, 0, [NSValue class], locals) rangeValue];
   return( NSStringFromRange( range));
}


static id  f_NSLocalizedString( id self, NSArray *arguments, NSMutableDictionary *locals)
{
   NSString   *s1;

   MulleScionPrintingValidateArgumentCount( arguments, 2, locals);

   s1 = MulleScionPrintingValidatedArgument( arguments, 0, [NSString class], locals);

   return( NSLocalizedString( s1, nil));
}


+ (NSMutableDictionary *) mulleScionDefaultBuiltinFunctionTable
{
   NSMutableDictionary  *dictionary;

   dictionary = [NSMutableDictionary dictionary];
   [dictionary setObject:[NSValue valueWithPointer:f_NSStringFromRange]
                  forKey:@"NSStringFromRange"];
   [dictionary setObject:[NSValue valueWithPointer:f_NSMakeRange]
                  forKey:@"NSMakeRange"];
   [dictionary setObject:[NSValue valueWithPointer:f_NSLocalizedString]
                  forKey:@"NSLocalizedString"];
   [dictionary setObject:[NSValue valueWithPointer:f_defined]
                  forKey:@"defined"];
   [dictionary setObject:[NSValue valueWithPointer:f_filter]
                  forKey:@"filter"];
   return( dictionary);
}


+ (void) setDefaultValuesOfLocalVariables:(NSMutableDictionary *) locals
{
   // setup some often needed OS X constants
   [locals setObject:[NSNumber numberWithInteger:NSOrderedSame]
              forKey:@"NSOrderedSame"];
   [locals setObject:[NSNumber numberWithInteger:NSOrderedAscending]
              forKey:@"NSOrderedAscending"];
   [locals setObject:[NSNumber numberWithInteger:NSOrderedDescending]
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

   [locals setObject:[NSNumber numberWithInteger:NSNotFound]
              forKey:@"NSNotFound"];
}


- (NSMutableDictionary *) localVariablesWithDefaultValues:(NSDictionary *) defaults
{
   NSMutableDictionary   *locals;

   locals = [NSMutableDictionary dictionary];

   // built in first
   [MulleGetClass( self) setDefaultValuesOfLocalVariables:locals];

   // user defaults later
   [locals addEntriesFromDictionary:defaults];

   initLineNumber( locals);

   // do not override user function table
   if( ! [locals objectForKey:MulleScionFunctionTableKey])
      [locals setObject:[MulleGetClass( self) mulleScionDefaultBuiltinFunctionTable]
                 forKey:MulleScionFunctionTableKey];

#if defined( HAVE_TRACE)
   isTracing = getenv( "MulleScionTrace") != NULL;
   [locals setObject:[NSNumber numberWithBool:isTracing]
              forKey:MulleScionTraceKey];
#endif
   return( locals);
}


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionObject   *curr;
   NSAutoreleasePool  *pool;
   extern char        MulleScionFrameworkVersion[];
    
   NSAssert( [locals valueForKey:@"NSNotFound"], @"use -[MulleScionTemplate localVariablesWithDefaultValues:] to create the localVariables dictionary");

   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];

   //
   // expose everything to the dataSource for max. hackability
   // trusted (writing OK, reading ? your choice!)
   //
   updateLineNumber( self, locals);

   [locals setObject:output
              forKey:MulleScionRenderOutputKey];
   [locals setObject:value_
              forKey:MulleScionCurrentFileKey];
#if __MULLE_OBJC__
   [locals setObject:@"Mulle"
             forKey:MulleScionFoundationKey];
#else
   [locals setObject:@"Apple"
             forKey:MulleScionFoundationKey];
#endif
   [locals setObject:[NSString stringWithUTF8String:MulleScionFrameworkVersion]
              forKey:MulleScionVersionKey];

   // must be provided, because it's too painful to always set it here

   curr = self->next_;
   while( curr)
      curr = [curr renderInto:output
               localVariables:locals
                   dataSource:dataSource];

   [pool release];

   return( curr);
}

@end


#pragma mark -

@implementation MulleScionPlainText( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   TRACE_RENDER( self, s, locals, dataSource);

   updateLineNumber( self, locals);
   MulleScionRenderPlaintextString( value_, output, locals, dataSource);
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

@implementation MulleScionVariable( Printing)

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
#ifdef HAVE_TRACE
   if( [value_ isEqualToString:MulleScionTraceKey])
   {
      isTracing = [valueToSet boolValue];
      NSLog( @"trace %s", isTracing ? "enabled" : "disabled");
   }
#endif
   TRACE_EVAL_CONT( self, valueToSet);
   [locals takeValue:valueToSet
          forKeyPath:value_];
}


// hackish: used for filtering only
- (id) evaluateValue:(id) target
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   id   result;

   result = [dataSource mulleScionPipeString:target
                               throughMethod:value_ // idenetifier
                              localVariables:locals];
   return( result);
}

@end


#pragma mark -

@implementation MulleScionFunction( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   NSEnumerator           *rover;
   NSMutableArray         *array;
   MulleScionExpression   *expr;
   id                     argument;
   id                     result;

   array = [NSMutableArray array];
   rover = [arguments_ objectEnumerator];
   while( expr = [rover nextObject])
   {
      argument = [expr valueWithLocalVariables:locals
                                    dataSource:dataSource];
      [array addObject:argument];
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

@implementation MulleScionMethod( Printing)

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
   NSUInteger   alignment;
   NSUInteger   size;
   char         *myType;
   void         *buf;

   if( value && ! [value isKindOfClass:[NSValue class]])
      return( NULL);

   NSGetSizeAndAlignment( type, &size, &alignment);

   buf = (void *) [[NSMutableData dataWithLength:size] mutableBytes];
   if( ! value)
      return( buf);

   switch( *type)
   {
   case _C_CHR      : *(char *)           buf = [value charValue]; return( buf);
   case _C_UCHR     : *(unsigned char *)  buf = [value unsignedCharValue]; return( buf);
   case _C_SHT      : *(short *)          buf = [value shortValue]; return( buf);
   case _C_USHT     : *(unsigned short *) buf = [value unsignedShortValue]; return( buf);
   case _C_INT      : *(int *)            buf = [value intValue]; return( buf);
   case _C_UINT     : *(unsigned int *)   buf = [value unsignedIntValue]; return( buf);
   case _C_LNG      : *(long *)           buf = [value longValue]; return( buf);
   case _C_ULNG     : *(unsigned long *)  buf = [value unsignedLongValue]; return( buf);
   case _C_LNG_LNG  : *(long long *)      buf = [value longLongValue]; return( buf);
   case _C_ULNG_LNG : *(unsigned long long *) buf = [value unsignedLongLongValue]; return( buf);
   case _C_FLT      : *(float *)          buf = [value floatValue]; return( buf);
   case _C_DBL      : *(double *)         buf = [value doubleValue]; return( buf);
#ifdef _C_BOOL
   case _C_BOOL     : *(bool *)           buf = [value boolValue]; return( buf);
#endif
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

   NSParameterAssert( target);
   TRACE_EVAL_BEGIN( self, target);

   if( target == MulleScionNull)
      return( MulleScionNull);

   pool = [NSAutoreleasePool new];

   signature = [dataSource mulleScionMethodSignatureForSelector:action_
                                                         target:target];
   if( ! signature)
      MulleScionPrintingException( NSInvalidArgumentException, locals,
                  @"Method \"%@\" (%p) is unknown on \"%@\"", NSStringFromSelector( action_), (void *) action_, [target class]);

   // remember varargs, there can be more arguments
   m = [signature numberOfArguments];
   n = [arguments_ count] + 2;
   if( m != n)
      MulleScionPrintingException( NSInvalidArgumentException, locals,
                                  @"Method \"%@\" expects %ld arguments (got %ld)", NSStringFromSelector( action_), (long) n,
                                       (long) m);


   invocation = [NSInvocation invocationWithMethodSignature:signature];
   [invocation setSelector:action_];

   for( i = 2; i < n; i++)
   {
      expr  = [arguments_ objectAtIndex:i - 2];
      value = [expr valueWithLocalVariables:locals
                                 dataSource:dataSource];
      NSParameterAssert( value);

      if( value == dataSource) // plug security hole
         MulleScionPrintingException( NSInvalidArgumentException, locals,
                                     @"You can't use the dataSource as an argument");
      if( value == MulleScionNull)
         value = nil;

      // type = id_type;  // ok, varargs with non-objects won't work
      // if( i < m)
      {
         type = (char *) [signature getArgumentTypeAtIndex:i];
         type = _NSObjCSkipRuntimeTypeQualifier( type);
      }

      switch( *type)
      {
      case _C_ID    : buf = &value; break;
      case _C_CLASS : buf = &value; break;
      case _C_SEL   : tmp = [value pointerValue]; buf = (id *) &tmp; break;
      default       : buf = numberBuffer( type, value); break;
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
      if( length >= 1024)
         buf = (id *) [[NSMutableData dataWithLength:length] mutableBytes];
      else
         buf = alloca( length);

      [invocation getReturnValue:buf];

      returnType = (char *) [signature methodReturnType];
      returnType = _NSObjCSkipRuntimeTypeQualifier( returnType);

      switch( *returnType)
      {
      case _C_ID       : result = *buf; break;
      case _C_CLASS    : result = *buf; break;
      case _C_SEL      : result = [NSValue valueWithPointer:        (void *) *(SEL *) buf]; break;
      case _C_CHARPTR  : result = [NSString stringWithCString:      (char *) buf]; break;
      case _C_CHR      : result = [NSNumber numberWithChar:         *(char *) buf]; break;
      case _C_UCHR     : result = [NSNumber numberWithUnsignedChar: *(unsigned char *) buf]; break;
      case _C_SHT      : result = [NSNumber numberWithShort:        *(short *) buf]; break;
      case _C_USHT     : result = [NSNumber numberWithUnsignedShort:*(unsigned short *) buf]; break;
      case _C_INT      : result = [NSNumber numberWithInt:          *(int *) buf]; break;
      case _C_UINT     : result = [NSNumber numberWithUnsignedInt:  *(unsigned int *) buf]; break;
      case _C_LNG      : result = [NSNumber numberWithLong:         *(long *) buf]; break;
      case _C_ULNG     : result = [NSNumber numberWithUnsignedLong: *(unsigned long *) buf]; break;
      case _C_LNG_LNG  : result = [NSNumber numberWithLongLong:     *(long long *) buf]; break;
      case _C_ULNG_LNG : result = [NSNumber numberWithUnsignedLongLong:*(unsigned long long *) buf]; break;
      case _C_FLT      : result = [NSNumber numberWithFloat:        *(float *) buf]; break;
      case _C_DBL      : result = [NSNumber numberWithDouble:       *(double *) buf]; break;
#ifdef _C_LNG_DBL
            //   case _C_LNG_DBL  : result = [NSNumber numberWithLongDouble: *(long double *) buf]; break;
#endif
#ifdef _C_BOOL
      case _C_BOOL     : result = [NSNumber numberWithBool:*(BOOL *) buf]; break;
#endif
      default          : result = [NSValue value:buf withObjCType:returnType]; break;
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
   NSParameterAssert( target);

   if( target == MulleScionNull && original)
      target = [dataSource mulleScionClassFromString:original];

   if( ! target)
      return( MulleScionNull);

   return( [self evaluateValue:target
                localVariables:locals
                    dataSource:dataSource]);
}

@end


#pragma mark -

@implementation MulleScionExpression( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   id   result;

   NSParameterAssert( value);
   result = ! value ? MulleScionNull : value;
   TRACE_EVAL_BEGIN_END( self, value, result);
   return( result);
}


- (NSString *) flushWithLocalVariables:(NSMutableDictionary *) locals
                            dataSource:(id <MulleScionDataSource>) dataSource
{
   return( nil);
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
   NSParameterAssert( value);
   return( [self evaluateValue:value
                localVariables:locals
                    dataSource:dataSource]);
}


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
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
   NSParameterAssert( value);

   value = [value mulleScionDescriptionWithLocalVariables:locals];
   MulleScionRenderString( value, output, locals, dataSource);

   [pool release];

   return( self->next_);
}

@end


#pragma mark -

@implementation MulleScionNumber( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   return( value_ ? value_ : MulleScionNull);
}

@end



#pragma mark -

@implementation MulleScionString( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   NSParameterAssert( value_ != nil);
   return( value_);
}

@end


#pragma mark -

@implementation MulleScionSelector( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   NSParameterAssert( value_ != nil);
   return( [NSValue valueWithPointer:(void *) NSSelectorFromString( value_)]);
}

@end


#pragma mark -

@implementation MulleScionArray( Printing)

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

@implementation MulleScionDictionary( Printing)

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

@implementation MulleScionParameterAssignment( Printing)

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


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
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
   NSParameterAssert( value);

   value = [value mulleScionDescriptionWithLocalVariables:locals];
   MulleScionRenderString( value, output, locals, dataSource);

   [pool release];

   return( self->next_);
}

@end


#pragma mark -

@interface MulleScionCommand( Printing)

- (MulleScionObject *) renderBlock:(MulleScionObject *) curr
                              into:(id <MulleScionOutput>) output
                    localVariables:(NSMutableDictionary *) locals
                        dataSource:(id <MulleScionDataSource>) dataSource;
@end


#pragma mark -

@implementation MulleScionCommand( Printing)

- (MulleScionObject *) renderBlock:(MulleScionObject *) curr
                              into:(id <MulleScionOutput>) output
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

      curr = [curr renderInto:output
               localVariables:locals
                   dataSource:dataSource];
   }
   return( curr);
}

@end


#pragma mark -

@implementation MulleScionAssignmentExpression( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   id   value;

   // lldb voodoo
   NSParameterAssert( [right_ isKindOfClass:[MulleScionExpression class]]);

   value = [right_ valueWithLocalVariables:locals
                                dataSource:dataSource];
   NSParameterAssert( value);
   [value_ evaluateSetValue:value
         withLocalVariables:locals
                 dataSource:dataSource];
   return( value);
}

@end


@implementation MulleScionSet( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   id   value;

   value = [right_ valueWithLocalVariables:locals
                                dataSource:dataSource];
   NSParameterAssert( value);
   [left_ evaluateSetValue:value
        withLocalVariables:locals
                dataSource:dataSource];
   return( value);
}


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
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


@implementation MulleScionLog( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   id   value;

   value = [expression_ valueWithLocalVariables:locals
                                     dataSource:dataSource];
   NSParameterAssert( value);

   fprintf( stderr, "%s\n", [[value description] UTF8String]);
   return( value);
}


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
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

@implementation MulleScionTerminator( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   TRACE_RENDER( self, s, locals, dataSource);

   updateLineNumber( self, locals);
   MulleScionPrintingException( NSInternalInconsistencyException, locals, @"stray %@ in template", [self commandName]);
}

@end


#pragma mark -

@implementation MulleScionExpressionCommand( Printing)

// just executes the expression, but discards the value
- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
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

@implementation MulleScionIf( Printing)

static Class  _nsStringClass;


MULLE_OBJC_DEPENDS_ON_LIBRARY( Foundation);

+ (void) load
{
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


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
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
   NSParameterAssert( value);

   curr = self->next_;

   flag = isTrue( value);
   TRACE_EVAL_BEGIN_END( self, value, [NSNumber numberWithBool:flag]);

   if( flag)
      curr = [self renderBlock:curr
                          into:output
                localVariables:locals
                    dataSource:dataSource];

   // here curr is still pointing to else or endif or the first block
   curr = [self terminateToElse:curr];
   if( [curr isElse])
   {
      if( ! flag)
         curr = [self renderBlock:curr->next_
                             into:output
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

@implementation MulleScionFor( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
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
   NSNumber              *oldi, *newi, *newi1;
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
   NSParameterAssert( value);

   TRACE_EVAL_CONT( right_, value);
   rover = nil;
   if( value != MulleScionNull)
   {
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
   }

   NSParameterAssert( ! left_ || [left_ isIdentifier]);

   identifier = [(MulleScionVariable *) left_ identifier];

   curr    = self->next_;
   memo    = curr;

   // NOT SURE ABOUT THIS
   if( ! identifier)
      goto done;
   
   info    = [NSMutableDictionary dictionaryWithCapacity:16];
   infoKey = [NSString stringWithFormat:@"%@#", identifier];
   [locals setObject:info
              forKey:infoKey];

   yes  = [NSNumber numberWithBool:YES];
   no   = [NSNumber numberWithBool:NO];

   i    = 0;
   newi = nil;
   next = [rover nextObject];
   while( key = next)
   {
      next = [rover nextObject];

      TRACE_EVAL_CONT( self, key);

      isFirst            = i == 0;
      isLast             = ! next;
      isEven             = !(i & 1);
      isSubdivisionEnd   = (i % division) == (NSUInteger) (division - 1);
      isSubdivisionStart = ! (i % division);

      // try to reuse previous NSNumbers
      if( ! newi)
      {
         oldi  = [NSNumber numberWithInteger:i - 1];
         newi  = [NSNumber numberWithInteger:i];
      }
      else
      {
         oldi  = newi;
         newi  = newi1;
      }
      newi1 = [NSNumber numberWithInteger:i + 1];
      
      [info setObject:newi
               forKey:@"i"];
      [info setObject:newi1
               forKey:@"nexti"];
      [info setObject:oldi
               forKey:@"previ"];

      [info setObject:[NSNumber numberWithInteger:i % division]
               forKey:@"modulo"];
      [info setObject:division == 1 ? newi : [NSNumber numberWithInteger:i / division]
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
                          into:output
                localVariables:locals
                    dataSource:dataSource];
      ++i;
   }

   if( i == 0)
   {
      curr = [self terminateToElse:curr];
      if( [curr isElse])
         [self renderBlock:curr->next_
                      into:output
            localVariables:locals
                dataSource:dataSource];
   }

   curr = [self terminateToEnd:curr];
   if( [curr isEndFor])
      curr = curr->next_;

   [locals removeObjectForKey:infoKey];
   [locals removeObjectForKey:identifier];   // always nil anyway

done:
   [pool release];

   return( curr);
}

@end


#pragma mark -

@implementation MulleScionWhile( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
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
      NSParameterAssert( value);

      if( ! isTrue( value))
         break;

      curr = [self renderBlock:memo
                          into:output
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

@implementation MulleScionBlock( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
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
                       into:output
             localVariables:locals
                 dataSource:dataSource];
   if( [curr isEndBlock])
      curr = curr->next_;

   [pool release];

   return( curr);
}

@end


#pragma mark -

@implementation MulleScionEndBlock( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   TRACE_RENDER( self, s, locals, dataSource);

   popFileName( locals);

   return( self->next_);
}

@end



#pragma mark -

@implementation NSObject( MulleScionComparison)

- (BOOL) mulleScionIsEqual:(id) other
{
   if( other == MulleScionNull)
      return( [MulleScionNull mulleScionIsEqual:self]);
   return( [self isEqual:other]);
}


- (NSComparisonResult) mulleScionCompare:(id) other
{
   if( other == MulleScionNull)
      return( - [MulleScionNull mulleScionCompare:self]);
   return( [(id) self compare:other]);
}

@end


@implementation MulleScionComparison( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   id                   otherValue;
   BOOL                 flag;
   NSComparisonResult   comparisonResult;
   id                   result;

   TRACE_EVAL_BEGIN( self, value);

   NSParameterAssert( value);

   otherValue = [self->right_ valueWithLocalVariables:locals
                                           dataSource:dataSource];
   NSParameterAssert( otherValue);

   switch( comparison_)
   {
      case MulleScionEqual    : flag = [value mulleScionIsEqual:otherValue]; break;
      case MulleScionNotEqual : flag = ! [value mulleScionIsEqual:otherValue]; break;

      default                 :
         comparisonResult = [value mulleScionCompare:otherValue];
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

@implementation MulleScionNot( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   id   result;

   NSParameterAssert( value);

   result = [NSNumber numberWithBool:! isTrue( value)];

   TRACE_EVAL_BEGIN_END( self, value, result);
   return( result);
}

@end


#pragma mark -

@implementation MulleScionAnd( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   id     otherValue;
   id     result;
   BOOL   flag;

   NSParameterAssert( value);

   TRACE_EVAL_BEGIN( self, value);
   flag = isTrue( value);
   if( flag)
   {
      otherValue = [self->right_ valueWithLocalVariables:locals
                                              dataSource:dataSource];
      NSParameterAssert( otherValue);

      TRACE_EVAL_CONT( self, otherValue);

      flag = isTrue( otherValue);
   }
   result = [NSNumber numberWithBool:flag];

   TRACE_EVAL_END( self, result);
   return( result);
}

@end


#pragma mark -

@implementation MulleScionOr( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   id     otherValue;
   id     result;
   BOOL   flag;

   NSParameterAssert( value);
   TRACE_EVAL_BEGIN( self, value);

   flag = isTrue( value);
   if( ! flag)
   {
      otherValue = [self->right_ valueWithLocalVariables:locals
                                              dataSource:dataSource];
      NSParameterAssert( otherValue);

      TRACE_EVAL_CONT( self, otherValue);
      flag = isTrue( otherValue);
   }

   result = [NSNumber numberWithBool:flag];

   TRACE_EVAL_END( self, result);

   return( result);
}

@end


#pragma mark -

@implementation MulleScionIndexing( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   id   otherValue;
   id   result;

   NSParameterAssert( value);
   TRACE_EVAL_BEGIN( self, value);

   if( value == MulleScionNull)
      return( value);

   otherValue = [self->right_ valueWithLocalVariables:locals
                                           dataSource:dataSource];
   NSParameterAssert( otherValue);
   TRACE_EVAL_CONT( self, otherValue);

   if( [value respondsToSelector:@selector( objectAtIndex:)])
      result = [value objectAtIndex:[otherValue integerValue]]; // must be a NSNumber or NSString (?)
   else
      if( [value respondsToSelector:@selector( objectForKey:)])
      {
         result = nil;
         if( [otherValue respondsToSelector:@selector( copy)])  // check if valid NSDictionary key
            result = [value objectForKey:otherValue];
         if( ! result)
            result = [value objectForKey:[otherValue description]];  // hackish and useful ??
      }
      else
         result = [value valueForKeyPath:otherValue];

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
   NSParameterAssert( value);
   otherValue = [self->right_ valueWithLocalVariables:locals
                                           dataSource:dataSource];
   NSParameterAssert( otherValue);

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

   // need more code for dictionary set

   [value setValue:valueToSet == MulleScionNull ? nil : valueToSet
        forKeyPath:[otherValue description]];
}

@end


#pragma mark -

@implementation MulleScionPipe( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   NSString        *identifier;
   MulleScionPipe  *next;
   id              result;

   NSParameterAssert( value);
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
      NSParameterAssert( result);

      return( result);
   }

   next = (MulleScionPipe *) self->right_;
   NSParameterAssert( [next->value_ isKindOfClass:[MulleScionVariable class]]);

   identifier = [(MulleScionVariable *) next->value_ identifier];
   value      = [dataSource mulleScionPipeString:value
                                   throughMethod:identifier
                                  localVariables:locals];
   NSParameterAssert( value);

   result     = [self->right_ evaluateValue:value
                             localVariables:locals
                                 dataSource:dataSource];
   TRACE_EVAL_END( self, result);

   NSParameterAssert( result);
   return( result);
}

@end


#pragma mark -

@implementation MulleScionDot( Printing)

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
   NSParameterAssert( result);
   return( result);
}

@end


#pragma mark -

@implementation MulleScionConditional( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionExpression   *choice;
   id                     result;

   NSParameterAssert( value);
   TRACE_EVAL_BEGIN( self, value);

   choice = self->middle_;
   if( ! isTrue( value))
      choice = self->right_;

   result = [choice valueWithLocalVariables:locals
                                dataSource:dataSource];
   TRACE_EVAL_END( self, result);
   NSParameterAssert( result);
   return( result);
}

@end


#pragma mark -

@implementation MulleScionFilter( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionExpression  *prev;
   NSMutableArray        *stack;
   NSMutableArray        *modeStack;
   NSAutoreleasePool     *pool;
   id                    filter;
   NSNumber              *prevMode;

   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];

   updateLineNumber( self, locals);

   prev = [locals objectForKey:MulleScionCurrentFilterKey];
   if( prev)
   {
      prevMode = [locals objectForKey:MulleScionCurrentFilterModeKey];
      NSCParameterAssert( prevMode);

      stack     = [locals objectForKey:MulleScionPreviousFiltersKey];
      modeStack = [locals objectForKey:MulleScionPreviousFilterModesKey];
      if( ! stack)
      {
         NSParameterAssert( ! modeStack);

         stack     = [NSMutableArray new];
         [locals setObject:stack
                    forKey:MulleScionPreviousFiltersKey];
         [stack release];
         modeStack = [NSMutableArray new];
         [locals setObject:modeStack
                    forKey:MulleScionPreviousFilterModesKey];
         [modeStack release];
      }

      [stack addObject:prev];
      [modeStack addObject:prevMode];
   }

   filter = self->expression_;

   //
   // if it's not a self method execute it now, and use result as a filter
   // object
   //
   if( [self->expression_ isMethod] && ! [(MulleScionMethod *) self->expression_ isSelfMethod])
   {
      filter = [self->expression_ valueWithLocalVariables:locals
                                               dataSource:dataSource];
      if( ! [filter respondsToSelector:@selector( evaluateValue:localVariables:dataSource:)])
         MulleScionPrintingException( NSInvalidArgumentException, locals, @"filter object does not respond to -evaluateValue:localVariables:dataSource:");
   }

   if( filter == MulleScionNull)
      MulleScionPrintingException( NSInvalidArgumentException, locals, @"filter argument evaluates to nil");

   [locals setObject:filter
              forKey:MulleScionCurrentFilterKey];
   [locals setObject:[NSNumber numberWithUnsignedInteger:self->_flags]
              forKey:MulleScionCurrentFilterModeKey];

   [pool release];

   return( self->next_);
}

@end


#pragma mark -

@implementation MulleScionEndFilter( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   NSMutableArray         *stack;
   NSAutoreleasePool      *pool;
   MulleScionExpression   *filter;
   NSString               *s;
   NSNumber               *mode;

   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];

   updateLineNumber( self, locals);

   if( ! [locals objectForKey:MulleScionCurrentFilterKey])
      MulleScionPrintingException( NSInvalidArgumentException, locals, @"stray endfilter");

   // get current filter and tell it to flush
   filter = [locals objectForKey:MulleScionCurrentFilterKey];
   s      = [filter flushWithLocalVariables:locals
                                 dataSource:dataSource];

   // replace with filter from stack if available
   stack  = [locals objectForKey:MulleScionPreviousFiltersKey];
   filter = [stack lastObject];
   if( filter)
   {
      [locals setObject:filter
                 forKey:MulleScionCurrentFilterKey];
      [stack removeLastObject];

      stack = [locals objectForKey:MulleScionPreviousFilterModesKey];
      mode  = [stack lastObject];
      [locals setObject:mode
                 forKey:MulleScionCurrentFilterModeKey];
      [stack removeLastObject];
   }
   else
   {
      [locals removeObjectForKey:MulleScionCurrentFilterKey];
      [locals removeObjectForKey:MulleScionPreviousFilterModesKey];
   }

   // push flushed string through remaining filters
   if( s)
      MulleScionRenderString( s, output, locals, dataSource);

   [pool release];

   return( self->next_);
}

@end


static NSBundle  *search( NSFileManager *manager, NSString *identifier, NSString *path, NSString *subdir, NSString *extension)
{
   NSDirectoryEnumerator  *rover;
   NSString               *item;
   NSAutoreleasePool      *pool;
   NSBundle               *bundle;

   bundle = nil;
   pool = [NSAutoreleasePool new];
   if( subdir)
      path = [path stringByAppendingPathComponent:subdir];

   if( getenv( "MULLESCION_DUMP_BUNDLE_SEARCHPATH"))
      NSLog( @"Searching %@ with %@ extension", path, extension ? extension : @"any");

   rover = [manager enumeratorAtPath:path];

   while( item = [rover nextObject])
   {
      if( ! [[[rover fileAttributes] objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
         continue;
      [rover skipDescendants];

      if( extension && ! [[item pathExtension] isEqualToString:extension])
         continue;

      bundle = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:item]];
      if( [[bundle bundleIdentifier] isEqualToString:identifier])
         break;
      bundle = nil;
   }

   [bundle retain];
   [pool release];

   return( [bundle autorelease]);
}


static NSBundle  *searchForBundleInDirectory( NSFileManager *manager, NSString *identifier, NSString *path)
{
   NSBundle   *bundle;

   bundle = search( manager, identifier, path, @"Frameworks", @"framework");
   if( ! bundle)
      bundle = search( manager, identifier, path, @"PlugIns", nil);

   return( bundle);
}


#pragma mark -

@implementation MulleScionRequires( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) output
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   NSAutoreleasePool    *pool;
   NSBundle             *bundle;
   NSArray              *directories;
   NSString             *path;
   NSEnumerator         *rover;
   NSFileManager        *manager;

   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];

   updateLineNumber( self, locals);
   bundle = [NSBundle bundleWithIdentifier:identifier_];
   if( ! bundle)
   {
      manager = [NSFileManager defaultManager];
      bundle  = searchForBundleInDirectory( manager, identifier_, [[NSBundle mainBundle] builtInPlugInsPath]);
      if( ! bundle)
      {
         // search through frameworks
         directories = NSSearchPathForDirectoriesInDomains( NSLibraryDirectory, NSAllDomainsMask, YES);

         rover = [directories objectEnumerator];
         while( path = [rover nextObject])
         {
            bundle = searchForBundleInDirectory( manager, identifier_, path);
            if( bundle)
               break;
         }
      }
   }

#ifdef __MULLE_OBJC__
   if( ! [bundle loadBundle])
#else
   if( ! [bundle load])
#endif
      MulleScionPrintingException( NSInvalidArgumentException, locals, @"could not %@ bundle with identifier \"%@\"", bundle ? @"load" : @"locate", identifier_);

   [pool release];

   return( self->next_);
}

@end
