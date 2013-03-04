//
//  MulleScionObjectModel+Printing.m
//  MulleScionTemplates
//
//  Created by Nat! on 24.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionObjectModel+Printing.h"

#import "MulleMutableLineNumber.h"
#import "MulleScionNull.h"
#import "MulleScionPrintingException.h"
#import "MulleScionDataSourceProtocol.h"
#import "NSObject+MulleScionDescription.h"
#import <Foundation/NSDebug.h>
#import <objc/objc-class.h>


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
# define TRACE_RENDER( self, s, locals, dataSource)   fprintf( stderr, "%s\n", [[self shortDescription] cString])
#else
# define TRACE_RENDER( self, s, locals, dataSource)
#endif


#if 0
# define TRACE_EVAL_BEGIN( self, value)               fprintf( stderr, "%s\n", [[NSString stringWithFormat:@"-->%@ (%@)", [self shortDescription], value] cString])
# define TRACE_EVAL_END( self, value)                 fprintf( stderr, "%s\n", [[NSString stringWithFormat:@"<--%@ (%@)", [self shortDescription], value] cString])
# define TRACE_EVAL_CONT( self, value)                fprintf( stderr, "%s\n", [[NSString stringWithFormat:@"   %@ (%@)", [self shortDescription], value] cString])
# define TRACE_EVAL_BEGIN_END( self, value, result)   fprintf( stderr, "%s\n", [[NSString stringWithFormat:@"<->%@ (%@->%@)", [self shortDescription], value, result] cString])
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



@implementation MulleScionObject ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   TRACE_RENDER( self, s, locals, dataSource);
   return( self->next_);
}


static void   initLineNumber( MulleScionObject *self, NSMutableDictionary *locals)
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


@implementation MulleScionTemplate ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionObject   *curr;
   NSAutoreleasePool  *pool;
   
   TRACE_RENDER( self, s, locals, dataSource);

   pool = [NSAutoreleasePool new];
   
   //
   // expose everything to the dataSource for max. hackability
   // trusted (writing OK, reading ? your choice!)
   //
   initLineNumber( self, locals);
   updateLineNumber( self, locals);

   [locals setObject:s
              forKey:MulleScionRenderOutputKey];
   [locals setObject:value_
              forKey:MulleScionCurrentFileKey];

   // hard to do in templates
   [locals setObject:[NSNumber numberWithUnsignedLong:NSNotFound]
              forKey:@"NSNotFound"];
   
   curr = self->next_;
   while( curr)
      curr = [curr renderInto:s
               localVariables:locals
                   dataSource:dataSource];
   
   [pool release];
   
   return( curr);
}

@end


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


@implementation MulleScionVariable ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   return( MulleScionValueForKeyPath( value_, locals, dataSource));
}

@end


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
                  @"Method \"%@\" is unknown on \"%@\"", NSStringFromSelector( action_), target);
   
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
   
   original     = nil;
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


@implementation MulleScionNumber ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   return( value_ ? value_ : MulleScionNull);
}

@end



@implementation MulleScionString ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   NSParameterAssert( value_ != nil);
   return( value_);
}

@end


@implementation MulleScionSelector ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   NSParameterAssert( value_ != nil);
   return( [NSValue valueWithPointer:NSSelectorFromString( value_)]);
}

@end


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


@implementation MulleScionVariableAssignment ( Printing)

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


@interface MulleScionCommand( Printing)

- (MulleScionObject *) renderBlock:(MulleScionObject *) curr
                              into:(id <MulleScionOutput>) s
                    localVariables:(NSMutableDictionary *) locals
                        dataSource:(id <MulleScionDataSource>) dataSource;
@end


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


@implementation MulleScionSet ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   id   value;
   
   // lldb voodoo
   NSParameterAssert( [expression_ isKindOfClass:[MulleScionExpression class]]);
   
   value = [expression_ valueWithLocalVariables:locals
                                     dataSource:dataSource];
   [locals setObject:value
              forKey:identifier_];
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


@implementation MulleScionTerminator ( Printing)


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   TRACE_RENDER( self, s, locals, dataSource);

   MulleScionPrintingException( NSInternalInconsistencyException, locals, @"stray %@ in template", [self commandName]);
}


@end


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


@implementation MulleScionIf ( Printing)

static Class  _nsNumberClass;


static BOOL  isTrue( id value)
{
   if( value == MulleScionNull)
      return( NO);
   if( [value respondsToSelector:@selector( boolValue)])
      return( [value boolValue]);
   return( YES);
}


+ (void) load
{
   _nsNumberClass = [NSNumber class];
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

   value = [expression_ valueWithLocalVariables:locals
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
   
   curr    = self->next_;
   memo    = curr;

   info    = [NSMutableDictionary dictionary];
   infoKey = [NSString stringWithFormat:@"%@#", identifier_];
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
                 forKey:identifier_];

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
   [locals removeObjectForKey:identifier_];   // always nil anyway
   
   [pool release];
   
   return( curr);
}

@end


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



@implementation MulleScionComparison ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   id                   otherValue;
   BOOL                 flag;
   NSComparisonResult   comparison;
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
   case MulleScionEqual    : comparison = ([value isEqual:otherValue] ? NSOrderedSame : NSOrderedAscending); break;
   case MulleScionNotEqual : comparison = ([value isEqual:otherValue] ? NSOrderedAscending : NSOrderedSame); break;
   default                 : comparison = [value compare:otherValue]; break;
   }

   flag = NO;
   switch( comparison)
   {
   case NSOrderedSame       :
      switch( comparison_)
      {
      case MulleScionEqual                :
      case MulleScionLessThanOrEqualTo    :
      case MulleScionGreaterThanOrEqualTo :
         flag = YES;
      }
      break;
   case NSOrderedAscending  :
      switch( comparison_)
      {
      case MulleScionNotEqual          :
      case MulleScionLessThan          :
      case MulleScionLessThanOrEqualTo :
         flag = YES;
      }
      break;
   case NSOrderedDescending :
      switch( comparison_)
      {
      case MulleScionNotEqual             :
      case MulleScionGreaterThan          :
      case MulleScionGreaterThanOrEqualTo :
         flag = YES;
      }
      break;
   }

   result = [NSNumber numberWithBool:flag];

   TRACE_EVAL_END( self, result);
   return( result);
}

@end


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
      result = [value objectAtIndex:[otherValue unsignedLongValue]];
   else
      result = [value valueForKeyPath:[otherValue description]];

   if( ! result)
      result = MulleScionNull;
   
   TRACE_EVAL_END( self, result);

   return( result);
}

@end


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
      result      = [value mulleScionValueForKeyPath:identifier
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
